--Given we have a file that indicates which dataset performed best, we should have
--three different datasets defined via WITH, grabbing and clipping coverages based on the file

--Arbitrarily pick a tsendtime to practice with, here February 18, 2020. 
--Note that with NLDAS this will pick an abitrary hour and we need the full 24-hour set
\set tsendin '1582027200'
\set resample_varkey 'daymet_mod_daily'
-- sets all integer feature and varid with query 
select hydroid as covid from dh_feature where hydrocode = 'cbp6_met_coverage' \gset

--Grab the USGS full drainage geometries/coverages and assign ratings to inicate best 
--performing precip dataset
WITH usgsCoverage as (
	SELECT f.*,
	--Join in ratings. Until ratings are put in db via REST, let's
	--use a random integer between 0 (NLDAS) and 2 (daymet)
	floor(random() * (2-0+1) + 0)::int as dataID,
	--Add area of watershed/coverage for refernce and to order from downstream to upstrea
	ST_AREA(fgeo.dh_geofield_geom) as covArea,
	fgeo.dh_geofield_geom as dh_geofield_geom
	FROM dh_feature as f
	LEFT JOIN field_data_dh_geofield as fgeo
	on (
		fgeo.entity_id = f.hydroid
		and fgeo.entity_type = 'dh_feature' 
	) 
	WHERE f.bundle = 'watershed' AND f.ftype = 'usgs_full_drainage'
	ORDER BY covArea DESC
),
--Get the geometry and feature fields for the full coverage based on the covid variable gset above. 
--This will be used to create a resampled NLDAS for the day
fullCoverage as (
	SELECT f.*,fgeo.dh_geofield_geom
	FROM dh_feature as f
	LEFT JOIN field_data_dh_geofield as fgeo
	on (
		fgeo.entity_id = f.hydroid
		and fgeo.entity_type = 'dh_feature' 
	) 
	WHERE f.hydroid = :'covid'
),
--Where PRISM is the best performing dataset, grab the appropriate
--daily raster from dh_weather_timeseries and resample to target resolution
--and then clip to watershed boundaries
prism as (
	SELECT cov.*,
	met.featureid,met.tsendtime,
	st_clip(st_resample(met.rast,rt.rast), cov.dh_geofield_geom) as rast
	FROM usgsCoverage as cov
	JOIN(
		select *
		from dh_timeseries_weather as met
		left outer join dh_variabledefinition as b
			on (met.varid = b.hydroid) 
		where b.varkey='prism_mod_daily'
			and met.featureid = :covid
			and met.tsendtime = :'tsendin'
	) AS met
	ON ST_Intersects(ST_ConvexHull(met.rast),cov.dh_geofield_geom)
	LEFT JOIN (select rast from raster_templates where varkey = :'resample_varkey') as rt
	ON 1 = 1
	WHERE cov.dataID = 1
),
--Where daymet is the best performing dataset, grab the appropriate
--daily raster from dh_weather_timeseries and resample to target resolution
--and then clip to watershed boundaries
daymet as (
	SELECT cov.*,
	met.featureid,met.tsendtime,
	st_clip(st_resample(met.rast,rt.rast), cov.dh_geofield_geom) as rast
	FROM usgsCoverage as cov
	JOIN(
		select *
		from dh_timeseries_weather as met
		left outer join dh_variabledefinition as b
			on (met.varid = b.hydroid) 
		where b.varkey='daymet_mod_daily'
			and met.featureid = :covid
			and met.tsendtime = :'tsendin'
	) AS met
	ON ST_Intersects(ST_ConvexHull(met.rast),cov.dh_geofield_geom)
	LEFT JOIN (select rast from raster_templates where varkey = :'resample_varkey') as rt
	ON 1 = 1
	WHERE cov.dataID = 2
),
--Union all NLDAS rasters for the day to get the sum of NLDAS for the day
nldasFullDay AS (
	SELECT st_union(met.rast,'sum') as rast
	FROM (
		select *
		from dh_timeseries_weather as met
		left outer join dh_variabledefinition as b
			on (met.varid = b.hydroid) 
		where b.varkey='nldas2_precip_hourly_tiled_16x16'
			and met.featureid = :covid
			and extract(year from to_timestamp(met.tsendtime)) = extract(year from to_timestamp(:'tsendin'))
			and extract(month from to_timestamp(met.tsendtime)) = extract(month from to_timestamp(:'tsendin'))
			and extract(day from to_timestamp(met.tsendtime)) = extract(day from to_timestamp(:'tsendin'))
	) AS met
),
nldasFullDayResamp AS (
	select st_resample(met.rast,rt.rast) as rast
	FROM fullCoverage as f
	JOIN nldasFullDay as met
	ON ST_ConvexHull(met.rast) && f.dh_geofield_geom
	LEFT JOIN (select rast from raster_templates where varkey = :'resample_varkey') as rt
	ON 1 = 1
),
--Union all NLDAS rasters for the day, intersecting by the usgsCoverage geometries
--to leverage the tiled NLDAS rasters. The end result is a raster for each coverage 
--where NLDAS is the most highly rated that is of the full day's dataset, 
--but clipped to only intersecting tiles
nldasDay as (
	SELECT cov.hydroid, cov.hydrocode,
	cov.ftype, cov.bundle, cov.name,
	:'tsendin' as tsendtime,
	st_union(met.rast,'sum') as rast
	FROM usgsCoverage as cov
	JOIN(
		select *
		from dh_timeseries_weather as met
		left outer join dh_variabledefinition as b
			on (met.varid = b.hydroid) 
		where b.varkey='nldas2_precip_hourly_tiled_16x16'
			and met.featureid = :covid
			and extract(year from to_timestamp(met.tsendtime)) = extract(year from to_timestamp(:'tsendin'))
			and extract(month from to_timestamp(met.tsendtime)) = extract(month from to_timestamp(:'tsendin'))
			and extract(day from to_timestamp(met.tsendtime)) = extract(day from to_timestamp(:'tsendin'))
	) AS met
	ON ST_Intersects(ST_ConvexHull(met.rast),cov.dh_geofield_geom)
	WHERE cov.dataID = 0
	GROUP BY cov.hydroid, cov.hydrocode, cov.ftype,
		cov.bundle, cov.name
),
--Now, using the union of NLDAS hourly data in nldasDay, resample to the template raster and clip to each 
--watershed where NLDAS is rated the best via an INNER JOIN and the WHERE in nldasDay
nldas as (
	SELECT cov.*,met.tsendtime,
	st_clip(st_resample(met.rast,rt.rast), cov.dh_geofield_geom) as rast
	FROM usgsCoverage as cov
	INNER JOIN nldasDay as met
	on cov.hydroid = met.hydroid
	LEFT JOIN (select rast from raster_templates where varkey = :'resample_varkey') as rt
	ON 1 = 1
),
--For each feature in usgsCoverage, find the non-NULL summary dataset (which will represent the best rated dataset)
amalgamate as (
	select cov.*, COALESCE(prismMet.rast,daymetMet.rast,nldasMet.rast) as rast
	FROM usgsCoverage as cov
	LEFT JOIN nldas as nldasMet
	on cov.hydroid = nldasMet.hydroid
	LEFT JOIN prism as prismMet
	on cov.hydroid = prismMet.hydroid
	LEFT JOIN daymet as daymetMet
	on cov.hydroid = daymetMet.hydroid
),
--Union the best rated datasets together. Since the data is sorted by drainage area, 
--upstream areas will populate after larger, downstream coverages
amalgamateUnion as (
	SELECT ST_union(amalgamate.rast) as rast
	FROM usgsCoverage as cov
	LEFT JOIN amalgamate as amalgamate
	on cov.hydroid = amalgamate.hydroid
)
--Use a full union to create a column with the amalgamateUnion raster and the nldasFulLDayResamp raster
--Then, union the rasters to get a raster in which the "background" is the nldasFullDayResamp and everything else is 
--the best fit raster
SELECT ST_union(fullUnion.rast) as rast
FROM (
	SELECT rast FROM nldasFullDayResamp
    UNION ALL
    SELECT rast FROM amalgamateUnion 
) as fullUnion;



