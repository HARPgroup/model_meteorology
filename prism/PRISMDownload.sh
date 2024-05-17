#!/bin/bash

#The first user input should be the year at which to download all daily PRISM data
YYYY=$1

#The second input is the extent (a vector mask) by which the imported precip rasters should be clipped
maskExtent=$2

#Develop an array of config variables that may change with new versions or structure in Hydro
declare -A configTest=( ["date"]=`date "+%Y-%m-%d"`
   ["entity_type"]="dh_feature"
   ["ext"]="_conus.tif"
   ["scratchdir"]="/tmp"
   ["multiplicity"]="tstime_singular"
   ["dataset"]="prism_precip_1day_"
   ["varkey"]="prism_precip_raster"
   ["extent_hydrocode"]="cbp6_met_coverage"
   ["extent_ftype"]="cbp_met_grid"
   ["extent_bundle"]="landunit"
   #["dbname" => $databases["default"]["default"]["database"],
   #["host" => $databases["default"]["default"]["host"],
   #["username" => $databases["default"]["default"]["username"],
)

#Get the coverage feature associated with this kind of raster time series
#$extent_hydroid = dh_search_feature($config['extent_hydrocode'], $config['extent_bundle'], $config['extent_ftype']);

#Convert today's date into our unified format for import into database
# $date_ts = dh_handletimestamp($config['date'])


#A simple array that will have the number of days in each month for the target year
declare -a days

#Evaluate if $YYYY is a leap year e.g. either divisible by 4 or 400, but not 100 inherently. 
#Below, we use the -d option to coerce date to get the maximum day available in each month of 
#the input year. This is done in each step of the loop using the date coercion at the beginning 
#e.g. the $y/$m/1 sets the date initially to the date $m/01/%y. From there, we addd a month and subtract a day.
for m in {1..12}; do
  days[$m - 1]=`date -d "$m/1 + 1 month - 1 day" "+%d"`
done


# create an empty record that we can later append the raster to 
declare -A values=(
    ['featureid']=$extent_hydroid
    ['entity_type']='dh_feature'
    ['tstime']=$date_ts
    ['tsendtime']=$(( $date_ts+86400 ))
    ['varid']=$varkey
)


#Now, download a raster for each day of each month from the PRISM webpage
for i in {0..11}
	do
	for (( j=1 ; j<=${days[$i]} ; j++ ))
		do
		#Download and unzip the raster from the PRISM webservices
		wget http://services.nacse.org/prism/data/public/4km/ppt/$YYYY$MM$DD
		unzip $YYYY$MM$DD
		
		#Update values to have the dates that are associated with this raster
		values["tstime"]=dh_handletimestamp $YYYY$MM$DD
		values["tsendtime"]=$(( values["tstime"]+86400 ))
		
		#Update dh_timeseries_weather with appropriate information
		echo "INSERT INTO dh_timeseries_weather (
			tstime,
			tsendtime,
			entity_type,
			featureid,
			varid)
		VALUES ( ${values["tstime"]}, ${values["tsendtime"]}, ${values["entity_type"]}, ${values["featureid"]}, ${values["varid"]} )" > insertWeatherRow.sql
		
		#Add row to database via the output text file:
		psql -h dbase2 -f "insertWeatherRow.sql" -d drupal.alpha #WE NEED TO GET THE TID ASSOCIATED WITH THIS INSERT
		#tid=VALUE FROM ABOVE!

		
		#Based on information from the raster, projection comes in at EPSG 6269
		#So, we will need to reproject to 4326
		#gdalinfo gdalinfo RISM_ppt_stable_4kmD2_${YYYY}${MM}${DD}_bil.bil
		gdalwarp PRISM_ppt_stable_4kmD2_${YYYY}${MM}${DD}_bil.bil -t_srs EPSG:4326 -of "gtiff" "PRISM-conus-4326-${YYYY}${MM}${DD}.gtiff"
		
		#Clipping the raster: Use gdalwarp to crop to the cutline maskExtent.csv, which is a csv of the CBP regions 
		gdalwarp -cutline $maskExtent -crop_to_cutline PRISM-conus-4326-${YYYY}${MM}${DD}.gtiff PRISM-CBP-4326-${YYYY}${MM}${DD}.gtiff
		
		#Create sql file that will add the raster (-a for amend) into the target table
		raster2pgsql -d -t 1000x1000 PRISM-CBP-4326-$YYYY$MM$DD.bil tmp_prism > tmp_prism-test.sql
		
		#Execute sql file to bring rasters into database (alpha)
		psql -h dbase2 -f "tmp_prism-test.sql" -d drupal.alpha
		
		#Now update dh_timeseries_weather
		echo "update dh_timeseries_weather
			set rast = foo.rast
			from (
			select prism.rast as rast
			from dh_feature as a
			left outer join field_data_dh_geofield as b
			on (
				a.hydroid = b.entity_id
				and b.entity_type = 'dh_feature'
			)
			left outer join dh_variabledefinition as c
			on (
				c.varkey = '$varkey'
			)
			left outer join tmp_prism as prism
			on (1 = 1)
				where b.entity_id is not null
				and c.hydroid is not null
				and a.hydroid = $extent_hydroid
			) as foo
			where tid = $tid" > updateWeatherRow.sql
			
   		#Add row to database via the output text file:
		psql -h dbase2 -f "updateWeatherRow.sql" -d drupal.alpha

		#Remove all create files for next loop
		rm $YYYY$MM$DD
		rm PRISM_ppt_stable_*
		rm PRISM-conus-4326*
		rm tmp_prism-test.sql
		rm updateWeatherRow.sql
		rm insertWeatherRow.sql
	done
done

#To do:
#Use dh_update_timeseries_weather to update the timeseries table with the values array above
#Create varkey
