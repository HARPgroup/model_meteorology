#!/bin/bash

#This function is intended to download daymet data for the input range.
#Data is downloaded as one netCDF per day

#Required inputs are:
#$1 = Date of interest
#$2-5 = Bounding box for download (associative array with north south west east in that order
#$6 = Single day download forcing, 1 or 0 and defaults to 0 (no forcing)

function downloadDaymet()
{
  #Define local variables for inputs to function:  
  local dateIn=$1
  #Pass in bbox
  declare -A bbox=(
  	#North and south coordinates are slighly more complicated as they are identified below using leading white space, that we remove via a second grep call
  	["north"]=$2
  	["south"]=$3
  	#For the east and west coordinates, get the first or second number that matches a literal minus sign (-) followed 
  	#by at least one digit possibly followed by a literal period (.) followed by potnetially more digits
  	["west"]=$4
  	["east"]=$5
  )
  
  local dayForcing="${6:-0}"
 
  #Set local variable for config information for convenience
  local configExt=".bil"
  local configDataset="daymet_precip"
  
  #Get the year associated with the date
  local YYYY=`date -d "${dateIn}" "+%Y"`
  #Get the julian day associated with the date
  local jday=`date -d "${dateIn}" "+%j"`
  #Get the next date for REST
  local nextDate=`date -d "${dateIn} + 1 days" "+%Y-%m-%d"`
  
  #Region - NA is used for conus. The complete list of regions is: na (North America), hi(Hawaii), pr(Puerto Rico)
  local region="na"
  
  #Daymet variables. Allow multiple, but variables should be space separated. 
  # The complete list of Daymet variables is: tmin, tmax, prcp, srad, vp, swe, dayl
  local var="prcp"
  
  echo "Accessing year ${YYYY} data for ${dateIn}"
  
  #Allow for future temperature or other met data downloads.
  #For now, par = $var = precip
  for par in $var; do
    echo "Getting ${par} data for ${dateIn}"
  	#Does the daily gtiff already exist?
    local checkFile="ORIGINAL_${configDataset}${dateIn}${configExt}"
    if [ ! -f "${checkFile}" ] || [ $dayForcing -eq 1 ]; then
      #Indivudal day either does not exist or forcing is on. Extract day from 
      #Rest services:
      #Output file named. This will be the netCDF downloaded from daymet
  	  local daymetOriginal="${configDataset}${par}_${dateIn}.nc"
  
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
  	  echo "Download data from REST for ${dayIn}"
  	  #For non-leap years, query January 1st through december 31st
  	  wget -O $daymetOriginal "https://thredds.daac.ornl.gov/thredds/ncss/grid/ornldaac/2129/daymet_v4_daily_${region}_${par}_${YYYY}.nc?var=lat&var=lon&var=${par}&north=${bbox["north"]}&west=${bbox["west"]}&east=${bbox["east"]}&south=${bbox["south"]}&horizStride=1&time_start=${dateIn}T00:00:00Z&time_end=${dateIn}T23:59:59Z&timeStride=1&accept=netcdf"
  	  
  	   
  	   
  	  echo "Confirming metadata accuracy for user input"
  	  #Find the dates associated with the bands, pulling the NETCDF dim time 
  	  #values from the metadata. This comes as 
  	  #NETCDF_DIM_time_VALUES={DATE1,DATE2,...,DATEN}
  	  #so we use pattern matching to find a repeating group using ()
  	  local bandDates=`gdalinfo NETCDF:"${daymetOriginal}":prcp | grep -oP "NETCDF_DIM_time_VALUES.*" | grep -oP "([0-9]*\.?[0-9]*,?[0-9]*\.?[0-9]*)+"`
  	   
  	  #Origin for dates:
  	  local dateOrigin=`gdalinfo NETCDF:"${daymetOriginal}":prcp | grep -oP "time#units=days since .*" | grep -oP "[0-9]+.*"`
  	  #GET ONLY DATE: ASSUMES 00:00:00 UTC!
  	  local dateOriginNoTime=`gdalinfo NETCDF:"${daymetOriginal}":prcp | grep -oP "time#units=days since .*" | grep -oP "[0-9]+.*" | grep -oP "[0-9]+-[0-9]+-[0-9]+"`
      
      #Get the day associated with the current raster based on $bandDates above.
      #Remove the decimal to floor down to an integer
      local bandDates=`echo $bandDates | grep -oP "^[0-9]+"`
      #Dates are 1 day behind, add 1
      local bandDates=$(( $bandDates + 1))
  	     
      #$bandDates is the days since $dateOriginNoTime (ASSUMES dateOriginN)
      local checkMetaDate=`date -d "${dateOriginNoTime} +$(( ${bandDates} -1 ))days" +%Y-%m-%d`
      
      if [ "$checkMetaDate" != "$dateIn" ]; then
        echo "WARNING: Date in Meta data does NOT match the expected date for band 1!"
      fi
        
      local finalTiff="ORIGINAL_${configDataset}${dateIn}${configExt}"
        
      #Send this band to its own raster
      gdal_translate -b 1 NETCDF:"${daymetOriginal}":prcp -of "EHdr" $finalTiff
	  echo "daymet data downloaded as NETCDF and translated to $finalTiff"
    else
      echo "The file ${checkFile} already exists. Please use forcing=1 to redownload this day (${dayIn}) or proceed to next date."
  	#End if statement for if file exists or download
  	fi
  #End var for loop
  done
}
