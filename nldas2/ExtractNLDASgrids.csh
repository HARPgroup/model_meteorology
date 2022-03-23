#!/bin/csh

set YEAR = $argv[1]

set OUTFOLDER =  users/BreckSullivan/ExtractNLDAS2Grids

./NLDAS2_GRIB_to_ASCII ./-R/NLDAS_FORA0125_H.002 ${OUTFOLDER} ${YEAR} 01 01 00 ${YEAR} 12 31 23 2 388 107 389 108

