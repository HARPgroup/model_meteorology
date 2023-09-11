library(sqldf)

# match dates in a time series

# get inputs
argst <- commandArgs(trailingOnly=T)
if (length(argst) < 5) {
  message("Use: Rscript time_template.R met_ts time_template")
  message("Ex: Rscript time_template.R /backup/meteorology/out/lseg_csv/mash/N51187.PET /tmp/met_1000.csv")
  q("no")
}

time_template <- fread(wdm_template)
#./make_wdm_template 1984 2024 met 1000

met_ts <- timeseries_correction(met_ts, time_template, data_col)
