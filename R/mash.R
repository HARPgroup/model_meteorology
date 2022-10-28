# cc manipulation
# 6.35%

# get inputs
argst <- commandArgs(trailingOnly=T)
if (length(argst) < 5) {
  message("Use: Rscript mash.R landseg observed_start observed_end synth_start synth_end [in_dir] [out_dir]")
  message("Ex: Rscript mash.R N51091 1984-01-01 2022-09-30 2002-10-01 2002-12-31 [in_dir] [out_dir]")
  message("Ex: Rscript mash.R N51091 1984-01-01 2022-09-30 2002-10-01 2002-12-31 /backup/model/out/lseg_csv/met2date [out_dir]")
  q("no")
}

# load required packages
library(lubridate)
library(sqldf)
library(data.table)

# defaults
out_dir="/backup/meteorology/out/lseg_csv/mash/"
site <- "http://deq1.bse.vt.edu:81/met/out/lseg_csv/1984010100-2022123123/" # temporary cloud url
def_year=year(now()) - 1
in_dir <- paste0("/backup/meteorology/out/lseg_csv/1984010100-",def_year,"123123/") # linux directory

# get arguments
landseg <- as.character(argst[1])
startdate1 <- as.character(argst[2])
enddate1 <- as.character(argst[3])
startdate2 <- as.character(argst[4])
enddate2 <- as.character(argst[5])
if (length(argst) >= 6) {
  in_dir <- as.character(argst[6]) 
}
if (length(argst) >= 7) {
  out_dir <- as.character(argst[7]) 
}


#install.packages("remotes")
#remotes::install_github("earthlab/cft")

# get monthly precip coefficients
# - load landseg feature rest
# - load gcm_models
# - load property ccP10T10_delta/ccP50T50_delta/ccP90T90_delta (pointer to the 10th,50th,90th percentile)
# - 
# get monthly temperature coefficients
# load base timeseries
# apply coefficients
#

# load synthetic_met_functions
source("https://raw.githubusercontent.com/HARPgroup/HARParchive/master/HARP-2021-2022/synthetic_met_functions.R")

# run get_lseg_csv to get download met data for range including mashup dates
lseg_csv <- get_lseg_csv(landseg = landseg, startdate = startdate1, enddate = enddate1, site = site, dir = in_dir)

# run generate_synthetic_timeseries to append two time periods together
mash_up <- generate_synthetic_timeseries(lseg_csv = lseg_csv, startdate1 = startdate1, enddate1 = enddate1, startdate2 = startdate2, enddate2 = enddate2)

#
#as.data.frame
lseg_df <- as.data.frame(lseg_csv$PET)
mash_df <- as.data.frame(mash_up$PET)
mash_pdf <- as.data.frame(mash_up$PET)
mash_yrmo_prc <- sqldf(
  "
    select year, month, sum(PRC) from mash_df
    group by year, month
  "
)
lseg_yrmo_prc <- sqldf(
  "
    select year, month, sum(PRC) from lseg_df
    group by year, month
  "
)

# generate plot
plot(as.Date(paste(mash_up$TMP$year,mash_up$TMP$month, mash_up$TMP$day,sep="-")), mash_up$TMP$TMP, type = "l")
plot(
  as.Date(paste(mash_up$PRC$year,mash_up$PRC$month, mash_up$PRC$day,sep="-")), 
  mash_up$PRC$PRC, 
  type = "l", 
  main = "Mashup 2019-2022 + 2002",
  xlab = "Year",
  ylab = "Monthly Total Precipitation (inches)"
)

# generate plot
plot(as.Date(paste(mash_up$TMP$year,mash_up$TMP$month, mash_up$TMP$day,sep="-")), mash_up$TMP$TMP, type = "l")
plot(
  as.Date(paste(mash_up$PRC$year,mash_up$PRC$month, mash_up$PRC$day,sep="-")), 
  mash_up$PRC$PRC, 
  type = "l", 
  main = "Mashup 2019-2022 + 2002",
  xlab = "Year",
  ylab = "Daily Total Precipitation (inches)"
)

write.table(mash_up$PRC,paste0(out_dir,landseg,".PRC"),col.names=FALSE,row.names=FALSE,sep=",")
write.table(mash_up$PET,paste0(out_dir,landseg,".PET"),col.names=FALSE,row.names=FALSE,sep=",")
write.table(mash_up$TMP,paste0(out_dir,landseg,".TMP"),col.names=FALSE,row.names=FALSE,sep=",")
write.table(mash_up$RAD,paste0(out_dir,landseg,".RAD"),col.names=FALSE,row.names=FALSE,sep=",")
write.table(mash_up$DPT,paste0(out_dir,landseg,".DPT"),col.names=FALSE,row.names=FALSE,sep=",")
write.table(mash_up$WND,paste0(out_dir,landseg,".WND"),col.names=FALSE,row.names=FALSE,sep=",")
