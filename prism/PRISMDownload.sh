#!/bin/bash

#The first user input should be the year at which to download all daily PRISM data
YYYY=$1

#The second input is the extent (a vector mask) by which the imported precip rasters should be clipped
maskExtent=$2

#A simple array that has the number of days in each month for the target year
days=(31 1 31 30 31 30 31 31 30 31 30 31)

#Evaluate if $YYYY is a leap year e.g. either divisible by 4 or 400, but not 100 inherently
a=$(( YYYY % 4 ))
b=$(( YYYY % 100 ))
c=$(( YYYY % 400 ))

#Check for leap year: is $a divisible by 4 and $b was not divisible by 100? or is $c divisible by 400?
if [ $a -eq 0 -a $b -ne 0 -o $c -eq 0 ]
then
#If leap year, set February days to 29
days[1]=29
else
#Otherwise set to 28
days[1]=28
fi

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
		
		#Bring into database
		
		
		rm $YYYY$MM$DD
		rm PRISM_ppt_stable_*
		rm PRISM-conus-4326*
	done
done

