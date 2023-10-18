basepath="/var/www/R"
source("/var/www/R/config.R")
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(sqldf))

nldas_root=Sys.getenv(c('NLDAS_ROOT'))[1]
source(paste0(nldas_root,"/R/nldas_feature_dataset_prop.R"))
ds <- RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)

argst <- commandArgs(trailingOnly = T)
if (length(argst) < 4) {
  message("Use: Rscript lseg_rolling_avg_graphs.R landseg dataset landseg_ftype model_version_code ")
  message("Ex: Rscript lseg_rolling_avg_graphs.R A51011 1984010100-2020123123 cbp532_landseg cbp-5.3.2 ")
  message("USTABE: Rolling_Averages_Graphs_Updated.R")
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
# setup output if not existing
outdir <- paste0(nldas_root,"/out/lseg_csv/",dataset,"/images/")
outurl <- paste0(ext_url_base,"/met/out/lseg_csv/",dataset,"/images/")
if (!file.exists(outdir)) {
  dir.create(outdir)
}

nldas_dataset <- nldas_feature_dataset_prop(ds, landseg, 'landunit', landseg_ftype, model_version_code, dataset, as_scen)

# 
#loading table 
table1 <- read.csv(paste0(outdir,landseg,"_rollingAVG_PET.csv"))

#Adding Julien day column 
table1$jday <- yday(table1$date)

#sorting tables
table_7day_HAMON <- sqldf("SELECT Year, Date, jday, rolling_7day_WATERDEF_HAMON
                    FROM table1")
table_30day_HAMON <- sqldf("SELECT Year, Date, jday, rolling_30day_WATERDEF_HAMON
                    FROM table1")
table_90day_HAMON <- sqldf("SELECT Year, Date, jday, rolling_90day_WATERDEF_HAMON
                    FROM table1") 
table_7day_HS <- sqldf("SELECT Year, Date, jday, rolling_7day_WATERDEF_HS
                    FROM table1")
table_30day_HS <- sqldf("SELECT Year, Date, jday, rolling_30day_WATERDEF_HS
                    FROM table1")
table_90day_HS <- sqldf("SELECT Year, Date, jday, rolling_90day_WATERDEF_HS
                    FROM table1") 

table_HAMONPET <- sqldf("SELECT Year, Date, jday, daily_Hpet
                    FROM table1") 
table_HSPET <- sqldf("SELECT Year, Date, jday, daily_HSpet
                    FROM table1") 
table_precip <- sqldf("SELECT Year, Date, jday, daily_precip, rolling_7day_PRC, rolling_30day_PRC, rolling_90day_PRC
                    FROM table1") 

#Creating tables with just 2020 data 
last_year <- max(table1$year)
first_year <- min(table1$year)
table.7day.HAMON.2020 <- sqldf(paste("select * from table_7day_HAMON where Year =",last_year))
table.30day.HAMON.2020 <- sqldf(paste("select * from table_30day_HAMON where Year =",last_year)) 
table.90day.HAMON.2020 <- sqldf(paste("select * from table_90day_HAMON where Year =",last_year))
table.7day.HS.2020 <- sqldf(paste("select * from table_7day_HS where Year =",last_year)) 
table.30day.HS.2020 <- sqldf(paste("select * from table_30day_HS where Year =",last_year)) 
table.90day.HS.2020 <- sqldf(paste("select * from table_90day_HS where Year =",last_year)) 
table.HAMONPET.2020 <- sqldf(paste("select * from table_HAMONPET where Year =",last_year))
table.HSPET.2020 <- sqldf(paste("select * from table_HSPET where Year =",last_year))
table.precip.2020 <- sqldf(paste("select * from table_precip where Year =",last_year))
yr_range=paste0(first_year,"-", last_year)
hil_txt=paste("The data for", last_year,"is highlighted.")
#Water Deficit Graphs: rolling 7,30, and 90 day averages for water deficit using
#both the Hamon and Hargreaves Samani methods 
df.7day.HAMON <- ggplot() + 
  geom_point(data = table_7day_HAMON, mapping = aes(x = jday, y = rolling_7day_WATERDEF_HAMON,color = "1984-2019"), 
             size = 0.5, stroke = 0.5, shape = 16, col = "black") + 
  geom_point(data = table.7day.HAMON.2020, aes(x=jday, y = rolling_7day_WATERDEF_HAMON, color= "2020"),
             size = 1, stroke = 0.5, shape = 16) +
  labs(x = "Julien Day (1-365)", 
       y = "Rolling 7Day Hamon PET Water Deficit (HPET-precip) (inches)", 
       color = "Legend", 
       caption =paste("Rolling 7 Day average water deficit for the years", yr_range,". Water deficit
       is defined as the potential evapotranspiration calculated by the Hamon method (inches) 
       minus the precipitation (inches).", hil_txt)) + 
  ggtitle(paste0("Rolling 7Day Hamon PET Water Deficit (Lseg ",landseg,")",yr_range))
df.7day.HAMON

df.7day.HS <- ggplot() + 
  geom_point(data = table_7day_HS, mapping = aes(x = jday, y = rolling_7day_WATERDEF_HS,color = "1984-2019"), 
             size = 0.5, stroke = 0.5, shape = 16, col = "black") + 
  geom_point(data = table.7day.HS.2020, aes(x=jday, y = rolling_7day_WATERDEF_HS, color= "2020"),
             size = 1, stroke = 0.5, shape = 16) +
  labs(x = "Julien Day (1-365)", 
       y = "Rolling 7Day Hargreaves Samani PET Water Deficit (HPET-precip) (inches)", 
       color = "Legend", 
       caption =paste("Rolling 7 Day average water deficit for the years",yr_range,". Water deficit
       is defined as the potential evapotranspiration calculated by the Hargreaves Samani method (inches) 
       minus the precipitation (inches).", hil_txt)) + 
  ggtitle(paste0("Rolling 7Day Hargreaves Samani PET Water Deficit (Lseg ",landseg,") : ", first_year,"-",last_year))
df.7day.HS

df.30day.HAMON <- ggplot() + 
  geom_point(data = table_30day_HAMON, mapping = aes(x = jday, y = rolling_30day_WATERDEF_HAMON,color = "1984-2019"), 
             size = 0.5, stroke = 0.5, shape = 16, col = "black") 
df.30day.HAMON <- df.30day.HAMON + 
  geom_point(data = table.30day.HAMON.2020, aes(x=jday, y = rolling_30day_WATERDEF_HAMON, color= "2020"),
             size = 1, stroke = 0.5, shape = 16) +
  labs(x = "Julien Day (1-365)", 
       y = "Rolling 30Day Hamon PET Water Deficit (HPET-precip) (inches)", 
       color = "Legend", 
       caption =paste("Rolling 30 Day average water deficit for the years",yr_range,". Water deficit
       is defined as the potential evapotranspiration calculated by the Hamon method (inches) 
       minus the precipitation (inches).", hil_txt)) + 
  ggtitle(paste0("Rolling 30Day Hamon PET Water Deficit (Lseg ",landseg,") 1984-2020"))
df.30day.HAMON

df.30day.HS <- ggplot() + 
  geom_point(data = table_30day_HS, mapping = aes(x = jday, y = rolling_30day_WATERDEF_HS,color = "1984-2019"), 
             size = 0.5, stroke = 0.5, shape = 16, col = "black") + 
  geom_point(data = table.30day.HS.2020, aes(x=jday, y = rolling_30day_WATERDEF_HS, color= "2020"),
             size = 1, stroke = 0.5, shape = 16) +
  labs(x = "Julien Day (1-365)", 
       y = "Rolling 30Day Hargreaves Samani PET Water Deficit (HPET-precip) (inches)", 
       color = "Legend", 
       caption =paste("Rolling 30 Day average water deficit for the years", yr_range,". Water deficit
       is defined as the potential evapotranspiration calculated by the Hargreaves Samani method (inches) 
       minus the precipitation (inches). ",hil_txt)) + 
  ggtitle(paste0("Rolling 30Day Hargreaves Samani PET Water Deficit (Lseg ",landseg,")", yr_range))
df.30day.HS

df.90day.HAMON <- ggplot() + 
  geom_point(data = table_90day_HAMON, mapping = aes(x = jday, y = rolling_90day_WATERDEF_HAMON,color = "1984-2019"), 
             size = 0.5, stroke = 0.5, shape = 16, col = "black") + 
  geom_point(data = table.90day.HAMON.2020, aes(x=jday, y = rolling_90day_WATERDEF_HAMON, color= "2020"),
             size = 1, stroke = 0.5, shape = 16) +
  labs(x = "Julien Day (1-365)", 
       y = "Rolling 90Day Hamon PET Water Deficit (HPET-precip) (inches)", 
       color = "Legend", 
       caption =paste("Rolling 90 Day average water deficit for the years",yr_range,". Water deficit
       is defined as the potential evapotranspiration calculated by the Hamon method (inches) 
       minus the precipitation (inches).",hil_txt)) + 
  ggtitle(paste0("Rolling 90Day Hamon PET Water Deficit (Lseg ",landseg,") ",yr_range))
df.90day.HAMON

df.90day.HS <- ggplot() + 
  geom_point(data = table_90day_HS, mapping = aes(x = jday, y = rolling_90day_WATERDEF_HS,color = "1984-2019"), 
             size = 0.5, stroke = 0.5, shape = 16, col = "black") + 
  geom_point(data = table.90day.HS.2020, aes(x=jday, y = rolling_90day_WATERDEF_HS, color= "2020"),
             size = 1, stroke = 0.5, shape = 16) +
  labs(x = "Julien Day (1-365)", 
       y = "Rolling 90Day Hargreaves Samani PET Water Deficit (HPET-precip) (inches)", 
       color = "Legend", 
       caption ="Rolling 90 Day average water deficit for the years 1984-2020. Water deficit
       is defined as the potential evapotranspiration calculated by the Hargr4eaves Samani method (inches) 
       minus the precipitation (inches). The data for 2020 is highlighted.") + 
  ggtitle(paste0("Rolling 90Day Hargreaves Samani PET Water Deficit (Lseg ",landseg,") 1984-2020"))
df.90day.HS

#Precipitation Graphs: rolling 7,30, and 90 day averages 
df.7day.precip <- ggplot() + 
  geom_point(data = table_precip, mapping = aes(x = jday, y = rolling_7day_PRC,color = "1984-2019"),
             size = 0.5, stroke = 0.5, shape = 16, col = "black") +
  geom_point(data = table.precip.2020, aes(x=jday, y = rolling_7day_PRC, color= "2020"),
             size = 1, stroke = 0.5, shape = 16) +
  labs(x = "Julien Day (1-365)", 
       y = "Rolling 7Day Precipitation (inches)", 
       color = "Legend", 
       caption ="Rolling 7 day average precipitation (inches).The data for 2020 is highlighted.") + 
  ggtitle(paste0("Rolling 7Day Precipitation (Lseg ",landseg,") 1984-2020"))
df.7day.precip

df.30day.precip <- ggplot() + 
  geom_point(data = table_precip, mapping = aes(x = jday, y = rolling_30day_PRC,color = "1984-2019"),
             size = 0.5, stroke = 0.5, shape = 16, col = "black") +
  geom_point(data = table.precip.2020, aes(x=jday, y = rolling_30day_PRC, color= "2020"),
             size = 1, stroke = 0.5, shape = 16) +
  labs(x = "Julien Day (1-365)", 
       y = "Rolling 30Day Precipitation (inches)", 
       color = "Legend", 
       caption ="Rolling 30 day average precipitation (inches).The data for 2020 is highlighted.") + 
  ggtitle(paste0("Rolling 30Day Precipitation (Lseg ",landseg,") 1984-2020"))
df.30day.precip

df.90day.precip <- ggplot() + 
  geom_point(data = table_precip, mapping = aes(x = jday, y = rolling_90day_PRC,color = paste0(first_year,"-",last_year)),
             size = 0.5, stroke = 0.5, shape = 16, col = "black") +
  geom_point(data = table.precip.2020, aes(x=jday, y = rolling_90day_PRC, color= last_year),
             size = 1, stroke = 0.5, shape = 16) +
  labs(x = "Julien Day (1-365)", 
       y = "Rolling 90Day Precipitation (inches)", 
       color = "Legend", 
       caption = paste("Rolling 90 day average precipitation (inches). The data for",last_year,"is highlighted.")) + 
  ggtitle(paste0("Rolling 90Day Precipitation (Lseg ",landseg,") ",dataset))
#df.90day.precip
ggsave(paste0(outdir,"rolling.90day.precip_",landseg,".png"))
img_url <- paste0(outurl,"rolling.90day.precip_",landseg,".png")
img_prop <- RomProperty$new(
  ds,
  list(
    propname = 'rolling.90day.precip',
    propcode = img_url,
    varkey = 'dh_image_file',
    featureid = nldas_dataset$pid,
    entity_type = 'dh_properties'
  ), 
  TRUE
)
img_prop$save(TRUE)
