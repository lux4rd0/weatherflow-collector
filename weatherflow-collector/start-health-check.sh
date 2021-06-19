#!/bin/bash

##
## WeatherFlow Collector - start-health-check.sh
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
healthcheck_interval=$WEATHERFLOW_COLLECTOR_HEALTHCHECK_INTERVAL
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL

##
## Set Specific Variables
##

collector_type="health-check"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (remote-rest.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
debug_curl=${debug_curl}
debug_sleeping=${debug_sleeping}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
healthcheck_interval=${healthcheck_interval}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Check for required intervals
##

if [ -z "${healthcheck}" ]; then echo "${echo_bold}start:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_HEALTHCHECK${echo_normal} environmental variable not set. Defaulting to true."; healthcheck="true"; export WEATHERFLOW_COLLECTOR_HEALTHCHECK="true"; fi

if [ -z "${healthcheck_interval}" ]; then echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_HEALTHCHECK_INTERVAL${echo_normal} environmental variable not set. Defaulting to ${echo_bold}15${echo_normal} seconds."; healthcheck_interval="15"; export WEATHERFLOW_COLLECTOR_HEALTHCHECK_INTERVAL="15"; fi

if [ -z "${host_hostname}" ]; then echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_HOST_HOSTNAME${echo_normal} environmental variable not set. Defaulting to ${echo_bold}weatherflow-collector${echo_normal}."; host_hostname="weatherflow-collector"; export WEATHERFLOW_COLLECTOR_HOST_HOSTNAME="weatherflow-collector"; fi

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

if [ "$debug_curl" == "true" ]; then curl=(  ); else curl=( --silent --show-error --fail ); fi

##
## Sleep for 60 seconds while we wait for everything to startup
##

echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} $(date) - Sleeping for 60 seconds on startup."

sleep 60;

##
## Start Health Check Loop
##

while ( true ); do
before=$(date +%s%N)

./exec-health-check.sh

after=$(date +%s%N)
delay=$(echo "scale=4;(${healthcheck_interval}-($after-$before) / 1000000000)" | bc)

if [ "$debug_sleeping" == "true" ]; then echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} Sleeping: ${delay} seconds"; fi

sleep "$delay"
done