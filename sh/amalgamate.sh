#!/bin/bash

#This script knits together (e.g. amalgamates) two rasters in dh_timeseries_weather based on a key raster
#Arugments to this function should be in the following order:
#1 = TS_START_IN = The start time used to identify the key raster and that represents the amalgamated raster
#2 = TS_END_IN = The end time used to identify the key raster and that represents the amalgamated raster
#3 = RESAMPLE_VARKEY = The varkey used to identify the raster in raster_templates of the final resolution for the amalgamation
#4 = AMALGAMATE_SCENARIO = The propname of the model scenario (property) that this data is stored under and the key raster is under
#5 = AMALGAMATE_VARKEY = The varkey identifying the variable under which this data will be stred in dh_timeseries_weather
#6 = RATINGS_VARKEY = The varkey used to identify the key raster that has cells that identify the raster to knit in e.g. the best fit raster to be amalgamated into that cell
#7-8 = COVERAGE_BUNDLE,COVERAGE_FTYPE = The bundle, ftype describing any one coverage that was involved in the rating process for this amalgamation as identified by $scenarioName
#9 = SCENARIO_NAME = The scenario that identifies the rating config file used to develop the ratings under geo workflow
#10-12 = EXTENT_HYDROCODE,EXTENT_BUNDLE,EXTENT_FTYPE = The hydrocode, bundle, and ftype used to identify the base feature that this the model scenario is stored under, the CBP6 extent for the 2025 HARP project
#13 = AMALGAMATE_SQL_FILE = A temporary file to write SQL to
#14 = KEYRASTER_YN = Should existing records be deleted? Should be TRUE or FALSE
#15-16 = db_host, db_name = The host, name of the database in which data is and will be stored
#17 = PROP_VAR_NAME = The property name used to identify the property stored on the scenario that contains the raw precip raster varkey

