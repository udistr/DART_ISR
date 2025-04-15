#!/bin/csh
if ( $#argv > 0 ) then
  set dateinit   = ${1} # starting date
  set datefnl   =  ${2} # target date   YYYYMMDDHH  # set this appropriately 
  set paramfile = `readlink -f ${3}` # Get absolute path for param.csh 
  setenv restore 1   # set the restore variable
else
  set dateinit  = 2020010800
  set datefnl   = 2020011000
  set paramfile = `readlink -f param.csh`
endif

source $paramfile
cd ${SHELL_SCRIPTS_DIR}
cp ${TEMPLATE_DIR}/input.nml.template input.nml

# Initialize datea to dateinit
set datea = $dateinit

# Loop until datea reaches or exceeds datefnl
while ( $datea <= $datefnl )
    echo "Processing date: $datea"
    ./get_obs.csh ${datea} ${paramfile}
    # Advance datea by ASSIM_INT_HOURS
    set datea = `echo $datea $ASSIM_INT_HOURS | ${DART_DIR}/models/wrf/work/advance_time`
end

echo "Processing completed from $dateinit to $datefnl"

#nohup ./run_get_obs.csh 2020010800 2020011000 `readlink -f param.csh` > & output.log &