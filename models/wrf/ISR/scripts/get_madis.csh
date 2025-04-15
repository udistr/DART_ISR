#!/bin/csh

set DATE = $1

set paramfile = `readlink -f ${2}` # Get absolute path for param.csh from command line arg

source $paramfile

set YY1 = `echo $DATE | cut -c1-4`
set MM1 = `echo $DATE | cut -c5-6`
set DD1 = `echo $DATE | cut -c7-8`
set HH1 = `echo $DATE | cut -c9-10`

set D1 = "${YY1}-${MM1}-${DD1}_${HH1}"
set DATE1 = "${YY1}${MM1}${DD1}"

# simulate date -d for D0 calculation
set D0 = `date -d "${DATE1} ${HH1} - 6 hours" "+%Y-%m-%d_%H"`

if ("$HH1" == "00") then
    set FILE = "${MADIS_DATA}/point/acars/netcdf/${DATE1}_0000"
    if (! -e "$FILE") then
        echo "get MADIS observations once per day"
        cd $MADIS_DATA

        set DATE1_plus_1day = `date -d "${YY1}${MM1}${DD1} ${HH1} + 23 hours" "+%Y%m%d %H"`

        # change date in parameter files using sed
        sed -i "/Start/s/[0-9]\{8\} [0-9]\{2\}/${YY1}${MM1}${DD1} ${HH1}/; /End/s/[0-9]\{8\} [0-9]\{2\}/${DATE1_plus_1day}/" ftp.par1.txt
        sed -i "/Start/s/[0-9]\{8\} [0-9]\{2\}/${YY1}${MM1}${DD1} ${HH1}/; /End/s/[0-9]\{8\} [0-9]\{2\}/${DATE1_plus_1day}/" api.par1.txt

        # run Perl script
        ./get_MADIS_Data_unix.pl >& get_madis_${D1}.txt
        set RC = $status
        if ($RC != 0) then
            echo "Command failed with exit code $RC. Exiting."
            exit 1
        endif
    endif
endif
