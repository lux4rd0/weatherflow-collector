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
function=$WEATHERFLOW_COLLECTOR_FUNCTION
healthcheck=$WEATHERFLOW_COLLECTOR_HEALTHCHECK
healthcheck_interval=$WEATHERFLOW_COLLECTOR_HEALTHCHECK_INTERVAL
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME

##
## Set Specific Variables
##

collector_type="health-check"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} Starting WeatherFlow Collector (remote-rest.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
healthcheck_interval=${healthcheck_interval}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Check for required intervals
##

if [ -z "${healthcheck}" ]; then echo "${echo_bold}start:${echo_normal} WEATHERFLOW_COLLECTOR_HEALTHCHECK environmental variable not set. Defaulting to true."; healthcheck="true"; fi

if [ -z "${healthcheck_interval}" ]; then echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} WEATHERFLOW_COLLECTOR_HEALTHCHECK_INTERVAL environmental variable not set. Defaulting to 60 seconds"; healthcheck_interval="5"; fi

if [ -z "${host_hostname}" ]; then echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} WEATHERFLOW_COLLECTOR_HOST_HOSTNAME environmental variable not set. Defaulting to weatherflow-collector"; host_hostname="weatherflow-collector"; fi

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
## Sleep for 60 seconds while we wait for everything to startup
##

sleep 60;

##
## Start Health Check Loop
##

while ( true ); do
before=$(date +%s%N)

./exec-health-check.sh

after=$(date +%s%N)
DELAY=$(echo "scale=4;(${healthcheck_interval}-($after-$before) / 1000000000)" | bc)

if [ "$debug_sleeping" == "true" ]; then echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} Sleeping: ${DELAY} seconds"; fi

sleep "$DELAY"
done

