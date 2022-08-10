args = commandArgs(trailingOnly=TRUE)

landseg <- args[1]

grids <- system2(command = "/backup/meteorology/nldas_land_grids", args = c(landseg))

paste(grids)
