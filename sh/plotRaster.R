#Call spatial libraries
library(raster)
library(sf)

#Load in hydrotools and connect to REST
library(hydrotools)
basepath='/var/www/R'
source('/var/www/R/config.R')


argst <- commandArgs(trailingOnly = T)
#Path to a raster
raster_path <- argst[1]
#Output filepath of plot
path_to_write <- argst[2]
#Should plot extent be limited to Commonwealth of Virginia?
plot_limit <- argst[3]

#Set plot limits if user requests only Virginia
if(as.logical(plot_limit)){
  xLimit <- c(-84,-77)
  yLimit <- c(36,40.5)
}

#Read in the target raster and project to 4326
rasterIn <- raster(raster_path)
crs(rasterIn) <-  crs(rasterIn,4326)

#Plot to requested path
png(path_to_write,
    width = 6, height = 4, 
    units = "in", res = 300)
#Limit plot extent per user request
if(as.logical(plot_limit)){
  plot(aTest, axes = TRUE,
       ylim = c(36,40.5),
       xlim = c(-84,-77)) 
}else{
  plot(aTest, axes = TRUE) 
}
dev.off()