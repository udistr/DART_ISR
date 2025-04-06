#!/bin/bash
source /shared/miniconda3/etc/profile.d/conda.sh
conda activate xmitgcm
CODEDIR=`pwd` #/lus/grand/projects/MEDDIAC/WRF-4.1.3_INTEL/DATA_1M
DATADIR=`pwd` #/lus/grand/projects/MEDDIAC/WRF-4.1.3_INTEL/DATA_1M

# YYYYMMDD
DATE1=$1
HOUR1=$2
DATE2=$3
HOUR2=$4

DATADIR=${DATE1}${HOUR1}
mkdir -p ${DATADIR}

cd $DATADIR
cp ../get_era5_data.sh ../GetERA5-* ../Download_WRF_snap.sh .

Nort=55
West=-15
Sout=15
East=55

d=`date -u -d "${DATE1}T${HOUR1} +7 hour"  +'%Y%m%dT%H'`
enddate=`date -u -d "${DATE2}T${HOUR2} +7 hour + 1 hour"  +'%Y%m%dT%H'`
echo $d
echo $enddate

echo "entering loop"
#archive folder
OLDDATA="/shared/WRF4.4/WRFDATA/old_data"
while [[ "$d" < "$enddate" ]]; do

  DATE1=${d:0:8}
  HOUR1=${d:9:2}

  echo "get data for $DATE1 $HOUR1"
  FILE="ERA5-${DATE1}${HOUR1}-sl.grib"

  if [ ! -e "$FILE" ]; then
    if [ -e "${OLDDATA}/$FILE" ]; then
      echo "$FILE file exists in the archive"
      cp ${OLDDATA}/${FILE} .
    else
      echo "$FILE does not exist. Downloading file"
      sed -e "s/DATE1/${DATE1}/g;s/HOUR1/${HOUR1}/g;s/Nort/${Nort}/g;s/West/${West}/g;s/Sout/${Sout}/g;s/East/${East}/g;" GetERA5-sl_snap.py > GetERA5-${DATE1}${HOUR1}-sl.py
      python GetERA5-${DATE1}${HOUR1}-sl.py
      rm GetERA5-${DATE1}${HOUR1}-sl.py
    fi
  else
    echo "$FILE file exists"
  fi
  
  FILE="ERA5-${DATE1}${HOUR1}-pl.grib"

  if [ ! -e "$FILE" ]; then
    if [ -e "${OLDDATA}/$FILE" ]; then
      echo "$FILE file exists in the archive"
      cp ${OLDDATA}/${FILE} .
    else
      echo "$FILE does not exist. Downloading file"
      sed -e "s/DATE1/${DATE1}/g;s/HOUR1/${HOUR1}/g;s/Nort/${Nort}/g;s/West/${West}/g;s/Sout/${Sout}/g;s/East/${East}/g;" GetERA5-pl_snap.py > GetERA5-${DATE1}${HOUR1}-pl.py
      python GetERA5-${DATE1}${HOUR1}-pl.py
      rm GetERA5-${DATE1}${HOUR1}-pl.py
    fi
  else
    echo "$FILE file exists"
  fi

  d=`date -u -d "${d} +7 hour + 1 hour"  +'%Y%m%dT%H'`
  #d=`date -u -d "${d} +7 hour + 6 hour"  +'%Y%m%dT%H'`

done  
exit 0
