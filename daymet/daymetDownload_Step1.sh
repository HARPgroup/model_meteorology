#!/bin/bash

#This script is intended to download daymet data for the input range.
#Data is downloaded as one netCDF per year, each raster having 365 bands
#Only full years are downloaded but LEAP YEARS REMOVE DEC 31st!

#Required inputs are:
#$1 = Start year
#$2 = End year, may equal start Year
#3 = File to mask extent to be used for bounding box of downloads
startYear=$1
endYear=$2
maskExtent=$3

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
