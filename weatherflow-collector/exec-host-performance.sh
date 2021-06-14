#!/bin/bash

##
## WeatherFlow Collector - exec-host-performance.sh
##

##
## WeatherFlow-Collector Details
##

source weatherflow-collector_details.sh

debug=$WEATHERFLOW_COLLECTOR_DEBUG
debug_curl=$WEATHERFLOW_COLLECTOR_DEBUG_CURL
function=$WEATHERFLOW_COLLECTOR_FUNCTION
healthcheck=$WEATHERFLOW_COLLECTOR_HEALTHCHECK
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
logcli_host_url=$WEATHERFLOW_COLLECTOR_LOGCLI_URL
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
public_name=$WEATHERFLOW_COLLECTOR_PUBLIC_NAME
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID
station_name=$WEATHERFLOW_COLLECTOR_STATION_NAME
token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Set Specific Variables
##

collector_type="host-performance"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_host_performance}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (exec-host-performance.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
debug_curl=${debug_curl}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
public_name=${public_name}
station_id=${station_id}
station_name=${station_name}
token=${token}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Curl Command
##

if [ "$debug_curl" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

##
## Health Check Function
##

health_check

##
## Escape Names (Function)
##

escape_names

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

processes=($(top -bn1 | grep zombie | awk '{print $4" "$6" "$8" "$10}'))

processes_running=${processes[0]}
processes_sleeping=${processes[1]}
processes_stopped=${processes[2]}
processes_zombie=${processes[3]}

if [ "$debug" == "true" ]
then

echo "
processes_running=${processes_running}
processes_sleeping=${processes_sleeping}
processes_stopped=${processes_stopped}
processes_zombie=${processes_zombie}"

fi

##
## Per Process CPU
## Derived from https://github.com/AraKhachatryan/top
##

pid_array=$(ls /proc | grep -E '^[0-9]+$')
clock_ticks=$(getconf CLK_TCK)

for pid in $pid_array
do
if [ -r /proc/"$pid"/stat ]
then

stat_array=( $(sed -E 's/(\([^\s)]+)\s([^)]+\))/\1_\2/g' /proc/"$pid"/stat) )
uptime_array=( $(cat /proc/uptime) )
comm=( $(grep -Po '^[^\s\/]+' /proc/"$pid"/comm) )
uptime=${uptime_array[0]}
ppid=${stat_array[3]}
utime=${stat_array[13]}
stime=${stat_array[14]}
cstime=${stat_array[16]}
starttime=${stat_array[21]}
total_time=$(( utime + stime ))
total_time=$(( total_time + cstime ))
seconds=$( awk 'BEGIN {print ( '"$uptime"' - ('"$starttime"' / '"$clock_ticks"') )}' )
cpu_usage=$( awk 'BEGIN {print ( 100 * (('$total_time' / '"$clock_ticks"') / '"$seconds"') )}' )

##
## Send CPU and Memory Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_process_stats,collector_key=${collector_key},collector_type=${collector_type},host_hostname=${host_hostname},source=${function},pid=${pid},ppid=${ppid},command=${comm} uptime=${uptime},utime=${utime},stime=${stime},cstime=${cstime},starttime=${starttime},total_time=${total_time},seconds=${seconds},cpu_usage=${cpu_usage}"

fi
done

##
## Send CPU and Memory Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_key=${collector_key},collector_type=${collector_type},host_hostname=${host_hostname},source=${function} cpu_gnice=${cpu_gnice},cpu_guest=${cpu_guest},cpu_idle=${cpu_idle},cpu_iowait=${cpu_iowait},cpu_irq=${cpu_irq},cpu_nice=${cpu_nice},cpu_soft=${cpu_soft},cpu_steal=${cpu_steal},cpu_sys=${cpu_sys},cpu_usr=${cpu_usr},mem_available=${mem_available},mem_buffers=${mem_buffers},mem_cache=${mem_cache},mem_free=${mem_free},mem_shared=${mem_shared},mem_total=${mem_total},mem_used=${mem_used},processes_running=${processes_running},processes_sleeping=${processes_sleeping},processes_stopped=${processes_stopped},processes_zombie=${processes_zombie},swap_free=${swap_free},swap_total=${swap_total},swap_used=${swap_used},loadavg_fifteen=${loadavg_fifteen},loadavg_five=${loadavg_five},loadavg_one=${loadavg_one}"

##
## End Timer
##

host_performance_end=$(date +%s%N)
host_performance_duration=$((host_performance_end-host_performance_start))

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_host_performance}${collector_type}:${echo_normal} host_performance_duration:${host_performance_duration}"; fi

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_key=${collector_key},collector_type=${collector_type},duration_type="host_performance",host_hostname=${host_hostname},source=${function} duration=${host_performance_duration}"