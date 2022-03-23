#!/bin/csh

set SYEAR = 1980
set EYEAR = 2014

set SYEAR = 2015
set EYEAR = 2019

set SYEAR = 2019

set IYEAR = $SYEAR

while ( $IYEAR <= $EYEAR )
   #echo $IYEAR
   sbatch TidalStation.csh $IYEAR
   @ IYEAR = $IYEAR + 1
end
