#!/bin/bash

##
## WeatherFlow Collector - startup.sh
##

##
## Read Environmental Variables
##

backend_type=$WEATHERFLOW_COLLECTOR_BACKEND_TYPE
collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE
debug=$WEATHERFLOW_COLLECTOR_DEBUG
device_id=$WEATHERFLOW_COLLECTOR_DEVICE_ID
elevation=$WEATHERFLOW_COLLECTOR_ELEVATION
forecast_interval=$WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL
function=$WEATHERFLOW_COLLECTOR_FUNCTION
healthcheck=$WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
hub_sn=$WEATHERFLOW_COLLECTOR_HUB_SN
import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
latitude=$WEATHERFLOW_COLLECTOR_LATITUDE
logcli_host_url=$WEATHERFLOW_COLLECTOR_LOGCLI_URL
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
longitude=$WEATHERFLOW_COLLECTOR_LONGITUDE
public_name=$WEATHERFLOW_COLLECTOR_PUBLIC_NAME
rest_interval=$WEATHERFLOW_COLLECTOR_REST_INTERVAL
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID
station_name=$WEATHERFLOW_COLLECTOR_STATION_NAME
threads=$WEATHERFLOW_COLLECTOR_THREADS
timezone=$WEATHERFLOW_COLLECTOR_TIMEZONE
token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Check for required intervals
##

if [ -z "${forecast_interval}" ] && [ "$collector_type" == "remote-forecast" ]
  then
    echo "WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL environmental variable not set. Defaulting to 60 seconds"

forecast_interval="60"

fi

if [ -z "${rest_interval}" ] && [ "$collector_type" == "remote-rest" ]
  then
    echo "WEATHERFLOW_COLLECTOR_REST_INTERVAL environmental variable not set. Defaulting to 60 seconds"

rest_interval="60"

fi

if [ -z "${import_days}" ] && [ "$collector_type" == "remote-import" ]
  then
    echo "WEATHERFLOW_COLLECTOR_IMPORT_DAYS environmental variable not set. Defaulting to 365 days"

import_days="365"

fi

##
## Random ID
##

random_id=$(od -A n -t d -N 1 /dev/urandom |tr -d ' ')

##
## Curl Command
##

if [ "$debug" == "true" ]

then

curl=(  )

else

curl=( --silent --show-error --fail)

fi

##
## Set Threads
##

if [ -z "$threads" ]

then

N=1

else

N=${threads}

fi

if [ "$debug" == "true" ]

then

echo "Starting WeatherFlow Collector (startup.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

backend_type=${backend_type}
collector_type=${collector_type}
debug=${debug}
device_id=${device_id}
elevation=${elevation}
forecast_interval=${forecast_interval}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
hub_sn=${hub_sn}
import_days=${import_days}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
latitude=${latitude}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
longitude=${longitude}
public_name=${public_name}
rest_interval=${rest_interval}
station_id=${station_id}
station_name=${station_name}
threads=${threads}
timezone=${timezone}
token=${token}"

else

echo "Starting WeatherFlow Collector (startup.sh) - https://github.com/lux4rd0/weatherflow-collector"

fi

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
## Send Startup Timestamp to InfluxDB
##

current_time=$(date +%s)

echo "time_epoch: ${current_time}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone},source=${function} docker_start=${current_time}000"

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

################################
##                            ##
## COLLECTOR TYPE = LOCAL-UDP ##
##                            ##
################################

if [ "${collector_type}" == "local-udp" ]  &&  [ "${function}" == "import" ]

then

echo "collector_type=${collector_type}
function=${function}"

hours=$(("$import_days" * 24))

for hours_loop in $(seq "$hours" -1 0) ; do

hours_start=$(date --date="${hours_loop} hours ago 00:00" +%s)

hours_end=$(("$hours_start" + 3599))

