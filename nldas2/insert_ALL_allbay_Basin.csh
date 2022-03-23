#!/bin/csh

  if ($argv[1] != 'GO') then
    if ($argv[1] != 'go') then
      echo ' '
      echo ' running this script creates new prad ywdms.  It may replace wdms'
      echo '  already in use. Check the script to make sure that the variables are correctly'
      echo '  set before continuing'
      echo ' '
      echo ' To make this script run, type: create_prad_wdms.csh GO'
      echo ' '
      exit
    endif
  endif

  source ../../fragments/set_tree

  #source PARAMS.DAT
  source $argv[2]

  mkdir -p $tree/input/scenario/climate/prad/$OUT_PRAD/
  mkdir -p $tree/input/scenario/climate/met/$OUT_MET/

  source $tree/config/seglists/${BASIN}.land

  if (-e problem) then
    rm problem
  endif

  foreach SEG ($segments)
     if ( $EXE == "PARALLEL" ) then
        srun --nodes=1 --ntasks=1 --exclusive --job-name=$SEG insert_ALL_allbay_OneSeg.csh $argv[2] $SEG &
     else
        csh insert_ALL_allbay_OneSeg.csh $argv[2] $SEG
     endif
  end

  wait


######### self-documentation
  set AUTONOTE_PRAD =  $tree/input/scenario/climate/prad/$OUT_PRAD/_AUTONOTE_PRAD
  if (-e $AUTONOTE_PRAD) then
    rm $AUTONOTE_PRAD
  endif
  echo "This dataset $OUT_PRAD was created by $USER on `date` " > $AUTONOTE_PRAD
  echo "ASCII data source: input/unformatted/$DATASRC/$VERSION/$PERIOD" >> $AUTONOTE_PRAD
  echo "Base WDM source: $tree/input/scenario/climate/prad/$INP_PRAD/" >> $AUTONOTE_PRAD
  echo "Using the code: $CODE" >> $AUTONOTE_PRAD

  set AUTONOTE_MET =  $tree/input/scenario/climate/met/$OUT_MET/_AUTONOTE_MET
  if (-e $AUTONOTE_MET) then
    rm $AUTONOTE_MET
  endif
  echo "This dataset $OUT_MET was created by $USER on `date` " > $AUTONOTE_MET
  echo "ASCII data source: input/unformatted/$DATASRC/$VERSION/$PERIOD" >> $AUTONOTE_MET
  echo "Base WDM source: $tree/input/scenario/climate/prad/$INP_MET/" >> $AUTONOTE_MET
  echo "Using the code: $CODE" >> $AUTONOTE_MET

