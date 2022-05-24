#!/bin/bash

echo "The year you would like to download is $1"
year=$1
echo "The day you would like to download is $2"
jDay=$2
echo "The output directory you would like to store the data is $3"
oDir=$3


# downloading the data
wget --load-cookies .urs_cookies --auth-no-challenge=on --keep-session-cookies -np -r -NP -R "*.xml" -c -N --content-disposition https://hydro1.gesdisc.eosdis.nasa.gov/data/NLDAS/NLDAS_FORA0125_H.002/$year/$jDay/
echo "data downloaded"

# moving it to desired directory
mv ./-R/hydro1.gesdisc.eosdis.nasa.gov/data/NLDAS/NLDAS_FORA0125_H.002/$year/$jDay $oDir
echo "data moved to desired directory"

# deleting other directory
rm -r ./-R
