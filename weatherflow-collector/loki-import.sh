#!/bin/bash

##
## WeatherFlow Importer - loki-import-influxdb.sh
##

##
## Read Environmental Variables
##

backend_type=$WEATHERFLOW_COLLECTOR_BACKEND_TYPE
#collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE
debug=$WEATHERFLOW_COLLECTOR_DEBUG
device_id=$WEATHERFLOW_COLLECTOR_DEVICE_ID
elevation=$WEATHERFLOW_COLLECTOR_ELEVATION
forecast_interval=$WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
hub_sn=$WEATHERFLOW_COLLECTOR_HUB_SN
import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
latitude=$WEATHERFLOW_COLLECTOR_LATITUDE
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
longitude=$WEATHERFLOW_COLLECTOR_LONGITUDE
public_name=$WEATHERFLOW_COLLECTOR_PUBLIC_NAME
rest_interval=$WEATHERFLOW_COLLECTOR_REST_INTERVAL
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID
station_name=$WEATHERFLOW_COLLECTOR_STATION_NAME
threads=$WEATHERFLOW_COLLECTOR_THREADS
timezone=$WEATHERFLOW_COLLECTOR_TIMEZONE
token=$WEATHERFLOW_COLLECTOR_TOKEN

# export WEATHERFLOW_COLLECTOR_BACKEND_TYPE=influxdb WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=local-udp WEATHERFLOW_COLLECTOR_DEBUG="true" WEATHERFLOW_COLLECTOR_DEVICE_ID=122367 WEATHERFLOW_COLLECTOR_ELEVATION=193.5202331542969 WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=app02.tylephony.com WEATHERFLOW_COLLECTOR_HUB_SN=HB-00038302 WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=4L851Jtjet7AJoFoFYR3di5Zniew28 WEATHERFLOW_COLLECTOR_INFLUXDB_URL=http://influxdb01.tylephony.com:8086/write?db=weatherflow WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=influxdb WEATHERFLOW_COLLECTOR_LATITUDE=38.62049 WEATHERFLOW_COLLECTOR_LONGITUDE=-90.52121 WEATHERFLOW_COLLECTOR_PUBLIC_NAME="Savannah Crossing" WEATHERFLOW_COLLECTOR_STATION_ID=40907 WEATHERFLOW_COLLECTOR_STATION_NAME="Savannah Crossing" WEATHERFLOW_COLLECTOR_TIMEZONE=America/Chicago WEATHERFLOW_COLLECTOR_TOKEN=a22afea7-00cc-4918-909a-923dd339f41c WEATHERFLOW_COLLECTOR_IMPORT_DAYS=5 WEATHERFLOW_COLLECTOR_THREADS=4

debug="true"

##
## Curl Command
##

if [ "$debug" == "true" ]
then

curl=(  )

else

curl=( --silent --output /dev/null --show-error --fail )

fi

##
## Thread Details
##

if [ -z "$threads" ]

then

N=1

else

N=${threads}

fi

####

## Escape Names

## Spaces

public_name_escaped=$(echo "${public_name}" | sed 's/ /\\ /g')
station_name_escaped=$(echo "${station_name}" | sed 's/ /\\ /g')

## Commas

public_name_escaped=$(echo "${public_name_escaped}" | sed 's/,/\\,/g')
station_name_escaped=$(echo "${station_name_escaped}" | sed 's/,/\\,/g')

## Equal Signs

public_name_escaped=$(echo "${public_name_escaped}" | sed 's/=/\\=/g')
station_name_escaped=$(echo "${station_name_escaped}" | sed 's/=/\\=/g')

##
## ProgressBar - https://github.com/fearside/ProgressBar/
##

function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:                           
# 1.2.1.1 Progress : [########################################] 100%
printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}



hours=$(("$import_days" * 24))

for hours_loop in $(seq "$hours" -1 0) ; do

hours_start=$(date --date="${hours_loop} hours ago 00:00" +%s)

hours_end=$(("$hours_start" + 3599))

