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
rm -Rf $oDir/$jDay
mv ./-R/hydro1.gesdisc.eosdis.nasa.gov/data/NLDAS/NLDAS_FORA0125_H.002/$year/$jDay $oDir -f
echo "data moved to desired directory ... Running basic QA"
# check if we have a full day
ok=1
for i in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23; do 
  if [ ! -f $year/$jDay/*${i}00.002.grb ]; then
    ok=0
  fi
done
if [ "$ok" == "0" ]; then
  echo "Only half day found. Exiting."
  rm -Rf $oDir/$jDay
  #rm -r ./-R
  exit
fi

# deleting other directory
rm -r ./-R
