library("sf")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")

sqldf(
  "select hydrocode,name from dh_feature 
   where ftype = 'nhd_huc8' 
   and hydrocode like 'nhd_huc8_020700%';
  ",
  connection = ds$connection
)

middle_potomac <- sqldf(
  "select '01646500 Potomac River at Little Falls' as name, 
    'usgs_ws_01646500' as hydrocode, 
    'usgs_full_drainage' as ftype, 
    st_astext(
      st_multi(
        st_concavehull(
          st_union(dh_geofield_geom),0.9)
        )
      ) as geom
  from dh_feature_fielded as a 
  where a.bundle = 'watershed' 
    and ftype = 'nhd_huc8' 
    and hydrocode like 'nhd_huc8_020700%'
    and hydrocode not in (
    'nhd_huc8_02070011', 'nhd_huc8_02070010'
  )
",
  connection = ds$connection, method="raw"
)


lat=38.94977778
lon=-77.12763889
wkt_gage = paste("POINT(",lon, lat,")")
plot(st_as_sf(middle_potomac,wkt="geom", crs = 4326)$geom, axes=TRUE)
plot(st_point(c(lon, lat)), cex=2, add=TRUE)
conf <- as.list(
  middle_potomac
)
conf$bundle='watershed'
conf$ftype='usgs_full_drainage'
conf$geom <- NULL

river_feature <- RomFeature$new(
  ds,config = conf
)
river_feature$save(TRUE)

dbBegin(ds$connection)
dbExecute(
  ds$connection,
  paste0(
    "INSERT INTO field_data_dh_geofield ( 
     entity_type,bundle, deleted,
     entity_id,revision_id,
     language,delta,
     dh_geofield_geom,
     dh_geofield_geo_type)
    select 'dh_feature', 'watershed', 0, ", 
    river_feature$hydroid, ",", river_feature$hydroid, ",", 
    "'und', 0,
     foo.geom, 
     'multipolygon'
     from (
       select 
         st_multi(
           st_concavehull(
             st_union(dh_geofield_geom),0.9)
       ) as geom
       from dh_feature_fielded as a 
       where a.bundle = 'watershed' 
       and ftype = 'nhd_huc8' 
       and hydrocode like 'nhd_huc8_020700%'
       and hydrocode not in (
         'nhd_huc8_02070011', 'nhd_huc8_02070010')
     ) as foo
    "
  )
)
dbExecute(
  ds$connection,
  paste0(
    "UPDATE field_data_dh_geofield 
     set dh_geofield_lat = st_y(st_centroid(dh_geofield_geom)),
     dh_geofield_lon = st_x(st_centroid(dh_geofield_geom)),
     dh_geofield_left = st_xmin(st_envelope(dh_geofield_geom)), 
     dh_geofield_top = st_ymax(st_envelope(dh_geofield_geom)),
     dh_geofield_right = st_xmax(st_envelope(dh_geofield_geom)),
     dh_geofield_bottom = st_ymin(st_envelope(dh_geofield_geom)), 
     dh_geofield_geohash = ST_GeoHash(dh_geofield_geom)
     where entity_type = 'dh_feature' 
     and entity_id = ", river_feature$hydroid
  ),
)
dbCommit(ds$connection)
# iff error 
dbRollback(ds$connection)

river_feature <- RomFeature$new(
  ds,config = conf,TRUE
)


rivertest <- RomFeature$new(
  ds,config = conf,TRUE
)
sqldf(
  paste0(
    "select count(*) from dh_feature where 
    hydroid=",river_feature$hydroid
  ),
  connection=ds$connection
)