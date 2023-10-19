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
nldas_site <- paste0(omsite,"/met/out/lseg_csv") # temporary cloud url
nldas_root=Sys.getenv(c('NLDAS_ROOT'))[1]
if(is.empty(nldas_root)) {
  message("Can not locate env variable NLDAS_ROOT. Please set and tryagain (or run hspf_config to set)")
  quit()
}
#source(paste(github_location,"HARParchive/HARP-2021-2022","lseg_functions.R", sep = "/"))
source(paste0(nldas_root, "/R/nldas_feature_dataset_prop.R"))

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
if (length(argst) > 4) {
  # store as a run scenario?
  as_scen = argst[5]
} else {
  as_scen = 0
}

# Variable names
om_con <- 'om_class_Constant'
om_file <- 'external_file'

# instantiate data frames and variables for loops
i <- 1

print(paste0("current landsegment: ", landseg))

# get/set a model for this data 
nldas_data <- nldas_feature_dataset_prop(ds, landseg, 'landunit', landseg_ftype, model_version_code, dataset, as_scen)

# read in lseg_csv
ts_file_url <- paste0(nldas_site,"/",dataset,"/",landseg,".PRC")
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
data_file$propcode <- ts_file_url
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

message(paste(landseg, allcount, "values checked"))

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
# todo: put summary of years with errors/anomalies
ydecount <- sqldf(
  "select year, count(*) as num_anom 
   from (
     select year, month, day, sum(tsvalue) as tsvalue
     from timeSeries 
     group by year, month, day
   ) as ts
   where tsvalue > 20.0"
)
for (i in 1:nrow(ydecount)) {
  dinfo <- ydecount[i,]
  yde_rec <- RomProperty$new(
    ds,
    list(entity_type='dh_properties',propname=paste('year',dinfo$year),varkey=om_con,featureid=de_count$pid),
    TRUE
  )
  yde_rec$propvalue <- as.integer(dinfo$num_anom)
  yde_rec$save(TRUE)
  yde_year <- RomProperty$new(
    ds,
    list(entity_type='dh_properties',propname='year',varkey=om_con,featureid=yde_rec$pid),
    TRUE
  )
  yde_year$propvalue <- as.integer(dinfo$year)
  yde_year$save(TRUE)
}

he_count <- RomProperty$new(
  ds,
  list(entity_type='dh_properties',propname='PRC_hourly_error_count',varkey=om_con,featureid=nldas_data$pid),
  TRUE
)
he_count$propvalue <- as.integer(hecount)
he_count$save(TRUE)
