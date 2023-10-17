##### This script houses functions used to create mash-up timeseries data for synthetic meteorological datasets
## Last Updated 4/27/22
## HARP Group



# met timeseries data downloading function
# inputs a landsegment 
# inputs start and end date
# inputs website and linux locations of data
# outputs a list of lseg_csv timesieries for entire downloaded time period
get_lseg_csv <- function(landseg, startdate, enddate, data_path){
  
  # creating timeframe variable for grabing data
  timeframe <- paste0(substring(startdate, 1, 4), substring(startdate, 6, 7), substring(startdate, 9, 10), "00-",
                      substring(enddate, 1, 4), substring(enddate, 6, 7), substring(enddate, 9, 10), "23")
  
  # downloading entire timeseries data
  # using web directory or linux terminal directory
  message("Reading observed met data")
  message(paste("RAD:",paste0(data_path,"/",landseg, ".RAD")))
  dfRAD <- data.table::fread(paste0(data_path,"/",landseg, ".RAD"))
  dfTMP <- data.table::fread(paste0(data_path,"/",landseg, ".TMP"))
  dfPET <- data.table::fread(paste0(data_path,"/",landseg, ".PET"))
  dfPRC <- data.table::fread(paste0(data_path,"/",landseg, ".PRC"))
  dfWND <- data.table::fread(paste0(data_path,"/",landseg, ".WND"))
  dfDPT <- data.table::fread(paste0(data_path,"/",landseg, ".DPT"))
  
  message("Data read. Formatting columns.")
  # adding date column for date manipulation
  colnames(dfRAD) = c("year","month","day","hour","RAD")
  dfRAD$date <- as.Date(paste(dfRAD$year,dfRAD$month,dfRAD$day,sep="-"))
  
  colnames(dfTMP) = c("year","month","day","hour","TMP")
  dfTMP$date <- as.Date(paste(dfTMP$year,dfTMP$month,dfTMP$day,sep="-"))
  
  colnames(dfPET) = c("year","month","day","hour","PET")
  dfPET$date <- as.Date(paste(dfPET$year,dfPET$month,dfPET$day,sep="-"))
  
  colnames(dfPRC) = c("year","month","day","hour","PRC")
  dfPRC$date <- as.Date(paste(dfPRC$year,dfPRC$month,dfPRC$day,sep="-"))
  
  colnames(dfWND) = c("year","month","day","hour","WND")
  dfWND$date <- as.Date(paste(dfWND$year,dfWND$month,dfWND$day,sep="-"))
  
  colnames(dfDPT) = c("year","month","day","hour","DPT")
  dfDPT$date <- as.Date(paste(dfDPT$year,dfDPT$month,dfDPT$day,sep="-"))
  
  
  # filter by inputted date range
  message(paste("Clipping RAD to", startdate, enddate))
  dfRAD <- sqldf(paste0("SELECT year, month, day, hour, RAD
                  FROM dfRAD
                  WHERE date between ", 
                        as.numeric(as.Date(startdate)),
                        " AND ",
                        as.numeric(as.Date(enddate)),
                        ""))
  
  message(paste("Clipping TMP to", startdate, enddate))
  dfTMP <- sqldf(paste0("SELECT year, month, day, hour, TMP
                  FROM dfTMP
                  WHERE date between ", 
                        as.numeric(as.Date(startdate)),
                        " AND ",
                        as.numeric(as.Date(enddate)),
                        ""))
  
  message(paste("Clipping PET to", startdate, enddate))
  dfPET <- sqldf(paste0("SELECT year, month, day, hour, PET
                  FROM dfPET
                  WHERE date between ", 
                        as.numeric(as.Date(startdate)),
                        " AND ",
                        as.numeric(as.Date(enddate)),
                        ""))
  
  message(paste("Clipping PRC to", startdate, enddate))
  dfPRC <- sqldf(paste0("SELECT year, month, day, hour, PRC
                  FROM dfPRC
                  WHERE date between ", 
                        as.numeric(as.Date(startdate)),
                        " AND ",
                        as.numeric(as.Date(enddate)),
                        ""))
  
  message(paste("Clipping WND to", startdate, enddate))
  dfWND <- sqldf(paste0("SELECT year, month, day, hour, WND
                  FROM dfWND
                  WHERE date between ", 
                        as.numeric(as.Date(startdate)),
                        " AND ",
                        as.numeric(as.Date(enddate)),
                        ""))
  
  message(paste("Clipping DPT to", startdate, enddate))
  dfDPT <- sqldf(paste0("SELECT year, month, day, hour, DPT
                  FROM dfDPT
                  WHERE date between ", 
                        as.numeric(as.Date(startdate)),
                        " AND ",
                        as.numeric(as.Date(enddate)),
                        ""))
  
  message("Merging all met components")
  # return new time series as list
  dfALL <- list(
    "RAD" = dfRAD,
    "TMP" = dfTMP,
    "PET" = dfPET, 
    "PRC" = dfPRC,
    "WND" = dfWND,
    "DPT" = dfDPT)
  
  message("Returning merged met.")
  return(dfALL)
  
}

