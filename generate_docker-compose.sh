#!/bin/bash

##
## WeatherFlow Collector - generate_docker-compose.sh
##

import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
logcli_host_url=$WEATHERFLOW_COLLECTOR_LOGCLI_URL
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
threads=$WEATHERFLOW_COLLECTOR_THREADS
token=$WEATHERFLOW_COLLECTOR_TOKEN

collector_key=$(echo "${WEATHERFLOW_COLLECTOR_TOKEN}" | awk -F"-" '{print $1}')

echo_bold=$(tput -T xterm bold)
echo_color_weatherflow=$(echo -e "\e[3$(( RANDOM * 6 / 32767 + 1 ))m")
echo_color_collector=$(echo -e "\e[3$(( RANDOM * 6 / 32767 + 1 ))m")
echo_normal=$(tput -T xterm sgr0)


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

echo "${echo_bold}WeatherFlow Collector${echo_normal} (generate_docker-compose.sh) - https://github.com/lux4rd0/weatherflow-collector

collector_key=${echo_bold}${collector_key}${echo_normal} (using partial API key)
import_days=${echo_bold}${import_days}${echo_normal}
influxdb_password=${echo_bold}${influxdb_password}${echo_normal}
influxdb_url=${echo_bold}${influxdb_url}${echo_normal}
influxdb_username=${echo_bold}${influxdb_username}${echo_normal}
logcli_host_url=${echo_bold}${logcli_host_url}${echo_normal}
loki_client_url=${echo_bold}${loki_client_url}${echo_normal}
threads=${echo_bold}${threads}${echo_normal}
token=${echo_bold}${token}${echo_normal}
"

if [ -z "${import_days}" ]; then echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${echo_bold}WEATHERFLOW_COLLECTOR_IMPORT_DAYS${echo_normal} variable was not set. Setting defaults: ${echo_bold}10${echo_normal} days"; import_days="10"; fi

if [ -z "${influxdb_password}" ]; then echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${echo_bold}WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD${echo_normal} was not set. Setting defaults: ${echo_bold}password${echo_normal}"; influxdb_password="password"; fi

if [ -z "${influxdb_url}" ]; then echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${echo_bold}WEATHERFLOW_COLLECTOR_INFLUXDB_URL${echo_normal} was not set. Setting defaults: ${echo_bold}http://influxdb:8086/write?db=weatherflow${echo_normal}"; influxdb_url="http://influxdb:8086/write?db=weatherflow" ; fi

if [ -z "${influxdb_username}" ]; then echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${echo_bold}WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME${echo_normal} was not set. Setting defaults: ${echo_bold}influxdb${echo_normal}"; influxdb_username="influxdb"; fi

if [ -z "${threads}" ]; then echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${echo_bold}WEATHERFLOW_COLLECTOR_THREADS${echo_normal} was not set. Setting defaults: ${echo_bold}4${echo_normal} threads."; threads="4"; fi

if [ -z "${token}" ]; then echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${echo_bold}WEATHERFLOW_COLLECTOR_TOKEN${echo_normal} was not set. Missing authentication token. Please provide your token as an environmental variable."; exit 1; fi

else

url_stations="https://swd.weatherflow.com/swd/rest/stations?token=${token}"

#echo "url_stations=${url_stations}"

response_url_stations=$(curl -si -w "\n%{size_header},%{size_download}" "${url_stations}")

##
## Extract the response header size
##

header_size_stations=$(sed -n '$ s/^\([0-9]*\),.*$/\1/ p' <<< "${response_url_stations}")

##
## Extract the response body size
##

body_size_stations=$(sed -n '$ s/^.*,\([0-9]*\)$/\1/ p' <<< "${response_url_stations}")

##
## Extract the response body
##

body_station="${response_url_stations:${header_size_stations}:${body_size_stations}}"

number_of_stations=$(echo "${body_station}" |jq '.stations | length')

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} Number of Stations: ${echo_bold}${number_of_stations}${echo_normal}"

number_of_stations_minus_one=$((number_of_stations-1))

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

station_name[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].name)
station_name_dc[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].name | sed 's/ /\_/g' | sed 's/.*/\L&/' | sed 's|[<>,]||g')
station_id[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].station_id)

done

FILE_DC="${PWD}/docker-compose.yml"

if test -f "${FILE_DC}"; then
existing_file_timestamp_dc=$(date -r "${FILE_DC}" "+%Y%m%d-%H%M%S")
echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} Existing ${echo_bold}${FILE_DC}${echo_normal} with a timestamp of ${echo_bold}${existing_file_timestamp_dc}${echo_normal} file found. Backup up file to ${FILE_DC}.${existing_file_timestamp_dc}.old"
mv "${FILE_DC}" "${FILE_DC}"."${existing_file_timestamp_dc}.old"
fi

##
## Loop through each device
##

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

