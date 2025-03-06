#!/bin/csh

set dateinit   = ${1}
set datefnl   = ${2}
set paramfile = `readlink -f ${3}` # Get absolute path for param.csh from command line arg

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
# cd $BASE_DIR/rundir
# cp ../output/${dateinit}/wrfinput_d01_152057_0_mean ./wrfinput_d01
# ./fill_inflation_restart
# mkdir ../output/${dateinit}/Inflation_input
# mv input_priorinf_*.nc ../output/${dateinit}/Inflation_input/

# MADIS data come on daily basis. At the beginning, download it
# for the first day. If it is midnight, it will be downloaded 
# in ./get_obs.csh

set HH1 = `echo ${dateinit} | cut -c9-10`
if (${HH1} != "00") then
  bash get_madis.sh ${dateinit}
endif

./get_obs.csh ${datea} ${paramfile}

# run it again for the next assimilation window
./gen_retro_icbc.csh ${datea} ${dateb} ${paramfile}

./driver.csh ${datea} ${datefnl} ${paramfile}
