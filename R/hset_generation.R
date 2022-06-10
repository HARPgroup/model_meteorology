## This script runs generate_lseg_hset.R
## inputs are desired data directories, and segment list

# load packages
.libPaths("/var/www/R/x86_64-pc-linux-gnu-library/")

# function that creates HSET csv files using generate_lseg_hset.R
hset_generation.R <- function(lsegDir, oDir, segList){
  i <- 1
  while(i<=length(segList)){
    landseg <- segList[i]
    # read in land segment temperature and radiation data
    #dfTMP <- read.table(paste0("http://deq1.bse.vt.edu:81/met/out/lseg_csv/1984010100-2020123123/",landseg,".TMP"), header = FALSE, sep = ",")
    #dfRAD <- read.table(paste0("http://deq1.bse.vt.edu:81/met/out/lseg_csv/1984010100-2020123123/",landseg,".RAD"), header = FALSE, sep = ",")
    dfTMP <- read.table(paste0(lsegDir,landseg,".TMP"), header = FALSE, sep = ",")
    dfRAD <- read.table(paste0(lsegDir,landseg,".RAD"), header = FALSE, sep = ",")
    colnames(dfTMP) = c("year","month","day","hour","temp")
    dfTMP$date <- as.Date(paste(dfTMP$year,dfTMP$month,dfTMP$day, sep="-"))
    colnames(dfRAD) = c("year","month","day","hour","rad")
    dfRAD$date <- as.Date(paste(dfRAD$year,dfRAD$month,dfRAD$day, sep="-"))
    
    # running generate_lseg_hset.R
    dfHSET <- generate_lseg_hset(dfTMP = dfTMP, dfRAD = dfRAD)
    
    # create and save ET file as csv
    write.table(dfHSET,paste0(oDir,landseg,".HSET"), 
                row.names = FALSE, col.names = FALSE, sep = ",")
    
    i <- i+1
  }
}
