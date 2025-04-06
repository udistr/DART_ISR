#!/bin/csh
#
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download

# init_ensemble_var.csh - script that creates perturbed initial
#                         conditions from the WRF-VAR system.
#                         (perts are drawn from the perturbation bank)
#
# created Nov. 2007, Ryan Torn NCAR/MMM
# modified by G. Romine 2011-2018

set initial_date = ${1}
set paramfile = `readlink -f ${2}` # Get absolute path for param.csh from command line arg
source $paramfile

cd ${RUN_DIR}
cp ${SHELL_SCRIPTS_DIR}/advance_time .


# KRF Generate the i/o lists in rundir automatically when initializing the ensemble
set num_ens = ${NUM_ENS}
set input_file_name  = "input_list_d01.txt"
set input_file_path  = "./advance_temp"
set output_file_name = "output_list_d01.txt"

set n = 1

if ( -e $input_file_name )  rm $input_file_name
if ( -e $output_file_name ) rm $output_file_name

while ($n <= $num_ens)

   set     ensstring = `printf %04d $n`
   set  in_file_name = ${input_file_path}${n}"/wrfinput_d01"
   set out_file_name = "filter_restart_d01."$ensstring

   echo $in_file_name  >> $input_file_name
   echo $out_file_name >> $output_file_name

   @ n++
end
###

set gdate  = (`echo $initial_date 0h -g | ${DART_DIR}/models/wrf/work/advance_time`)
set gdatef = (`echo $initial_date ${ASSIM_INT_HOURS}h -g | ${DART_DIR}/models/wrf/work/advance_time`)
set wdate  =  `echo $initial_date 0h -w | ${DART_DIR}/models/wrf/work/advance_time`
set yyyy   = `echo $initial_date | cut -b1-4`
set mm     = `echo $initial_date | cut -b5-6`
set dd     = `echo $initial_date | cut -b7-8`
set hh     = `echo $initial_date | cut -b9-10`

${COPY} ${TEMPLATE_DIR}/namelist.input.meso namelist.input
${REMOVE} ${RUN_DIR}/WRF
${LINK} ${OUTPUT_DIR}/${initial_date} WRF
set job_ids = ()
set n = 1
while ( $n <= $NUM_ENS )

   echo "  QUEUEING ENSEMBLE MEMBER $n at `date`"

   mkdir -p ${RUN_DIR}/advance_temp${n}

   ${LINK} ${RUN_DIR}/WRF_RUN/* ${RUN_DIR}/advance_temp${n}/.
   ${LINK} ${RUN_DIR}/input.nml ${RUN_DIR}/advance_temp${n}/input.nml

   ${COPY} ${OUTPUT_DIR}/${initial_date}/wrfinput_d01_${gdate[1]}_${gdate[2]}_mean \
           ${RUN_DIR}/advance_temp${n}/wrfvar_output
   #sleep 3
   ${COPY} ${RUN_DIR}/add_bank_perts.py ${RUN_DIR}/advance_temp${n}/.

   set cmd3 = "/shared/miniconda3/envs/xmitgcm/bin/python ${RUN_DIR}/advance_temp${n}/add_bank_perts.py ${n} '${PERTS_DIR}'"
   ${REMOVE} ${RUN_DIR}/advance_temp${n}/nclrun3.out
          cat >!    ${RUN_DIR}/advance_temp${n}/nclrun3.out << EOF
          conda activate xmitgcm
          $cmd3
EOF
   echo $cmd3 >! ${RUN_DIR}/advance_temp${n}/nclrun3.out.tim   # TJH replace cat above

   @ cpus_per_task = ${FILTER_PROCS} / ${FILTER_MPI}

   cat >! ${RUN_DIR}/rt_assim_init_${n}.csh << EOF
#!/bin/csh
#=================================================================
#SBATCH --partition=compute
#SBATCH --get-user-env
#SBATCH --export=ALL
#SBATCH -J first_advance_${n}
#SBATCH --output=wrf.init."%j".out
#SBATCH --error=wrf.init."%j".err
#SBATCH --nodes=${FILTER_NODES}
#SBATCH --ntasks-per-node=${FILTER_MPI}
#SBATCH --cpus-per-task=${cpus_per_task}
#=================================================================

   echo "rt_assim_init_${n}.csh is running in `pwd`"
   cd ${RUN_DIR}/advance_temp${n}
   if (-e wrfvar_output) then
      echo "Running nclrun3.out to create wrfinput_d01 for member $n at `date`"

      chmod +x nclrun3.out
      ./nclrun3.out >& add_perts.out

      if ( -z add_perts.err ) then
         echo "Perts added to member ${n}"
      else
         echo "ERROR! Non-zero status returned from add_bank_perts.ncl. Check ${RUN_DIR}/advance_temp${n}/add_perts.err."
         cat add_perts.err
         exit
      endif

      ${MOVE} wrfvar_output wrfinput_d01
   endif

   cd $RUN_DIR

   echo "Running first_advance.csh for member $n at `date`"
   ${SHELL_SCRIPTS_DIR}/first_advance.csh $initial_date $n $paramfile

EOF

   set id = `sbatch --parsable ${RUN_DIR}/rt_assim_init_${n}.csh`
   set job_ids = ($job_ids $id)
   @ n++

end

# Wait for all jobs to complete using squeue
while (1)
    set still_running = 0
    
    foreach id ($job_ids)
        # Check if the job is still in the queue
        set job_exists = `squeue -j $id -h | wc -l`
        if ($job_exists > 0) then
            set still_running = 1
            #echo "Job $id is still running..."
        endif
    end
    
    if ($still_running == 0) then
        echo "All jobs have completed!"
        break
    endif
    
    echo "Waiting for jobs to complete... sleeping for 30 seconds"
    sleep 30
end

mv wrf.init.* ${OUTPUT_DIR}/${initial_date}/logs/

cd $BASE_DIR/rundir

set gdate = (`echo $initial_date 0 -g | ${DART_DIR}/models/wrf/work/advance_time`)

cp ../output/${initial_date}/wrfinput_d01_${gdate[1]}_${gdate[2]}_mean ./wrfinput_d01
/shared/miniconda3/envs/gcc_env/bin/ncatted -a TRUELAT1,global,m,f,0.0 wrfinput_d01
./fill_inflation_restart
mkdir -p ${OUTPUT_DIR}/${initial_date}/Inflation_input
mv input_priorinf_*.nc ${OUTPUT_DIR}/${initial_date}/Inflation_input/

exit 0

