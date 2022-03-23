#!/bin/csh

@ NJOBS = `qd -S | grep bgb | wc -l`
echo $NJOBS

@ NLINES = `cat list.txt | wc -l`
echo $NLINES
while ( $NLINES > 0 )
	if ( $NJOBS < 5 ) then
		set JOB = `head -1 list.txt`
		echo $JOB
		cp _jobs/$JOB .
		qsub $JOB

		sed '1d' list.txt > tmpfile; mv tmpfile list.txt

		#rm $JOB
	endif

	sleep 60
	@ NLINES = `cat list.txt | wc -l`

end
