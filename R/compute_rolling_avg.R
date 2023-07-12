library(dplyr)
#in order to run the new land segment commands for each phase, 
#the new files must be created on the users computer
#log into deq1
argst <- commandArgs(trailingOnly = T)
if (length(argst) < 2) {
  message("Use: Rscript compute_rolling_avg.R landseg dataset")
  message("Ex: Rscript compute_rolling_avg.R A51011 1984010100-2020123123")
  quit()
}

landseg = argst[1]
dataset = argst[2]
landseg_ftype = argst[3]
model_version_code = argst[4]

# load config defaults
site <- "http://deq1.bse.vt.edu:81/d.dh"  #Specify the site of interest, either d.bet OR d.dh
basepath <- '/var/www/R';
source(paste(basepath,'config.R',sep='/'))
ds <- RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)
# Variable names
om_con <- 'om_class_Constant'
om_file <- 'external_file'
img_file <- 'dh_image_file'

# load met functions 
source(paste(github_location,"model_meteorology","R/lseg_functions.R", sep = "/"))
source(paste(github_location,"model_meteorology","R/nldas_feature_dataset_prop.R", sep = "/"))

nldas_dir <- "/backup/meteorology/out/lseg_csv" # directory where met data is stored
# NOTE: the variable "ext_url_base" is the CORRECT ONE TO USE FOR ALL SCRIPTS
#       this variable is intended to differentiate things like omsite which can
#       sometimes be an internal private network url wherease 
#       ext_url_base is ALWAYS an internet accessible address
nldas_url_base <- paste0(ext_url_base,'/met/out/lseg_csv')
outdir=Sys.getenv(c('NLDAS_ROOT'))[1]

print(paste0("current landsegment: ", landseg))
# read in a model container
nldas_data <- nldas_feature_dataset_prop(ds, landseg, 'landunit',landseg_ftype, 'object')

