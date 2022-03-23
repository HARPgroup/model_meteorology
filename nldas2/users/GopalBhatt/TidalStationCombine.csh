#!/bin/csh

set SYEAR = 1980
set EYEAR = 2019

set OUTFOLDER = OUTPUT_20200417

set NGRID  = 7
set IGRID  = 1
set GRIDS = ( 390 112 389 109 391 106 391 101 391 98 392 98 392 96 )

set VARS = ( PP RH RN TT VP WD )

while ( $IGRID <= $NGRID )
   @ iX = ($IGRID - 1) * 2 + 1
   @ iY = ($IGRID - 1) * 2 + 2
   #echo "$iX $iY"
   set X = $GRIDS[$iX]
   set Y = $GRIDS[$iY]
   echo "$X $Y"
   foreach VAR ( $VARS )
      if ( -e $OUTFOLDER/COM_x${X}y${Y}z${VAR}.txt ) rm -v $OUTFOLDER/COM_x${X}y${Y}z${VAR}.txt
      set IYEAR = $SYEAR
      while ( $IYEAR <= $EYEAR )
         cat $OUTFOLDER/${IYEAR}/x${X}y${Y}z${VAR}.txt >> $OUTFOLDER/COM_x${X}y${Y}z${VAR}.txt
         @ IYEAR = $IYEAR + 1
      end
   end
   @ IGRID = $IGRID + 1
end
