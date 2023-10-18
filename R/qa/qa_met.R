library('hydrotools')
library('zoo')
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)

rodf <- data.frame(
  'model_version' = c('cbp-6.0', 'cbp-6.0'),
  'runid' = c('mash', 'mash'),
  'metric' = c('PRC_anomaly_count','PRC_daily_error_count'),
  'runlabel' = c('PRC_anomaly_count', 'PRC_daily_error_count')
)
met_data <- om_vahydro_metric_grid(
  metric = metric, runids = rodf, bundle = "landunit", ftype = "cbp6_landseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
