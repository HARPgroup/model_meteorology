### f hamon hargraves function call 

# if needed. 
#install.packages('Evapotranspiration')
#install.pacakges('tidyr')

#path_to_function = '/bluefish/archive/modeling/g600/code/src/data_import/PETMod/et_hamon_hargraves_correction.R'
path_to_function = '/modeling/g600/code/src/data_import/PETMod/et_hamon_hargraves_correction.R'
source(path_to_function)

args <- commandArgs(trailingOnly = TRUE)
aland_seg<-args[1]
aelevation<-args[2]
alatitude<-args[3]

# set up the paths accordingly before running. 

et_hamon_hargraves_correction(
  land_seg=aland_seg,
  elevation=as.numeric(aelevation),
  latitude=as.numeric(alatitude),
  read_loc_base = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/N20150521J96',
  read_loc_aux = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/aux',
  #read_loc_s25 = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/NOAA_T30_HS/2021-2030',
  #save_loc     = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/NOAA_T30_HS/2021-2030'
  #read_loc_s25 = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP45_P90_HS/2046-2055',
  #save_loc     = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP45_P90_HS/2046-2055'
  #read_loc_s25 = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP45_P50/2036-2065',
  #save_loc     = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP45_P50/2036-2065'
  #read_loc_s25 = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP85_M06/2021-2030',
  #save_loc     = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP85_M06/2021-2030'
  #read_loc_s25 = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP45_P90/2051-2060',
  #save_loc     = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP45_P90/2051-2060'
  #read_loc_s25 = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP45_P10/2051-2060',
  #save_loc     = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP45_P10/2051-2060'
  #read_loc_s25 = './../../../../input/unformatted/CMIP5_Y2050_KKZ/RCP85_P50/MFY2050_MACA_KXX',
  #save_loc     = './../../../../input/unformatted/CMIP5_Y2050_KKZ/RCP85_P50/MFY2050_MACA_KXX'
  #read_loc_s25 = './../../../../input/unformatted/CMIP5_Y2050_KKZ/RCP85_M30/MFY2050_MACA_K11',
  #save_loc     = './../../../../input/unformatted/CMIP5_Y2050_KKZ/RCP85_M30/MFY2050_MACA_K11'
  #read_loc_s25 = './../../../../input/unformatted/CMIP5_Y2050_KKZ/RCP85_M26/MFY2050_MACA_K20',
  #save_loc     = './../../../../input/unformatted/CMIP5_Y2050_KKZ/RCP85_M26/MFY2050_MACA_K20'
  #read_loc_s25 = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP45_P50/2081-2090',
  #save_loc     = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP45_P50/2081-2090'
  read_loc_s25 = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP85_P50/2051-2060',
  save_loc     = './../../../../input/unformatted/CMIP5_BCSD_ENSEMBLE/RCP85_P50/2051-2060'
 )
