#!/bin/bash

#The first user input should be the start year at which to begin downloading daymet data
startyr=$1

#The second input is the extent (a vector mask) by which the imported precip rasters should be clipped. This may be a file path to a WKT csv files, for instance.
maskExtent=$2

#Update the variable definition table. Only needs to be performed once to ensure PRISM data has a reference varkey and other data:
#--Update dh_variabledefinition to include a variable for prism data
#INSERT INTO dh_variabledefinition (varname,vardesc,vocabulary,varunits,varkey,datatype,varcode,isregular,timestep,timeunits,nodataval,status,options,varabbrev,multiplicity)
#VALUES ('daymet Model Daily','daymet raster import.','daymet','mm/day','daymet_mod_daily','cumulative','daymet_mod_daily',1,86400,'seconds',-9999,1,'a:0:{}','daymet','tstime_singular');


#Develop an array of config variables that may change with new versions or structure in Hydro
declare -A config=(
   ["entity_type"]="dh_feature"
   ["ext"]="_CBP.gtiff"
   ["scratchdir"]="/tmp"
   ["dataset"]="daymet_precip_"
   ["datasource"]="daymet"
   ["varkey"]="daymet_precip_raster"
   ["extent_hydrocode"]="cbp6_met_coverage"
   ["extent_ftype"]="cbp_met_grid"
   ["extent_bundle"]="landunit"
)

#Region - NA is used for conus. The complete list of regions is: na (North America), hi(Hawaii), pr(Puerto Rico)
region="na"

#Daymet variables. Allow multiple, but variables should be space separated. 
# The complete list of Daymet variables is: tmin, tmax, prcp, srad, vp, swe, dayl
var="prcp"

#Get the bounding box of the user selected mask.
#First, get the extent output from ogrinfo
bboxExtent=`ogrinfo $maskExtent maskExtent | grep "Extent: "`

#Use grep to get only the matching pattern (-o) via perl regular expression (-P) to identify the coordinates of the bounding box.
#This returns both the east/west coordinate or the north AND south coordinates. We can use head/tail to just get the coordinate 
#of interest for the array below
declare -A bbox=(
	#For the east and west coordinates, get the first or second number that matches a literal minus sign (-) followed 
	#by at least one digit possibly followed by a literal period (.) followed by potnetially more digits
	["west"]=`echo $bboxExtent | grep -oP "\-[0-9]+[\.]?[0-9]*" | head -1`
	["east"]=`echo $bboxExtent | grep -oP "\-[0-9]+[\.]?[0-9]*" | tail -1`
	#North and south coordinates are slighly more complicated as they are identified below using leading white space, that we remove via a second grep call
	["south"]=`echo $bboxExtent | grep -oP " [0-9]+[\.]?[0-9]*" | grep -oP "([0-9]+[\.]?[0-9]*){1}" | head -1`
	["north"]=`echo $bboxExtent | grep -oP " [0-9]+[\.]?[0-9]*" | grep -oP "([0-9]+[\.]?[0-9]*){1}" | tail -1`
)


