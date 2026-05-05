#!/bin/bash

#Arugments to this function should be in the following order:
#1 = datasource = precip data name used in temporary file generation e.g. "prism"
#2 = finalTiff = File path of the raster to import into dbase
#3 = tstime = string in form of YYYY-MM-DD HH
#4 = tsendtime = string in form of YYYY-MM-DD HH
#5 = entity_type = entity_type of desired db feature
#6 = varkey = The key for the variable definition in dh_variabledefinition of interest e.g. daymet_precip_raster for daymet data
#7 = extent_hydrocode = Hydrocode of base feature
#8 = tile_size = How many pixels in each square tile?
#9 = db_name = data base name on host
#10 = db_host = host database
#11 = no_data_value = false or double value to represent the no data pixel value. If false, will use PSQL default algorithim
#12 = force = Should data be deleted and reimported?


if [ $# -lt 11 ]; then
  echo "Use: met_raster2dn.sh datasource finalTiff tstime tsendtime entity_type varkey extent_hydrocode tile_size db_name db_host no_data_value force"
  exit
fi
datasource=$1
finalTiff=$2
tstime=$3
tsendtime=$4
entity_type=$5
varkey=$6
extent_hydrocode=$7
tile_size=$8
db_name=$9
db_host=${10}
no_data_value=${11}
#If no_data_value is set to false, assume the default raster2pgsql algorithim is sufficient.
#Otherwise, manually set no data value on call
if [ "$no_data_value" == 'false' ]; then
  no_data_option=""
else
  no_data_option="-N ${no_data_value} "
fi
force=0
if [ $# -gt 11 ]; then
  force=${12}
fi
echo "Creating sql file to import raster..."
#Create sql file that will add the raster (-a for amend or -d for drop and recreate) into the target table
#The -t option tiles the raster for easier loading
tmp_sql_file=tmp_${datasource}-${tstime}-test.sql
tmp_tbl_name="tmp_${datasource}_${tstime}"

rast_evalu="raster2pgsql -d -t ${tile_size}x${tile_size} ${no_data_option}${finalTiff} ${tmp_tbl_name} > ${tmp_sql_file}"

echo "Running ${rast_evalu}"
eval ${rast_evalu}

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
insert_sql="insert into dh_timeseries_weather(tstime,tsendtime, varid, featureid, entity_type, rast, bbox)
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