make_sane_hours <- function(base_ts) {
  if (max(base_ts$hour) > 23) {
    base_ts$hour <- base_ts$hour - 1
  }
  return(base_ts)
}

make_cbp_hours <- function(base_ts) {
  if (min(base_ts$hour) == 0) {
    base_ts$hour <- base_ts$hour + 1
  }
  return(base_ts)
}

# do a single, flexible period adjustment
# requires that data column is named tsvalue
# do a single, flexible period adjustment
# requires that data column is named tsvalue
make_single_synts <- function(base_ts, startdate1, enddate1, startdate2, enddate2){
  
  date_ranges = as.data.frame(list(startdate1 = startdate1, enddate1 = enddate1, startdate2 = startdate2, enddate1 = enddate1, enddate2 = enddate2))
  date_ranges <- sqldf(
    "
   SELECT datetime(enddate1) as last_real, datetime(startdate2) as startdate2, datetime(enddate2) as enddate2, 
      datetime(unixepoch(startdate2) + (unixepoch(enddate1) - unixepoch(startdate2) + 3600 ), 'unixepoch')  as next_date, 
      (unixepoch(startdate2) - unixepoch(enddate1))  as extra_secs, 
      (unixepoch(enddate1) - unixepoch(startdate2) + 86400 ) as offset_tsecs ,
      unixepoch(enddate1) end1_ts, unixepoch(startdate2) as start2_ts
    from date_ranges 
  "
  )
  
  base_ts <- sqldf(
    "select a.year, a.month, a.day, a.hour, 
   datetime( 
     (a.year ||'-'|| substr('0' || a.month, -2, 2) ||'-' || substr('0' || a.day, -2, 2) || ' ' || substr('0' || a.hour, -2, 2) || ':00:00')
   ) as thisdate, tsvalue
   from base_ts as a 
  "
  )
  mash_ts <- sqldf(
    "select a.year, a.month, a.day, a.hour, 
   datetime(a.thisdate, ('+' || b.offset_tsecs || ' seconds')) as thisdate, tsvalue
   from base_ts as a 
   left outer join date_ranges as b 
   on (1 = 1) 
   where a.thisdate >= b.startdate2 
     and datetime(a.thisdate, ('+' || b.offset_tsecs || ' seconds')) <= b.enddate2
   "
  )
  mash_ts$year <- as.integer(format(as.Date(mash_ts$thisdate,tz="UTC"), format='%Y'))
  mash_ts$month <- as.integer(format(as.Date(mash_ts$thisdate,tz="UTC"), format='%m'))
  mash_ts$day <- as.integer(format(as.Date(mash_ts$thisdate,tz="UTC"), format='%d'))
  mash_ts$hour <- as.integer(format(as.POSIXct(mash_ts$thisdate,tz="UTC"), format='%H'))
  
  
  mash_ts <- sqldf(
    "
  select year, month, day, hour, tsvalue from (
    select * from base_ts 
    UNION select * from mash_ts
  ) as foo
  order by year, month, day, hour
  "
  )
  return(mash_ts)
}

