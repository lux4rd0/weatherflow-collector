#!/bin/bash

##
## WeatherFlow Collector - start.sh
##

##
## WeatherFlow-Collector Details
##

source weatherflow-collector_details.sh

echo "${echo_color_start}

 █     █░▓█████ ▄▄▄     ▄▄▄█████▓ ██░ ██ ▓█████  ██▀███    █████▒██▓     ▒█████   █     █░
▓█░ █ ░█░▓█   ▀▒████▄   ▓  ██▒ ▓▒▓██░ ██▒▓█   ▀ ▓██ ▒ ██▒▓██   ▒▓██▒    ▒██▒  ██▒▓█░ █ ░█░
▒█░ █ ░█ ▒███  ▒██  ▀█▄ ▒ ▓██░ ▒░▒██▀▀██░▒███   ▓██ ░▄█ ▒▒████ ░▒██░    ▒██░  ██▒▒█░ █ ░█ 
░█░ █ ░█ ▒▓█  ▄░██▄▄▄▄██░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄ ▒██▀▀█▄  ░▓█▒  ░▒██░    ▒██   ██░░█░ █ ░█ 
░░██▒██▓ ░▒████▒▓█   ▓██▒ ▒██▒ ░ ░▓█▒░██▓░▒████▒░██▓ ▒██▒░▒█░   ░██████▒░ ████▓▒░░░██▒██▓ 
░ ▓░▒ ▒  ░░ ▒░ ░▒▒   ▓▒█░ ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░░ ▒▓ ░▒▓░ ▒ ░   ░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  
  ▒ ░ ░   ░ ░  ░ ▒   ▒▒ ░   ░     ▒ ░▒░ ░ ░ ░  ░  ░▒ ░ ▒░ ░     ░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░  
  ░   ░     ░    ░   ▒    ░       ░  ░░ ░   ░     ░░   ░  ░ ░     ░ ░   ░ ░ ░ ▒    ░   ░  
    ░       ░  ░     ░  ░         ░  ░  ░   ░  ░   ░                ░  ░    ░ ░      ░    "


echo "${echo_color_remote_socket}
                                                                                          
       ▄████▄   ▒█████   ██▓     ██▓    ▓█████  ▄████▄  ▄▄▄█████▓ ▒█████   ██▀███         
      ▒██▀ ▀█  ▒██▒  ██▒▓██▒    ▓██▒    ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▒██▒  ██▒▓██ ▒ ██▒       
      ▒▓█    ▄ ▒██░  ██▒▒██░    ▒██░    ▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▒██░  ██▒▓██ ░▄█ ▒       
      ▒▓▓▄ ▄██▒▒██   ██░▒██░    ▒██░    ▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██   ██░▒██▀▀█▄         
      ▒ ▓███▀ ░░ ████▓▒░░██████▒░██████▒░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░ ████▓▒░░██▓ ▒██▒       
      ░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░▓  ░░ ▒░▓  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░       
        ░  ▒     ░ ▒ ▒░ ░ ░ ▒  ░░ ░ ▒  ░ ░ ░  ░  ░  ▒       ░      ░ ▒ ▒░   ░▒ ░ ▒░       
      ░        ░ ░ ░ ▒    ░ ░     ░ ░      ░   ░          ░      ░ ░ ░ ▒    ░░   ░        
      ░ ░          ░ ░      ░  ░    ░  ░   ░  ░░ ░                   ░ ░     ░            
      ░                                        ░                                          
"



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

if [ -z "${function}" ]; then echo "${echo_bold}start:${echo_normal} WEATHERFLOW_COLLECTOR_FUNCTION environmental variable not set. Defaulting to collector."; function="collector"; fi

if [ -z "${collector_type}" ]; then echo "${echo_bold}${echo_color_start}start:${echo_normal} WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE environmental variable not set. Defaulting to start."; collector_type="start"; fi

