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
set DATE = $1

mkdir -p ${OUTPUT_DIR}/${DATE}

if (-e ${OUTPUT_DIR}/${DATE}/obs_seq.out) then
  echo "MADIS observation file for the current date exists, continue to filter"
else
  echo "MADIS observation file does not exist, getting data"

  set YY1 = `echo $DATE | cut -c1-4`
  set MM1 = `echo $DATE | cut -c5-6`
  set DD1 = `echo $DATE | cut -c7-8`
  set HH1 = `echo $DATE | cut -c9-10`

  if ( ${HH1} == "00" ) then
    bash get_madis.sh $DATE
  endif

  set DATE1_m2 = `date -d "${YY1}${MM1}${DD1} ${HH1} - 2 hours" "+%Y %-m %-d %-H"`
  set DATE1_p3 = `date -d "${YY1}${MM1}${DD1} ${HH1} + 3 hours" "+%Y %-m %-d %-H"`

  echo "Start converting MADIS data"
  ./convert_madis.csh ${DATE1_m2} ${DATE1_p3}

  source /shared/miniconda3/etc/profile.d/conda.csh
  conda activate xmitgcm
  # Get start and end times
  set START_TIME = `date -d "${YY1}${MM1}${DD1} ${HH1} - 2 hours" "+%s"`
  set END_TIME = `date -d "${YY1}${MM1}${DD1} ${HH1} + 3 hours" "+%s"`

  rm data_ims/*

  # Loop through each hour (3600 seconds)
  set current = $START_TIME
  while ($current <= $END_TIME)
      set YEAR = `date -d @$current "+%Y"`
      set MONTH = `date -d @$current "+%m"`
      set DAY = `date -d @$current "+%d"`
      set HOUR = `date -d @$current "+%H"`
      echo "get IMS data for $YEAR $MONTH $DAY $HOUR"
      ipython get_ims.py $YEAR $MONTH $DAY $HOUR
      
      # Move to next hour
      @ current += 3600
  end
  conda deactivate
  cat data_ims/ims* > obs_seq_ims.txt
  # A patch to overcome wrong date in first obs
  (head -1 obs_seq_ims.txt; cat obs_seq_ims.txt) > temp_file
  mv temp_file data_ims/obs_seq_ims.txt

  ${DART_DIR}/observations/obs_converters/text/work/text_to_obs

  ${DART_DIR}/models/wrf/work/obs_sequence_tool
  mv obs_seq.out ${OUTPUT_DIR}/${DATE}/

endif


