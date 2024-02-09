basepath="/var/www/R"
source("/var/www/R/config.R")
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(sqldf))


nldas_root=Sys.getenv(c('NLDAS_ROOT'))[1]
nldas_url_base <- paste0(ext_url_base,'/met/out/lseg_csv')
source(paste0(nldas_root,"/R/nldas_feature_dataset_prop.R"))
ds <- RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)

argst <- commandArgs(trailingOnly = T)
if (length(argst) < 2) {
  message("Use: Rscript met_plots.R landseg dataset")
  message("Ex: Rscript met_plots.R A51011 1984010100-2020123123")
  quit()
}

landseg = argst[1]
dataset = argst[2]
landseg_ftype = argst[3]
model_version_code = argst[4]
years = unlist(strsplit(argst[5], ","))
if (length(years) <= 1) {
  # try splitting on space
  years = unlist(strsplit(argst[5], " "))
}

outdir <- paste0(nldas_root,"/out/lseg_csv/",dataset,"/images/")
outurl <- paste0(ext_url_base,"/met/out/lseg_csv/",dataset,"/images/")

filedir <- paste(nldas_root,"out/lseg_csv", dataset, sep="/")
scales <- list("PRC"=3.0, "PET" = 0.25)
nldas_dataset <- nldas_feature_dataset_prop(ds, landseg, 'landunit', landseg_ftype, model_version_code, dataset, 1)
annual_details <- RomProperty$new(
  ds, 
  list(
    propname="annual_details",
    varkey="om_model_element", 
    featureid=nldas_dataset$pid, 
    entity_type='dh_properties'
  ),
  TRUE
)

if (is.na(annual_details$pid)) {
  message(paste("Could not find NLDAS years dataset creating."))
  annual_details$save(TRUE)
}

for (comp in c('PRC', 'PET')) {
  filename <- paste(landseg,comp,sep=".")
  filepath <- paste(filedir,filename, sep="/")
  dat <- read.table(filepath, sep=",")
  names(dat) <- c("year", "month", "day", "hour", "tsvalue")
  
  for (yr in years) {
    # create a place to store
    thisyear <- RomProperty$new(
      ds, 
      list(
        propname=yr,
        varkey="om_model_element", 
        featureid=annual_details$pid, 
        entity_type='dh_properties'
      ),
      TRUE
    )
    
    if (is.na(thisyear$pid)) {
      message(paste("Could not find",yr,"dataset creating."))
      thisyear$save(TRUE)
    }
    
    # open the plot file
    yrdat <- sqldf(
      paste(
        "select year, month, day, sum(tsvalue) as tsvalue 
         from dat 
         where year = ", yr,
        "group by year, month, day"
      )
    )
    filename <- paste0(outdir,landseg,"_monthly_quant_", comp,"_",yr,".png")
    fileurl <- paste0(outurl,landseg,"_monthly_quant_", comp,"_",yr, ".png")
    png(filename)
    # render the plot
    boxplot(as.numeric(yrdat$tsvalue) ~ yrdat$month, ylim=c(0,as.numeric(scales[comp]) ))
    dev.off()
    message(paste("Saving image file to:", filename, "URL:", fileurl))
    img_file <- RomProperty$new(
      ds,
      list(
        entity_type='dh_properties',
        propname=paste0('fig_monthly_quant_',comp),
        varkey = 'dh_image_file',
        featureid=thisyear$pid
      ),
      TRUE
    )
    img_file$propcode <- fileurl
    img_file$save(TRUE)
    
    # make a bar plot
    
    modat <- sqldf("select month, min(tsvalue), max(tsvalue), sum(tsvalue) as tsvalue from yrdat group by month order by month")
    ymax <- max(modat$tsvalue)
    filename <- paste0(outdir,landseg,"_monthly_sum_", comp,"_",yr,".png")
    fileurl <- paste0(outurl,landseg,"_monthly_sum_", comp,"_",yr, ".png")
    png(filename)
    # render the plot
    barplot(as.numeric(modat$tsvalue) ~ modat$month, ylim=c(0,as.numeric(ymax) ))
    dev.off()
    message(paste("Saving image file to:", filename, "URL:", fileurl))
    img_file <- RomProperty$new(
      ds,
      list(
        entity_type='dh_properties',
        propname=paste0('fig_monthly_',comp),
        varkey = 'dh_image_file',
        featureid=thisyear$pid
      ),
      TRUE
    )
    img_file$propcode <- fileurl
    img_file$save(TRUE)
  }
}
