#!/bin/bash

#The first user input should be the year at which to download all daily PRISM data
YYYY=$1

#The second input is the extent (a vector mask) by which the imported precip rasters should be clipped
maskExtent=$2

#A simple array that will have the number of days in each month for the target year
declare -a days

#Evaluate if $YYYY is a leap year e.g. either divisible by 4 or 400, but not 100 inherently. 
#Below, we use the -d option to coerce date to get the maximum day available in each month of 
#the input year. This is done in each step of the loop using the date coercion at the beginning 
#e.g. the $y/$m/1 sets the date initially to the date $m/01/%y. From there, we addd a month and subtract a day.
for m in {1..12}; do
  days[$m - 1]=`date -d "$m/1 + 1 month - 1 day" "+%d"`
done

#Now, download a raster for each day of each month from the PRISM webpage
for i in {0..11}
	do
	for (( j=1 ; j<=${days[$i]} ; j++ ))
		do
		wget http://services.nacse.org/prism/data/public/4km/ppt/$YYYY$MM$DD
		unzip $YYYY$MM$DD
		
		#Based on information from the raster, projection comes in at EPSG 6269
		#So, we will need to reproject to 4326
		#gdalinfo gdalinfo PRISM_ppt_stable_4kmD2_20090407_bil.bil
		 gdalwarp PRISM_ppt_stable_4kmD2_$YYYY$MM$DD_bil.bil -t_srs EPSG:4326 "PRISM-conus-4326-$YYYY$MM$DD.bil"
		
		#Clipping the raster: Use gdalwarp to crop to the cutline maskExtent.csv, which is a csv of the CBP regions 
		gdalwarp -cutline $maskExtent -crop_to_cutline PRISM-conus-4326.bil PRISM-CBP-4326-$YYYY$MM$DD.bil
		
		#Create sql file that will add the raster (-a for amend) into the target table
		raster2pgsql -a -t 1000x1000 PRISM-CBP-4326-$YYYY$MM$DD.bil tmp_prism > tmp_prism-test.sql
		
		#Execute sql file to bring raster into database (alpha)
		psql -h dbase2 -f "tmp_prism-test.sql" -d drupal.alpha
		
		#Remove all create files for next loop
		rm $YYYY$MM$DD
		rm PRISM_ppt_stable_*
		rm PRISM-conus-4326*
		rm tmp_prism-test.sql
	done
done