make_single_synts_test <- function(base_ts, startdate1, enddate1, startdate2, enddate2){
  # uses strict numerical addition to create synthetic date range, then uses sqlite (or other sqldf engine)
  # to make the new timestamp which should handle leaps, DST etc without incident.
  date_ranges = as.data.frame(list(startdate1 = startdate1, enddate1 = enddate1, startdate2 = startdate2, enddate1 = enddate1, enddate2 = enddate2))
  date_ranges <- sqldf(
    "
   SELECT datetime(enddate1) as last_real, datetime(startdate2) as startdate2, datetime(enddate2) as enddate2, 
      datetime(unixepoch(startdate2) + (unixepoch(enddate1) - unixepoch(startdate2) + 3600 ), 'unixepoch')  as next_date, 
      (unixepoch(startdate2) - unixepoch(enddate1))  as extra_secs, 
      (unixepoch(enddate1) - unixepoch(startdate2) ) as offset_tsecs ,
      unixepoch(enddate1) end1_ts, unixepoch(startdate2) as start2_ts
    from date_ranges 
    "
  )
  
  base_ts <- sqldf(
    "select a.year, a.month, a.day, a.hour, 
   datetime( 
     (a.year ||'-'|| substr('0' || a.month, -2, 2) ||'-' || substr('0' || a.day, -2, 2) || ' ' || substr('0' || a.hour, -2, 2) || ':00:00')
   ) as thisdate, tsvalue
   from base_ts as a 
  "
  )
  base_ts <- sqldf(
    "
     select * from base_ts as a 
     where thisdate <= (select max(last_real) from date_ranges)
    "
  )
  
  mash_ts <- sqldf(
    "select a.year, a.month, a.day, a.hour, 
   datetime(a.thisdate, ('+' || b.offset_tsecs || ' seconds')) as thisdate, tsvalue
   from base_ts as a 
   left outer join date_ranges as b 
   on (1 = 1) 
   where a.thisdate >= b.startdate2 
     and datetime(a.thisdate, ('+' || b.offset_tsecs || ' seconds')) <= b.enddate2
   "
  )
  mash_ts$year <- as.integer(format(as.Date(mash_ts$thisdate,tz="UTC"), format='%Y'))
  mash_ts$month <- as.integer(format(as.Date(mash_ts$thisdate,tz="UTC"), format='%m'))
  mash_ts$day <- as.integer(format(as.Date(mash_ts$thisdate,tz="UTC"), format='%d'))
  mash_ts$hour <- as.integer(format(as.POSIXct(mash_ts$thisdate,tz="UTC"), format='%H')) + 1
  
  new_ts <- rbind(base_ts, mash_ts)
  
  mash_ts <- sqldf(
    "
  select * from (
    select a.year, a.month, a.day, a.hour, a.tsvalue from base_ts as a 
      where a.thisdate < (select max(startdate2) from date_ranges)
    UNION select year, month, day, hour, tsvalue from mash_ts
  ) as foo
  order by year, month, day, hour
  "
  )
  return(mash_ts)
}


