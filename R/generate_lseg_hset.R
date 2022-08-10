# Function that calculates Hargreaves-Samani method of potential evapotranspiration
# Requires an hourly temperature and radiation dfs
# Containing columns year, month, day, hour, date, and respective metric (temp, rad)
# Outputs a dataframe of ET values with columns year, month, day, hour, PET
generate_lseg_hset <- function(dfTMP, dfRAD){
  # calculate daily maximum and minimum temperature values
  dailyMetrics <- sqldf("SELECT date, max(temp) max_temp, min(temp) min_temp
                       FROM dfTMP
                       GROUP BY date")
  # repeat daily maximum and minimum 24 times to match up with hourly values
  dailyMetrics$freq <- 24
  hourlyMetrics <- data.frame(date = dfTMP$date,
                              max_temp = rep(dailyMetrics$max_temp, dailyMetrics$freq),
                              min_temp = rep(dailyMetrics$min_temp, dailyMetrics$freq))
  # calculate PET (mm/day)
  k <- 0.19 # empirical coefficient
  hsPET <- (0.0135*(k)*(dfTMP$temp+17.8)*((hourlyMetrics$max_temp - hourlyMetrics$min_temp)^0.5)*0.408*(dfRAD$rad))
  # convert PET to inch/hour
  hsPET <- hsPET*0.0393701/24
  # create PET dataframe
  dfHSET <- data.frame(year = dfTMP$year,
                       month = dfTMP$month,
                       day = dfTMP$day,
                       hour = dfTMP$hour,
                       PET = hsPET)
}
