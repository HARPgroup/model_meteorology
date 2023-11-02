basepath="/var/www/R"
source("/var/www/R/config.R")
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(sqldf))
# load lseg_functions
source("/opt/model/model_meteorology/R/lseg_functions.R")

nldas_root=Sys.getenv(c('NLDAS_ROOT'))[1]
source(paste0(nldas_root,"/R/nldas_feature_dataset_prop.R"))
ds <- RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)

argst <- commandArgs(trailingOnly = T)
if (length(argst) < 2) {
  message("Use: Rscript lseg_hset.R landseg dataset ")
  message("Ex: Rscript lseg_hset.R A51011 1984010100-2020123123 ")
  quit()
}

landseg = argst[1]
dataset = argst[2]
# setup output if not existing
##### This script is an outline of calculating PET using the Hamon Method and downloading csv
dataset_url = paste0("http://deq1.bse.vt.edu:81/met/out/lseg_csv/",dataset)
dataset_path = paste0(nldas_root,"/out/lseg_csv/",dataset)
# loop iterates through AllLandsegList and outputs 2 csv files, one for each PET method
# read in land segment radiation data
dfRAD <- read.table(paste0(dataset_url,"/",landseg,".RAD"), header = FALSE, sep = ",")
colnames(dfRAD) = c("year","month","day","hour","rad")
dfRAD$date <- as.Date(paste(dfRAD$year,dfRAD$month,dfRAD$day,sep="-"))
# read in land segment temperature data
dfTMP <- read.table(paste0(dataset_url,"/",landseg,".TMP"), header = FALSE, sep = ",")
colnames(dfTMP) = c("year","month","day","hour","temp")
dfTMP$date <- as.Date(paste(dfTMP$year,dfTMP$month,dfTMP$day,sep="-"))

# calculate HET values and create df
dfHET <- generate_lseg_hset(dfTMP = dfTMP, dfRAD = dfRAD)
  
# create and save HET file as csv
write.table(
  dfHET,
  paste0(dataset_path,"/",landseg,".HSET"), 
  row.names = FALSE, col.names = FALSE, sep = ","
)
