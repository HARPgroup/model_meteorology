# variables to test lseg_rolling_avg_graphs.R
nldas_root="https://raw.githubusercontent.com/HARPgroup/model_meteorology/main"
landseg = "L54071"
dataset = "mash"
landseg_ftype = "cbp6_landseg"
model_version_code = "cbp-6.0"
as_scen = 1

# Run lines 1-95 roughly

sqldf(
  "select * 
   from (
     select year, month, day, sum(tsvalue) as tsvalue
     from timeSeries 
     group by year, month, day
   ) as ts
   where tsvalue > 20.0"
)


# To QA table generation
dfPRC <- read.table(paste0(nldas_site,"/",dataset,"/",landseg,".PRC"), header = FALSE, sep = ",")
dfHET <- read.table(paste0(nldas_site,"/",dataset,"/",landseg,".HET"), header = FALSE, sep = ",")
dfTMP <- read.table(paste0(nldas_site,"/",dataset,"/",landseg,".TMP"), header = FALSE, sep = ",")
dfHSET <- read.table(paste0(nldas_site,"/",dataset,"/",landseg,".HSET"), header = FALSE, sep = ",")
dfRAD <- read.table(paste0(nldas_site,"/",dataset,"/",landseg,".RAD"), header = FALSE, sep = ",")


# Then run 
