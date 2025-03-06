#!/bin/csh

# Script arguments:
# ${1} = start_year   (e.g. 2017)
# ${2} = start_month  (e.g. 04)
# ${3} = start_day    (e.g. 27)
# ${4} = start_hour   (e.g. 00)
# ${5} = end_year     (e.g. 2017)
# ${6} = end_month    (e.g. 04)
# ${7} = end_day      (e.g. 27)
# ${8} = end_hour     (e.g. 06)

# Example usage: ./convert_madis.csh 2017 04 27 00 2017 04 27 06

./madis_conv.csh acars ${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8}
./madis_conv.csh marine ${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8}
./madis_conv.csh mesonet ${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8}
./madis_conv.csh metar ${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8}
./madis_conv.csh profiler ${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8}
./madis_conv.csh rawin ${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8}
./madis_conv.csh satwnd ${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8}





