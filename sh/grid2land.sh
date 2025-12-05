#!/bin/bash
#sDate = start date in the format YYYYMMDDHH
#eDate = end date in the format YYYYMMDDHH
. hspf_config
echo "NLDAS_ROOT = $NLDAS_ROOT"
# declaring arguments and telling user what they are
echo "The start date of the timeframe is $1"
sDate=$1
echo "The end date of the timeframe is $2"
eDate=$2
echo "The directory of your grided data is $3"
gDir=$3
echo "The desired output directory is $4"
oDir=$4
landname=$5

# splitting up dates into components
sYear=$(echo $sDate | cut -c1-4)
sMonth=$(echo $sDate | cut -c5-6)
sDay=$(echo $sDate | cut -c7-8)
sHour=$(echo $sDate | cut -c9-10)
eYear=$(echo $eDate | cut -c1-4)
eMonth=$(echo $eDate | cut -c5-6)
eDay=$(echo $eDate | cut -c7-8)
eHour=$(echo $eDate | cut -c9-10)

met_land_cells=`$NLDAS_ROOT/nldas_land_cells $landname`
# @todo: use the date function to see if we can tell which cells 
#        have already been processed, and then omit them 
# get the modified timestamp of the target file ion seconds since the epoch
# date -r $gdir/$cell "+%s"


cYear=$sYear
complete=0
while [ $complete != 1 ]; do
 if [ $cYear -le $eYear ]; then
    echo "NLDAS2_GRIB_to_ASCII $gDir $oDir $cYear $sMonth $sDay $sHour $cYear $eMonth $eDay $eHour $met_land_cells"
    NLDAS2_GRIB_to_ASCII $gDir $oDir $cYear $sMonth $sDay $sHour $cYear $eMonth $eDay $eHour $met_land_cells
  else
    complete=1
  fi
  cYear=$[$cYear+1]
done