for ((YYYY=startyr;YYYY<=endyr;YYYY++)); do
echo $YYYY
	for par in $var; do
	echo $par
		
		#Output file named. This will be the raster cropped to maskExtent and reprojected in EPSG:4326
		finalTiff=${config["dataset"]}${YYYY}${MM}${DD}${config["ext"]}
		
		#Evaluate if the year is a leap year. daymet uses 365 day years and on leap years December 31st will be missing:
		#Evaluate if $YYYY is a leap year e.g. either divisible by 4 or 400, but not 100 inherently. 
		#Below, we use the -d option to coerce date to get the maximum day available in each month of 
		#the input year. This is done in each step of the loop using the date coercion at the beginning 
		#e.g. the $y/$m/1 sets the date initially to the date $m/01/%y. From there, we addd a month and subtract a day.
		if [ `date -d "${YYYY}/02/1 + 1 month - 1 day" "+%d"` -eq 29 ]; then
			#For leap years, end query at december 30th
			wget -O ${par}_${YYYY}subset.nc "https://thredds.daac.ornl.gov/thredds/ncss/grid/ornldaac/2129/daymet_v4_daily_${region}_${par}_${YYYY}.nc?var=lat&var=lon&var=${par}&north=${bbox["north"]}&west=${bbox["west"]}&east=${bbox["east"]}&south=${bbox["south"]}&horizStride=1&time_start=${YYYY}-01-01T12:00:00Z&time_end=${YYYY}-12-30T12:00:00Z&timeStride=1&accept=netcdf"
		else
			#For non-leap years, query january 1st through december 31st
			wget -O ${par}_${YYYY}subset.nc "https://thredds.daac.ornl.gov/thredds/ncss/grid/ornldaac/2129/daymet_v4_daily_${region}_${par}_${YYYY}.nc?var=lat&var=lon&var=${par}&north=${bbox["north"]}&west=${bbox["west"]}&east=${bbox["east"]}&south=${bbox["south"]}&horizStride=1&time_start=${YYYY}-01-01T12:00:00Z&time_end=${YYYY}-12-31T12:00:00Z&timeStride=1&accept=netcdf"
			
		fi
		
		#Based on information from the raster, projection comes in at EPSG 6269
		#So, we will need to reproject to 4326
		#gdalinfo gdalinfo RISM_ppt_stable_4kmD2_${YYYY}${MM}${DD}_bil.bil
		gdalwarp NETCDF:"${par}_${YYYY}subset.nc":prcp -t_srs EPSG:4326 -of "gtiff" "${config["datasource"]}-${par}-${YYYY}.gtiff"
		
		#Clipping the raster: Use gdalwarp to crop to the cutline maskExtent.csv, which is a csv of the CBP regions 
		gdalwarp -of "gtiff" -cutline $maskExtent -crop_to_cutline ${config["datasource"]}-${par}-${YYYY}.gtiff $finalTiff
		
		#Identify how many bands there are in the raster. For a full year download, 
		#this should be 365. However, we should evaluate this programmatically to 
		#be sure. Below, we get only the band numbers from gdal info by first 
		#searching in the pattern Band XX and then getting only the maximum number 
		#via a reverse sort
		numBands=`gdalinfo daymet-prcp-2023.gtiff -nomd -norat | grep -oP "Band [0-9]* " | grep -oP "[0-9]*" | sort -nr | head -n1`
		
		#Find the dates associated with the bands, pulling the NETCDF dim time 
		#values from the metadata. This comes as 
		#NETCDF_DIM_time_VALUES={DATE1,DATE2,...,DATEN}
		#so we use pattern matching to find a repeating group using ()
		bandDates=`gdalinfo daymet_precip_2023_CBP.gtiff | grep -oP "NETCDF_DIM_time_VALUES.*" | grep -oP "([0-9]*\.?[0-9]*,?[0-9]*\.?[0-9]*)+"`
		
		#Origin for dates:
		dateOrigin=`gdalinfo daymet_precip_2023_CBP.gtiff | grep -oP "time#units=days since .*" | grep -oP "[0-9]+.*"`
		#Seconds before epoch
		timeBeforeEpoch=`date --date="$dateOrigin" +'%s'`
		
		for (( i=1 ; DDIt<=$numBands ; i++ ))
		  do
		  #Get the day associated with the current raster based on $bandDates above.
		  #Use awk to search in a comma separated (-F ',') file for line $i.
		  #Note the use of single quotes!
		  bandDatei=`echo $bandDates | awk -F ',' '{print $'$i'}'`
		  
		  #bandDatei is the days since 1950-01-01 00:00:00. We need seconds 
		  #after epoch
		  echo $(( $bandDatei * 86400 + $timeBeforeEpoch ))
		  
		  
		  met_raster2db.sh ${config["datasource"]} $finalTiff "$YYYY-01-01 00" 86400 ${config["entity_type"]} ${config["varkey"]} $i
		  
		done
		
		#addRasterToDBase2 "$YYYY-$MM-$DD 00" config $finalTiff 86400
		
		
		
		#################TESTING
		#Get a representative numeric value of the date to be compatible with VAHydro data, specifying a compatible timezone and getting the date in seconds
		tstime=`TZ="America/New_York" date -d "$YYYY-$MM-$DD 00:00:00" +'%s'`
		tsendtime=$(( $tstime+86400 ))
		
		#Create sql file that will add the raster (-a for amend or -d for drop and recreate) into the target table
		#The -t option tiles the raster for easier loading
		raster2pgsql -d -t 1000x1000 -b 1 $finalTiff tmp_${config["datasource"]} > tmp_${config["datasource"]}-test.sql
		
		#Execute sql file to bring rasters into database (alpha)
		psql -h dbase2 -f "tmp_${config["datasource"]}-test.sql" -d drupal.alpha
		
		########################
		
	done;
done


