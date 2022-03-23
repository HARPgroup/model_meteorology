#!/bin/csh

set YEAR = $argv[1]

set I = 1

while ( $I <= 366 )
   set DDD = "`printf %03d $I`"
   if ( ! -e ./-R/NLDAS_FORA0125_H.002/${YEAR}/${DDD} ) then
      /modeling/tools/wget-1.18/bin/wget --load-cookies ~/.urs_cookies --auth-no-challenge=on --keep-session-cookies -np -r -NP -R "*.xml" -c -N -nH --cut-dirs=2 --content-disposition https://hydro1.gesdisc.eosdis.nasa.gov/data/NLDAS/NLDAS_FORA0125_H.002/${YEAR}/${DDD}/;
   endif
   @ I = $I + 1
end