##
## ╦═╗┌─┐┌┬┐┌─┐┌┬┐┌─┐  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐
## ╠╦╝├┤ ││││ │ │ ├┤   ║│││├─┘│ │├┬┘ │ 
## ╩╚═└─┘┴ ┴└─┘ ┴ └─┘  ╩┴ ┴┴  └─┘┴└─ ┴ 
##

FILE_import_remote[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-remote-import.sh"
if test -f "${FILE_import_remote[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_remote[$station_number]}" "+%Y%m%d-%H%M%S")

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} Existing ${echo_bold}${FILE_import_remote[$station_number]}${echo_normal} file found. Backup up file to ${FILE_import_remote[$station_number]}.${existing_file_timestamp[$station_number]}.old"

mv "${FILE_import_remote[$station_number]}" "${FILE_import_remote[$station_number]}"."${existing_file_timestamp[$station_number]}.old"

fi

##
## Only create Loki Import files if logcli_host_url is set
##

if [ -n "$logcli_host_url" ]

then

##
## ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬  ┌─┐┌─┐┌─┐┬   ┬ ┬┌┬┐┌─┐
## ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  │  │ ││  ├─┤│───│ │ ││├─┘
## ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴─┘└─┘└─┘┴ ┴┴─┘ └─┘─┴┘┴  
##

FILE_import_loki_local_udp[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-local-udp.sh"
if test -f "${FILE_import_loki_local_udp[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_local_udp[$station_number]}" "+%Y%m%d-%H%M%S")

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} Existing ${echo_bold}${FILE_import_loki_local_udp[$station_number]}${echo_normal} file found. Backup up file to ${FILE_import_loki_local_udp[$station_number]}.${existing_file_timestamp[$station_number]}.old"

mv "${FILE_import_loki_local_udp[$station_number]}" "${FILE_import_loki_local_udp[$station_number]}"."${existing_file_timestamp[$station_number]}.old"

fi

##
## ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐┌─┐┌┬┐
## ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───├┤ │ │├┬┘├┤ │  ├─┤└─┐ │ 
## ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └  └─┘┴└─└─┘└─┘┴ ┴└─┘ ┴ 
##

FILE_import_loki_remote_forecast[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-remote-forecast.sh"
if test -f "${FILE_import_loki_remote_forecast[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_remote_forecast[$station_number]}" "+%Y%m%d-%H%M%S")

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} Existing ${echo_bold}${FILE_import_loki_remote_forecast[$station_number]}${echo_normal} file found. Backup up file to ${FILE_import_loki_remote_forecast[$station_number]}.${existing_file_timestamp[$station_number]}.old"

mv "${FILE_import_loki_remote_forecast[$station_number]}" "${FILE_import_loki_remote_forecast[$station_number]}"."${existing_file_timestamp[$station_number]}.old"

fi

##
## ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┬─┐┌─┐┌─┐┌┬┐
## ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───├┬┘├┤ └─┐ │ 
## ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  ┴└─└─┘└─┘ ┴ 
##

FILE_import_loki_remote_rest[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-remote-rest.sh"
if test -f "${FILE_import_loki_remote_rest[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_remote_rest[$station_number]}" "+%Y%m%d-%H%M%S")

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} Existing ${echo_bold}${FILE_import_loki_remote_rest[$station_number]}${echo_normal} file found. Backup up file to ${FILE_import_loki_remote_rest[$station_number]}.${existing_file_timestamp[$station_number]}.old"

mv "${FILE_import_loki_remote_rest[$station_number]}" "${FILE_import_loki_remote_rest[$station_number]}"."${existing_file_timestamp[$station_number]}.old"

fi

##
## ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┌─┐┬┌─┌─┐┌┬┐
## ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───└─┐│ ││  ├┴┐├┤  │ 
## ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └─┘└─┘└─┘┴ ┴└─┘ ┴ 
##

FILE_import_loki_remote_socket[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-remote-socket.sh"
if test -f "${FILE_import_loki_remote_socket[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_remote_socket[$station_number]}" "+%Y%m%d-%H%M%S")

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} Existing ${echo_bold}${FILE_import_loki_remote_socket[$station_number]}${echo_normal} file found. Backup up file to ${FILE_import_loki_remote_socket[$station_number]}.${existing_file_timestamp[$station_number]}.old"

mv "${FILE_import_loki_remote_socket[$station_number]}" "${FILE_import_loki_remote_socket[$station_number]}"."${existing_file_timestamp[$station_number]}.old"

fi
fi

##
## ┌┬┐┌─┐┌─┐┬┌─┌─┐┬─┐   ┌─┐┌─┐┌┬┐┌─┐┌─┐┌─┐┌─┐┬ ┬┌┬┐┬  
##  │││ ││  ├┴┐├┤ ├┬┘───│  │ ││││├─┘│ │└─┐├┤ └┬┘││││  
## ─┴┘└─┘└─┘┴ ┴└─┘┴└─   └─┘└─┘┴ ┴┴  └─┘└─┘└─┘o┴ ┴ ┴┴─┘
##

