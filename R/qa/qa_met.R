library('hydrotools')
library('zoo')
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")

metdf <- data.frame(
  'model_version' = c('cbp-6.0', 'met-1.0', 'met-1.0'),
  'runid' = c('met2date', 'nldas2rst', 'prismrst'),
  'metric' = c('precip_annual_max_in','precip_annual_max_in', 'precip_annual_max_in'),
  'runlabel' = c('m2d_precip_annual_max_in', 'nldrst_precip_annual_max_in', 'prism_precip_annual_max_in')
)
metdf <- rbind(
  metdf, c('met-1.0', 'nldas2rst', 'precip_annual_min_in', 'nldrst_pmin_in')
)
metdf <- rbind(
  metdf, c('met-1.0', 'prismrst', 'precip_annual_min_in', 'prism_pmin_in')
)

met_data <- om_vahydro_metric_grid(
  metric = metric, runids = metdf, bundle = "landunit", ftype = "cbp6_landseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
nrow(met_data[which(! is.na(met_data$prism_precip_annual_max_in)),])

land_df <- data.frame( 'model_version'='cbp-6.1','runid'='subsheds',metric='l90_RUnit',runlabel='Runit L90 NLDAS')
land_df <- rbind(land_df, c('cbp-6.1', 'pubsheds', 'l90_RUnit', 'Runit L90 PRISM'))
land_data <- om_vahydro_metric_grid(
  metric = metric, runids = land_df, bundle = "landunit", ftype = "cbp6_landseg",
  ds = ds, debug=TRUE
)


riv_df <- data.frame( model_version='cbp-6.1',runid='pubsheds',metric='l90_Qout',runlabel='L90 PRISM')
riv_df <- rbind(riv_df, c('cbp-6.1', 'subsheds', 'l90_Qout', 'L90 NLDAS'))
riv_df <- rbind(riv_df, c('usgs-2.0', 'runid_400', 'l90_Qout', 'L90 USGS'))
riv_df <- rbind(riv_df, c('vahydro-1.0', 'runid_400', 'l90_Qout', 'L90 cbp6'))
riv_data <- om_vahydro_metric_grid(
  metric = metric, runids = riv_df, bundle = "watershed", ftype = "vahydro",
  ds = ds, debug=TRUE
)
riv_data$riverseg <- gsub("vahydrosw_wshed_", "", riv_data$hydrocode)
potomac_lf <- fn_extract_basin(riv_data, "PM7_4820_0001")

boxplot(met_data$nldrst_precip_annual_max_in, met_data$prism_precip_annual_max_in , names = c('nldas(rst)', 'prism(rst)'), main="Max Annual Precip 1984-2023")

boxplot(met_data$nldrst_pmin_in, met_data$prism_pmin_in, names = c('nldas(rst)', 'prism(rst)'), main="Min Annual Precip 1984-2023")
bigdiffs <- sqldf("select hydrocode from met_data where abs((prism_pmin_in - nldrst_pmin_in)/nldrst_pmin_in) >= 0.2")

big_diff_lrsegs <- sqldf(
  paste(
    "select a.hydrocode as landseg, replace(b.hydrocode,'vahydrosw_wshed_','') as riverseg
     from dh_feature_fielded as a 
     left outer join dh_feature_fielded as b 
     on (
       a.dh_geofield_geom && b.dh_geofield_geom 
       and b.bundle='watershed'
       and b.ftype = 'vahydro'
     )
     where a.ftype = 'cbp6_landseg'
       and a.bundle = 'landunit'
       and a.hydrocode in (", 
       paste0(
         "'",stringr::str_replace_all(
           paste(as.vector(bigdiffs$hydrocode),collapse=","), 
           ",", "','"),
         "'"
       ),
    ")"
  ), connection = ds$connection
)

landseg = "N51171"
landseg_feature <- RomFeature$new(
  ds,config = list(
    hydrocode=landseg,bundle='landunit',ftype='cbp6_landseg'
  ), 
  TRUE
)
met_info = landseg_feature$propvalues(propcode = 'met-1.0')[,c('propname', 'pid', 'propcode')]
met_model <- RomProperty$new(ds,list(pid=met_info$pid),TRUE)


met_nested <- ds$get_json_prop(met_model$pid)
model_info = landseg_feature$propvalues(propcode = 'cbp-6.1')[,c('propname', 'pid', 'propcode')]
land_model <- RomProperty$new(ds,list(pid=model_info$pid),TRUE)
land_nested <- ds$get_json_prop(land_model$pid)

nldat <- read.csv(paste0('http://deq1.bse.vt.edu:81/met/nldas2rst/lseg_csv/',landseg,'.PRC'),col.names=c('yr','mo','da','hr','tsvalue'))
prdat <- read.csv(paste0('http://deq1.bse.vt.edu:81/met/prismrst/lseg_csv/',landseg,'.PRC'),col.names=c('yr','mo','da','hr','tsvalue'))

nl_ann <- sqldf("select yr,avg(tsvalue) as pavg, max(tsvalue) as pmax from (select yr, mo, sum(tsvalue) as tsvalue from nldat group by yr, mo) group by yr order by yr")
pr_ann <- sqldf("select yr,avg(tsvalue) as pavg, max(tsvalue) as pmax from (select yr, mo, sum(tsvalue) as tsvalue from prdat group by yr, mo) group by yr order by yr")

comp_ann <- sqldf("select a.yr, a.pmax as prism, b.pmax as nldas2 from pr_ann as a, nl_ann as b where a.yr = b.yr order by a.yr")
barplot((comp_ann$prism - comp_ann$nldas2) ~ comp_ann$yr, main=paste("Monthly Max Comparison",landseg),ylab = "Max Month PRISM - NLDAS in.")


argst <- c( 'N51069', 'pubsheds', '/media/model/p6/out/land/pubsheds/eos/N51069_0111-0211-0411.csv', '/media/model/p6/out/land/pubsheds/images', 'cbp-6.1', 'cbp6_landseg')

gageid="01646500"
hcode=paste0("usgs_ws_", gageid)
ts_prism <- read.csv(paste0('http://deq1.bse.vt.edu:81/met/PRISM/precip/',hcode,"_precip_daily.csv"))
ts_nldas2 <- read.csv(paste0('http://deq1.bse.vt.edu:81/met/PRISM/precip/',hcode,"_precip_daily.csv"))
ts_prism$flow_in <- (((ts_prism$obs_flow / 1.547) * 3.07) / (640 * ts_prism$area_sqmi)) /12
plot(ts_prism$flow_in ~ ts_prism$precip_in)
prism_lm <- lm(ts_prism$flow_in ~ ts_prism$precip_in)
summary(prism_lm)

