#!/bin/bash

#The first user input should be the year at which to download all daily PRISM data
YYYY=$1

#The second input is the extent (a vector mask) by which the imported precip rasters should be clipped
maskExtent=$2

#Update the variable definition table. Only needs to be performed once to ensure PRISM data has a reference varkey and other data:
#--Update dh_variabledefinition to include a variable for prism data
#INSERT INTO dh_variabledefinition (varname,vardesc,vocabulary,varunits,varkey,datatype,varcode,isregular,timestep,timeunits,nodataval,status,options,varabbrev,multiplicity)
#VALUES ('PRISM Model Daily','PRISM raster import.','prism','mm/day','prism_mod_daily','cumulative','prism_mod_daily',1,86400,'seconds',-9999,1,'a:0:{}','PRISM','tstime_singular');


#Develop an array of config variables that may change with new versions or structure in Hydro
declare -A config=(
   ["entity_type"]="dh_feature"
   ["ext"]="_CBP.gtiff"
   ["scratchdir"]="/tmp"
   ["dataset"]="PRISM_precip_"
   ["varkey"]="prism_precip_raster"
   ["extent_hydrocode"]="cbp6_met_coverage"
   ["extent_ftype"]="cbp_met_grid"
   ["extent_bundle"]="landunit"
)

#Get the coverage feature associated with this kind of raster time series
#$extent_hydroid = dh_search_feature($config['extent_hydrocode'], $config['extent_bundle'], $config['extent_ftype']);

#Convert today's date into our unified format for import into database
# $date_ts = dh_handletimestamp($config['date'])

#Now, download a raster for each day of each month from the PRISM webpage
for MM in {1..12}
	do
	
	#Evaluate if $YYYY is a leap year e.g. either divisible by 4 or 400, but not 100 inherently. 
	#Below, we use the -d option to coerce date to get the maximum day available in each month of 
	#the input year. This is done in each step of the loop using the date coercion at the beginning 
	#e.g. the $y/$m/1 sets the date initially to the date $m/01/%y. From there, we addd a month and subtract a day.
	daysInMonth=`date -d "$YYYY/$MM/1 + 1 month - 1 day" "+%d"`
	
	for (( DD=1 ; DD<=$daysInMonth ; DD++ ))
		do
		
		finalTiff=${config["dataset"]}${YYYY}${MM}${DD}${config["ext"]}
		
		#Download and unzip the raster from the PRISM webservices
		wget http://services.nacse.org/prism/data/public/4km/ppt/$YYYY$MM$DD
		unzip $YYYY$MM$DD
				
		#Get a representative numeric value of the date to be compatible with VAHydro data, specifying a compatible timezone and getting the date in seconds
		tstime= `TZ="America/New_York" date -d "$YYYY-$MM-$DD 00:00:00" +'%s'`
		tsendtime=$(( $tstime+86400 ))
		
		
		#Based on information from the raster, projection comes in at EPSG 6269
		#So, we will need to reproject to 4326
		#gdalinfo gdalinfo RISM_ppt_stable_4kmD2_${YYYY}${MM}${DD}_bil.bil
		gdalwarp PRISM_ppt_stable_4kmD2_${YYYY}${MM}${DD}_bil.bil -t_srs EPSG:4326 -of "gtiff" "PRISM-conus-4326-${YYYY}${MM}${DD}.gtiff"
		
		#Clipping the raster: Use gdalwarp to crop to the cutline maskExtent.csv, which is a csv of the CBP regions 
		gdalwarp -of "gtiff" -cutline $maskExtent -crop_to_cutline PRISM-conus-4326-${YYYY}${MM}${DD}.gtiff $finalTiff
		
		#Create sql file that will add the raster (-a for amend or -d for drop and recreate) into the target table
		#The -t option tiles the raster for easier loading
		raster2pgsql -d -t 1000x1000 $finalTiff tmp_prism > tmp_prism-test.sql
		
		#Execute sql file to bring rasters into database (alpha)
		psql -h dbase2 -f "tmp_prism-test.sql" -d drupal.alpha
		
		#Now update dh_timeseries_weather
		echo "--insert into dh_timeseries_weather(tstime,tsendtime, varid, featureid, entity_type, rast)

			select '$tstime','$tsendtime', v.hydroid as varid, f.hydroid as featureid, '${config["entity_type"]}', met.rast
			from dh_feature as f 
			left outer join dh_variabledefinition as v
				on (v.varkey = '${config["varkey"]}')
			--We join in dh_timeseries_weather in case this data has already been created. This join will add no data if 
			--there is no matching data in dh_timeseries_weather
			left outer join dh_timeseries_weather as w
				on (f.hydroid = w.featureid and w.tstime = '${tstime}' and w.varid = v.hydroid) 
			left outer join tmp_prism as met
				on (1 = 1)
			--By specifying tid = NULL we ensure this query returns no rows if there is a match within dh_timeseries_weather
			WHERE w.tid is null
				AND f.hydrocode = '${config["extent_hydrocode"]}';" > updateWeatherRow.sql
			
   		#Add row to database via the output text file:
		psql -h dbase2 -f "updateWeatherRow.sql" -d drupal.alpha

		#Remove all create files for next loop
		rm $YYYY$MM$DD
		rm PRISM_ppt_stable_*
		rm PRISM-conus-4326*
		rm tmp_prism-test.sql
		rm updateWeatherRow.sql
	done
done

