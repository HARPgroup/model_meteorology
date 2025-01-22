#!/bin/bash

#Arugments to this function should be in the following order:
#1 = datasource = precip data name used in temporary file generation e.g. "prism"
#2 = finalTiff = File path of the raster to import into dbase
#3 = tstime = string in form of YYYY-MM-DD HH
#4 = tsElapse/dt = How much time in seconds is this data representative for? E.g. for daily data, this is 86400
#5 = entity_type = entity_type of desired db feature
#6 = varkey = The key for the variable definition in dh_variabledefinition of interest e.g. daymet_precip_raster for daymet data
#7 = extent hydrocode
#8 = db_name

#We set up a local name reference to the config array passed in by the user to easily access its value
#CAUTION: Changes to confignr likely impact the original array passed by user!
if [ $# -lt 8 ]; then
  echo "Use: met_raster2dn.sh datasource finalTiff tstime tsendtime entity_type varkey extent_hydrocode db_name force"
  exit
fi
datasource=$1
finalTiff=$2
tstime=$3
tsendtime=$4
entity_type=$5
varkey=$6
extent_hydrocode=$7
db_name=$8
db_host=$9
force=0
if [ $# -gt 9 ]; then
  force=${10}
fi
echo "Creating sql file to import raster..."
#Create sql file that will add the raster (-a for amend or -d for drop and recreate) into the target table
#The -t option tiles the raster for easier loading
tmp_sql_file=tmp_${datasource}-${tstime}-test.sql
tmp_tbl_name="tmp_${datasource}_${tstime}"
raster2pgsql -d -t 1000x1000 $finalTiff $tmp_tbl_name > $tmp_sql_file

echo "Sending raster to db..."
#Execute sql file to bring rasters into database (alpha)
psql -h $db_host -f "$tmp_sql_file" -d $db_name

if [ "$force" == "1" ]; then
  # user wishes to delete old values
  echo "TRYING: delete from dh_timeseries_weather 
        WHERE varid in (select hydroid from dh_variabledefinition where varkey = '${varkey}')
		AND featureid in (
			select hydroid from dh_feature where hydrocode = '${extent_hydrocode}'
		)
		and tstime = $tstime 
		and tsendtime = $tsendtime
		;"

  echo "delete from dh_timeseries_weather 
        WHERE varid in (select hydroid from dh_variabledefinition where varkey = '${varkey}')
		AND featureid in (
			select hydroid from dh_feature where hydrocode = '${extent_hydrocode}'
		)
		and tstime = $tstime 
		and tsendtime = $tsendtime
		;" | psql -h $db_host -d $db_name 
fi

echo "Updating dh_timeseries_weather..."
#Now update dh_timeseries_weather
# Notes:
#	--We join in dh_timeseries_weather in case this data has already been created. This join will add no data if 
#	--there is no matching data in dh_timeseries_weather
#	--By specifying tid = NULL we ensure this query returns no rows if there is a match within dh_timeseries_weather
insert_sql="insert into dh_timeseries_weather(tstime,tsendtime, varid, featureid, entity_type, bbox, rast)
	select '$tstime','$tsendtime', v.hydroid as varid, f.hydroid as featureid, '${entity_type}', met.rast,
          st_envelope(met.rast)
	from dh_feature as f 
	left outer join dh_variabledefinition as v
		on (v.varkey = '${varkey}')
	left outer join dh_timeseries_weather as w
		on (f.hydroid = w.featureid and w.tstime = '${tstime}' and w.varid = v.hydroid) 
	left outer join ${tmp_tbl_name} as met
		on (1 = 1)
	WHERE w.tid is null
		AND f.hydrocode = '${extent_hydrocode}';"
echo "SQL: $insert_sql"
echo $insert_sql | psql -h $db_host -d $db_name
echo "Removing unecessary files..."
echo "drop table ${tmp_tbl_name};" | psql -h $db_host -d $db_name
rm $tmp_sql_file
