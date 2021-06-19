#!/bin/bash

##
## WeatherFlow Collector - exec-health-check.sh
##

##
## WeatherFlow-Collector Details
##

source weatherflow-collector_details.sh

##
## Set Variables from Environmental Variables
##

backend_type=$WEATHERFLOW_COLLECTOR_BACKEND_TYPE
debug=$WEATHERFLOW_COLLECTOR_DEBUG
debug_curl=$WEATHERFLOW_COLLECTOR_DEBUG_CURL
device_id=$WEATHERFLOW_COLLECTOR_DEVICE_ID
elevation=$WEATHERFLOW_COLLECTOR_ELEVATION
forecast_interval=$WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL
function=$WEATHERFLOW_COLLECTOR_FUNCTION
healthcheck=$WEATHERFLOW_COLLECTOR_HEALTHCHECK
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

disable_host_performance=$WEATHERFLOW_COLLECTOR_DISABLE_HOST_PERFORMANCE
disable_local_udp=$WEATHERFLOW_COLLECTOR_DISABLE_LOCAL_UDP
disable_remote_forecast=$WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_FORECAST
disable_remote_rest=$WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_REST
disable_remote_socket=$WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_SOCKET

disable_healthcheck_host_performance=$WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_HOST_PERFORMANCE
disable_healthcheck_local_udp=$WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_LOCAL_UDP
disable_healthcheck_remote_forecast=$WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_REMOTE_FORECAST
disable_healthcheck_remote_rest=$WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_REMOTE_REST
disable_healthcheck_remote_socket=$WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_REMOTE_SOCKET

##
## Set Specific Variables
##

collector_type="health-check"

if [ "$debug" == "true" ]

then

echo "Starting WeatherFlow Collector (host-performance.sh) - https://github.com/lux4rd0/weatherflow-collector

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
token=${token}

disable_host_performance=${disable_host_performance}
disable_local_udp=${disable_local_udp}
disable_remote_forecast=${disable_remote_forecast}
disable_remote_rest=${disable_remote_rest}
disable_remote_socket=${disable_remote_socket}

disable_healthcheck_host_performance=${disable_healthcheck_host_performance}
disable_healthcheck_local_udp=${disable_healthcheck_local_udp}
disable_healthcheck_remote_forecast=${disable_healthcheck_remote_forecast}
disable_healthcheck_remote_rest=${disable_healthcheck_remote_rest}
disable_healthcheck_remote_socket=${disable_healthcheck_remote_socket}
"

fi

##
## Curl Command
##

if [ "$debug_curl" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

##
## Send Healthcheck Events To InfluxDB
##

function health_check_curl {

if [ -e "${health_check_file}" ]

then 

if [ "$(stat --format=%Y "${health_check_file}")" -le $(( $(date +%s) - health_check_interval )) ]
then

if [ -n "$influxdb_url" ]; then curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "weatherflow_system_events,collector_key=${collector_key},collector_type=${collector_type},host_hostname=${host_hostname},source=${function},event=healthcheck,health_check_collector_type=${health_check_collector_type} up=0"; fi

echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} $(date) - ${health_check_collector_type} check is more than ${health_check_interval} seconds old."; pkill -TERM -P "$(pgrep -f start-"${health_check_collector_type}".sh)"; pkill -f -TERM promtail
echo "
${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} $(date) - ${health_check_collector_type} restarted."

else

if [ -n "$influxdb_url" ]; then curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "weatherflow_system_events,collector_key=${collector_key},collector_type=${collector_type},host_hostname=${host_hostname},source=${function},event=healthcheck,health_check_collector_type=${health_check_collector_type} up=1"; fi

if [ "$debug" == "true" ]
then
echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} $(date) - ${health_check_collector_type} check is less than ${health_check_interval} seconds old"; fi

fi

else

if [ -n "$influxdb_url" ]; then curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "weatherflow_system_events,collector_key=${collector_key},collector_type=${collector_type},host_hostname=${host_hostname},source=${function},event=healthcheck,health_check_collector_type=${health_check_collector_type} up=0"; fi

echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} $(date) - ${health_check_collector_type} check has failed. No check file found."; pkill -TERM -P "$(pgrep -f start-"${health_check_collector_type}".sh)"; pkill -f -TERM promtail
echo "
${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} $(date) - ${health_check_collector_type} restarted."

fi

}

##
## Disable Health Checks if Collector is Disabled
##

if [ "${disable_host_performance}" == "true" ]; then disable_healthcheck_host_performance="true"; fi
if [ "${disable_local_udp}" == "true" ]; then disable_healthcheck_local_udp="true"; fi
if [ "${disable_remote_forecast}" == "true" ]; then disable_healthcheck_remote_forecast="true"; fi
if [ "${disable_remote_rest}" == "true" ]; then disable_healthcheck_remote_rest="true"; fi
if [ "${disable_remote_socket}" == "true" ]; then disable_healthcheck_remote_socket="true"; fi

##
## Health Check Function
##

health_check

##
## Start Timer
##

health_check_start=$(date +%s%N)

##
## Remote Socket
##

if [ "$disable_healthcheck_remote_socket" != "true" ]; then

health_check_collector_type="remote-socket"
health_check_file="health-check-${health_check_collector_type}.txt"
health_check_interval="65"

##
## Send Healthcheck Events To InfluxDB
##

health_check_curl

fi

##
## Remote REST
##

if [ "$disable_healthcheck_remote_rest" != "true" ]; then

health_check_collector_type="remote-rest"
health_check_file="health-check-${health_check_collector_type}.txt"
health_check_interval="65"

##
## Send Healthcheck Events To InfluxDB
##

health_check_curl

fi

##
## Remote Forecast
##

if [ "$disable_healthcheck_remote_forecast" != "true" ]; then

health_check_collector_type="remote-forecast"
health_check_file="health-check-${health_check_collector_type}.txt"
health_check_interval="305"

##
## Send Healthcheck Events To InfluxDB
##

health_check_curl

fi

##
## Local UDP
##

if [ "$disable_healthcheck_local_udp" != "true" ]; then

health_check_collector_type="local-udp"
health_check_file="health-check-${health_check_collector_type}.txt"
health_check_interval="65"

##
## Send Healthcheck Events To InfluxDB
##

health_check_curl

fi

##
## host-performance
##

if [ "$disable_healthcheck_host_performance" != "true" ]; then

health_check_collector_type="host-performance"
health_check_file="health-check-${health_check_collector_type}.txt"
health_check_interval="65"

##
## Send Healthcheck Events To InfluxDB
##

health_check_curl

fi

## End Timer

health_check_end=$(date +%s%N)
health_check_duration=$((health_check_end-health_check_start))

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_health_check}${collector_type}:${echo_normal} health_check_duration:${health_check_duration}"; fi

##
## Send Timer Metrics To InfluxDB
##

if [ -n "$influxdb_url" ]; then

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_key=${collector_key},collector_type=${collector_type},duration_type="health_check",host_hostname=${host_hostname},source=${function} duration=${health_check_duration}"; fi