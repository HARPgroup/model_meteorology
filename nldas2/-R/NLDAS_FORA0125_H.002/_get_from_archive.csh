#!/bin/csh

set SYEAR = $argv[1]
set EYEAR = $argv[2]

set IYEAR = $SYEAR

while ( $IYEAR <= $EYEAR )
   echo $IYEAR
   cp -vip /archive/modeling/NLDAS2/-R/NLDAS_FORA0125_H.002/${IYEAR}.tar ./
   @ IYEAR = $IYEAR + 1
end
