#!/bin/bash

##
## WeatherFlow Collector - start.sh
##

##
## WeatherFlow-Collector Details
##

source weatherflow-collector_details.sh

echo -en "\033[01;38;5;52m █     █░▓█████ ▄▄▄     ▄▄▄█████▓ ██░ ██ ▓█████  ██▀███    █████▒██▓     ▒█████   █     █░\n"
echo -en "\033[01;38;5;124m▓█░ █ ░█░▓█   ▀▒████▄   ▓  ██▒ ▓▒▓██░ ██▒▓█   ▀ ▓██ ▒ ██▒▓██   ▒▓██▒    ▒██▒  ██▒▓█░ █ ░█░\n"
echo -en "\033[01;38;5;196m▒█░ █ ░█ ▒███  ▒██  ▀█▄ ▒ ▓██░ ▒░▒██▀▀██░▒███   ▓██ ░▄█ ▒▒████ ░▒██░    ▒██░  ██▒▒█░ █ ░█ \n"
echo -en "\033[01;38;5;202m░█░ █ ░█ ▒▓█  ▄░██▄▄▄▄██░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄ ▒██▀▀█▄  ░▓█▒  ░▒██░    ▒██   ██░░█░ █ ░█ \n"
echo -en "\033[01;38;5;208m░░██▒██▓ ░▒████▒▓█   ▓██▒ ▒██▒ ░ ░▓█▒░██▓░▒████▒░██▓ ▒██▒░▒█░   ░██████▒░ ████▓▒░░░██▒██▓ \n"
echo -en "\033[01;38;5;214m░ ▓░▒ ▒  ░░ ▒░ ░▒▒   ▓▒█░ ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░░ ▒▓ ░▒▓░ ▒ ░   ░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  \n"
echo -en "\033[01;38;5;220m  ▒ ░ ░   ░ ░  ░ ▒   ▒▒ ░   ░     ▒ ░▒░ ░ ░ ░  ░  ░▒ ░ ▒░ ░     ░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░  \n"
echo -en "\033[01;38;5;226m  ░   ░     ░    ░   ▒    ░       ░  ░░ ░   ░     ░░   ░  ░ ░     ░ ░   ░ ░ ░ ▒    ░   ░  \n"
echo -en "\033[01;38;5;228m    ░       ░  ░     ░  ░         ░  ░  ░   ░  ░   ░                ░  ░    ░ ░      ░    \n"

echo ""
                                                                                 
echo -en "\033[01;38;5;52m       ▄████▄   ▒█████   ██▓     ██▓    ▓█████  ▄████▄  ▄▄▄█████▓ ▒█████   ██▀███         \n"
echo -en "\033[01;38;5;124m      ▒██▀ ▀█  ▒██▒  ██▒▓██▒    ▓██▒    ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▒██▒  ██▒▓██ ▒ ██▒       \n"
echo -en "\033[01;38;5;196m      ▒▓█    ▄ ▒██░  ██▒▒██░    ▒██░    ▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▒██░  ██▒▓██ ░▄█ ▒       \n"
echo -en "\033[01;38;5;202m      ▒▓▓▄ ▄██▒▒██   ██░▒██░    ▒██░    ▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██   ██░▒██▀▀█▄         \n"
echo -en "\033[01;38;5;208m      ▒ ▓███▀ ░░ ████▓▒░░██████▒░██████▒░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░ ████▓▒░░██▓ ▒██▒       \n"
echo -en "\033[01;38;5;214m      ░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░▓  ░░ ▒░▓  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░       \n"
echo -en "\033[01;38;5;220m        ░  ▒     ░ ▒ ▒░ ░ ░ ▒  ░░ ░ ▒  ░ ░ ░  ░  ░  ▒       ░      ░ ▒ ▒░   ░▒ ░ ▒░       \n"
echo -en "\033[01;38;5;226m      ░        ░ ░ ░ ▒    ░ ░     ░ ░      ░   ░          ░      ░ ░ ░ ▒    ░░   ░        \n"
echo -en "\033[01;38;5;228m      ░ ░          ░ ░      ░  ░    ░  ░   ░  ░░ ░                   ░ ░     ░            \n"
echo -en "\033[01;38;5;228m      ░                                        ░                                          \n"

echo "${echo_normal}"

##
## Set Variables from Environmental Variables
##

collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE
debug=$WEATHERFLOW_COLLECTOR_DEBUG
debug_curl=$WEATHERFLOW_COLLECTOR_DEBUG_CURL
disable_host_performance=$WEATHERFLOW_COLLECTOR_DISABLE_HOST_PERFORMANCE
disable_local_udp=$WEATHERFLOW_COLLECTOR_DISABLE_LOCAL_UDP
disable_remote_forecast=$WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_FORECAST
disable_remote_rest=$WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_REST
disable_remote_socket=$WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_SOCKET
function=$WEATHERFLOW_COLLECTOR_FUNCTION
healthcheck=$WEATHERFLOW_COLLECTOR_HEALTHCHECK
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
logcli_host_url=$WEATHERFLOW_COLLECTOR_LOGCLI_URL
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID
station_name=$WEATHERFLOW_COLLECTOR_STATION_NAME
threads=$WEATHERFLOW_COLLECTOR_THREADS
token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Check for required variables
##

if [ -z "${collector_type}" ]; then echo "${echo_bold}${echo_color_start}start:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE${echo_normal} environmental variable not set. Defaulting to ${echo_bold}start${echo_normal}."; collector_type="start"; fi

if [ -z "${function}" ]; then echo "${echo_bold}${echo_color_start}start:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_FUNCTION${echo_normal} environmental variable not set. Defaulting to ${echo_bold}collector${echo_normal}."; function="collector"; export WEATHERFLOW_COLLECTOR_FUNCTION="collector"; fi

if [ -z "${healthcheck}" ]; then echo "${echo_bold}${echo_color_start}start:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_HEALTHCHECK${echo_normal} environmental variable not set. Defaulting to ${echo_bold}true${echo_normal}."; healthcheck="true"; export WEATHERFLOW_COLLECTOR_HEALTHCHECK="true"; fi

