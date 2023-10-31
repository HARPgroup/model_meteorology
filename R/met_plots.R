dataset <- "mash"
landseg <- "N51660"
filename <- "/backup/meteorology/out/lseg_csv/mash/N51165.PRC"

nldas_dir <- "/backup/meteorology/out/lseg_csv" # directory where met data is stored
nldas_dir <- "http://deq1.bse.vt.edu:81/met/out/lseg_csv" # directory where met data is stored

filedir <- paste(nldas_dir, dataset, sep="/")
scales <- list("PRC"=3.0, "PET" = 0.25)

filename <- "http://deq1.bse.vt.edu:81/met/out/lseg_csv/mash/N51165.PRC"
for (comp in c('PRC', 'PET')) {
  filename <- paste(landseg,comp,sep=".")
  filepath <- paste(filedir,filename, sep="/")
  dat <- read.table(filepath, sep=",")
  names(dat) <- c("year", "month", "day", "hour", "tsvalue")
  # open the plot file
  filename <- paste0(nldas_dir,"/",dataset,"/",landseg,"_rollingAVG_met.png")
  png(filename)
  # render the plot
  boxplot(as.numeric(dat$tsvalue) ~ dat$year, ylim=c(0,as.numeric(scales[comp]) ))
  dev.off()
  fileurl <- paste0(nldas_url_base,"/",dataset,"/",landseg,"bw_", comp)
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
}