if [ -z "${threads}" ]; then echo "WEATHERFLOW_COLLECTOR_THREADS environmental variable not set. Defaulting to 4 thread"; threads="4"; fi

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal}  Starting WeatherFlow Collector (start.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
import_days=${import_days}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
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



#  ::::::::   ::::::::  :::        :::        :::::::::: :::::::: ::::::::::: ::::::::  :::::::::  
# :+:    :+: :+:    :+: :+:        :+:        :+:       :+:    :+:    :+:    :+:    :+: :+:    :+: 
# +:+        +:+    +:+ +:+        +:+        +:+       +:+           +:+    +:+    +:+ +:+    +:+ 
# +#+        +#+    +:+ +#+        +#+        +#++:++#  +#+           +#+    +#+    +:+ +#++:++#:  
# +#+        +#+    +#+ +#+        +#+        +#+       +#+           +#+    +#+    +#+ +#+    +#+ 
# #+#    #+# #+#    #+# #+#        #+#        #+#       #+#    #+#    #+#    #+#    #+# #+#    #+# 
#  ########   ########  ########## ########## ########## ########     ###     ########  ###    ### 

if [ "${function}" == "collector" ]

then

##
## Startup Collector Processes
##

# ┬ ┬┌─┐┌─┐┌┬┐  ┌─┐┌─┐┬─┐┌─┐┌─┐┬─┐┌┬┐┌─┐┌┐┌┌─┐┌─┐
# ├─┤│ │└─┐ │───├─┘├┤ ├┬┘├┤ │ │├┬┘│││├─┤││││  ├┤ 
# ┴ ┴└─┘└─┘ ┴   ┴  └─┘┴└─└  └─┘┴└─┴ ┴┴ ┴┘└┘└─┘└─┘

if [ "$disable_host_performance" != "true" ]; then
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Starting up host-performance."
while : ; do ./start-host-performance.sh ; done &
else
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} WEATHERFLOW_COLLECTOR_DISABLE_HOST_PERFORMANCE set to \"true\". Disabling host-performance."
export WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_HOST_PERFORMANCE="true"
fi

# ┬  ┌─┐┌─┐┌─┐┬   ┬ ┬┌┬┐┌─┐
# │  │ ││  ├─┤│───│ │ ││├─┘
# ┴─┘└─┘└─┘┴ ┴┴─┘ └─┘─┴┘┴  

if [ "$disable_local_udp" != "true" ]; then
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Starting up local-udp."
while : ; do ./start-local-udp.sh ; done &
else
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} WEATHERFLOW_COLLECTOR_DISABLE_LOCAL_UDP set to \"true\". Disabling local-udp."
export WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_LOCAL_UDP="true"
fi

# ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐┌─┐┌┬┐
# ├┬┘├┤ ││││ │ │ ├┤───├┤ │ │├┬┘├┤ │  ├─┤└─┐ │ 
# ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └  └─┘┴└─└─┘└─┘┴ ┴└─┘ ┴ 
                                                               

if [ "$disable_remote_forecast" != "true" ]; then
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Starting up remote-forecast."
while : ; do ./start-remote-forecast.sh ; done &
else
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_FORECAST set to \"true\". Disabling remote-forecast."
export WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_REMOTE_FORECAST="true"
fi

# ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┬─┐┌─┐┌─┐┌┬┐
# ├┬┘├┤ ││││ │ │ ├┤───├┬┘├┤ └─┐ │ 
# ┴└─└─┘┴ ┴└─┘ ┴ └─┘  ┴└─└─┘└─┘ ┴ 

if [ "$disable_remote_rest" != "true" ]; then
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Starting up remote-rest."
while : ; do ./start-remote-rest.sh ; done &
else
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_REST set to \"true\". Disabling remote-rest."
export WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_REMOTE_REST="true"
fi

# ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┌─┐┬┌─┌─┐┌┬┐
# ├┬┘├┤ ││││ │ │ ├┤───└─┐│ ││  ├┴┐├┤  │ 
# ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └─┘└─┘└─┘┴ ┴└─┘ ┴ 

