#!/bin/csh

set YEAR = $argv[1]
echo $YEAR
tar -xf ${YEAR}.tar
set failed = $status; if( $failed == 1 ) exit 1
rm ${YEAR}.tar
