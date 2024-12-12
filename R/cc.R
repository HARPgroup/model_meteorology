library("sqldf")
met_file = "http://deq1.bse.vt.edu:81/met/nldas2_resamptile/precip/N51137-nldas2-all.csv"
p10_file = "https://raw.githubusercontent.com/HARPgroup/cbp6/refs/heads/master/hildebrant_thesis/gcm_precip_data/lseg_delta_pr_RCP45_Ensemble_CRT_2041_2070_P10.csv"

met_data <- read.csv(met_file)
p10data <- read.csv(p10_file)

lseg_mo_data <- p10data[which(p10data$FIPS_NHL == "N51137"),]
lseg_factors <- as.data.frame(t(lseg_mo_data[,month.abb]))
lseg_factors$mo <- c(1:nrow(lseg_factors))
names(lseg_factors) <- c('pct', 'mo')
lseg_factors$factor <- (100.0 + lseg_factors$pct) / 100.0

met_data_adjusted <- sqldf(
  "select a.featureid, a.obs_date, a.tstime, a.tsendtime, a.yr, a.mo, a.da, a.hr, 
   a.precip_in * b.factor as precip_in 
   from met_data as a 
   left outer join lseg_factors as b 
   on (a.mo = b.mo)
   order by a.tsendtime
  " 
)
