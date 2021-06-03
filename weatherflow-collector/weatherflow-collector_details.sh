#!/bin/bash

##
## WeatherFlow Collector - weatherflow-collector_details.sh
##

weatherflow_collector_version="3.1.4"
#grafana_loki_binary_path="./promtail-linux-amd64"
grafana_loki_binary_path="/usr/bin/promtail"
debug_sleeping=$WEATHERFLOW_COLLECTOR_DEBUG_SLEEPING
collector_key=$(echo ${WEATHERFLOW_COLLECTOR_TOKEN} | awk -F"-" '{print $1}')

##
## Echo Details
##

echo_bold=$(tput -T xterm bold)
echo_blink=$(tput -T xterm blink)
echo_black=$(tput -T xterm setaf 0)
echo_red=$(tput -T xterm setaf 1)

echo_color_health_check=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_host_performance=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_local_udp=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_remote_forecast=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_remote_rest=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_remote_socket=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_start=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_remote_import=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")

echo_normal=$(tput -T xterm sgr0)

##
## Functions
##

function escape_names () {

##
## Change Variable Name for Name - Station Name
##

#echo "Coming In"
#echo "name:${name} station_name=${station_name}"

if [ -n "${name}" ]; then station_name="${name}"; fi

#echo "Going Out"
#echo "name:${name} station_name=${station_name}"

##
## Escape Names
##

##
## Spaces
##

public_name_escaped="${public_name// /\\ }"
station_name_escaped="${station_name// /\\ }"

##
## Commas
##

public_name_escaped="${public_name_escaped//,/\\,}"
station_name_escaped="${station_name_escaped//,/\\,}"

##
## Equal Signs
##

public_name_escaped="${public_name_escaped//=/\\=}"
station_name_escaped="${station_name_escaped//=/\\=}"

}

##
## ProgressBar - https://github.com/fearside/ProgressBar/
##

function ProgressBar () {
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")
printf "\r${echo_blink}${echo_bold}Progress${echo_normal} : ${echo_bold}[${echo_normal}${_fill// /${echo_red}${echo_bold}▒${echo_normal}}${_empty// /-}${echo_bold}]${echo_normal} ${_progress}%%"
}

##
## Health Check
##

function health_check () {

if [ "$healthcheck" == "true" ]; then health_check_file="health-check-${collector_type}.txt"; touch ${health_check_file}; fi

}

##
## Send Startup Event Timestamp to InfluxDB
##

function docker_startup () {

if [ "$debug" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

current_time=$(date +%s)

#echo "${bold}${collector_type}:${normal} time_epoch: ${current_time}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_key=${collector_key},collector_type=${collector_type},host_hostname=${host_hostname},source=${function} docker_start=${current_time}000"

}