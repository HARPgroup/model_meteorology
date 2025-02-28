#!/bin/bash

#This scripts plots a raster of interst as png
#Arugments to this function should be in the following order:
#1 = TS_START_IN = The start time used to identify the raster to be plotted
#2 = TS_END_IN = The end time used to identify the raster to be plotted
#3 = MODEL_SCENARIO = The propname of the model scenario (property) that this raster is stored under
#4 = RATINGS_VARKEY = The varkey used to identify the raster from dh_timeseries_weather
#5-7 = EXTENT_HYDROCODE,EXTENT_BUNDLE,EXTENT_FTYPE = The hydrocode, bundle, and ftype used to identify the base feature that this the model scenario is stored under, the CBP6 extent for the 2025 HARP project
#8 = RASTER_SQL_FILE = A temporary file to write SQL to
#9-10 = db_host, db_name = The host, name of the database in which data is and will be stored
#11 = Final path to store plot of raster
#12 = Temporary directory to store intermediate products
#This script finds a raster of interest in dh_timeseries_weather and exports it to a tiff using gdal_translate. 
#An R script then writes the final product to a png file
if [ $# -lt 12 ]; then
  echo "Use: plotRaster.sh TS_START_IN TS_END_IN MODEL_SCENARIO RATINGS_VARKEY EXTENT_HYDROCODE EXTENT_BUNDLE EXTENT_FTYPE RASTER_SQL_FILE db_host db_name PATH_TO_PLOT TEMP_DIR"
  exit
fi

TS_START_IN=$1
TS_END_IN=$2
MODEL_SCENARIO=$3
RATINGS_VARKEY=$4
EXTENT_HYDROCODE=${5}
EXTENT_BUNDLE=${6}
EXTENT_FTYPE=${7}
RASTER_SQL_FILE=${8}
db_host=${9}
db_name=${10}
PATH_TO_PLOT=${11}
TEMP_DIR=${12}

#First, set important variable in SQL session
rasterSQL="
\\set tsstartin '$TS_START_IN'   \n
\\set tsendin '$TS_END_IN'    \n
\\set model_scenario '$MODEL_SCENARIO'    \n
\\set ratings_varkey '$RATINGS_VARKEY'   \n
   \n
select hydroid as covid from dh_feature   \n
where hydrocode = '$EXTENT_HYDROCODE' and bundle = '$EXTENT_BUNDLE'   \n
AND ftype = '$EXTENT_FTYPE' \\gset   \n
   \n
SELECT scen.pid as scenariopid    \n
FROM dh_properties as scen    \n
LEFT JOIN dh_properties as model   \n 
ON model.pid =  scen.featureid    \n
LEFT JOIN dh_feature as feat    \n
on feat.hydroid = model.featureid    \n
WHERE feat.hydroid = :'covid'     \n
and scen.propname = :'model_scenario' \\gset   \n
   \n
SELECT hydroid AS ratings FROM dh_variabledefinition WHERE varkey = :'ratings_varkey' \\gset   \n
\n
SELECT tid   \n
FROM dh_timeseries_weather   \n
WHERE tstime = :tsstartin   \n
	AND tsendtime = :tsendin   \n
	AND featureid = :scenariopid   \n
	AND varid = :ratings   \n
	AND entity_type = 'dh_properties'   \n
)   \n
"

# turn off the expansion of the asterisk
set -f
echo "Writing sql insert to $RASTER_SQL_FILE"
#Delete previous dh_timeseries entries
echo $rasterSQL
echo -e $rasterSQL > $RASTER_SQL_FILE 
cat $RASTER_SQL_FILE | psql -h $db_host $db_name
tid=$(psql -qtAX -h $db_host -d $db_name -f $RASTER_SQL_FILE)

rasterPath="{TEMP_DIR}/raster.tiff"
plotTempPath="${TEMP_DIR}/${RATINGS_VARKEY}_${TS_END_IN}.PNG"
plotPath="${PATH_TO_PLOT}/${RATINGS_VARKEY}_${TS_END_IN}.PNG"

echo "Found tid = $tid for plot"
echo "Calling :gdal_translate -of GTiff PG:\"host=192.168.0.21 port=5432 sslmode=disable user=postgres dbname=$dbname schema=public table=dh_timeseries_weather column=rast where='tid = $tid'\" $rasterPath"
gdal_translate -of GTiff PG:"host=192.168.0.21 port=5432 sslmode=disable user=postgres dbname=$dbname schema=public table=dh_timeseries_weather column=rast where='tid = $tid'" $rasterPath

echo "Calling: Rscript $META_MODEL_ROOT/scripts/river/usgsdata.R ${rasterPath} $plotTempPath"
Rscript ${MET_SCRIPT_PATH}/sh/plotRaster.R $rasterPath $plotTempPath

# note: the install -D command create the destination directory path if it doesn't exist
echo "Running: install -D $plotTempPath $plotPath"
install -D $plotTempPath $plotPath
