#!/bin/bash

##
## WeatherFlow Collector - host-performance.sh
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
token=${token}"

fi

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
## Health Check
##

if [ "$healthcheck" == "true" ]
then

health_check_file="/weatherflow-collector/health_check.txt"
touch ${health_check_file}

fi

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

##
## Start Timer
##

host_performance_start=$(date +%s%N)


##
## Pull Host Metrics
##

memory=($(free -w))

mem_total=${memory[8]}
mem_used=${memory[9]}
mem_free=${memory[10]}
mem_shared=${memory[11]}
mem_buffers=${memory[12]}
mem_cache=${memory[13]}
mem_available=${memory[14]}
swap_total=${memory[16]}
swap_used=${memory[17]}
swap_free=${memory[18]}

if [ "$debug" == "true" ]
then

echo "
mem_total=${mem_total}
mem_used=${mem_used}
mem_free=${mem_free}
mem_shared=${mem_shared}
mem_buffers=${mem_buffers}
mem_cache=${mem_cache}
mem_available=${mem_available}
swap_total=${swap_total}
swap_used=${swap_used}
swap_free=${swap_free}"

fi

cpu=($(mpstat 1 1 | tail -1))

cpu_usr=${cpu[2]}
cpu_nice=${cpu[3]}
cpu_sys=${cpu[4]}
cpu_iowait=${cpu[5]}
cpu_irq=${cpu[6]}
cpu_soft=${cpu[7]}
cpu_steal=${cpu[8]}
cpu_guest=${cpu[9]}
cpu_gnice=${cpu[10]}
cpu_idle=${cpu[11]}

if [ "$debug" == "true" ]
then

echo "
cpu_usr=${cpu_usr}
cpu_nice=${cpu_nice}
cpu_sys=${cpu_sys}
cpu_iowait=${cpu_iowait}
cpu_irq=${cpu_irq}
cpu_soft=${cpu_soft}
cpu_steal=${cpu_steal}
cpu_guest=${cpu_guest}
cpu_gnice=${cpu_gnice}
cpu_idle=${cpu_idle}"

fi

loadavg=($(cat /proc/loadavg))

loadavg_one=${loadavg[0]}
loadavg_five=${loadavg[1]}
loadavg_fifteen=${loadavg[2]}

if [ "$debug" == "true" ]
then

echo "
loadavg_one=${loadavg_one}
loadavg_five=${loadavg_five}
loadavg_fifteen=${loadavg_fifteen}"

fi

##
## Send CPU and Memory Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} cpu_gnice=${cpu_gnice}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} cpu_guest=${cpu_guest}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} cpu_idle=${cpu_idle}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} cpu_iowait=${cpu_iowait}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} cpu_irq=${cpu_irq}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} cpu_nice=${cpu_nice}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} cpu_soft=${cpu_soft}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} cpu_steal=${cpu_steal}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} cpu_sys=${cpu_sys}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} cpu_usr=${cpu_usr}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} mem_available=${mem_available}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} mem_buffers=${mem_buffers}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} mem_cache=${mem_cache}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} mem_free=${mem_free}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} mem_shared=${mem_shared}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} mem_total=${mem_total}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} mem_used=${mem_used}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} swap_free=${swap_free}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} swap_total=${swap_total}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} swap_used=${swap_used}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} loadavg_fifteen=${loadavg_fifteen}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} loadavg_five=${loadavg_five}
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} loadavg_one=${loadavg_one}"

## End Timer

host_performance_end=$(date +%s%N)
host_performance_duration=$((host_performance_end-host_performance_start))

echo "host_performance_duration:${host_performance_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},host_hostname=${host_hostname},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} duration=${host_performance_duration}"
