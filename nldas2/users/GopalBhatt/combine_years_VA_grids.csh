#!/bin/csh

set VARS = ( PP TT WD)

set GRIDS = ( 382 99 390 97 392 96 389 98 385 99 389 102 392 99 390 102 387 102 390 99 393 100 395 103 390 103 389 96 388 97 386 98 383 99 381 100 390 96 391 96 385 106 386 101 384 102 387 106 383 110 393 101 394 102 395 104 385 101 384 101 390 101 389 101 382 107 388 101 386 103 385 105 383 106 387 100 389 100 388 105 388 98 388 99  )

set NGRIDS = ${#GRIDS}

@ NGRIDS = $NGRIDS / 2

echo $NGRIDS

set IGRID = 1

while ( $IGRID <= $NGRIDS )
   @ X = ($IGRID - 1) * 2 + 1
   @ Y = $IGRID * 2
   #echo $X $Y
   set GX = $GRIDS[$X]
   set GY = $GRIDS[$Y]
   echo "... processing $GX $GY"
   foreach VAR ( $VARS )
      #ls -l  OUTPUT_20191220/*/x${GX}y${GY}z${VAR}.txt
      cat OUTPUT_20191220/*/x${GX}y${GY}z${VAR}.txt > combined_2003_2019_VA_grids/x${GX}y${GY}z${VAR}.txt
   end
   @ IGRID = $IGRID + 1
end