#This script takes the key raster (varid of best data set in each cell) and sets one varid to NULL. It then takes the resampled (to target resolution) raw precip
#data and fills in the NULLs via a union such that we derive a product that has varids in the non-target cells and precip data in the cells that were of the target varid
#This is then added to the dh_timeseries_weather and can be called for further manipulation. To allow us to use a loop for calling this script, the base raster is either the product of the
#previous loop or the key raster and is controlled by the first statement in WITH. A temporary table is used to store the intermediate before a delete+insert adds It
#to the database. Note that the final raster is reclassified to remove any negative values and instead replace them with a consistent no data value since NLDAS uses 9999 as nodatavalue and PRISM + daymet use -9999.
if [ $# -lt 17 ]; then
  echo "Use: amalgamate.sh TS_START_IN TS_END_IN RESAMPLE_VARKEY AMALGAMATE_SCENARIO AMALGAMATE_VARKEY RATINGS_VARKEY COVERAGE_BUNDLE COVERAGE_FTYPE SCENARIO_NAME EXTENT_HYDROCODE EXTENT_BUNDLE EXTENT_FTYPE AMALGAMATE_SQL_FILE DELETE_TF db_host db_name"
  exit
fi

TS_START_IN=$1
TS_END_IN=$2
RESAMPLE_VARKEY=$3
AMALGAMATE_SCENARIO=$4
AMALGAMATE_VARKEY=$5
RATINGS_VARKEY=$6
COVERAGE_BUNDLE=$7
COVERAGE_FTYPE=$8
SCENARIO_NAME=$9
EXTENT_HYDROCODE=${10}
EXTENT_BUNDLE=${11}
EXTENT_FTYPE=${12}
AMALGAMATE_SQL_FILE=${13}
KEYRASTER_YN=${14}
db_host=${15}
db_name=${16}
PROP_VAR_NAME=${17}

#First, set important variable in SQL session
amalSQL="
\\set tsstartin '$TS_START_IN'   \n
\\set tsendin '$TS_END_IN'    \n
\\set resample_varkey '$RESAMPLE_VARKEY'    \n
\\set amalgamate_scenario '$AMALGAMATE_SCENARIO'    \n
\\set amalgamate_varkey '$AMALGAMATE_VARKEY'    \n
\\set ratings_varkey '$RATINGS_VARKEY'   \n
\\set coverage_bundle '$COVERAGE_BUNDLE'    \n
\\set coverage_ftype '$COVERAGE_FTYPE'    \n
\\set scenarioName '$SCENARIO_NAME'   \n
\\set prop_var_name '$PROP_VAR_NAME'   \n
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
and scen.propname = :'amalgamate_scenario' \\gset   \n
   \n
SELECT propVar.propcode as scenvarkey   \n
FROM dh_properties as scen    \n
LEFT JOIN dh_properties as model    \n
ON model.pid =  scen.featureid    \n
LEFT JOIN dh_feature as feat    \n
on feat.hydroid = model.featureid   \n
LEFT JOIN dh_properties as propVar   \n
ON propVar.featureid = scen.pid    \n
WHERE scen.propname = :'scenarioName'   \n
AND propVar.propname = :'prop_var_name'   \n
AND feat.bundle = :'coverage_bundle'   \n
AND feat.ftype = :'coverage_ftype'   \n
LIMIT 1 \gset   \n
   \n
SELECT v.hydroid as scenvarid   \n
FROM dh_variabledefinition as v   \n
WHERE v.varkey = :'scenvarkey' \\gset   \n
   \n
SELECT hydroid AS ratings FROM dh_variabledefinition WHERE varkey = :'amalgamate_varkey' \\gset   \n
SELECT hydroid AS keyratings FROM dh_variabledefinition WHERE varkey = :'ratings_varkey' \\gset   \n
"

#Depending on the $KEYRASTER_YN value supplied by user, decide whether the key raster (that which only has varids in each cell to identify the best data set)
#or an existing amalgamated raster (which may have some remaining varids but also some precip data) should serve as the base product to which more data will be
#amalgamated 
if $KEYRASTER_YN; then
	amalSQL="${amalSQL} \n
	CREATE TEMP TABLE tmp_amalgamate as (       \n
		WITH varidRaster as (     \n
			SELECT *     \n
			FROM dh_timeseries_weather     \n
			WHERE tstime = :tsstartin     \n
				AND tsendtime = :tsendin     \n
				AND featureid = :scenariopid     \n
				AND varid = :keyratings     \n
				AND entity_type = 'dh_properties'     \n
	)     \n
	"
else
	amalSQL="${amalSQL} \n
	CREATE TEMP TABLE tmp_amalgamate as (  
		WITH varidRaster as (   \n
			SELECT *   \n
			FROM dh_timeseries_weather   \n
			WHERE tstime = :tsstartin   \n
				AND tsendtime = :tsendin   \n
				AND featureid = :scenariopid   \n
				AND varid = :ratings   \n
				AND entity_type = 'dh_properties'   \n
	)   \n
	"
fi

#Set the selected varid identified by the scenario input by user to no data and union the resampled precip data (resamp) to it
#Then delete the existing amalgamation (if any) and add the newest version but set negative values to no data first to deal WITH
#the different no data values between prism and daymet (-9999) and NLDAS2 (9999)
amalSQL="${amalSQL} \n
	, resamp as (     \n
		SELECT      \n
		ST_Resample(     \n
			ST_Union(met.rast),     \n
			rt.rast     \n
		) as rast,     \n
		v.varkey     \n
		FROM dh_timeseries_weather as met     \n
		LEFT JOIN dh_variabledefinition as v     \n
		ON v.hydroid = met.varid     \n
		LEFT JOIN (select rast from raster_templates where varkey = :'resample_varkey') as rt     \n
		ON 1 = 1     \n
		WHERE met.tstime <= :tsendin     \n
			AND met.tsendtime >= :tsendin     \n
			AND v.varkey = :'scenvarkey'     \n
			AND met.featureid = :covid     \n
		GROUP BY v.varkey, rt.rast     \n
	)     \n
	,amalgamate as (     \n
		SELECT ST_Union(amalgamate.rast,'LAST') as rast     \n
		FROM (     \n
			SELECT rast     \n
			FROM resamp     \n
			WHERE varkey = :'scenvarkey'     \n
			UNION ALL     \n
			SELECT ST_SetBandNoDataValue(var.rast,:scenvarid) as rast     \n
			FROM varidRaster as var     \n
		) as amalgamate     \n
	)     \n
	SELECT * FROM amalgamate     \n
);     \n
     \n
DELETE FROM dh_timeseries_weather     \n
WHERE varid = :ratings     \n
	AND entity_type = 'dh_properties'     \n
	AND tstime = :tsstartin     \n
	AND tsendtime = :tsendin     \n
	AND featureid = :scenariopid;     \n
     \n
INSERT INTO dh_timeseries_weather (tstime,tsendtime, featureid, entity_type, rast, bbox, varid)     \n
SELECT :tsstartin,:tsendin,:scenariopid,'dh_properties',     \n
	ST_Reclass(fr.rast,1,'-9999-0:9999,0-9999:0-9999','32BF',9999), \n
	ST_ConvexHull(fr.rast),     \n
	:ratings     \n
FROM tmp_amalgamate as fr     \n
LEFT JOIN dh_timeseries_weather as dupe     \n
ON ( dupe.tstime = :tsstartin     \n
		AND dupe.tsendtime = :tsendin     \n
		AND dupe.featureid = :scenariopid     \n
		AND dupe.varid = :ratings)     \n
WHERE dupe.tid IS NULL     \n
RETURNING tid;     \n
"

# turn off the expansion of the asterisk
set -f
echo "Writing sql insert to $AMALGAMATE_SQL_FILE"
#Delete previous dh_timeseries entries
echo $amalSQL
echo -e $amalSQL > $AMALGAMATE_SQL_FILE 
cat $AMALGAMATE_SQL_FILE | psql -h $db_host $db_name