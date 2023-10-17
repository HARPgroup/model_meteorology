# cc manipulation
# 6.35%
options(scipen=999) # disable scientific notation in dataframes
# get inputs
argst <- commandArgs(trailingOnly=T)
if (length(argst) < 5) {
  message("Use: Rscript mash.R landseg observed_start observed_end synth_start synth_end [in_dir] [out_dir] [method=1/2]")
  message("Ex: Rscript mash.R N51091 1984-01-01 2022-09-30 2002-10-01 2002-12-31 [in_dir] [out_dir]")
  message("Ex: Rscript mash.R N51091 1984-01-01 2022-09-30 2002-10-01 2002-12-31 /backup/model/out/lseg_csv/met2date [out_dir]")
  q("no")
}

# load required packages
library(lubridate)
library(sqldf)
library(data.table)
# load synthetic_met_functions todo: make a package
#source("https://raw.githubusercontent.com/HARPgroup/model_meteorology/main/R/synthetic_met_functions.R")
source("/opt/model/model_meteorology/R/synthetic_met_functions.R")

# defaults
out_dir="/backup/meteorology/out/lseg_csv/mash/"
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
method <- 1
if (length(argst) >= 8) {
  method <- as.integer(argst[8]) 
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

# run generate_synthetic_timeseries to append two time periods together
fexts <- c('PRC', 'PET', 'TMP', 'RAD', 'DPT', 'WND')
if (method == 2) {
  message("Using method 2 - new mashing")
  for (fext in fexts) {
    fname <- paste0(in_dir,"/",landseg,".", fext)
    message(paste("Opening", fname))
    base_ts <- data.table::fread(fname)
    colnames(base_ts) <- c('year', 'month', 'day', 'hour', 'tsvalue')
    mash_ts <- make_single_synts(base_ts, startdate1, enddate1, startdate2, enddate2)
    foutname <- paste0(out_dir,"/",landseg,".", fext)
    message(paste("Saving", foutname))
    data.table::fwrite(mash_ts, foutname, col.names=FALSE)
  }
} else {   
  message("Using method 1 - old mashing")
  # run get_lseg_csv to get download met data for range including mashup dates
  lseg_csv <- get_lseg_csv(landseg = landseg, startdate = startdate1, enddate = enddate1, data_path = in_dir)

  message("Calling generate_synthetic_timeseries()")
  mash_up <- generate_synthetic_timeseries(lseg_csv = lseg_csv, startdate1 = startdate1, enddate1 = enddate1, startdate2 = startdate2, enddate2 = enddate2)
  message("Returned from generate_synthetic_timeseries()")

  message(paste("Write PRC to",paste0(out_dir,"/",landseg,".PRC")))
  write.table(mash_up$PRC,paste0(out_dir,"/",landseg,".PRC"),col.names=FALSE,row.names=FALSE,sep=",")
  message(paste("Write PET to",paste0(out_dir,"/",landseg,".PET")))
  write.table(mash_up$PET,paste0(out_dir,"/",landseg,".PET"),col.names=FALSE,row.names=FALSE,sep=",")
  message(paste("Write TMP to",paste0(out_dir,"/",landseg,".TMP")))
  write.table(mash_up$TMP,paste0(out_dir,"/",landseg,".TMP"),col.names=FALSE,row.names=FALSE,sep=",")
  message(paste("Write RAD to",paste0(out_dir,"/",landseg,".RAD")))
  write.table(mash_up$RAD,paste0(out_dir,"/",landseg,".RAD"),col.names=FALSE,row.names=FALSE,sep=",")
  message(paste("Write DPT to",paste0(out_dir,"/",landseg,".DPT")))
  write.table(mash_up$DPT,paste0(out_dir,"/",landseg,".DPT"),col.names=FALSE,row.names=FALSE,sep=",")
  message(paste("Write WND to",paste0(out_dir,"/",landseg,".WND")))
  write.table(mash_up$WND,paste0(out_dir,"/",landseg,".WND"),col.names=FALSE,row.names=FALSE,sep=",")
}
