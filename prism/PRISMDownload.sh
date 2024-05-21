#!/bin/bash

#Function to add the raster to the database
source addRasterToDBase2.sh
#Function to get PRISM download
source downloadDailyPRISM.sh

#The first user input should be the year at which to download all daily PRISM data
YYYY=$1

#The second input is the extent (a vector mask) by which the imported precip rasters should be clipped. This may be a file path to a WKT csv files, for instance.
maskExtent=$2

#Update the variable definition table. Only needs to be performed once to ensure PRISM data has a reference varkey and other data:
#--Update dh_variabledefinition to include a variable for prism data
#INSERT INTO dh_variabledefinition (varname,vardesc,vocabulary,varunits,varkey,datatype,varcode,isregular,timestep,timeunits,nodataval,status,options,varabbrev,multiplicity)
#VALUES ('PRISM Model Daily','PRISM raster import.','prism','mm/day','prism_mod_daily','cumulative','prism_mod_daily',1,86400,'seconds',-9999,1,'a:0:{}','PRISM','tstime_singular');
#psql -h dbase2 -f "insertVarDef.sql" -d drupal.alpha

echo "Creating config array for ${YYYY} downloads..."
#Develop an array of config variables that may change with new versions or structure in Hydro
declare -A config=(
   ["entity_type"]="dh_feature"
   ["ext"]="_CBP.gtiff"
   ["scratchdir"]="/tmp"
   ["datasource"]="PRISM"
   ["dataset"]="PRISM_precip_"
   ["varkey"]="prism_mod_daily"
   ["extent_hydrocode"]="cbp6_met_coverage"
   ["extent_ftype"]="cbp_met_grid"
   ["extent_bundle"]="landunit"
)

#Now, download a raster for each day of each month from the PRISM webpage
for MM in {1..12}
	do
	
	echo "Getting data for month ${MM}..."
	#Evaluate if $YYYY is a leap year e.g. either divisible by 4 or 400, but not 100 inherently. 
	#Below, we use the -d option to coerce date to get the maximum day available in each month of 
	#the input year. This is done in each step of the loop using the date coercion at the beginning 
	#e.g. the $y/$m/1 sets the date initially to the date $m/01/%y. From there, we addd a month and subtract a day.
	daysInMonth=`date -d "$YYYY/$MM/1 + 1 month - 1 day" "+%d"`
	
	for (( DD=1 ; DD<=$daysInMonth ; DD++ ))
		do
		finalTiff=${config["dataset"]}${YYYY}${MM}${DD}${config["ext"]}
		
		echo "Getting data for month ${YYYY}-${MM}-${DD}..."
		#Download the daily PRISM data for target day, reporject, and crop
		downloadDailyPRISM config $finalTiff $maskExtent $YYYY $MM $DD
		
		echo "Seding data for month ${YYYY}-${MM}-${DD} to database..."
		#Add raster to the timeseries table
		addRasterToDBase2 config $finalTiff "$YYYY-$MM-$DD 00" 86400
		
	done
done