# mash up time series function
# inputs lseg_csv data list for one land segment and entire timeperiod (output of get_lseg_csv function)
# inputs two start dates and end dates in "YYYY-MM-DD" format
# outputs a synthetic timeseries for modeling purposes
generate_synthetic_timeseries <- function(lseg_csv, startdate1, enddate1, startdate2, enddate2){
  
  # seperate list into individual data frames
  dfRAD <- lseg_csv$RAD
  dfTMP <- lseg_csv$TMP
  dfPET <- lseg_csv$PET
  dfPRC <- lseg_csv$PRC
  dfWND <- lseg_csv$WND
  dfDPT <- lseg_csv$DPT
  
  # adding date column for date manipulation
  message("Formatting individual MET components for synthesis")
  colnames(dfRAD) = c("year","month","day","hour","RAD")
  dfRAD$date <- as.Date(paste(dfRAD$year,dfRAD$month,dfRAD$day,sep="-"))
  
  colnames(dfTMP) = c("year","month","day","hour","TMP")
  dfTMP$date <- as.Date(paste(dfTMP$year,dfTMP$month,dfTMP$day,sep="-"))
  
  colnames(dfPET) = c("year","month","day","hour","PET")
  dfPET$date <- as.Date(paste(dfPET$year,dfPET$month,dfPET$day,sep="-"))
  
  colnames(dfPRC) = c("year","month","day","hour","PRC")
  dfPRC$date <- as.Date(paste(dfPRC$year,dfPRC$month,dfPRC$day,sep="-"))
  
  colnames(dfWND) = c("year","month","day","hour","WND")
  dfWND$date <- as.Date(paste(dfWND$year,dfWND$month,dfWND$day,sep="-"))
  
  colnames(dfDPT) = c("year","month","day","hour","DPT")
  dfDPT$date <- as.Date(paste(dfDPT$year,dfDPT$month,dfDPT$day,sep="-"))
  
  
  # declaring difference in years for naming purposes
  year_diff = as.numeric(substring(enddate1, 1, 4)) - as.numeric(substring(startdate2, 1, 4))
  
  # filter by inputted date ranges
  message("Isolating RAD obs")
  dfRAD1 <- sqldf(paste0("SELECT year, month, day, hour, RAD
                  FROM dfRAD
                  WHERE date between ", 
                         as.numeric(as.Date(startdate1)),
                         " AND ",
                         as.numeric(as.Date(enddate1)),
                         ""))
  dfRAD2 <- sqldf(paste0("SELECT year + ", year_diff, " , month, day, hour, RAD
                  FROM dfRAD
                  WHERE date between ", 
                         as.numeric(as.Date(startdate2)),
                         " AND ",
                         as.numeric(as.Date(enddate2)),
                         ""))
  
  
  message("Isolating TMP obs")
  dfTMP1 <- sqldf(paste0("SELECT year, month, day, hour, TMP
                  FROM dfTMP
                  WHERE date between ", 
                         as.numeric(as.Date(startdate1)),
                         " AND ",
                         as.numeric(as.Date(enddate1)),
                         ""))
  dfTMP2 <- sqldf(paste0("SELECT year + ", year_diff, " , month, day, hour, TMP
                  FROM dfTMP
                  WHERE date between ", 
                         as.numeric(as.Date(startdate2)),
                         " AND ",
                         as.numeric(as.Date(enddate2)),
                         ""))
  
  message("Isolating PET obs")
  dfPET1 <- sqldf(paste0("SELECT year, month, day, hour, PET
                  FROM dfPET
                  WHERE date between ", 
                         as.numeric(as.Date(startdate1)),
                         " AND ",
                         as.numeric(as.Date(enddate1)),
                         ""))
  dfPET2 <- sqldf(paste0("SELECT year + ", year_diff, " , month, day, hour, PET
                  FROM dfPET
                  WHERE date between ", 
                         as.numeric(as.Date(startdate2)),
                         " AND ",
                         as.numeric(as.Date(enddate2)),
                         ""))

  message("Isolating PRC obs")
  dfPRC1 <- sqldf(paste0("SELECT year, month, day, hour, PRC
                  FROM dfPRC
                  WHERE date between ", 
                         as.numeric(as.Date(startdate1)),
                         " AND ",
                         as.numeric(as.Date(enddate1)),
                         ""))
  dfPRC2 <- sqldf(paste0("SELECT year + ", year_diff, " , month, day, hour, PRC
                  FROM dfPRC
                  WHERE date between ", 
                         as.numeric(as.Date(startdate2)),
                         " AND ",
                         as.numeric(as.Date(enddate2)),
                         ""))

  
  message("Isolating WND obs")
  dfWND1 <- sqldf(paste0("SELECT year, month, day, hour, WND
                  FROM dfWND
                  WHERE date between ", 
                         as.numeric(as.Date(startdate1)),
                         " AND ",
                         as.numeric(as.Date(enddate1)),
                         ""))
  dfWND2 <- sqldf(paste0("SELECT year + ", year_diff, " , month, day, hour, WND
                  FROM dfWND
                  WHERE date between ", 
                         as.numeric(as.Date(startdate2)),
                         " AND ",
                         as.numeric(as.Date(enddate2)),
                         ""))

  
  dfDPT1 <- sqldf(paste0("SELECT year, month, day, hour, DPT
                  FROM dfDPT
                  WHERE date between ", 
                         as.numeric(as.Date(startdate1)),
                         " AND ",
                         as.numeric(as.Date(enddate1)),
                         ""))
  dfDPT2 <- sqldf(paste0("SELECT year + ", year_diff, " , month, day, hour, DPT
                  FROM dfDPT
                  WHERE date between ", 
                         as.numeric(as.Date(startdate2)),
                         " AND ",
                         as.numeric(as.Date(enddate2)),
                         ""))

  # renaming columns to match before merging timeseries tables
  colnames(dfRAD2) = c("year","month","day","hour","RAD")
  colnames(dfTMP2) = c("year","month","day","hour","TMP")
  colnames(dfPET2) = c("year","month","day","hour","PET")
  colnames(dfPRC2) = c("year","month","day","hour","PRC")
  colnames(dfWND2) = c("year","month","day","hour","WND")
  colnames(dfDPT2) = c("year","month","day","hour","DPT")
  
  # combining two timeseries
#  dfRAD_MASH <- rbind(dfRAD1, leap_year_correction(dfRAD2))
#  dfTMP_MASH <- rbind(dfTMP1, leap_year_correction(dfTMP2))
#  dfPET_MASH <- rbind(dfPET1, leap_year_correction(dfPET2))
#  dfPRC_MASH <- rbind(dfPRC1, leap_year_correction(dfPRC2))
#  dfWND_MASH <- rbind(dfWND1, leap_year_correction(dfWND2))
#  dfDPT_MASH <- rbind(dfDPT1, leap_year_correction(dfDPT2))

  dfRAD_MASH <- rbind(dfRAD1, dfRAD2)
  dfTMP_MASH <- rbind(dfTMP1, dfTMP2)
  dfPET_MASH <- rbind(dfPET1, dfPET2)
  dfPRC_MASH <- rbind(dfPRC1, dfPRC2)
  dfWND_MASH <- rbind(dfWND1, dfWND2)
  dfDPT_MASH <- rbind(dfDPT1, dfDPT2)
  
  # return new time series as list
  dfSYNTHETIC <- list(
    "RAD" = dfRAD_MASH,
    "TMP" = dfTMP_MASH,
    "PET" = dfPET_MASH, 
    "PRC" = dfPRC_MASH,
    "WND" = dfWND_MASH,
    "DPT" = dfDPT_MASH
  )

  # return new time series as list
#  dfSYNTHETIC <- list(
#    "RAD" = leap_year_correction(dfRAD_MASH),
#    "TMP" = leap_year_correction(dfTMP_MASH),
#    "PET" = leap_year_correction(dfPET_MASH), 
#    "PRC" = leap_year_correction(dfPRC_MASH),
#    "WND" = leap_year_correction(dfWND_MASH),
#    "DPT" = leap_year_correction(dfDPT_MASH))
  
  return(dfSYNTHETIC)
}