if [ "$disable_remote_socket" != "true" ]; then
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Starting up remote-socket."
while : ; do ./start-remote-socket.sh ; done &
else
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_SOCKET set to \"true\". Disabling remote-socket."
export WEATHERFLOW_COLLECTOR_DISABLE_HEALTHCHECK_REMOTE_SOCKET="true"
fi

# ┬ ┬┌─┐┌─┐┬ ┌┬┐┬ ┬   ┌─┐┬ ┬┌─┐┌─┐┬┌─
# ├─┤├┤ ├─┤│  │ ├─┤───│  ├─┤├┤ │  ├┴┐
# ┴ ┴└─┘┴ ┴┴─┘┴ ┴ ┴   └─┘┴ ┴└─┘└─┘┴ ┴

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Starting up health-check."
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



# ┬  ┌─┐┌─┐┌─┐┬   ┬ ┬┌┬┐┌─┐
# │  │ ││  ├─┤│───│ │ ││├─┘
# ┴─┘└─┘└─┘┴ ┴┴─┘ └─┘─┴┘┴  

if [ "${collector_type}" == "local-udp" ]

then

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} collector_type=${collector_type}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} function=${function}"

hours=$(("$import_days" * 24))

for hours_loop in $(seq "$hours" -1 0) ; do
hours_start=$(date --date="${hours_loop} hours ago 00:00" +%s)
hours_end=$(("$hours_start" + 3599))
date_start=$(date -d @"${hours_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${hours_end} --rfc-3339=seconds | sed 's/ /T/')

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Hour Slices Remaining: $hours_loop"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} date_start: $date_start"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} date_end: $date_end"

##
## Start Timer
##

import_start=$(date +%s%N)

##
## Start "threading"
##

logs=$(./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp)
num_of_logs=$(echo "${logs}" | jq -r ". | length")
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Number of logs: ${num_of_logs}
"
num_of_logs_minus_one=$((num_of_logs-1))
for log in $(seq 0 ${num_of_logs_minus_one})
do

(

echo "${logs}" | jq -r .["${log}"].line | ./exec-local-udp.sh
) &

if [[ $(jobs -r -p | wc -l) -ge $threads ]]; then wait -n; ProgressBar "${log}" ${num_of_logs_minus_one}; fi

done

wait

echo "
${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Finished!
"

##
## End "threading"
##

##
## End Timer
##

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

#echo "import_duration:${import_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},source=${function},station_name=${station_name_escaped} duration=${import_duration}"
done
exit 1
fi

# ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┌─┐┬┌─┌─┐┌┬┐
# ├┬┘├┤ ││││ │ │ ├┤───└─┐│ ││  ├┴┐├┤  │ 
# ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └─┘└─┘└─┘┴ ┴└─┘ ┴ 

if [ "${collector_type}" == "remote-socket" ]

then

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} collector_type=${collector_type}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} function=${function}"

hours=$(("$import_days" * 24))

for hours_loop in $(seq "$hours" -1 0) ; do

hours_start=$(date --date="${hours_loop} hours ago 00:00" +%s)
hours_end=$(("$hours_start" + 3599))

date_start=$(date -d @"${hours_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${hours_end} --rfc-3339=seconds | sed 's/ /T/')

hours_start_echo=$(date -d @"${hours_start}")
hours_end_echo=$(date -d @${hours_end})

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Hour Slices Remaining: $hours_loop"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} date_start: $date_start - ${hours_start_echo}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} date_end: $date_end - ${hours_end_echo}"

##
## Start Timer
##

import_start=$(date +%s%N)

##
## Start "threading"
##

logs=$(./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp)

num_of_logs=$(echo "${logs}" | jq -r ". | length")

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Number of logs: ${num_of_logs}
"

num_of_logs_minus_one=$((num_of_logs-1))

for log in $(seq 0 ${num_of_logs_minus_one})

do

(

echo "${logs}" | jq -r .["${log}"].line | ./exec-remote-socket.sh

) &

if [[ $(jobs -r -p | wc -l) -ge $threads ]]; then wait -n; ProgressBar "${log}" ${num_of_logs_minus_one}; fi

done

wait

echo "
${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Finished!
"

##
## End "threading"
##

##
## End Timer
##

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

#echo "import_duration:${import_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},source=${function},station_name=${station_name_escaped} duration=${import_duration}"
done

exit 1

fi

# ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐┌─┐┌┬┐
# ├┬┘├┤ ││││ │ │ ├┤───├┤ │ │├┬┘├┤ │  ├─┤└─┐ │ 
# ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └  └─┘┴└─└─┘└─┘┴ ┴└─┘ ┴ 

if [ "${collector_type}" == "remote-forecast" ]

then

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} collector_type=${collector_type}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} function=${function}"

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

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Days Remaining: $days_loop"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} date_start: $date_start - ${days_start_echo}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} date_end: $date_end - ${days_end_echo}"