date_start=$(date -d @"${hours_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${hours_end} --rfc-3339=seconds | sed 's/ /T/')

echo "Hour Slices Remaining: $hours_loop"
#echo "hours_start: $hours_start"
#echo "hours_end: $hours_end"
echo "date_start: $date_start"
echo "date_end: $date_end"

##
## LOCAL-UDP
##

echo "LOCAL-UDP"

## Start Timer

import_start=$(date +%s%N)

##
## Start "threading"
##

logs=$(./logcli-linux-amd64 query --addr="http://log01.tylephony.com:3100" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="local-udp",station_name="'"${station_name}"'"}' | jq --slurp)

num_of_logs=$(echo "${logs}" | jq -r ". | length")

if [ "$debug" == "true" ]
then

echo "Number of logs: ${num_of_logs}"

fi

num_of_logs_minus_one=$((num_of_logs-1))

for log in $(seq 0 ${num_of_logs_minus_one})

do

(

echo "${logs}" | jq -r .["${log}"].line | WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED="false" WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=local-udp ./local-udp-influxdb.sh

    ProgressBar ${log} ${num_of_logs_minus_one}

) &

    # allow to execute up to $N jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $N ]]; then
        # now there are $N jobs already running, so wait here for any job
        # to be finished so there is a place to start next one.
        wait -n
    fi

done

wait

printf '\nFinished!\n'

#
# End "threading"
#

## End Timer

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

echo "import_duration:${import_duration}"

## Send Timer Metrics To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=local-udp,elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=import,station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} duration=${import_duration}"


##
## REMOTE-REST
##

echo "REMOTE-REST"

## Start Timer

import_start=$(date +%s%N)

##
## Start "threading"
##

debug="true"

##
## Thread Details
##

if [ -z "$threads" ]

then

N=1

else

N=${threads}

fi

N=${threads}

logs=$(./logcli-linux-amd64 query --addr="http://log01.tylephony.com:3100" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="remote-rest",station_name="'"${station_name}"'"}' | jq --slurp)

num_of_logs=$(echo "${logs}" | jq -r ". | length")

if [ "$debug" == "true" ]
then

echo "Number of logs: ${num_of_logs}"

fi

num_of_logs_minus_one=$((num_of_logs-1))

for log in $(seq 0 $num_of_logs_minus_one) ; do

(

echo "${logs}" | jq -r .["${log}"].line | WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED="false" WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-rest ./remote-rest-influxdb.sh

    ProgressBar ${log} ${num_of_logs_minus_one}

) &

    # allow to execute up to $N jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $N ]]; then
        # now there are $N jobs already running, so wait here for any job
        # to be finished so there is a place to start next one.
        wait -n
    fi

done

wait

printf '\nFinished!\n'

#
# End "threading"
#

## End Timer

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

echo "import_duration:${import_duration}"

## Send Timer Metrics To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=remote-rest,elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=import,station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} duration=${import_duration}"

##
## REMOTE-SOCKET
##

echo "REMOTE-SOCKET"

## Start Timer

import_start=$(date +%s%N)

##
## Start "threading"
##

debug="true"

##
## Thread Details
##

if [ -z "$threads" ]

then

N=1

else

N=${threads}

fi

N=${threads}

logs=$(./logcli-linux-amd64 query --addr="http://log01.tylephony.com:3100" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="remote-socket",station_name="'"${station_name}"'"}' | jq --slurp)

num_of_logs=$(echo "${logs}" | jq -r ". | length")

if [ "$debug" == "true" ]
then

echo "Number of logs: ${num_of_logs}"

fi

num_of_logs_minus_one=$((num_of_logs-1))

for log in $(seq 0 $num_of_logs_minus_one) ; do

(

echo "${logs}" | jq -r .["${log}"].line | WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED="false" WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-socket ./remote-socket-influxdb.sh

    ProgressBar ${log} ${num_of_logs_minus_one}

) &

    # allow to execute up to $N jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $N ]]; then
        # now there are $N jobs already running, so wait here for any job
        # to be finished so there is a place to start next one.
        wait -n
    fi

done

wait

printf '\nFinished!\n'

#
# End "threading"
#

## End Timer

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

echo "import_duration:${import_duration}"

## Send Timer Metrics To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=remote-socket,elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=import,station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} duration=${import_duration}"


done
