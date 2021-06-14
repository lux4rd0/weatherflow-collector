#!/bin/bash

##
## WeatherFlow Collector - start-host-performance.sh
##

##
## WeatherFlow-Collector Details
##

source weatherflow-collector_details.sh

##
## Set Variables from Environmental Variables
##

debug=$WEATHERFLOW_COLLECTOR_DEBUG
debug_curl=$WEATHERFLOW_COLLECTOR_DEBUG_CURL
debug_sleeping=$WEATHERFLOW_COLLECTOR_DEBUG_SLEEPING
function=$WEATHERFLOW_COLLECTOR_FUNCTION
healthcheck=$WEATHERFLOW_COLLECTOR_HEALTHCHECK
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
perf_interval=$WEATHERFLOW_COLLECTOR_PERF_INTERVAL
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME

##
## Set Specific Variables
##

collector_type="host-performance"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_host_performance}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (remote-rest.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
debug_curl=${debug_curl}
debug_sleeping=${debug_sleeping}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
perf_interval=${perf_interval}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Check for required intervals
##

if [ -z "${perf_interval}" ]; then echo "${echo_bold}${echo_color_host_performance}${collector_type}:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_PERF_INTERVAL${echo_normal} environmental variable not set. Defaulting to ${echo_bold}60 ${echo_normal} seconds."; perf_interval="60"; export WEATHERFLOW_COLLECTOR_PERF_INTERVAL="60"; fi

if [ -z "${host_hostname}" ]; then echo "${echo_bold}${echo_color_host_performance}${collector_type}:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_HOST_HOSTNAME${echo_normal} environmental variable not set. Defaulting to ${echo_bold}weatherflow-collector${echo_normal}."; host_hostname="weatherflow-collector"; export WEATHERFLOW_COLLECTOR_HOST_HOSTNAME="weatherflow-collector"; fi

##
## Set InfluxDB Precision to seconds
##

if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Send Startup Event Timestamp to InfluxDB
##

process_start

##
## Curl Command
##

if [ "$debug" == "true" ]; then curl=(  ); else curl=( --silent --show-error --fail ); fi

##
## Start Host Performance Loop
##

while ( true ); do
before=$(date +%s%N)

./exec-host-performance.sh

after=$(date +%s%N)
delay=$(echo "scale=4;(${perf_interval}-($after-$before) / 1000000000)" | bc)
if [ "$debug_sleeping" == "true" ]; then echo "${echo_bold}${echo_color_host_performance}${collector_type}:${echo_normal} Sleeping: ${delay} seconds"; fi
sleep "$delay"
done