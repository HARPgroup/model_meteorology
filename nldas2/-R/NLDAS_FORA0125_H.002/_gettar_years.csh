#!/bin/csh

set SYEAR = $argv[1]
set EYEAR = $argv[2]

set IYEAR = $SYEAR

while ( $IYEAR <= $EYEAR ) 
   aws s3 cp s3://modeling-data.chesapeakebay.net/nldas/${IYEAR}.tar ./ &
   @ IYEAR = $IYEAR + 1
end
wait