leap_year_correction <- function(met_ts) {
  met_years <- sqldf("select year, count(*) from met_ts group by year order by year")
  for (i in nrow(met_years)) {
    yr <- met_years[i,]$year
    if ((julian.Date(date(paste0(yr,"-12-31")), origin=date(paste0(yr-1,"-12-31"))))[1] > 365) {
      # insure that February has 29 days (if full month of February)
      febn <- sqldf(
        paste0(
          "select count(*) from (
             select year, month, day from met_ts
             where month = 2 AND year = ", yr, 
             " group by year, month, day 
          ) as foo"
        )
      )
      if (febn == 28) {
        # if it has 28 we know that it *needs* a leap year, and the intention is for a full month of February
        # so we duplicate the 28th
        feb29 <- sqldf(
          paste0(
            "select * from met_ts
           where (cast(month as INT) || day) == '228'
           and year = ", yr
          )
        )
        feb29$day <- 29
        met_ts <- sqldf(
          paste0(
            "select * from (
               select * from met_ts
               UNION 
               select * from feb29
            ) order by year, month, day"
          )
        )
        # If it had less than 28, we conclude that the timeseries stops before the end of February
        # If it has more than 28 then we know it is just fine and we do nothing
      }
    } else {
      # insure that February has 28 days (if full month of february)
      met_ts <- sqldf(
        paste0(
          "select * from met_ts
           where (cast(month as INT) || day) <> '229'
           and year = ", yr," 
           UNION 
           select * from met_ts
           where year <> ", yr
        )
      )
    }
  }
  return(met_ts)
}

