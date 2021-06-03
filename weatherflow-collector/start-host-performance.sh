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

echo "${echo_bold}${echo_color_host_performance}${collector_type}:${echo_normal} Starting WeatherFlow Collector (remote-rest.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
perf_interval=${perf_interval}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Check for required intervals
##

if [ -z "${perf_interval}" ]; then echo "${echo_bold}${echo_color_host_performance}${collector_type}:${echo_normal} WEATHERFLOW_COLLECTOR_PERF_INTERVAL environmental variable not set. Defaulting to 60 seconds"; perf_interval="60"; fi

if [ -z "${host_hostname}" ]; then echo "${echo_bold}${echo_color_host_performance}${collector_type}:${echo_normal} WEATHERFLOW_COLLECTOR_HOST_HOSTNAME environmental variable not set. Defaulting to weatherflow-collector"; host_hostname="weatherflow-collector"; fi

##
## Set InfluxDB Precision to seconds
##

if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Send Startup Event Timestamp to InfluxDB
##

docker_startup

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
DELAY=$(echo "scale=4;(${perf_interval}-($after-$before) / 1000000000)" | bc)
if [ "$debug_sleeping" == "true" ]; then echo "${echo_bold}${echo_color_host_performance}${collector_type}:${echo_normal} Sleeping: ${DELAY} seconds"; fi
sleep "$DELAY"
done