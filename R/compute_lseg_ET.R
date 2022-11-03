##### This script is an outline of calculating PET for land segments
#### It uses temperature and radiation data to calculate PET for each landsegment
#### The two methods for calculating PET are the Hamon and the Hargreaves-Samani 
#### The temperature and radiation data is located in the /backup/meteorology/out/lseg_csv
#### The generated csv files for PET will be outputed and stored in the same /backup/meteorology/out/lseg_csv directory
#### The csv files for the Hamon method follow the naming convention lseg.HET
#### The csv files for the Hargreaves-Samani method follow the naming convention lseg.HSET
## Last Updated 7/29/21
## HARP Group
argst <- commandArgs(trailingOnly = T)
if (length(argst) < 2) {
  message("Use: Rscript compute_rolling_avg.R landseg dataset")
  message("Ex: Rscript compute_rolling_avg.R A51011 1984010100-2020123123")
  quit()
}
landseg = argst[1]
dataset = argst[2]

nldas_dir <- "/backup/meteorology/out/lseg_csv" # directory where met data is stored
outdir=Sys.getenv(c('NLDAS_ROOT'))[1]

# load packages
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(sqldf))

# load vahydro functions
site <- "http://deq1.bse.vt.edu:81/d.dh"  #Specify the site of interest, either d.bet OR d.dh
basepath <- '/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# load lseg_functions
# todo: move these to model_meteorology repo
source(paste(github_location,"HARParchive/HARP-2021-2022","lseg_functions.R", sep = "/"))

# read in land segment temperature and radiation data
message("Loading Temperature data")
dfTMP <- read.table(paste0(nldas_dir,"/",dataset,"/",landseg,".TMP"), header = FALSE, sep = ",")
message("Loading Radiation data")
dfRAD <- read.table(paste0(nldas_dir,"/",dataset,"/",landseg,".RAD"), header = FALSE, sep = ",")
#dfTMP <- read.table(paste0("/backup/meteorology/out/lseg_csv/1984010100-2020123123/",landseg,".TMP"), header = FALSE, sep = ",")
#dfRAD <- read.table(paste0("/backup/meteorology/out/lseg_csv/1984010100-2020123123/",landseg,".RAD"), header = FALSE, sep = ",")
colnames(dfTMP) = c("year","month","day","hour","temp")
dfTMP$date <- as.Date(paste(dfTMP$year,dfTMP$month,dfTMP$day, sep="-"))
colnames(dfRAD) = c("year","month","day","hour","rad")
dfRAD$date <- as.Date(paste(dfRAD$year,dfRAD$month,dfRAD$day, sep="-"))

############################################################ Hargreaves-Samani Method
dfHET <- generate_lseg_het(dfTMP = dfTMP, dfRAD = dfRAD)
write.table(dfHET,paste0(nldas_dir,"/",dataset,"/",landseg,".HET"), 
              row.names = FALSE, col.names = FALSE, sep = ",")

dfHSET <- generate_lseg_hset(dfTMP = dfTMP, dfRAD = dfRAD)
write.table(dfHSET,paste0(nldas_dir,"/",dataset,"/",landseg,".HSET"), 
              row.names = FALSE, col.names = FALSE, sep = ",")
