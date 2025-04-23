#!/bin/csh
#     
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
      
#   driver.csh - script that is the driver for the
#                            CONUS analysis system
#                            MODIFIED for new DART direct
#                            file access
#     
#      provide an input argument of the first
#      analysis time in yyyymmddhh format.
#                           
#   Created May 2009, Ryan Torn, U. Albany
#   Modified by G. Romine to run realtime cases 2011-18
#
########################################################################
#   run as: nohup csh driver.csh 2017042706 param.csh >& run.log &
########################################################################
# Set the correct values here
set paramfile = `readlink -f ${2}` # Get absolute path for param.csh from command line arg
########################################################################
# Likely do not need to change anything below
########################################################################
      
source $paramfile
         
cd ${OBSPROC_DIR}
mkdir -p data_ims
mkdir -p data_madis
mkdir -p ${OUTPUT_DIR}/OBS

cp ${SHELL_SCRIPTS_DIR}/get_madis.csh .
cp ${SHELL_SCRIPTS_DIR}/convert_madis.csh .
cp ${SHELL_SCRIPTS_DIR}/madis_conv.csh .
cp ${TEMPLATE_DIR}/input.nml.template input.nml
set DATE = $1

mkdir -p ${OUTPUT_DIR}/${DATE}

if (-e ${OUTPUT_DIR}/OBS/obs_seq.out_${DATE}) then
  echo "obs_seq.out file for the current date exists, continue to filter"
  cp ${OUTPUT_DIR}/OBS/obs_seq.out_${DATE} ${OUTPUT_DIR}/${DATE}/obs_seq.out
else
  echo "obs_seq.out file does not exist, getting data"

  ########################################################################
  # MADIS data
  ########################################################################

  set YY1 = `echo $DATE | cut -c1-4`
  set MM1 = `echo $DATE | cut -c5-6`
  set DD1 = `echo $DATE | cut -c7-8`
  set HH1 = `echo $DATE | cut -c9-10`

  if ( ${HH1} == "00" ) then
    set DATE0  = `echo $DATE -24 | ${DART_DIR}/models/wrf/work/advance_time`
    echo "checks if ${DATE0} files are available"
    ./get_madis.csh $DATE0 $paramfile
    echo "checks if ${DATE} files are available"
    ./get_madis.csh $DATE $paramfile
  endif

  if ( ${ASSIM_INT_HOURS} == 6 ) then
    #6 hours
    set DATE1_m2 = `date -d "${YY1}${MM1}${DD1} ${HH1} - 2 hours" "+%Y %-m %-d %-H"`
    set DATE1_p3 = `date -d "${YY1}${MM1}${DD1} ${HH1} + 3 hours" "+%Y %-m %-d %-H"`
  else if ( ${ASSIM_INT_HOURS} == 1 ) then
    # 1 hour
    set DATE1_m2 = `date -d "${YY1}${MM1}${DD1} ${HH1}" "+%Y %-m %-d %-H"`
    set DATE1_p3 = `date -d "${YY1}${MM1}${DD1} ${HH1}" "+%Y %-m %-d %-H"`
  else
    echo "not yet implemented"
    echo "update get obs.csh for implementation"
  endif

  echo "Start converting MADIS data"
  ./convert_madis.csh ${DATE1_m2} ${DATE1_p3}

  ########################################################################
  # IMS data
  ########################################################################

  source /shared/miniconda3/etc/profile.d/conda.csh
  conda activate xmitgcm
  # Get start and end times
  if ( ${ASSIM_INT_HOURS} == "6" ) then
    #6 hours
    set START_TIME = `date -d "${YY1}${MM1}${DD1} ${HH1} - 2 hours" "+%s"`
    set END_TIME = `date -d "${YY1}${MM1}${DD1} ${HH1} + 3 hours" "+%s"`
  else if ( ${ASSIM_INT_HOURS} == "1" ) then
    # 1 hour
    set START_TIME = `date -d "${YY1}${MM1}${DD1} ${HH1}" "+%s"`
    set END_TIME = `date -d "${YY1}${MM1}${DD1} ${HH1}" "+%s"`
  else
    echo "not yet implemented"
    echo "update get obs.csh for implementation"
  endif

  rm data_ims/*

  # Loop through each hour (3600 seconds)
  set current = $START_TIME
  while ($current <= $END_TIME)
    set YEAR = `date -d @$current "+%Y"`
    set MONTH = `date -d @$current "+%m"`
    set DAY = `date -d @$current "+%d"`
    set HOUR = `date -d @$current "+%H"`
    if (-e ${IMS_DATA}/data/ims_${YEAR}${MONTH}${DAY}${HOUR}.txt) then
      echo "IMS data for $YEAR $MONTH $DAY $HOUR found in archive"
      cp ${IMS_DATA}/data/ims_${YEAR}${MONTH}${DAY}${HOUR}.txt data_ims
    else
      echo "get IMS data for $YEAR $MONTH $DAY $HOUR"
      ipython get_ims.py $YEAR $MONTH $DAY $HOUR
      cp data_ims/ims_$YEAR$MONTH$DAY$HOUR.txt ${IMS_DATA}
    endif
    # Move to next hour
    @ current += 3600
  end
  conda deactivate
  cat data_ims/ims* > obs_seq_ims.txt
  # A patch to overcome the wrong date in the first obs
  (head -1 obs_seq_ims.txt; cat obs_seq_ims.txt) > temp_file
  mv temp_file data_ims/obs_seq_ims.txt

  set max_tries = 20
  set tries = 0
  set finished = 0

  while ($tries < $max_tries && $finished == 0)
    ./text_to_obs > log.text_to_obs
    @ tries = ${tries} + 1
    
    set finished_count = `grep Finished log.text_to_obs | wc -l`
    if ($finished_count == 1) then
      set finished = 1
      echo "Success: Found 'Finished' in log file after $tries attempt(s)"
    else
      echo "Attempt ${tries}: 'Finished' not found yet"
      if ($tries < $max_tries) then
        echo "Trying again..."
      else
        echo "Maximum number of attempts (${max_tries}) reached without finding 'Finished'"
        exit 1
      endif
    endif
  end

  ########################################################################
  # run obs_sequence_tool to combine data
  ########################################################################

  ${DART_DIR}/models/wrf/work/obs_sequence_tool
  #save copy
  cp obs_seq.out ${OUTPUT_DIR}/OBS/obs_seq.out_${DATE}
  # move to output folder
  mv obs_seq.out ${OUTPUT_DIR}/${DATE}/

endif


