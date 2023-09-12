library(sqldf)

# match dates in a time series

# get inputs
argst <- commandArgs(trailingOnly=T)
if (length(argst) < 3) {
  message("Use: Rscript time_template.R landseg in_dir time_template")
  message("Ex: Rscript time_template.R N51011 /backup/meteorology/out/lseg_csv/mash/ /tmp/met_1000.csv")
  message("Note: to make a time template, use 'make_wdm_template', ex: cbp make_wdm_template 1984 2024 met 1000")
  q("no")
}
landseg <- as.character(argst[1])
in_dir <- as.character(argst[2]) 
time_template <- as.character(argst[3]) 

time_template <- fread(wdm_template)
#./make_wdm_template 1984 2024 met 1000

fexts <- s('PRC', 'PET', 'TMP', 'RAD', 'DPT', 'WND')
for (i in length(fexts)) {
  fext <- fexts[i]
  fname <- paste0(in_dir,"/",landseg,".", fext)
  met_ts <- data.table::fread(fname)
  met_ts <- timeseries_correction(met_ts, time_template, data_col)
  data.table::fwrite(met_ts, fname)
}

