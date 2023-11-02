library(sqldf)

nldas_root=Sys.getenv(c('NLDAS_ROOT'))[1]
nldas_url_base <- paste0(ext_url_base,'/met/out/lseg_csv')

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

filedir <- paste(nldas_root, dataset, sep="/")
scales <- list("PRC"=3.0, "PET" = 0.25)
nldas_data <- nldas_feature_dataset_prop(ds, landseg, 'landunit',landseg_ftype, 'object')

for (comp in c('PRC', 'PET')) {
  filename <- paste(landseg,comp,sep=".")
  filepath <- paste(filedir,filename, sep="/")
  dat <- read.table(filepath, sep=",")
  names(dat) <- c("year", "month", "day", "hour", "tsvalue")
  # open the plot file
  dat <- sqldf("select year, month, day, sum(tsvalue) as tsvalue from dat group by year, month, day")
  filename <- paste0(nldas_root,"/met/out/lseg_csv/",dataset,"/",landseg,"_annual_prc_quant.png")
  png(filename)
  # render the plot
  boxplot(as.numeric(dat$tsvalue) ~ dat$year, ylim=c(0,as.numeric(scales[comp]) ))
  dev.off()
  fileurl <- paste0(nldas_url_base,"/",dataset,"/",landseg,"_annual_prc_quant", comp)
  ydat <- sqldf("select year, min(tsvalue), max(tsvalue), sum(tsvalue) as tsvalue from dat group by year")
  message(paste("Saving image file to:", filename, "URL:", fileurl))
  img_file <- RomProperty$new(
    ds,
    list(
      entity_type='dh_properties',
      propname=paste0('fig_annual_prc_quant_',comp),
      varkey=img_file,
      featureid=nldas_data$pid
    ),
    TRUE
  )
  img_file$propcode <- fileurl
  img_file$save(TRUE)
  
  # make a bar plot
  
  ydat <- sqldf("select year, sum(tsvalue) as tsvalue from dat group by year order by year")
  filename <- paste0(nldas_root,"/met/out/lseg_csv/",dataset,"/",landseg,"_annual_sum_prc.png")
  png(filename)
  # render the plot
  barplot(as.numeric(ydat$tsvalue) ~ ydat$year, ylim=c(0,as.numeric(scales[comp]) ))
  dev.off()
  fileurl <- paste0(nldas_url_base,"/",dataset,"/",landseg,"_annual_sum_prc.png", comp)
  ydat <- sqldf("select year, min(tsvalue), max(tsvalue), sum(tsvalue) as tsvalue from dat group by year")
  message(paste("Saving image file to:", filename, "URL:", fileurl))
  img_file <- RomProperty$new(
    ds,
    list(
      entity_type='dh_properties',
      propname=paste0('fig_annual_',comp),
      varkey=img_file,
      featureid=nldas_data$pid
    ),
    TRUE
  )
  img_file$propcode <- fileurl
  img_file$save(TRUE)
}
