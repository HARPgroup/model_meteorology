#!/bin/csh

  if (${#argv} != 2) then
    echo 'Missing Inputs: (1) PARAMS file name (2) Segment'
    exit
  endif

  source ../../fragments/set_tree

  #source PARAMS.DAT
  source $argv[1]

  set SEG = $argv[2]

  set TMPFOLDER = `uuidgen`
  mkdir -p ../../../tmp/$USER-scratch/$TMPFOLDER/
  cd       ../../../tmp/$USER-scratch/$TMPFOLDER/

  if (-e problem) then
    rm problem
  endif

  cp $tree/config/blank_wdm/message.wdm ./

#  cp $tree/config/blank_wdm/blank_prad.wdm prad_${SEG}.wdm
#  cp $tree/config/blank_wdm/blank_met.wdm  met_${SEG}.wdm
  
  cp $tree/input/scenario/climate/prad/$INP_PRAD/prad_${SEG}.wdm prad_${SEG}.wdm
  cp $tree/input/scenario/climate/met/$INP_MET/met_${SEG}.wdm    met_${SEG}.wdm

#  set SEGx = A`echo $SEG | awk '{print substr($0,2,5)}'`
#  cp $tree/input/scenario/climate/prad/$INP_PRAD/prad_${SEGx}.wdm prad_${SEG}.wdm
#  cp $tree/input/scenario/climate/met/$INP_MET/met_${SEGx}.wdm    met_${SEG}.wdm

  echo $SEG, $DATASRC, $VERSION, $PERIOD, $SYEAR, $EYEAR, $HPRC, $HTMP, $HPET, $HRAD, $HWND, $DDPT, $DCLC | $CODE

  if (-e problem) then
    echo "PROBLEM:"
    cat problem
    exit
  endif

  mv prad_${SEG}.wdm $tree/input/scenario/climate/prad/$OUT_PRAD/
  mv met_${SEG}.wdm  $tree/input/scenario/climate/met/$OUT_MET/

  cd ../
  rm -r $TMPFOLDER
