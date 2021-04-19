#!/bin/bash

##
## WeatherFlow Collector - Container Heath Check
##

## HEALTHCHECK --interval=60s --timeout=3s CMD /weatherflow-collector/health_check.sh

health_check_file="/weatherflow-collector/health_check.txt"

if [ $(stat --format=%Y $health_check_file) -le $(( $(date +%s) - 60 )) ]; then 
    echo "Check is more than 60 seconds old"
    exit 1

else
    echo "Check is less than 60 seconds old"
    exit 0
fi






