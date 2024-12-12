################
#
# ET Function for loop.. 
#
###############

et_hamon_hargraves_correction <- function(land_seg,
                                        elevation,
                                        latitude,
                                        read_loc_base,
                                        read_loc_s25,
                                        read_loc_aux,
                                        save_loc,
                                        hamon_out_loc = 'hm',
                                        hargraves_out_loc = 'hs'
                                       ) {  
### get libraries
print("setting libPaths")
#.libPaths("~/R/x86_64-redhat-linux-gnu-library/PET_2022-07/")
.libPaths("~/R/x86_64-redhat-linux-gnu-library/3.5/")
.libPaths()
require(Evapotranspiration)
require(tidyr)

# load built indata
data(constants)

# SET FUNCTION INPUTS 

base_tmp = read.csv(paste(read_loc_base, '/hourly_', land_seg, '.csv', sep = ''))
s25_tmp  = read.csv(paste(read_loc_s25, '/', land_seg, '.TMP', sep = ''), head = FALSE)
base_rad = read.csv(paste(read_loc_aux, '/', land_seg, '.RAD', sep = ''), head = FALSE)
base_wnd = read.csv(paste(read_loc_aux, '/', land_seg, '.WND', sep = ''), head = FALSE)
base_dpt = read.csv(paste(read_loc_aux, '/', land_seg, '.DPT', sep = ''), head = FALSE)


###################################
# begin processing.... 
# get min/max 
base_tmp_ag = tidyr::unite_(base_tmp, paste(colnames(base_tmp)[c(2,3,4)], collapse="-"), colnames(base_tmp)[c(2,3,4)])
base_tmp_ag[,2] = as.Date(gsub('_', '-', base_tmp_ag[,2]))
base_tmp_min = aggregate.data.frame(base_tmp_ag[,4], by = list(base_tmp_ag[,2]), FUN = 'min')
base_tmp_max = aggregate.data.frame(base_tmp_ag[,4], by = list(base_tmp_ag[,2]), FUN = 'max')
base_tt = data.frame(date = base_tmp_min[,1], tmin =  base_tmp_min[,2], tmax = base_tmp_max[,2])

# get min/max 
s25_tmp_ag = tidyr::unite_(s25_tmp, paste(colnames(s25_tmp)[c(1,2,3)], collapse="-"), colnames(s25_tmp)[c(1,2,3)])
s25_tmp_ag[,1] = as.Date(gsub('_', '-', s25_tmp_ag[,1]))
s25_tmp_min = aggregate.data.frame(s25_tmp_ag[,3], by = list(s25_tmp_ag[,1]), FUN = 'min')
s25_tmp_max = aggregate.data.frame(s25_tmp_ag[,3], by = list(s25_tmp_ag[,1]), FUN = 'max')
s25_tt = data.frame(date = s25_tmp_min[,1], tmin =  s25_tmp_min[,2], tmax = s25_tmp_max[,2])

# get min/max 
# s50_tmp_ag = tidyr::unite_(s50_tmp, paste(colnames(s50_tmp)[c(1,2,3)], collapse="-"), colnames(s50_tmp)[c(1,2,3)])
# s50_tmp_ag[,1] = as.Date(gsub('_', '-', s50_tmp_ag[,1]))
# s50_tmp_min = aggregate.data.frame(s50_tmp_ag[,3], by = list(s50_tmp_ag[,1]), FUN = 'min')
# s50_tmp_max = aggregate.data.frame(s50_tmp_ag[,3], by = list(s50_tmp_ag[,1]), FUN = 'max')
# s50_tt = data.frame(date = s50_tmp_min[,1], tmin =  s50_tmp_min[,2], tmax = s50_tmp_max[,2])

# get the julian day
jday <- as.POSIXlt(base_tmp_ag[,2], format = "%d%b%y")$yday

# get daily tdew for daily RH 
base_dpt_ag = tidyr::unite_(base_dpt, paste(colnames(base_dpt)[c(1,2,3)], collapse="-"), colnames(base_dpt)[c(1,2,3)])
base_dpt_ag[,1] = as.Date(gsub('_', '-', base_dpt_ag[,1]))
base_dpt_ave = aggregate.data.frame(base_dpt_ag[,3], by = list(base_dpt_ag[,1]), FUN = 'mean')
dpt_ave = data.frame(date = base_dpt_ave[,1], dpt.day =  base_dpt_ave[,2]) 


# get sunshine hours from solar radiation data.
base_rad_ag = tidyr::unite_(base_rad, paste(colnames(base_rad)[c(1,2,3)], collapse="-"), colnames(base_rad)[c(1,2,3)])
base_rad_ag[,1] = as.Date(gsub('_', '-', base_rad_ag[,1]))

count_hours = function(x) {
  all = sum(x>0)
  return(all)
}

base_rad_hrs = aggregate.data.frame(base_rad_ag[,3], by = list(base_rad_ag[,1]), FUN = 'count_hours')
base_hrs = data.frame(date = base_rad_hrs[,1], nhrs = base_rad_hrs[,2] )

# put it all together 
df1 = base_tmp_ag[52585:140256,]
df1$Year = base_tmp[52585:140256,2]
df1$Month = base_tmp[52585:140256,3]
df1$Day = base_tmp[52585:140256,4]
df1$Hour = base_tmp[52585:140256,5]
df1$hour = NULL
df1$temperature.dC. = NULL
df1$pot.et.in. = NULL


print("line 89")
df2 = merge(df1, base_tt, by.x = 'year - month - day', by.y = 'date', all.x = TRUE)
print("line 91")
df3 = merge(df2, base_hrs, by.x = 'year - month - day', by.y = 'date', all.x = TRUE)
print("line 93")
df4 = merge(df3, dpt_ave, by.x = 'year - month - day', by.y = 'date', all.x = TRUE)
df4$wnd = base_wnd[96433:184104,5]
df4$dpt = base_dpt[96433:184104,5]
df4$rad = base_rad[96433:184104,5]
df4$sdtemp = base_tmp$temperature.dC.[52585:140256]
df4$julian = jday[52585:140256]

# get it in final form matching the evapo library .........

rh = function(tmin, tmax, tdew) {
  e0 = function(T) {
    e0 = 0.6108*exp((17.27*T)/(T + 237.3))
    return(e0)
  }
  ea = e0(tdew)
  e01 = e0(tmin)
  e02 = e0(tmax)
  es = (e01 + e02)/2
  rh = ea/es*100
  rh[rh>100] = 100
  return(rh)
}

# 25 scenario
df_25 = df4
print("line 119")
df_25_1 = merge(df_25, s25_tt, by.x = 'year - month - day', by.y = 'date', all.x = TRUE)
df_25_1$sdtemp = s25_tmp[,5]

# # 50 scenario
# df_50 = df4
# df_50_1 = merge(df_50, s50_tt, by.x = 'year - month - day', by.y = 'date', all.x = TRUE)
# df_50_1$sdtemp = s50_tmp[,5]


base_data = data.frame(Station.Numer = df3$seg,
                       Year = df4$Year,
                       Month = df4$Month,
                       Day = df4$Day,
                       Hour = df4$Hour,
                       Julian = df4$julian,
                       Temp.subdaily = df4$sdtemp,
                       Tdew.subdaily = df4$dpt, 
                       RH.subdaily = rh(df4$tmin, df4$tmax, df4$dpt.day),
                       Rs.subdaily = df4$rad/24,
                       n.daily = df3$nhrs,
                       uz.subdaily = df4$wnd*0.44704,
                       Tmin.daily = df4$tmin,
                       Tmax.daily = df4$tmax
)


s25_data = data.frame(Station.Numer = df3$seg,
                      Year = df_25_1$Year,
                      Month = df_25_1$Month,
                      Day = df_25_1$Day,
                      Hour = df_25_1$Hour,
                      Julian = df_25_1$julian,
                      Temp.subdaily = df_25_1$sdtemp,
                      Tdew.subdaily = df_25_1$dpt, 
                      RH.subdaily = rh(df_25_1$tmin.y, df_25_1$tmax.y, df_25_1$dpt.day + df_25_1$tmax.y - df4$tmax),
                      Rs.subdaily = df4$rad/24,
                      n.daily = df3$nhrs,
                      uz.subdaily = df_25_1$wnd*0.44704,
                      Tmin.daily = df_25_1$tmin.y,
                      Tmax.daily = df_25_1$tmax.y
)



# update constants 

deg2rad = function(deg) {
  rad = deg * pi/180
  return(rad)
}



constants$lat = latitude
constants$lat_rad = deg2rad(latitude)
constants$as = 0.23        #(Roderick, 1999, page 181) 
constants$bs = 0.5  # I left these for now, not sure if they are good or not ....
constants$Elev = elevation # meters gaithersburg md
constants$z = 10 # meters
#skipping the constants for estimating sunshine hours from cloud cover, as sunshine hours are used as
# input
# ones for crae
#constants$PA = 1183
# skipping constant for Morton's procedure 

# make ET inputs 

base_input <- ReadInputs(base_data, constants,
                         stopmissing=c(1,1,1),
                         timestep="subdaily")


s25_input <- ReadInputs(s25_data, constants,
                        stopmissing=c(1,1,1),
                        timestep="subdaily")


## calculate ET estimates 

base_hn = ET.Hamon(base_input, constants = NULL, ts="daily")
base_hs = ET.HargreavesSamani(base_input, constants, ts="daily")

s25_hn = ET.Hamon(s25_input, constants = NULL, ts="daily")
s25_hs = ET.HargreavesSamani(s25_input, constants, ts="daily")

### make output files  

# make new base
new_base = base_tmp[52585:140256,c(2,3,4,5,7)]

new_base$month = format(new_base$month, width = 2)
new_base$day = format(new_base$day, width = 2)
new_base$hour = format(new_base$hour, width = 2)

hm_out = new_base
hs_out = new_base

# wash negetives 

base_hn$ET.Daily[base_hn$ET.Daily < 0] <- 0.01
s25_hn$ET.Daily[s25_hn$ET.Daily < 0] <- 0.01

base_hs$ET.Daily[base_hs$ET.Daily < 0] <- 0.01
s25_hs$ET.Daily[s25_hs$ET.Daily < 0] <- 0.01

# get fraction  

hm_frac_day = (s25_hn$ET.Daily/base_hn$ET.Daily)
hs_frac_day = (s25_hs$ET.Daily/base_hs$ET.Daily) 

hm_out_agg = tidyr::unite_(hm_out, paste(colnames(hm_out)[c(1,2,3)], collapse="-"), colnames(hm_out)[c(1,2,3)])
hm_out_agg[,1] = as.Date(gsub('_', '-', hm_out_agg[,1]))
hm_out$date = hm_out_agg[,1]
hm_frac_merge = data.frame(date = index(s25_hn$ET.Daily), hamon.change = hm_frac_day)
print("line 234")
hm_merge = merge(hm_out, hm_frac_merge, by = 'date', all.x = TRUE)
hm_merge$date = NULL
hm_merge$hamon.change = hm_merge$pot.et.in. *  hm_merge$hamon.change
hm_merge$pot.et.in. = NULL

options(scipen=999)
hm_merge$hamon.change = format(hm_merge$hamon.change, digits = 8)

hs_out_agg = tidyr::unite_(hs_out, paste(colnames(hs_out)[c(1,2,3)], collapse="-"), colnames(hs_out)[c(1,2,3)])
hs_out_agg[,1] = as.Date(gsub('_', '-', hs_out_agg[,1]))
hs_out$date = hs_out_agg[,1]
hs_frac_merge = data.frame(date = index(s25_hn$ET.Daily), hargraves.change = hs_frac_day)
print("line 247")
hs_merge = merge(hs_out, hs_frac_merge, by = 'date', all.x = TRUE)
hs_merge$date = NULL
hs_merge$hargraves.change = hs_merge$pot.et.in. *  hs_merge$hargraves.change
hs_merge$pot.et.in. = NULL

hs_merge$hargraves.change = format(hs_merge$hargraves.change, digits = 8)


# write out the CSVs 

write.csv(hm_merge, paste(save_loc, '/', hamon_out_loc, '/', land_seg, '.PET', sep = ''), row.names = FALSE, quote = FALSE)
write.csv(hs_merge, paste(save_loc, '/', hargraves_out_loc, '/', land_seg, '.PET', sep = ''), row.names = FALSE, quote = FALSE)

cat(paste('Files written to:', paste(save_loc, '/', hamon_out_loc, '/', land_seg, '.PET', sep = ''), 'and', 
          paste(save_loc, '/', hargraves_out_loc, '/', land_seg, '.PET', sep = '')))

# return something just cuz
return(0)

}

