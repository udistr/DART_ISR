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
set datea  = `echo $dateinit $ASSIM_INT_HOURS | ${DART_DIR}/models/wrf/work/advance_time`
set dateb  = `echo $datea $ASSIM_INT_HOURS | ${DART_DIR}/models/wrf/work/advance_time`

# get data and run ungrib.exe, metgrid.exe and real.exe
./gen_retro_icbc.csh ${dateinit} ${datea} ${paramfile}

# run ensemble of simulations for the next time step
./init_ensemble_var.csh ${dateinit} ${paramfile}

# generate first inflation - moved into init_ensemble_var.csh

# MADIS data come on daily basis. At the beginning, download it
# for the first day. If it is midnight, need to download the previous day.
set HH1 = `echo ${dateinit} | cut -c9-10`
if (${HH1} != "00") then
  set date0  = `echo $dateinit -24 | ${DART_DIR}/models/wrf/work/advance_time`
  ./get_madis.sh ${date0} $paramfile
endif

./get_obs.csh ${datea} ${paramfile}

# run it again for the next assimilation window
./gen_retro_icbc.csh ${datea} ${dateb} ${paramfile}

./driver.csh ${datea} ${datefnl} ${paramfile} 

#nohup ./driver.csh ${datea} ${datefnl} ${paramfile}  > run_all_log.out 2>&1 &
#nohup ./driver.csh ${datea} ${datefnl} ${paramfile} > & output.log &

