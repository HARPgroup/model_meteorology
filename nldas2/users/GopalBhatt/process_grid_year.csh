#!/bin/csh

set YEAR      = $argv[1]
set XGRID     = $argv[2]
set YGRID     = $argv[3]

set DIRECTORY = `pwd`
set OUTFOLDER = ${DIRECTORY}/$argv[4]

echo $OUTFOLDER

cd ../../
./NLDAS2_GRIB_to_ASCII ./-R/NLDAS_FORA0125_H.002 ${OUTFOLDER} ${YEAR} 01 01 00 ${YEAR} 12 31 23 1 $XGRID $YGRID
