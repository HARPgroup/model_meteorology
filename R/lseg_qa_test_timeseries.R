##### This script runs QA on land segment summary stat data. It generates a txt file with list of land segments it flags.
## Last Updated 4/26/22
## HARP Group
## To change metric and QA testing value alter lines 33 and 45
## Change the .XXX label at the end of the paste statement in line 36 to correspond to metric (ex: PRC = precipitation)
## Change the numeric condition in the if statement to fit needs in line 45 (for precipitation > 1 corresponds to > 1 in/hr)

# load packages
#.libPaths("/var/www/R/x86_64-pc-linux-gnu-library/")
basepath <- '/var/www/R';
source(paste(basepath,'config.R',sep='/'))

#suppressPackageStartupMessageslibrary(lubridate))
##library(sqldf)
#library(IHA)
#library(zoo)
suppressPackageStartupMessages(library(data.table))

ds <- RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)

# load lseg_functions
nldas_url_path = "/met/out/lseg_csv"
nldas_site <- paste0(omsite,nldas_url_path) # temporary cloud url
nldas_dir <- "/backup/meteorology/" # directory where met data is stored
outdir=Sys.getenv(c('NLDAS_ROOT'))[1]
#source(paste(github_location,"HARParchive/HARP-2021-2022","lseg_functions.R", sep = "/"))

argst <- commandArgs(trailingOnly = T)
if (length(argst) < 4) {
  message("Use: Rscript lseg_qa_test_timeseries.R landseg dataset landseg_ftype model_version_code ")
  message("Ex: Rscript lseg_qa_test_timeseries.R A51011 1984010100-2020123123 cbp532_landseg cbp-5.3.2 ")
  quit()
}

landseg = argst[1]
dataset = argst[2]
landseg_ftype = argst[3]
model_version_code = argst[4]

# Variable names
om_con <- 'om_class_Constant'
om_file <- 'external_file'

# instantiate data frames and variables for loops
i <- 1

print(paste0("current landsegment: ", landseg))

# read in a model container
lseg_feature <- RomFeature$new(
  ds, list(
    ftype = landseg_ftype,
    bundle = 'landunit',
    hydrocode = landseg
  ),
  TRUE
)
if (!(lseg_feature$hydroid > 0)) {
  message(paste("Could not find", landseg))
  next
}
lseg_model <- RomProperty$new(
  ds, list(
    featureid = lseg_feature$hydroid,
    propcode = model_version_code,
    propname = paste(lseg_feature$name, model_version_code),
    varkey = 'om_model_element',
    entity_type = 'dh_feature'
  ),
  TRUE
)
if (is.na(lseg_model$pid)) {
  message(paste("Could not find mode for", landseg, ", creating."))
  lseg_model$save(TRUE)
}
nldas_datasets <- RomProperty$new(
  ds, list(
    featureid = lseg_model$pid,
    propname = 'nldas_datasets',
    entity_type = 'dh_properties'
  ),
  TRUE
)
if (is.na(nldas_datasets$pid)) {
  message(paste("Could not find NLDAS datasets for", landseg, ", creating."))
  nldas_datasets$save(TRUE)
}
nldas_data <- RomProperty$new(
  ds, list(
    featureid = nldas_datasets$pid,
    propname = dataset,
    entity_type = 'dh_properties'
  ),
  TRUE
)
if (is.na(nldas_data$pid)) {
  message(paste("Could not find NLDAS", dataset, ", creating."))
  nldas_data$save(TRUE)
}

# read in lseg_csv
ts_file_url <- paste0(nldas_site,"/",dataset,"/",landseg,".PRC")
ts_ext_file_url <- paste0(ext_url_base, nldas_url_path,"/",dataset,"/",landseg,".PRC")
timeSeries <- fread(ts_file_url)
names(timeSeries) <- c('year','month','day','hour','tsvalue')
# code with correct input directory if running on deq machine
#timeSeries <- fread(paste0(dir, "out/lseg_csv/1984010100-2020123123/",landseg,".PRC"))
print(paste0(landseg," data read"))
data_file <- RomProperty$new(
  ds,
  list(
    entity_type='dh_properties',propname='file',varkey=om_file,featureid=nldas_data$pid
  ),
  TRUE
)
data_file$propcode <- ts_ext_file_url
data_file$save(TRUE)

# line of code to help run even with incomplete lseg_csv
#timeSeries <- timeSeries[-nrow(timeSeries),]

# loops iterates through to check for abnormally values 
j <- 1
allcount <- sqldf("select count(*) as num_anom from timeSeries")
hecount <- sqldf("select count(*) as num_anom from timeSeries where tsvalue > 4.0")
decount <- sqldf(
  "select count(*) as num_anom 
   from (
     select year, month, day, sum(tsvalue) as tsvalue
     from timeSeries 
     group by year, month, day
   ) as ts
   where tsvalue > 20.0"
)
pcount <- sqldf("select count(*) as num_anom from timeSeries where tsvalue > 1.0")

print(paste0(landseg, allcount, "values checked"))

data_status <- RomProperty$new(
  ds,
  list(entity_type='dh_properties',propname='status',varkey=om_con,featureid=nldas_data$pid),
  TRUE
)
# flag as bad if there are anomalous values, or no values
if ( (hecount > 0) || (decount > 0) || (allcount == 0)) {
  data_status$propvalue <- 0
} else {
  data_status$propvalue <- 1
}
data_status$save(TRUE)
data_flagged <- RomProperty$new(
  ds,
  list(entity_type='dh_properties',propname='PRC_anomaly_count',varkey=om_con,featureid=nldas_data$pid),
  TRUE
)
data_flagged$propvalue <- as.integer(pcount)
data_flagged$save(TRUE)

data_count <- RomProperty$new(
  ds,
  list(entity_type='dh_properties',propname='record_count',varkey=om_con,featureid=nldas_data$pid),
  TRUE
)
data_count$propvalue <- as.integer(allcount)
data_count$save(TRUE)

de_count <- RomProperty$new(
  ds,
  list(entity_type='dh_properties',propname='PRC_daily_error_count',varkey=om_con,featureid=nldas_data$pid),
  TRUE
)
de_count$propvalue <- as.integer(decount)
de_count$save(TRUE)

he_count <- RomProperty$new(
  ds,
  list(entity_type='dh_properties',propname='PRC_hourly_error_count',varkey=om_con,featureid=nldas_data$pid),
  TRUE
)
he_count$propvalue <- as.integer(hecount)
he_count$save(TRUE)