echo "services:
  weatherflow-collector:
    container_name: weatherflow-collector-${collector_key}
    environment:
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEBUG_CURL: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_HEALTH_CHECK: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_HOST_PERFORMANCE: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_LOCAL_UDP: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_FORECAST: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_REST: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_SOCKET: \"false\"
      WEATHERFLOW_COLLECTOR_HEALTHCHECK: \"true\"
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: ${influxdb_password}
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: ${influxdb_url}
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: ${influxdb_username}" > docker-compose.yml

if [ -n "$loki_client_url" ]

then

echo "WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL: ${loki_client_url}" >> docker-compose.yml

fi

echo "WEATHERFLOW_COLLECTOR_THREADS: ${threads}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    ports:
    - protocol: udp
      published: 50222
      target: 50222
    restart: always
version: '3.3'" >> docker-compose.yml


##
## ╦═╗┌─┐┌┬┐┌─┐┌┬┐┌─┐  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐
## ╠╦╝├┤ ││││ │ │ ├┤   ║│││├─┘│ │├┬┘ │ 
## ╩╚═└─┘┴ ┴└─┘ ┴ └─┘  ╩┴ ┴┴  └─┘┴└─ ┴ 
##

echo "docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-remote-import \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-import \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEBUG_CURL=false \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HEALTHCHECK=true \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=${influxdb_password} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=${influxdb_url} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=${influxdb_username} \\
  -e WEATHERFLOW_COLLECTOR_LOGCLI_URL=${logcli_host_url} \\
  -e WEATHERFLOW_COLLECTOR_STATION_ID=\"${station_id[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_remote[$station_number]}"

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${FILE_import_remote[$station_number]} file created"

##
## Only create Loki Import files if logcli_host_url is set
##

if [ -n "$logcli_host_url" ]

then

##
## ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐┌─┐┌┬┐
## ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───├┤ │ │├┬┘├┤ │  ├─┤└─┐ │ 
## ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └  └─┘┴└─└─┘└─┘┴ ┴└─┘ ┴ 
##

echo "docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-remote-forecast \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-forecast \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEBUG_CURL=false \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HEALTHCHECK=true \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=${influxdb_password} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=${influxdb_url} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=${influxdb_username} \\
  -e WEATHERFLOW_COLLECTOR_LOGCLI_URL=${logcli_host_url} \\
  -e WEATHERFLOW_COLLECTOR_STATION_NAME=\"${station_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_loki_remote_forecast[$station_number]}"

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${FILE_import_loki_remote_forecast[$station_number]} file created"

##
## ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┬─┐┌─┐┌─┐┌┬┐
## ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───├┬┘├┤ └─┐ │ 
## ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  ┴└─└─┘└─┘ ┴ 
##

echo "docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-remote-rest \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-rest \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEBUG_CURL=false \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HEALTHCHECK=true \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=${influxdb_password} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=${influxdb_url} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=${influxdb_username} \\
  -e WEATHERFLOW_COLLECTOR_LOGCLI_URL=${logcli_host_url} \\
  -e WEATHERFLOW_COLLECTOR_STATION_NAME=\"${station_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_loki_remote_rest[$station_number]}"

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${FILE_import_loki_remote_rest[$station_number]} file created"

##
## ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┌─┐┬┌─┌─┐┌┬┐
## ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───└─┐│ ││  ├┴┐├┤  │ 
## ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └─┘└─┘└─┘┴ ┴└─┘ ┴ 
##

echo "docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-remote-socket \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-socket \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEBUG_CURL=false \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HEALTHCHECK=true \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=${influxdb_password} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=${influxdb_url} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=${influxdb_username} \\
  -e WEATHERFLOW_COLLECTOR_LOGCLI_URL=${logcli_host_url} \\
  -e WEATHERFLOW_COLLECTOR_STATION_NAME=\"${station_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_loki_remote_socket[$station_number]}"

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${FILE_import_loki_remote_socket[$station_number]} file created"

##
## ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬  ┌─┐┌─┐┌─┐┬   ┬ ┬┌┬┐┌─┐
## ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  │  │ ││  ├─┤│───│ │ ││├─┘
## ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴─┘└─┘└─┘┴ ┴┴─┘ └─┘─┴┘┴  
##

echo "docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-local-udp \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=local-udp \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEBUG_CURL=false \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HEALTHCHECK=true \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=${influxdb_password} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=${influxdb_url} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=${influxdb_username} \\
  -e WEATHERFLOW_COLLECTOR_LOGCLI_URL=${logcli_host_url} \\
  -e WEATHERFLOW_COLLECTOR_STATION_NAME=\"${station_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_loki_local_udp[$station_number]}"

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${FILE_import_loki_local_udp[$station_number]} file created"

fi

done

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${FILE_DC} file created"

fi