#echo "./logcli-linux-amd64 query --addr=\"${logcli_host_url}\" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app=\"weatherflow-collector\",collector_type=\""${collector_type}"\",station_name=\""${station_name}"\"}' | jq --slurp | jq -r .[0].line"
./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp | jq -r .[0].line | WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED="false" ./exec-remote-forecast.sh

done

exit 1

fi

# ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┬─┐┌─┐┌─┐┌┬┐
# ├┬┘├┤ ││││ │ │ ├┤───├┬┘├┤ └─┐ │ 
# ┴└─└─┘┴ ┴└─┘ ┴ └─┘  ┴└─└─┘└─┘ ┴ 

if [ "${collector_type}" == "remote-rest" ]

then

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} collector_type=${collector_type}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} function=${function}"

hours=$(("$import_days" * 24))

for hours_loop in $(seq "$hours" -1 0) ; do

hours_start=$(date --date="${hours_loop} hours ago 00:00" +%s)

hours_end=$(("$hours_start" + 3599))

date_start=$(date -d @"${hours_start}" --rfc-3339=seconds | sed 's/ /T/')
date_end=$(date -d @${hours_end} --rfc-3339=seconds | sed 's/ /T/')

hours_start_echo=$(date -d @"${hours_start}")
hours_end_echo=$(date -d @${hours_end})

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Hour Slices Remaining: $hours_loop"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} date_start: $date_start - ${hours_start_echo}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} date_end: $date_end - ${hours_end_echo}"

##
## Start Timer
##

import_start=$(date +%s%N)

##
## Start "threading"
##

logs=$(./logcli-linux-amd64 query --addr="${logcli_host_url}" -q --limit=100000 --timezone=Local --forward --from="${date_start}" --to="${date_end}" --output=jsonl '{app="weatherflow-collector",collector_type="'"${collector_type}"'",station_name="'"${station_name}"'"}' | jq --slurp)

num_of_logs=$(echo "${logs}" | jq -r ". | length")

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Number of logs: ${num_of_logs}
"

num_of_logs_minus_one=$((num_of_logs-1))

for log in $(seq 0 ${num_of_logs_minus_one})

do

(

echo "${logs}" | jq -r .["${log}"].line | WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED="false" ./exec-remote-rest.sh

) &

if [[ $(jobs -r -p | wc -l) -ge $threads ]]; then wait -n; ProgressBar "${log}" ${num_of_logs_minus_one}; fi

done

wait

echo "
${echo_bold}${echo_color_start}${collector_type}:${echo_normal} Finished!
"

##
## End "threading"
##

##
## End Timer
##

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

#echo "import_duration:${import_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},source=${function},station_name=${station_name_escaped} duration=${import_duration}"

done

exit 1

fi

# ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┬┌┬┐┌─┐┌─┐┬─┐┌┬┐
# ├┬┘├┤ ││││ │ │ ├┤───││││├─┘│ │├┬┘ │ 
# ┴└─└─┘┴ ┴└─┘ ┴ └─┘  ┴┴ ┴┴  └─┘┴└─ ┴ 

if [ "${collector_type}" == "remote-import" ]

then

echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} collector_type=${collector_type}"
echo "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} function=${function}"

./start-remote-import.sh

exit 1

fi






fi

echo "nothing to see here."