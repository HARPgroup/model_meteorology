#!/bin/bash

function downloadDailyPRISM()
{
#Arugments to this function should be in the following order:
#1 = config = array with datasource, varkey, extent_hydrocode, and other relevant information for adding file to dbase2
#2 = finalTiff = File path of the raster to import into dbase
#3 = maskExtent = file path to the cutline
#4 = YYYY = Four digit year e.g. 2024
#5 = MM = Two digit month e.g. 05 for May
#6 = DD = Two-digit day e.g 09 for the 9th

#We set up a local name reference to the config array passed in by the user to easily access its value
#CAUTION: Changes to confignr likely impact the original array passed by user!
local -n confignr=$1

echo "Getting data from REST..."
#Download and unzip the raster from the PRISM webservices
wget http://services.nacse.org/prism/data/public/4km/ppt/$YYYY$MM$DD
unzip $YYYY$MM$DD

echo "Projecting raster..."
#Based on information from the raster, projection comes in at EPSG 6269
#So, we will need to reproject to 4326
#gdalinfo gdalinfo RISM_ppt_stable_4kmD2_${YYYY}${MM}${DD}_bil.bil
gdalwarp PRISM_ppt_stable_4kmD2_${YYYY}${MM}${DD}_bil.bil -t_srs EPSG:4326 -of "gtiff" "${confignr["datasource"]}-conus-4326-${YYYY}${MM}${DD}.gtiff"

echo "Clipping raster..."
#Clipping the raster: Use gdalwarp to crop to the cutline maskExtent.csv, which is a csv of the CBP regions 
gdalwarp -of "gtiff" -cutline $maskExtent -crop_to_cutline ${confignr["datasource"]}-conus-4326-${YYYY}${MM}${DD}.gtiff $finalTiff

echo "Removing unecessary files..."
#Remove all create unecessary files:
rm $YYYY$MM$DD
rm PRISM_ppt_stable_*
rm ${confignr["datasource"]}-conus-4326*
}