#!/bin/csh

set SYEAR = $argv[1]
set EYEAR = $argv[2]

set IYEAR = $SYEAR

while ( $IYEAR <= $EYEAR )
   csh _untar.csh $IYEAR & 
   @ IYEAR = $IYEAR + 1
end
