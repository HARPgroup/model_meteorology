############################################################################
# EXTRACT NLDAS 2 CLIMATE DATA
# Version 1.0.1
# GDAL Version: 1.8 Complete (http://www.kyngchaos.com/software:frameworks) 
# Download: http://trac.osgeo.org/gdal/wiki/DownloadingGdalBinaries
# module load gdal-1.11.0/gcc-4.4.7
# Developer: GOPAL BHATT (gopal.bhatt@psu.edu)
# Contact: Prof. CHRIS DUFFY (cxd11@psu.edu)
############################################################################

SHELL = /bin/sh

srcdir	= .
builddir	= .
top_builddir = build
prefix = .

SRC	= .
# THIS IS WHERE YOU CHANGE THE GDAL INSTALL DIRECTORY
GDAL	= /Library/Frameworks/GDAL.framework
# default linux
#GDAL_INC	= -I/usr/local/include/
#GDAL_LIB	= -L/usr/local/lib/
# Ubtuntu 20.04 - uncomment
GDAL_INC	= -I/usr/include/gdal/
GDAL_LIB	= -L/usr/lib/
#GDAL_INC        = -I/home/bgb/tools/gdal-1.10.1/include
#GDAL_LIB        = -L/home/bgb/tools/gdal-1.10.1/lib

CPP	= /usr/bin/c++
CFLAGS	= -c
DEBUG	= -g
LIBS	= -lgdal -lm

OBJS	= pickGridVal.o NLDAS2_GRIB_to_ASCII.o

all: NLDAS2_GRIB_to_ASCII

NLDAS2_GRIB_to_ASCII: $(OBJS)
	$(CPP) $(OBJS) -o NLDAS2_GRIB_to_ASCII $(GDAL_LIB) $(LIBS)
	@ echo

NLDAS2_ASCII_to_LSegs: NLDAS2_ASCII_to_LSegs.o
	$(CPP) NLDAS2_ASCII_to_LSegs.o -o NLDAS2_ASCII_to_LSegs $(GDAL_LIB) $(LIBS)
	@ echo

LongTermAvgRNMax: LongTermAvgRNMax.o
	$(CPP) LongTermAvgRNMax.o -o LongTermAvgRNMax $(GDAL_LIB) $(LIBS)
	@ echo


#pickGridVal.o: pickGridVal.h pickGridVal.cpp
#	$(CPP) $(CFLAGS) $(DEBUG) $(GDAL_INC) pickGridVal.cpp\

NLDAS2_GRIB_to_ASCII.o: pickGridVal.h NLDAS2_GRIB_to_ASCII.cpp
	$(CPP) $(CFLAGS) $(DEBUG) $(GDAL_INC) NLDAS2_GRIB_to_ASCII.cpp\

pickGridVal.o: pickGridVal.h pickGridVal.cpp
	$(CPP) $(CFLAGS) $(DEBUG) $(GDAL_INC) pickGridVal.cpp\

clean:
	rm -rf *.o NLDAS2_GRIB_to_ASCII NLDAS2_GRIB_to_ASCII.tar

tar:
	tar cfv NLDAS2_GRIB_to_ASCII.cpp.tar\
		pickGridVal.h pickGridVal.cpp NLDAS2_GRIB_to_ASCII.cpp Makefile InputFormat.txt TestInput.txt README