if [ -z "${threads}" ]; then echo "${echo_bold}${echo_color_start}start:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_THREADS${echo_normal} environmental variable not set. Defaulting to ${echo_bold}4${echo_normal} threads."; threads="4"; export WEATHERFLOW_COLLECTOR_THREADS="4"; fi

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_start}start:${echo_normal} $(date) - Starting WeatherFlow Collector (start.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
debug_curl=${debug_curl}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
import_days=${import_days}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
logcli_host_url=${logcli_host_url}
station_id=${station_id}
station_name=${station_name}
threads=${threads}
token=${token}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Set InfluxDB Precision to seconds
##

if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Curl Command
##

if [ "$debug_curl" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

##  ::::::::   ::::::::  :::        :::        :::::::::: :::::::: ::::::::::: ::::::::  :::::::::  
## :+:    :+: :+:    :+: :+:        :+:        :+:       :+:    :+:    :+:    :+:    :+: :+:    :+: 
## +:+        +:+    +:+ +:+        +:+        +:+       +:+           +:+    +:+    +:+ +:+    +:+ 
## +#+        +#+    +:+ +#+        +#+        +#++:++#  +#+           +#+    +#+    +:+ +#++:++#:  
## +#+        +#+    +#+ +#+        +#+        +#+       +#+           +#+    +#+    +#+ +#+    +#+ 
## #+#    #+# #+#    #+# #+#        #+#        #+#       #+#    #+#    #+#    #+#    #+# #+#    #+# 
##  ########   ########  ########## ########## ########## ########     ###     ########  ###    ### 

if [ "${function}" == "collector" ]

then

##
## Startup Collector Processes
##

##
## ┬ ┬┌─┐┌─┐┌┬┐  ┌─┐┌─┐┬─┐┌─┐┌─┐┬─┐┌┬┐┌─┐┌┐┌┌─┐┌─┐
## ├─┤│ │└─┐ │───├─┘├┤ ├┬┘├┤ │ │├┬┘│││├─┤││││  ├┤ 
## ┴ ┴└─┘└─┘ ┴   ┴  └─┘┴└─└  └─┘┴└─┴ ┴┴ ┴┘└┘└─┘└─┘
##

if [ "$disable_host_performance" != "true" ]; then
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Starting up ${echo_bold}${echo_color_start}host-performance${echo_normal}."
while : ; do ./start-host-performance.sh ; done &
else
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_DISABLE_HOST_PERFORMANCE${echo_normal} set to \"true\". Disabling host-performance."
export WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_HOST_PERFORMANCE="true"
fi

##
## ┬  ┌─┐┌─┐┌─┐┬   ┬ ┬┌┬┐┌─┐
## │  │ ││  ├─┤│───│ │ ││├─┘
## ┴─┘└─┘└─┘┴ ┴┴─┘ └─┘─┴┘┴  
##

if [ "$disable_local_udp" != "true" ]; then
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Starting up ${echo_bold}${echo_color_start}local-udp${echo_normal}."
while : ; do ./start-local-udp.sh ; done &
else
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_DISABLE_LOCAL_UDP${echo_normal} set to \"true\". Disabling local-udp."
export WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_LOCAL_UDP="true"
fi

##
## ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐┌─┐┌┬┐
## ├┬┘├┤ ││││ │ │ ├┤───├┤ │ │├┬┘├┤ │  ├─┤└─┐ │ 
## ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └  └─┘┴└─└─┘└─┘┴ ┴└─┘ ┴ 
##                                                             

if [ "$disable_remote_forecast" != "true" ]; then
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Starting up ${echo_bold}${echo_color_start}remote-forecast${echo_normal}"
while : ; do ./start-remote-forecast.sh ; done &
else
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_FORECAST${echo_normal} set to \"true\". Disabling remote-forecast."
export WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_REMOTE_FORECAST="true"
fi

##
## ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┬─┐┌─┐┌─┐┌┬┐
## ├┬┘├┤ ││││ │ │ ├┤───├┬┘├┤ └─┐ │ 
## ┴└─└─┘┴ ┴└─┘ ┴ └─┘  ┴└─└─┘└─┘ ┴ 
##

if [ "$disable_remote_rest" != "true" ]; then
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Starting up ${echo_bold}${echo_color_start}remote-rest${echo_normal}."
while : ; do ./start-remote-rest.sh ; done &
else
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_REST${echo_normal} set to \"true\". Disabling remote-rest."
export WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_REMOTE_REST="true"
fi

##
## ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┌─┐┬┌─┌─┐┌┬┐
## ├┬┘├┤ ││││ │ │ ├┤───└─┐│ ││  ├┴┐├┤  │ 
## ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └─┘└─┘└─┘┴ ┴└─┘ ┴ 
##

if [ "$disable_remote_socket" != "true" ]; then
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Starting up ${echo_bold}${echo_color_start}remote-socket${echo_normal}."
while : ; do ./start-remote-socket.sh ; done &
else
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_SOCKET${echo_normal} set to \"true\". Disabling remote-socket."
export WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_REMOTE_SOCKET="true"
fi

##
## ┬ ┬┌─┐┌─┐┬ ┌┬┐┬ ┬   ┌─┐┬ ┬┌─┐┌─┐┬┌─
## ├─┤├┤ ├─┤│  │ ├─┤───│  ├─┤├┤ │  ├┴┐
## ┴ ┴└─┘┴ ┴┴─┘┴ ┴ ┴   └─┘┴ ┴└─┘└─┘┴ ┴
##

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Starting up ${echo_bold}${echo_color_start}health-check${echo_normal}."
./start-health-check.sh

fi

# ::::::::::: ::::    ::::  :::::::::   ::::::::  ::::::::: ::::::::::: 
#     :+:     +:+:+: :+:+:+ :+:    :+: :+:    :+: :+:    :+:    :+:     
#     +:+     +:+ +:+:+ +:+ +:+    +:+ +:+    +:+ +:+    +:+    +:+     
#     +#+     +#+  +:+  +#+ +#++:++#+  +#+    +:+ +#++:++#:     +#+     
#     +#+     +#+       +#+ +#+        +#+    +#+ +#+    +#+    +#+     
#     #+#     #+#       #+# #+#        #+#    #+# #+#    #+#    #+#     
# ########### ###       ### ###         ########  ###    ###    ###  

if [ "${function}" == "import" ]

then

##
## Escape Names (Function)
##

escape_names

##
## ┬  ┌─┐┌─┐┌─┐┬   ┬ ┬┌┬┐┌─┐
## │  │ ││  ├─┤│───│ │ ││├─┘
## ┴─┘└─┘└─┘┴ ┴┴─┘ └─┘─┴┘┴  
##

if [ "${collector_type}" == "local-udp" ]

then

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Retrieving Logs From ${echo_bold}${logcli_host_url}${echo_normal}, Pushing Metrics to ${echo_bold}${influxdb_url}${echo_normal}."
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - collector_type=${echo_bold}${collector_type}${echo_normal}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - function=${echo_bold}${function}${echo_normal}"

hours=$((import_days * 24))

for hours_loop in $(seq "$hours" -1 0) ; do
hours_start=$(date --date="${hours_loop} hours ago 00:00" +%s)
hours_end=$((hours_start + 3599))
date_start=$(date -d @"${hours_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${hours_end} --rfc-3339=seconds | sed 's/ /T/')

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Hour Slices Remaining: ${echo_bold}$hours_loop${echo_normal}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - date_start: $date_start"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - date_end: $date_end"

##
## Start Timer
##

import_start=$(date +%s%N)

##
## Start "threading"
##

logs=$(./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp)
#echo "./logcli-linux-amd64 query --addr=\"${logcli_host_url}\" -q --limit=100000 --timezone=Local --forward --from=\"${date_start}\" --to=\"${date_end}\" --output=jsonl '{app=\"weatherflow-collector\",collector_type=\"'\"${collector_type}\"'\",station_name=\"'\"${station_name}\"'\"}')"
num_of_logs=$(echo "${logs}" | jq -r ". | length")

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Number of logs: ${echo_bold}${num_of_logs}${echo_normal}
"
num_of_logs_minus_one=$((num_of_logs-1))

##
## Init Progress
##

init_progress "${num_of_logs}"

for log in $(seq 0 ${num_of_logs_minus_one})
do

(

echo "${logs}" | jq -r .["${log}"].line | ./exec-local-udp.sh
) &

if [[ $(jobs -r -p | wc -l) -ge $threads ]]; then wait -n; fi

##
## Increment Progress Bar
##

inc_progress

done

wait

echo "
${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Finished!
"

##
## End "threading"
##

##
## End Timer
##

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))
import_duration_seconds=$((import_duration/1000000000))

echo -n "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Import Duration: ${echo_bold}"; show_progress_time ${import_duration_seconds}

echo "${echo_normal}
"

#echo "import_duration:${import_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},source=${function},station_name=${station_name_escaped} duration=${import_duration}"
done
exit 1
fi


##
## ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┌─┐┬┌─┌─┐┌┬┐
## ├┬┘├┤ ││││ │ │ ├┤───└─┐│ ││  ├┴┐├┤  │ 
## ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └─┘└─┘└─┘┴ ┴└─┘ ┴ 
##

if [ "${collector_type}" == "remote-socket" ]

then

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Retrieving Logs From ${echo_bold}${logcli_host_url}${echo_normal}, Pushing Metrics to ${echo_bold}${influxdb_url}${echo_normal}."
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - collector_type=${echo_bold}${collector_type}${echo_normal}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - function=${echo_bold}${function}${echo_normal}"

hours=$(("$import_days" * 24))

for hours_loop in $(seq "$hours" -1 0) ; do

hours_start=$(date --date="${hours_loop} hours ago 00:00" +%s)
hours_end=$(("$hours_start" + 3599))

date_start=$(date -d @"${hours_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${hours_end} --rfc-3339=seconds | sed 's/ /T/')

hours_start_echo=$(date -d @"${hours_start}")
hours_end_echo=$(date -d @${hours_end})

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Hour Slices Remaining: ${echo_bold}$hours_loop${echo_normal}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - date_start: $date_start - ${hours_start_echo}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - date_end: $date_end - ${hours_end_echo}"

##
## Start Timer
##

import_start=$(date +%s%N)

##
## Start "threading"
##

logs=$(./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp)

num_of_logs=$(echo "${logs}" | jq -r ". | length")

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Number of logs: ${echo_bold}${num_of_logs}${echo_normal}
"

num_of_logs_minus_one=$((num_of_logs-1))

##
## Init Progress Bar
##

init_progress "${num_of_logs}"


for log in $(seq 0 ${num_of_logs_minus_one})

do

(

echo "${logs}" | jq -r .["${log}"].line | ./exec-remote-socket.sh

) &

if [[ $(jobs -r -p | wc -l) -ge $threads ]]; then wait -n; fi

##
## Increment Progress Bar
##

inc_progress

done

wait

echo "
${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Finished!
"

##
## End "threading"
##

##
## End Timer
##

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))
import_duration_seconds=$((import_duration/1000000000))

echo -n "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Import Duration: ${echo_bold}"; show_progress_time ${import_duration_seconds}

echo "${echo_normal}
"

#echo "import_duration:${import_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},source=${function},station_name=${station_name_escaped} duration=${import_duration}"
done

exit 1

fi

##
## ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐┌─┐┌┬┐
## ├┬┘├┤ ││││ │ │ ├┤───├┤ │ │├┬┘├┤ │  ├─┤└─┐ │ 
## ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └  └─┘┴└─└─┘└─┘┴ ┴└─┘ ┴ 
##

if [ "${collector_type}" == "remote-forecast" ]

then

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Retrieving Logs From ${echo_bold}${logcli_host_url}${echo_normal}, Pushing Metrics to ${echo_bold}${influxdb_url}${echo_normal}."
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - collector_type=${echo_bold}${collector_type}${echo_normal}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - function=${echo_bold}${function}${echo_normal}"

for days_loop in $(seq "$import_days" -1 0) ; do

##
## Choose noon local as the collect log time to pull in the forecast
##

days_start=$(date --date="${days_loop} days ago 12:00" +%s)
days_end=$(("$days_start" + 1800))

date_start=$(date -d @"${days_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${days_end} --rfc-3339=seconds | sed 's/ /T/')

days_start_echo=$(date -d @"${days_start}")
days_end_echo=$(date -d @${days_end})

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Days Remaining: ${echo_bold}$days_loop${echo_normal}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - date_start: $date_start - ${days_start_echo}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - date_end: $date_end - ${days_end_echo}"

#echo "./logcli-linux-amd64 query --addr=\"${logcli_host_url}\" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app=\"weatherflow-collector\",collector_type=\""${collector_type}"\",station_name=\""${station_name}"\"}' | jq --slurp | jq -r .[0].line"
./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp | jq -r .[0].line | ./exec-remote-forecast.sh

done

exit 1

fi

##
## ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┬─┐┌─┐┌─┐┌┬┐
## ├┬┘├┤ ││││ │ │ ├┤───├┬┘├┤ └─┐ │ 
## ┴└─└─┘┴ ┴└─┘ ┴ └─┘  ┴└─└─┘└─┘ ┴ 
##

if [ "${collector_type}" == "remote-rest" ]

then

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Retrieving Logs From ${echo_bold}${logcli_host_url}${echo_normal}, Pushing Metrics to ${echo_bold}${influxdb_url}${echo_normal}."
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - collector_type=${echo_bold}${collector_type}${echo_normal}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - function=${echo_bold}${function}${echo_normal}"

hours=$((import_days * 24))

for hours_loop in $(seq "$hours" -1 0) ; do

hours_start=$(date --date="${hours_loop} hours ago 00:00" +%s)

hours_end=$(("$hours_start" + 3599))

date_start=$(date -d @"${hours_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${hours_end} --rfc-3339=seconds | sed 's/ /T/')

hours_start_echo=$(date -d @"${hours_start}")
hours_end_echo=$(date -d @${hours_end})

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Hour Slices Remaining: ${echo_bold}$hours_loop${echo_normal}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - date_start: $date_start - ${hours_start_echo}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - date_end: $date_end - ${hours_end_echo}"

##
## Start Timer
##

import_start=$(date +%s%N)

##
## Start "threading"
##

logs=$(./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp)

num_of_logs=$(echo "${logs}" | jq -r ". | length")

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Number of logs: ${echo_bold}${num_of_logs}${echo_normal}
"

num_of_logs_minus_one=$((num_of_logs-1))

##
## Init Progress Bar
##

init_progress "${num_of_logs}"

for log in $(seq 0 ${num_of_logs_minus_one})

do

(

echo "${logs}" | jq -r .["${log}"].line | ./exec-remote-rest.sh

) &

if [[ $(jobs -r -p | wc -l) -ge $threads ]]; then wait -n; fi

##
## Increment Progress Bar
##

inc_progress

done

wait

echo "
${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Finished!
"

##
## End "threading"
##

##
## End Timer
##

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))
import_duration_seconds=$((import_duration/1000000000))

echo -n "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Import Duration: ${echo_bold}"; show_progress_time ${import_duration_seconds}

echo "${echo_normal}
"

#echo "import_duration:${import_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},source=${function},station_name=${station_name_escaped} duration=${import_duration}"

done

exit 1

fi

##
## ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┬┌┬┐┌─┐┌─┐┬─┐┌┬┐
## ├┬┘├┤ ││││ │ │ ├┤───││││├─┘│ │├┬┘ │ 
## ┴└─└─┘┴ ┴└─┘ ┴ └─┘  ┴┴ ┴┴  └─┘┴└─ ┴ 
##

if [ "${collector_type}" == "remote-import" ]

then

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Retrieving Logs From ${echo_bold}https://swd.weatherflow.com/${echo_normal}, Pushing Metrics to ${echo_bold}${influxdb_url}${echo_normal}."
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - collector_type=${echo_bold}${collector_type}${echo_normal}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - function=${echo_bold}${function}${echo_normal}"

./start-remote-import.sh

exit 1

fi

fi

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - nothing to see here."