#creating the merged dataset 
met_rolling_avg <- function(dfTMP, dfPRC, dfHET, dfHSET, dfTOTAL){
  
  # create df of daily values
  dailyPrecip <- sqldf("SELECT year, date, month, sum(precip) daily_precip
                           FROM dfTOTAL
                           GROUP BY date") 
  dailyTemp <- sqldf("SELECT date, avg(temp) daily_temp
                       FROM dfTOTAL
                       GROUP BY date") %>% select(daily_temp)
  dailyHPET <- sqldf("SELECT date, sum(Hpet) daily_Hpet
                       FROM dfTOTAL
                       GROUP BY date") %>% select(daily_Hpet)
  dailyHSPET <- sqldf("SELECT date, sum(HSpet) daily_HSpet
                       FROM dfTOTAL
                       GROUP BY date") %>% select(daily_HSpet)
  #creating daily water deficit values 
  
  dailyHPET$daily_water_deficit_HAMON <- dailyHPET$daily_Hpet - dailyPrecip$daily_precip
  dailyHSPET$daily_water_deficit_HS <- dailyHSPET$daily_HSpet - dailyPrecip$daily_precip
  
  df <- cbind(dailyPrecip, dailyHPET, dailyTemp, dailyHSPET)
  
  #rolling averages for precip
  rolling_7day_PRC <- sqldf(paste('SELECT *, AVG(daily_precip)
                           OVER (ORDER BY date ASC ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
                           AS rolling_7day_PRC
                          FROM df',sep="")) %>% select(rolling_7day_PRC)
  rolling_30day_PRC <- sqldf(paste('SELECT *, AVG(daily_precip)
                           OVER (ORDER BY date ASC ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
                           AS rolling_30day_PRC
                          FROM df',sep="")) %>% select(rolling_30day_PRC)
  rolling_90day_PRC <- sqldf(paste('SELECT *, AVG(daily_precip)
                           OVER (ORDER BY date ASC ROWS BETWEEN 89 PRECEDING AND CURRENT ROW)
                           AS rolling_90day_PRC
                          FROM df',sep="")) %>% select(rolling_90day_PRC)
  
  #rolling avergaes for Hamon PET 
  rolling_7day_HPET <- sqldf(paste('SELECT *, AVG(daily_Hpet)
                           OVER (ORDER BY date ASC ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
                           AS rolling_7day_HPET
                          FROM df',sep="")) %>% select(rolling_7day_HPET)
  rolling_30day_HPET <- sqldf(paste('SELECT *, AVG(daily_Hpet)
                           OVER (ORDER BY date ASC ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
                           AS rolling_30day_HPET
                          FROM df',sep="")) %>% select(rolling_30day_HPET)
  rolling_90day_HPET <- sqldf(paste('SELECT *, AVG(daily_Hpet)
                           OVER (ORDER BY date ASC ROWS BETWEEN 89 PRECEDING AND CURRENT ROW)
                           AS rolling_90day_HPET
                          FROM df',sep="")) %>% select(rolling_90day_HPET)
  
  #rolling avergaes for Hargreaves Samani PET 
  rolling_7day_HSPET <- sqldf(paste('SELECT *, AVG(daily_HSpet)
                           OVER (ORDER BY date ASC ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
                           AS rolling_7day_HSPET
                          FROM df',sep="")) %>% select(rolling_7day_HSPET)
  rolling_30day_HSPET <- sqldf(paste('SELECT *, AVG(daily_HSpet)
                           OVER (ORDER BY date ASC ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
                           AS rolling_30day_HSPET
                          FROM df',sep="")) %>% select(rolling_30day_HSPET)
  rolling_90day_HSPET <- sqldf(paste('SELECT *, AVG(daily_HSpet)
                           OVER (ORDER BY date ASC ROWS BETWEEN 89 PRECEDING AND CURRENT ROW)
                           AS rolling_90day_HSPET
                          FROM df',sep="")) %>% select(rolling_90day_HSPET)
  
  #rolling averages for temperature
  rolling_7day_TEMP <- sqldf(paste('SELECT *, AVG(daily_temp)
                           OVER (ORDER BY date ASC ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
                           AS rolling_7day_TEMP
                          FROM df',sep="")) %>% select(rolling_7day_TEMP)
  rolling_30day_TEMP <- sqldf(paste('SELECT *, AVG(daily_temp)
                           OVER (ORDER BY date ASC ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
                           AS rolling_30day_TEMP
                          FROM df',sep="")) %>% select(rolling_30day_TEMP)
  rolling_90day_TEMP <- sqldf(paste('SELECT *, AVG(daily_temp)
                           OVER (ORDER BY date ASC ROWS BETWEEN 89 PRECEDING AND CURRENT ROW)
                           AS rolling_90day_TEMP
                          FROM df',sep="")) %>% select(rolling_90day_TEMP)
  
  #rolling averages for water deficit (HamonPET-Precip)
  rolling_7day_WATERDEF_HAMON <- sqldf(paste('SELECT *, AVG(daily_water_deficit_HAMON)
                           OVER (ORDER BY date ASC ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
                           AS rolling_7day_WATERDEF_HAMON
                          FROM df',sep="")) %>% select(rolling_7day_WATERDEF_HAMON)
  rolling_30day_WATERDEF_HAMON <- sqldf(paste('SELECT *, AVG(daily_water_deficit_HAMON)
                           OVER (ORDER BY date ASC ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
                           AS rolling_30day_WATERDEF_HAMON
                          FROM df',sep="")) %>% select(rolling_30day_WATERDEF_HAMON)
  rolling_90day_WATERDEF_HAMON <- sqldf(paste('SELECT *, AVG(daily_water_deficit_HAMON)
                           OVER (ORDER BY date ASC ROWS BETWEEN 89 PRECEDING AND CURRENT ROW)
                           AS rolling_90day_WATERDEF_HAMON
                          FROM df',sep="")) %>% select(rolling_90day_WATERDEF_HAMON)
  
  #rolling averages for water deficit (HSPET-Precip)
  rolling_7day_WATERDEF_HS <- sqldf(paste('SELECT *, AVG(daily_water_deficit_HS)
                           OVER (ORDER BY date ASC ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
                           AS rolling_7day_WATERDEF_HS
                          FROM df',sep="")) %>% select(rolling_7day_WATERDEF_HS)
  rolling_30day_WATERDEF_HS <- sqldf(paste('SELECT *, AVG(daily_water_deficit_HS)
                           OVER (ORDER BY date ASC ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
                           AS rolling_30day_WATERDEF_HS
                          FROM df',sep="")) %>% select(rolling_30day_WATERDEF_HS)
  rolling_90day_WATERDEF_HS <- sqldf(paste('SELECT *, AVG(daily_water_deficit_HS)
                           OVER (ORDER BY date ASC ROWS BETWEEN 89 PRECEDING AND CURRENT ROW)
                           AS rolling_90day_WATERDEF_HS
                          FROM df',sep="")) %>% select(rolling_90day_WATERDEF_HS)
  
  #final table with 7-day, 30-day, and 90-day rolling averages for precipitation, temperature, and water deficit
  rollingAVG <- cbind(df, rolling_7day_PRC, rolling_30day_PRC, rolling_90day_PRC, rolling_7day_HPET, 
                      rolling_30day_HPET, rolling_90day_HPET, rolling_7day_HSPET, rolling_30day_HSPET, rolling_90day_HSPET, 
                      rolling_7day_TEMP,rolling_30day_TEMP, rolling_90day_TEMP, rolling_7day_WATERDEF_HAMON, 
                      rolling_30day_WATERDEF_HAMON,rolling_90day_WATERDEF_HAMON, rolling_7day_WATERDEF_HS, rolling_30day_WATERDEF_HS,
                      rolling_90day_WATERDEF_HS) 
  return(rollingAVG)
}

  
#reading in precip, pet, and temp data sets
dfPRC <- read.table(paste0(nldas_dir,"/",dataset, "/",landseg,".PRC"), header = FALSE, sep = ",")
# Note: we compute HET and HSET in 
dfHET <- read.table(paste0(nldas_dir,"/",dataset, "/",landseg,".HET"), header = FALSE, sep = ",")
dfTMP <- read.table(paste0(nldas_dir,"/",dataset, "/",landseg,".TMP"), header = FALSE, sep = ",")
dfHSET <- read.table(paste0(nldas_dir,"/",dataset, "/",landseg,".HSET"), header = FALSE, sep = ",")

colnames(dfTMP) = c("year","month","day","hour","temp")
dfTMP$date <- as.Date(paste(dfTMP$year,dfTMP$month,dfTMP$day, sep="-")) 
colnames(dfHET) = c("year1","month1","day1","hour1","Hpet")
dfHET$date1 <- as.Date(paste(dfHET$year,dfHET$month,dfHET$day, sep="-"))                      
colnames(dfPRC) = c("year2","month2","day2","hour2","precip")
dfPRC$date2 <- as.Date(paste(dfPRC$year,dfPRC$month,dfPRC$day, sep="-"))
colnames(dfHSET) = c("year3","month3","day3","hour3","HSpet")
dfHSET$date3 <- as.Date(paste(dfTMP$year,dfTMP$month,dfTMP$day, sep="-"))
dfTOTAL <- cbind(dfTMP, dfHET, dfPRC, dfHSET) %>% select(date, year, month, day, hour, temp, precip, Hpet, HSpet) 
#creating table from function
rollingAVGs <- met_rolling_avg(dfTMP = dfTMP, dfPRC = dfPRC, dfHET = dfHET, dfHSET = dfHSET, dfTOTAL=dfTOTAL)
  
# create and save PET file as csv
write.table(rollingAVGs,paste0(nldas_dir,"/",dataset,"/",landseg,"rollingAVG_met.csv"), 
            row.names = FALSE, col.names = TRUE, sep = ",")
dailyPrecipP6 <-  sqldf("SELECT year, month, date, daily_precip
                           FROM rollingAVGs 
                           WHERE daily_precip > 0.01")
#precip dats for Phase 6 land segs 
precipDaysP6 <- sqldf("SELECT year, daily_precip, count(daily_precip) precip_days
                          FROM dailyPrecipP6
                          WHERE daily_precip > 0
                          GROUP BY year")
#total precip per year for Phase 6 land segs 
precipP6 <- sqldf("SELECT year, sum(daily_precip) total_precip
                     FROM dailyPrecipP6
                     GROUP BY year")
#create precip graph 
precip6 <- ggplot() + 
  geom_bar(data = precipDaysP6, aes(x = year, y = precip_days), stat = "identity") + 
  geom_bar(data = precipP6, aes(x = year, y = total_precip), stat = "identity", fill= "darkblue") +
  xlab("Year") + 
  ylab("Preciptation Days (number of days with measurable precipitation > 0.01 in) 
     and Annual Precipitation Depth (in)") +
  ggtitle(paste0("Number of Precipitation Days and Annual Precip For Phase 6(Lseg ",landseg,")"))

filename <- paste0(nldas_dir,"/",dataset,"/",landseg,"_rollingAVG_met.png")
png(filename)
precip6
dev.off()
fileurl <- paste0(nldas_url_base,"/",dataset,"/",landseg,"_rollingAVG_met.png")
message(paste("Saving image file to:", filename, "URL:", fileurl))
img_file <- RomProperty$new(
  ds,
  list(
    entity_type='dh_properties',propname='fig_rollingAVG_met',varkey=img_file,featureid=nldas_data$pid
  ),
  TRUE
)
img_file$propcode <- fileurl
img_file$save(TRUE)
