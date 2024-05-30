#!/bin/bash

#This script is intended to download daymet data for the input range.
#Data is downloaded as one netCDF per year, each raster having 365 bands
#Only full years are downloaded but LEAP YEARS REMOVE DEC 31st!

#Required inputs are:
#$1 = Date of interest
#$2 = Output directory
#$3 = Single day download forcing, 1 or 0 and defaults to 0 (no forcing)
#$4 = Redownload year forcing, 1 or 0 and defaults to 0 (no forcing)
dateIn=$1
output_dir=$2
dayForcing="${3:-0}"
yearForcing="${4:-0}"
configExt=${config["ext"}
configDataset=${config["dataset"}

#Get the year associated with the date
YYYY=`date -d "${dateIn}" "+%Y"`
#Get the julian day associated with the date
jday=`date -d "${dateIn}" "+%j"`

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


#In case of need of loop for several years, see below commented out loop:
#for ((YYYY=startYear;YYYY<=endYear;YYYY++)); do
echo $YYYY
#Allow for future temperature or other met data downloads.
#For now, par = $var = precip
for par in $var; do
  echo $par
	#Output file named for the full year archive. This will be the netCDF downloaded from daymet
	daymetOriginal="${output_dir}/${configDataset}${par}_${YYYY}.nc"
  
  #Evalute the user input configuration. Is the full year to be downloaded?
  #Is forcing on?
  #If the full year archive is not available, download and extract all days.
  #If it is available and forcing is on OR the request day is unavailable, extract
  #from the full year archive.
  if [ ! -f "${output_dir}/${YYYY}/${daymetOriginal}" ] || [ $yearForcing -eq 1 ]; then
    #Download full year archive and extract all days:
    
    #Evaluate if the year is a leap year. daymet uses 365 day years and on leap years December 31st will be missing:
	  #Evaluate if $YYYY is a leap year e.g. either divisible by 4 or 400, but not 100 inherently. 
	  #Below, we use the -d option to coerce date to get the maximum day available in each month of 
	  #the input year. This is done in each step of the loop using the date coercion at the beginning 
	  #e.g. the $y/$m/1 sets the date initially to the date $m/01/%y. From there, we addd a month and subtract a day.
	  if [ `date -d "${YYYY}/02/1 + 1 month - 1 day" "+%d"` -eq 29 ]; then
	  	#For leap years, end query at december 30th
	  	wget -O $daymetOriginal "https://thredds.daac.ornl.gov/thredds/ncss/grid/ornldaac/2129/daymet_v4_daily_${region}_${par}_${YYYY}.nc?var=lat&var=lon&var=${par}&north=${bbox["north"]}&west=${bbox["west"]}&east=${bbox["east"]}&south=${bbox["south"]}&horizStride=1&time_start=${YYYY}-01-01T00:00:00Z&time_end=${YYYY}-12-30T23:59:59Z&timeStride=1&accept=netcdf"
	  else
	  	#For non-leap years, query january 1st through december 31st
	  	wget -O $daymetOriginal "https://thredds.daac.ornl.gov/thredds/ncss/grid/ornldaac/2129/daymet_v4_daily_${region}_${par}_${YYYY}.nc?var=lat&var=lon&var=${par}&north=${bbox["north"]}&west=${bbox["west"]}&east=${bbox["east"]}&south=${bbox["south"]}&horizStride=1&time_start=${YYYY}-01-01T00:00:00Z&time_end=${YYYY}-12-31T23:59:59Z&timeStride=1&accept=netcdf"
	  fi
	  
	  #Identify how many bands there are in the raster. For a full year download, 
	  #this should be 365. However, we should evaluate this programmatically to 
	  #be sure. Below, we get only the band numbers from gdal info by first 
	  #searching in the pattern Band XX and then getting only the maximum number 
	  #via a reverse sort
	  numBands=`gdalinfo NETCDF:"${daymetOriginal}":prcp -nomd -norat | grep -oP "Band [0-9]* " | grep -oP "[0-9]*" | sort -nr | head -n1`
	  
	  #Find the dates associated with the bands, pulling the NETCDF dim time 
	  #values from the metadata. This comes as 
	  #NETCDF_DIM_time_VALUES={DATE1,DATE2,...,DATEN}
	  #so we use pattern matching to find a repeating group using ()
	  bandDates=`gdalinfo NETCDF:"${daymetOriginal}":prcp | grep -oP "NETCDF_DIM_time_VALUES.*" | grep -oP "([0-9]*\.?[0-9]*,?[0-9]*\.?[0-9]*)+"`
	  
	  #Origin for dates:
	  dateOrigin=`gdalinfo NETCDF:"${daymetOriginal}":prcp | grep -oP "time#units=days since .*" | grep -oP "[0-9]+.*"`
	  #GET ONLY DATE: ASSUMES 00:00:00 UTC!
	  dateOriginNoTime=`gdalinfo NETCDF:"${daymetOriginal}":prcp | grep -oP "time#units=days since .*" | grep -oP "[0-9]+.*" | grep -oP "[0-9]+-[0-9]+-[0-9]+"`
	  
	  for (( i=1 ; i<=$numBands ; i++ ))
	    do
	    #Write data to the appropriate folder:
      #Check if base directory for the julian day exists. If not, create it:
      if [ ! -d "${output_dir}/${YYYY}/${i}" ]; then
        #Using -p option, create the Parent year directory if it has not yet 
        #been created
        mkdir -p "${output_dir}/${YYYY}/${i}" 
      fi
      #Set the source directory for this file:
      src_dir="${output_dir}/${YYYY}/${i}"
	    
	    #Get the day associated with the current raster based on $bandDates above.
	    #Use awk to search in a comma separated (-F ',') file for line $i.
	    #Note the use of single quotes! Remove the decimal to floor down to an 
	    #integer
	    bandDatei=`echo $bandDates | awk -F ',' '{print $'$i'}' | grep -oP "^[0-9]+"`
	    #Dates are 1 day behind, add 1
	    bandDatei=$(( $bandDatei + 1))
	    
	    #bandDatei is the days since $dateOriginNoTime (ASSUMES dateOriginN)
	    checkMetaDate=`date -d "${dateOriginNoTime} +$(( ${bandDatei} -1 ))days" +%Y-%m-%d`
      #Based on julian day (estimated based on assumption of complete dataset 
      #and the raster band number)
      checkJulianDate=`date -d "${YYYY}-01-01 +$(( ${i} -1 ))days" +%Y-%m-%d`
      
      if [ "$checkMetaDate" != "$checkJulianDate" ]; then
        echo "WARNING: Date in Meta data does NOT match the expected date for band ${i}!"
      fi
      
      finalTiff="ORIGINAL_${configDataset}${checkJulianDate}${configExt}"
      
      #Send this band to its own raster
	    gdal_translate -b $i NETCDF:"${daymetOriginal}":prcp -of "gtiff" $src_dir/$finalTiff
	    
	  #End band for loop
	  done
    
  else
    #Annual archive already exists
    annualArchive=${output_dir}/${YYYY}/${daymetOriginal}
    #Does the daily gtiff already exist?
    checkFile="ORIGINAL_${configDataset}${dateIn}${configExt}"
    if [ ! -f "${output_dir}/${YYYY}/${jday}/${checkFile}" ] || [ $dayForcing -eq 1 ]; then
      #Indivudal day either does not exist or forcing is on. Extract day from 
      #Rest services:
      #Output file named. This will be the netCDF downloaded from daymet
	    daymetOriginal="${output_dir}/${configDataset}${par}_${dateIn}.nc"
	
	    #Evaluate if the year is a leap year. daymet uses 365 day years and on leap years December 31st will be missing:
	    #Evaluate if $YYYY is a leap year e.g. either divisible by 4 or 400, but not 100 inherently. 
	    #Below, we use the -d option to coerce date to get the maximum day available in each month of 
	    #the input year. This is done in each step of the loop using the date coercion at the beginning 
	    #e.g. the $y/$m/1 sets the date initially to the date $m/01/%y. From there, we addd a month and subtract a day.
	    if [ `date -d "${YYYY}/02/1 + 1 month - 1 day" "+%d"` -eq 29 ]; then
	    	if [ "${dateIn}" = "${YYYY}-12-31" ];then
	    	#For leap years, end query at december 30th
	    	  echo "DECEMBER 31st CANNOT BE DOWNLOADED DUE TO DAYMET YEAR LIMITATIONS"
	    	  exit
	    	fi
	    fi
	    #For non-leap years, query January 1st through december 31st
	    wget -O $daymetOriginal "https://thredds.daac.ornl.gov/thredds/ncss/grid/ornldaac/2129/daymet_v4_daily_${region}_${par}_${YYYY}.nc?var=lat&var=lon&var=${par}&north=${bbox["north"]}&west=${bbox["west"]}&east=${bbox["east"]}&south=${bbox["south"]}&horizStride=1&time_start=${dateIn}T00:00:00Z&time_end=${dateIn}T23:59:59Z&timeStride=1&accept=netcdf"
	    
	    #Find the dates associated with the bands, pulling the NETCDF dim time 
	    #values from the metadata. This comes as 
	    #NETCDF_DIM_time_VALUES={DATE1,DATE2,...,DATEN}
	    #so we use pattern matching to find a repeating group using ()
	    bandDates=`gdalinfo NETCDF:"${daymetOriginal}":prcp | grep -oP "NETCDF_DIM_time_VALUES.*" | grep -oP "([0-9]*\.?[0-9]*,?[0-9]*\.?[0-9]*)+"`
	    
	    #Origin for dates:
	    dateOrigin=`gdalinfo NETCDF:"${daymetOriginal}":prcp | grep -oP "time#units=days since .*" | grep -oP "[0-9]+.*"`
	    #GET ONLY DATE: ASSUMES 00:00:00 UTC!
	    dateOriginNoTime=`gdalinfo NETCDF:"${daymetOriginal}":prcp | grep -oP "time#units=days since .*" | grep -oP "[0-9]+.*" | grep -oP "[0-9]+-[0-9]+-[0-9]+"`
	    
      #Write data to the appropriate folder:
      #Check if base directory for the julian day exists. If not, create it:
      if [ ! -d "$output_dir/$YYYY/$jday" ]; then
        #Using -p option, create the Parent year directory if it has not yet 
        #been created
        mkdir -p "$output_dir/$YYYY/$jday" 
      fi
      #Set the source directory for this file:
      src_dir="$output_dir/$YYYY/$jday"
      
      #Get the day associated with the current raster based on $bandDates above.
      #Remove the decimal to floor down to an integer
      bandDates=`echo $bandDates | grep -oP "^[0-9]+"`
      #Dates are 1 day behind, add 1
      bandDates=$(( $bandDates + 1))
	      
      #$bandDates is the days since $dateOriginNoTime (ASSUMES dateOriginN)
      checkMetaDate=`date -d "${dateOriginNoTime} +$(( ${bandDates} -1 ))days" +%Y-%m-%d`
      
      if [ "$checkMetaDate" != "$dateIn" ]; then
        echo "WARNING: Date in Meta data does NOT match the expected date for band 1!"
      fi
        
      finalTiff="ORIGINAL_${configDataset}${dateIn}${configExt}"
        
      #Send this band to its own raster
      gdal_translate -b 1 NETCDF:"${daymetOriginal}":prcp -of "gtiff" $src_dir/$finalTiff
    fi
  fi
	
#End var for loop
done



