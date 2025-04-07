#!/bin/csh -f

source /shared/miniconda3/etc/profile.d/conda.csh
# Activate conda environment
conda activate xmitgcm

set paramfile = ${5}

# Source parameters
source ${paramfile}

# Set directories
set CODEDIR = `pwd`
set DATADIR = `pwd`

# Get command line arguments
set DATE1 = $1
set HOUR1 = $2
set DATE2 = $3
set HOUR2 = $4

# Create and navigate to data directory
set DATADIR = ${DATE1}${HOUR1}
mkdir -p ${DATADIR}
cd $DATADIR

# Set geographical boundaries
set Nort = 55
set West = -15
set Sout = 15
set East = 55

# Calculate date ranges
set d = `date -u -d "${DATE1}T${HOUR1} +7 hour" "+%Y%m%dT%H"`
set enddate = `date -u -d "${DATE2}T${HOUR2} +6 hour + 1 hour" "+%Y%m%dT%H"`

echo $d
echo $enddate

echo "entering loop"

# Archive folder
set OLDDATA = "/shared/WRF4.4/WRFDATA/old_data"

# Main loop
while (1)
    # Extract date components
    set DATE1 = `echo $d | cut -c1-8`
    set HOUR1 = `echo $d | cut -c10-11`
    
    # Check if we need to exit the loop
    if (`expr "$d" \> "$enddate"` == 1) then
        break
    endif
    
    echo "get data for $DATE1 $HOUR1"
    
    # Process surface level file
    set FILE = "ERA5-${DATE1}${HOUR1}-sl.grib"
    if (! -e "$FILE") then
        if (-e "${OLDDATA}/$FILE") then
            echo "$FILE file exists in the archive"
            cp ${OLDDATA}/${FILE} .
        else
            echo "$FILE does not exist. Downloading file"
            sed -e "s/DATE1/${DATE1}/g;s/HOUR1/${HOUR1}/g;s/Nort/${Nort}/g;s/West/${West}/g;s/Sout/${Sout}/g;s/East/${East}/g;" GetERA5-sl_snap.py > GetERA5-${DATE1}${HOUR1}-sl.py
            python GetERA5-${DATE1}${HOUR1}-sl.py
            rm GetERA5-${DATE1}${HOUR1}-sl.py
        endif
    else
        echo "$FILE file exists"
    endif
    
    # Process pressure level file
    set FILE = "ERA5-${DATE1}${HOUR1}-pl.grib"
    if (! -e "$FILE") then
        if (-e "${OLDDATA}/$FILE") then
            echo "$FILE file exists in the archive"
            cp ${OLDDATA}/${FILE} .
        else
            echo "$FILE does not exist. Downloading file"
            sed -e "s/DATE1/${DATE1}/g;s/HOUR1/${HOUR1}/g;s/Nort/${Nort}/g;s/West/${West}/g;s/Sout/${Sout}/g;s/East/${East}/g;" GetERA5-pl_snap.py > GetERA5-${DATE1}${HOUR1}-pl.py
            python GetERA5-${DATE1}${HOUR1}-pl.py
            rm GetERA5-${DATE1}${HOUR1}-pl.py
        endif
    else
        echo "$FILE file exists"
    endif
    
    # Increment date
    set d = `date -u -d "${d} +7 hour + 1 hour" "+%Y%m%dT%H"`
    #set d = `date -u -d "${d} +7 hour + ${ASSIM_INT_HOURS} hour" "+%Y%m%dT%H"`
end

exit 0