timeseries_correction <- function(met_ts, time_template, data_col) {
  if (ncol(met_ts) < 5) {
    message(paste("Daily time series for", data_col,"no correction applied.") )
    return(met_ts)
  }
  colnames(met_ts) = c("year","month","day","hour",data_col)
  colnames(time_template) = c("year","month","day","hour",data_col)
  harmo <- sqldf(
    paste0(
      " 
        select a.year, a.month, a.day, a.hour, avg(b.", data_col,") as tsvalue 
        from time_template as a 
        left outer join 
        met_ts as b 
        on (
          a.year = b.year 
          and a.month = b.month 
          and a.day = b.day 
          and a.hour = b.hour
        ) 
        group by a.year, a.month, a.day, a.hour 
        order by a.year, a.month, a.day, a.hour 
      "
    )
  )
  # we fix NULL values here
  # also, this fixes where hour = 0 because the 
  # WDM export routine sets an hour of 0 for the first record, the 1-24 for everything
  # afterwards. Weird. But we keep it, since it will require it as input
  harmo <- sqldf(
    paste0(
      " 
        select year, month, day, hour, 
           CASE 
              WHEN tsvalue IS NULL THEN 0.0
              ELSE tsvalue
           END as tsvalue
        from harmo
        order by year, month, day, hour 
      "
    )
  )
  return(harmo)
}

# posting timeseries function
# inputs a land segment
# inputs two start dates and end dates
# inputs a lseg_csv synthetic timeseries for given dates (output of generate_synthetic_timesieries function)
# inputs saving directory
# posts new synthetic timeseries to terminal for wdm generation
post_synthetic_timeseries <- function(landseg, startdate1, enddate1, startdate2, enddate2, lseg_csv, dir){
  
  # create mashup date format for saving
  mashupdate <- paste0(substring(startdate1, 1, 4), substring(startdate1, 6, 7), substring(startdate1, 9, 10), "00-",
                       substring(enddate2, 1, 4), substring(enddate2, 6, 7), substring(enddate2, 9, 10), "23")
  
  
  # saving and posting new timeseries
  # first line is for local testing
  # second line saves to ouput directory on linux
  write.table(lseg_csv$RAD, paste0("C:/Users/kylew/Documents/HARP/NLDAS/mashups/", mashupdate, landseg, ".RAD"), 
              row.names = FALSE, col.names = FALSE, sep = ",")
  #write.table(lseg_csv$RAD,paste0(dir, mashupdate, landseg,".RAD"), 
  #           row.names = FALSE, col.names = FALSE, sep = ",")
  
  write.table(lseg_csv$TMP, paste0("C:/Users/kylew/Documents/HARP/NLDAS/mashups/", mashupdate, landseg, ".TMP"), 
              row.names = FALSE, col.names = FALSE, sep = ",")
  #write.table(lseg_csv$TMP,paste0(dir, mashupdate, landseg,".TMP"), 
  #           row.names = FALSE, col.names = FALSE, sep = ",")
  
  write.table(lseg_csv$PET, paste0("C:/Users/kylew/Documents/HARP/NLDAS/mashups/", mashupdate, landseg, ".PET"), 
              row.names = FALSE, col.names = FALSE, sep = ",")
  #write.table(lseg_csv$PET,paste0(dir, mashupdate, landseg,".PET"), 
  #           row.names = FALSE, col.names = FALSE, sep = ",")
  
  write.table(lseg_csv$PRC, paste0("C:/Users/kylew/Documents/HARP/NLDAS/mashups/", mashupdate, landseg, ".PRC"), 
              row.names = FALSE, col.names = FALSE, sep = ",")
  #write.table(lseg_csv$PRC,paste0(dir, mashupdate, landseg,".PRC"), 
  #           row.names = FALSE, col.names = FALSE, sep = ",")
  
  write.table(lseg_csv$WND, paste0("C:/Users/kylew/Documents/HARP/NLDAS/mashups/", mashupdate, landseg, ".WND"), 
              row.names = FALSE, col.names = FALSE, sep = ",")
  #write.table(lseg_csv$WND,paste0(dir, mashupdate, landseg,".WND"), 
  #           row.names = FALSE, col.names = FALSE, sep = ",")
  
  write.table(lseg_csv$DPT, paste0("C:/Users/kylew/Documents/HARP/NLDAS/mashups/", mashupdate, landseg, ".DPT"), 
              row.names = FALSE, col.names = FALSE, sep = ",")
  #write.table(lseg_csv$DPT,paste0(dir, mashupdate, landseg,".DPT"), 
  #           row.names = FALSE, col.names = FALSE, sep = ",")
}

