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

met_data <- om_vahydro_metric_grid(
  metric = metric, runids = metdf, bundle = "landunit", ftype = "cbp6_landseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
nrow(met_data[which(! is.na(met_data$prism_precip_annual_max_in)),])

landseg = "N24021"
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
barplot((comp_ann$prism - comp_ann$nldas2) ~ comp_ann$yr, main="Monthly Max Comparison",ylab = "Max Month PRISM - NLDAS in.")

