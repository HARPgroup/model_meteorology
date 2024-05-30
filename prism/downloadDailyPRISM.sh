#!/bin/bash

function downloadDailyPRISM()
{
	#Arugments to this function should be in the following order:
	#1 = finalTiff = File path of the raster to import into dbase
	#2= YYYY = Four digit year e.g. 2024
	#3 = MM = Two digit month e.g. 05 for May
	#4 = DD = Two-digit day e.g 09 for the 9th

	#We set up a local name reference to the config array passed in by the user to easily access its value
	#CAUTION: Changes to confignr likely impact the original array passed by user!
	finalTiff=$1
	YYYY=$2
	MM=$3
	DD=$4
	>&2 echo "Getting data from PRISM REST service..."
	>&2 echo "Trying: wget http://services.nacse.org/prism/data/public/4km/ppt/$YYYY$MM$DD "
	#Download and unzip the raster from the PRISM webservices
	wget http://services.nacse.org/prism/data/public/4km/ppt/$YYYY$MM$DD
	unzip $YYYY$MM$DD
	download_name="PRISM_ppt_*${YYYY}${MM}${DD}_bil.bil"
	#Check if file exists. Recent day may be provisional and have a different name than "stable" data.
	#We send the output of compgen below to /dev/null bitbucket to ensure it doesn't echo anything to the terminal
	if compgen -G $download_name > /dev/null; then
		#Since stable and orignal data may have different names, we can use comgen with glob patterns(option -G)
		#to get the file name of the downloaded file
		originalFile=`compgen -G $download_name`
		mv $originalFile $finalTiff
		#Based on information from the raster, projection comes in at EPSG 6269
		#So, we will need to reproject to 4326
		rm $YYYY$MM$DD
		rm PRISM_ppt_*
		originalFile=$finalTiff
	else
		>&2 echo "PRISM download could not find $download_name "
		>&2 echo "Downloaded files have unique format. Please check..."
		originalFile="-9999"
	fi
	# return the file name to the calling statement
	return $originalFile
}

function downloadProcessDailyPRISM()
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
#Check if file exists. Recent day may be provisional and have a different name than "stable" data.
#We send the output of compgen below to /dev/null bitbucket to ensure it doesn't echo anything to the terminal
if compgen -G "PRISM_ppt_*${YYYY}${MM}${DD}_bil.bil" > /dev/null; then
	#Since stable and orignal data may have different names, we can use comgen with glob patterns(option -G)
	#to get the file name of the downloaded file
    originalFile=`compgen -G "PRISM_ppt_*${YYYY}${MM}${DD}_bil.bil"`
	
	#Based on information from the raster, projection comes in at EPSG 6269
	#So, we will need to reproject to 4326
	gdalwarp $originalFile -t_srs EPSG:4326 -of "gtiff" "${confignr["datasource"]}-conus-4326-${YYYY}${MM}${DD}.gtiff"

	echo "Clipping raster..."
	#Clipping the raster: Use gdalwarp to crop to the cutline maskExtent.csv, which is a csv of the CBP regions 
	gdalwarp -of "gtiff" -cutline $maskExtent -crop_to_cutline ${confignr["datasource"]}-conus-4326-${YYYY}${MM}${DD}.gtiff $finalTiff

	echo "Removing unecessary files..."
	#Remove all create unecessary files:
	rm $YYYY$MM$DD
	rm PRISM_ppt_*
	rm ${confignr["datasource"]}-conus-4326*
else
	echo "File not found!"
	echo "Downloaded files have unique format. Please check..."
fi
}