date_start=$(date -d @"${hours_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${hours_end} --rfc-3339=seconds | sed 's/ /T/')

echo "Hour Slices Remaining: $hours_loop"
echo "date_start: $date_start"
echo "date_end: $date_end"

##
## Start Timer
##

import_start=$(date +%s%N)

##
## Start "threading"
##

logs=$(./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp)

num_of_logs=$(echo "${logs}" | jq -r ". | length")

echo "Number of logs: ${num_of_logs}"

num_of_logs_minus_one=$((num_of_logs-1))

for log in $(seq 0 ${num_of_logs_minus_one})

do

(

echo "${logs}" | jq -r .["${log}"].line | WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED="false" ./local-udp-influxdb.sh

) &

    if [[ $(jobs -r -p | wc -l) -ge $N ]]; then
        wait -n

    ProgressBar "${log}" ${num_of_logs_minus_one}

    fi

done

wait

printf '\nFinished!\n'

##
## End "threading"
##

##
## End Timer
##

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

echo "import_duration:${import_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} duration=${import_duration}"

done

fi

if [ "${collector_type}" == "local-udp" ]  &&  [ "${function}" == "collector" ]

then

echo "
collector_type=${collector_type}
function=${function}"

/usr/bin/stdbuf -oL /usr/bin/python ./weatherflow-listener.py | ./local-udp-influxdb.sh

fi

####################################
##                                ##
## COLLECTOR TYPE = REMOTE-SOCKET ##
##                                ##
####################################

if [ "${collector_type}" == "remote-socket" ]  &&  [ "${function}" == "import" ]

then

echo "collector_type=${collector_type}
function=${function}"

hours=$(("$import_days" * 24))

for hours_loop in $(seq "$hours" -1 0) ; do

hours_start=$(date --date="${hours_loop} hours ago 00:00" +%s)

hours_end=$(("$hours_start" + 3599))

date_start=$(date -d @"${hours_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${hours_end} --rfc-3339=seconds | sed 's/ /T/')

echo "Hour Slices Remaining: $hours_loop"
echo "date_start: $date_start"
echo "date_end: $date_end"

##
## Start Timer
##

import_start=$(date +%s%N)

##
## Start "threading"
##

logs=$(./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp)

num_of_logs=$(echo "${logs}" | jq -r ". | length")

echo "Number of logs: ${num_of_logs}"

num_of_logs_minus_one=$((num_of_logs-1))

for log in $(seq 0 ${num_of_logs_minus_one})

do

(

echo "${logs}" | jq -r .["${log}"].line | WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED="false" ./remote-socket-influxdb.sh

) &

    if [[ $(jobs -r -p | wc -l) -ge $N ]]; then
        wait -n

    ProgressBar "${log}" ${num_of_logs_minus_one}

    fi

done

wait

printf '\nFinished!\n'

##
## End "threading"
##

##
## End Timer
##

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

echo "import_duration:${import_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} duration=${import_duration}"

done

fi

if [ "${collector_type}" == "remote-socket" ]  &&  [ "${function}" == "collector" ]

then

echo "collector_type=${collector_type}
function=${function}"

JSON='\n{"type":"listen_start", "device_id": "'"${device_id}"'", "id":"weatherflow-collector-start_'"${random_id}"'"}\n{"type":"listen_start_events", "station_id": "'"${station_id}"'", "id":"weatherflow-collector-start_events_'"${random_id}"'"}\n{"type":"listen_rapid_start", "device_id": "'"${device_id}"'", "id":"weatherflow-collector-rapid_start_'"${random_id}"'"}\n'

echo -e "$JSON" | ./websocat_amd64-linux-static -n "wss://ws.weatherflow.com/swd/data?token=${token}" | ./remote-socket-influxdb.sh

fi

######################################
##                                  ##
## COLLECTOR TYPE = REMOTE-FORECAST ##
##                                  ##
######################################

if [ "${collector_type}" == "remote-forecast" ]  &&  [ "${function}" == "import" ]

then

echo "collector_type=${collector_type}
function=${function}"

for days_loop in $(seq "$import_days" -1 0) ; do

##
## Choose noon local as the collect log time to pull in the forecast
##

days_start=$(date --date="${days_loop} days ago 12:00" +%s)

days_end=$(("$days_start" + 1800))

date_start=$(date -d @"${days_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${days_end} --rfc-3339=seconds | sed 's/ /T/')

echo "Days Remaining: $days_loop"
echo "date_start: $date_start"
echo "date_end: $date_end"

./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp | jq -r .[0].line | WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED="false" ./import-forecast-influxdb.sh

done

fi

if [ "${collector_type}" == "remote-forecast" ]  &&  [ "${function}" == "collector" ]
then

echo "collector_type=${collector_type}"

startup_check=0

while ( true ); do
  before=$(date +%s%N)

##
## Run the hourly forecasts at 00, 15, 30, 45 minutes except on startup
##

hourly_time_build_check_minute=$(date +"%M")

if [ "$hourly_time_build_check_minute" == "00" ] || [ "$hourly_time_build_check_minute" == "15" ] || [ "$hourly_time_build_check_minute" == "30" ] || [ "$hourly_time_build_check_minute" == "45" ]

then

hourly_time_build_check_flag="true"

echo "Running Hourly Forecast - Quarter Hour Time Interval - ${hourly_time_build_check_minute} Minute"

else

hourly_time_build_check_flag="false"

echo "Skipping Hourly Forecast - Quarter Hour Time Interval - ${hourly_time_build_check_minute} Minute"

fi

##
## Run on startup
##

if [ "$startup_check" == "0" ]

then

hourly_time_build_check_flag="true"

echo "Running Hourly Forecast - First Time Startup"

fi

  curl "${curl[@]}" -w "\n" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${station_id}&token=${token}" | WEATHERFLOW_COLLECTOR_HOURLY_FORECAST_RUN=${hourly_time_build_check_flag} ./remote-forecast-influxdb.sh
  after=$(date +%s%N)
  DELAY=$(echo "scale=4;(${forecast_interval}-($after-$before) / 1000000000)" | bc)
  echo "Sleeping: ${DELAY} seconds"
  ((startup_check=startup_check+1))
  echo "Loop: ${startup_check}"
  sleep "$DELAY"
done

fi

##################################
##                              ##
## COLLECTOR TYPE = REMOTE-REST ##
##                              ##
##################################

if [ "${collector_type}" == "remote-rest" ]  &&  [ "${function}" == "import" ]

then

echo "collector_type=${collector_type}
function=${function}"

hours=$(("$import_days" * 24))

for hours_loop in $(seq "$hours" -1 0) ; do

hours_start=$(date --date="${hours_loop} hours ago 00:00" +%s)

hours_end=$(("$hours_start" + 3599))

date_start=$(date -d @"${hours_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${hours_end} --rfc-3339=seconds | sed 's/ /T/')

echo "Hour Slices Remaining: $hours_loop"
echo "date_start: $date_start"
echo "date_end: $date_end"

##
## Start Timer
##

import_start=$(date +%s%N)

##
## Start "threading"
##

logs=$(./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp)

num_of_logs=$(echo "${logs}" | jq -r ". | length")

echo "Number of logs: ${num_of_logs}"

num_of_logs_minus_one=$((num_of_logs-1))

for log in $(seq 0 ${num_of_logs_minus_one})

do

(

echo "${logs}" | jq -r .["${log}"].line | WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED="false" ./remote-rest-influxdb.sh

) &

    if [[ $(jobs -r -p | wc -l) -ge $N ]]; then
        wait -n

    ProgressBar "${log}" ${num_of_logs_minus_one}

    fi

done

wait

printf '\nFinished!\n'

##
## End "threading"
##

##
## End Timer
##

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

echo "import_duration:${import_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} duration=${import_duration}"

done

fi

if [ "${collector_type}" == "remote-rest" ]  &&  [ "${function}" == "collector" ]

then

while ( true ); do
  before=$(date +%s)
  curl "${curl[@]}" -w "\n" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/observations/station/${station_id}?token=${token}" | ./remote-rest-influxdb.sh
  after=$(date +%s)
  DELAY=$(echo "${rest_interval}-($after-$before)" | bc)
  echo "Sleeping ${DELAY}"
  sleep "$DELAY"
done

fi

####################################
##                                ##
## COLLECTOR TYPE = REMOTE-IMPORT ##
##                                ##
####################################

if [ "${collector_type}" == "remote-import" ]  &&  [ "${function}" == "import" ]

then

echo "collector_type=${collector_type}"

##
## Loop through the days for a full import
##

for days_loop in $(seq "$import_days" -1 0) ; do

time_start=$(date --date="${days_loop} days ago 00:00" +%s)

time_end=$(("$time_start" + 86340))

echo "Day: $days_loop days ago"
echo "time_start: $time_start"
echo "time_end: $time_end"

curl "${curl[@]}" -w "\n" -X GET --header 'Accept: application/json' "https://swd.weatherflow.com/swd/rest/observations/device/${device_id}?time_start=${time_start}&time_end=${time_end}&token=${token}" | ./remote-import-influxdb.sh

done

fi

echo "No Remote Collector Configured

Please check configurations:

backend_type=${backend_type}
collector_type=${collector_type}
debug=${debug}
device_id=${device_id}
elevation=${elevation}
forecast_interval=${forecast_interval}
function=${function}
host_hostname=${host_hostname}
hub_sn=${hub_sn}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
latitude=${latitude}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
longitude=${longitude}
public_name=${public_name}
rest_interval=${rest_interval}
station_id=${station_id}
station_name=${station_name}
timezone=${timezone}
token=${token}"
