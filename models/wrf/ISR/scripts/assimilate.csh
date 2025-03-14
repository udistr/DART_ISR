#!/bin/csh
#
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download

# datea and paramfile are command-line arguments - OR -
# are set by a string editor (sed) command.

set datea     = ${1}
set paramfile = ${2}

source $paramfile

set start_time = `date +%s`
echo "host is " `hostname`

cd ${RUN_DIR}

# make sure that no observations outside the time range get inside
# conversion to minutes to allow windows smaller than hour
@ ass_min = (${ASSIM_INT_HOURS} * 60 + ${ASSIM_INT_MINUTES}) / 2

set s_asim = (`echo $datea -${ass_min}m -g | ${DART_DIR}/models/wrf/work/advance_time`)
set e_asim = (`echo $datea  ${ass_min}m -g | ${DART_DIR}/models/wrf/work/advance_time`)

sed -i "/first_obs_days/c\   first_obs_days          = ${s_asim[1]}," input.nml
sed -i "/first_obs_seconds/c\   first_obs_seconds       = ${s_asim[2]}," input.nml
sed -i "/last_obs_days/c\   last_obs_days           = ${e_asim[1]}," input.nml
sed -i "/last_obs_seconds/c\   last_obs_seconds        = ${e_asim[2]}," input.nml

echo $start_time >& ${RUN_DIR}/filter_started

# Make sure the previous results are not hanging around
if ( -e ${RUN_DIR}/obs_seq.final )  ${REMOVE} ${RUN_DIR}/obs_seq.final
if ( -e ${RUN_DIR}/filter_done   )  ${REMOVE} ${RUN_DIR}/filter_done

#  run data assimilation system
if ( $SUPER_PLATFORM == 'LSF queuing system' ) then

   setenv TARGET_CPU_LIST -1
   setenv FORT_BUFFERED true
   mpirun.lsf ./filter || exit 1

else if ( $SUPER_PLATFORM == 'derecho' ) then

   setenv MPI_SHEPHERD FALSE

   setenv TMPDIR  /dev/shm
   limit stacksize unlimited
   mpiexec -n 256 -ppn 128 ./filter || exit 1

else if ( $SUPER_PLATFORM == 'aws' ) then

   setenv MPI_SHEPHERD FALSE
   #ncatted -a TRUELAT1,global,m,f,0.0 wrfinput_d01

   setenv TMPDIR  /dev/shm
   limit stacksize unlimited
   @ total_cpus = ${FILTER_NODES} * ${FILTER_PROCS}
   mpiexec -n ${total_cpus} --map-by ppr:${total_cpus}:node ./filter || exit 1

endif

if ( -e ${RUN_DIR}/obs_seq.final )  touch ${RUN_DIR}/filter_done

set end_time = `date  +%s`
@ length_time = $end_time - $start_time
echo "duration = $length_time"

exit 0

