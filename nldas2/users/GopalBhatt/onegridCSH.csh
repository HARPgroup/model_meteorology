#!/bin/csh

set SYEAR = $argv[1]
set EYEAR = $argv[2]

set XGRID = $argv[3]
set YGRID = $argv[4]

set OUTDIR = $argv[5]

set IYEAR = $SYEAR

while ( $IYEAR <= $EYEAR )
   mkdir -p $OUTDIR/$IYEAR
   echo $IYEAR
   csh process_grid_year.csh $IYEAR $XGRID $YGRID $OUTDIR &
   @ IYEAR = $IYEAR + 1
end

wait
