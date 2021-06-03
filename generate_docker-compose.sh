#!/bin/bash

##
## WeatherFlow Collector - docker-compose.yml generator
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


echo "${echo_color_weatherflow}

 █     █░▓█████ ▄▄▄     ▄▄▄█████▓ ██░ ██ ▓█████  ██▀███    █████▒██▓     ▒█████   █     █░
▓█░ █ ░█░▓█   ▀▒████▄   ▓  ██▒ ▓▒▓██░ ██▒▓█   ▀ ▓██ ▒ ██▒▓██   ▒▓██▒    ▒██▒  ██▒▓█░ █ ░█░
▒█░ █ ░█ ▒███  ▒██  ▀█▄ ▒ ▓██░ ▒░▒██▀▀██░▒███   ▓██ ░▄█ ▒▒████ ░▒██░    ▒██░  ██▒▒█░ █ ░█ 
░█░ █ ░█ ▒▓█  ▄░██▄▄▄▄██░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄ ▒██▀▀█▄  ░▓█▒  ░▒██░    ▒██   ██░░█░ █ ░█ 
░░██▒██▓ ░▒████▒▓█   ▓██▒ ▒██▒ ░ ░▓█▒░██▓░▒████▒░██▓ ▒██▒░▒█░   ░██████▒░ ████▓▒░░░██▒██▓ 
░ ▓░▒ ▒  ░░ ▒░ ░▒▒   ▓▒█░ ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░░ ▒▓ ░▒▓░ ▒ ░   ░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  
  ▒ ░ ░   ░ ░  ░ ▒   ▒▒ ░   ░     ▒ ░▒░ ░ ░ ░  ░  ░▒ ░ ▒░ ░     ░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░  
  ░   ░     ░    ░   ▒    ░       ░  ░░ ░   ░     ░░   ░  ░ ░     ░ ░   ░ ░ ░ ▒    ░   ░  
    ░       ░  ░     ░  ░         ░  ░  ░   ░  ░   ░                ░  ░    ░ ░      ░    "


echo "${echo_color_collector}
                                                                                          
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

echo "${echo_normal}"

echo "${echo_bold}WeatherFlow Collector${echo_normal} (generate_docker-compose.sh) - https://github.com/lux4rd0/weatherflow-collector

collector_key=${collector_key}
import_days=${import_days}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
threads=${threads}
token=${token}
"

if [ -z "${import_days}" ]; then echo "WEATHERFLOW_COLLECTOR_IMPORT_DAYS variable was not set. Defaulting to 365 days"; import_days="365"; fi

if [ -z "${influxdb_password}" ]; then echo "WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD was not set. Setting defaults: password"; influxdb_password="password"; fi

if [ -z "${influxdb_url}" ]; then echo "WEATHERFLOW_COLLECTOR_INFLUXDB_URL was not set. Setting defaults: http://influxdb:8086/write?db=weatherflow"; influxdb_url="http://influxdb:8086/write?db=weatherflow" ; fi

if [ -z "${influxdb_username}" ]; then echo "WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME was not set. Setting defaults: influxdb"; influxdb_username="influxdb"; fi

if [ -z "${threads}" ]; then echo "WEATHERFLOW_COLLECTOR_THREADS was not set. Setting defaults: 4"; threads="4"; fi

if [ -z "${token}" ]; then echo "Missing authentication token. Please provide your token as an environmental variable."

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

#echo "Number of Stations: ${number_of_stations}"

number_of_stations_minus_one=$((number_of_stations-1))

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

#echo "Station Number Loop: $station_number"

station_name[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].name)
station_name_dc[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].name | sed 's/ /\_/g' | sed 's/.*/\L&/' | sed 's|[<>,]||g')

done

FILE_DC="${PWD}/docker-compose.yml"

if test -f "${FILE_DC}"; then
existing_file_timestamp_dc=$(date -r "${FILE_DC}" "+%Y%m%d-%H%M%S")
echo "Existing ${FILE_DC} with a timestamp of ${existing_file_timestamp_dc} file found. Backup up file to ${FILE_DC}.${existing_file_timestamp_dc}"
mv "${FILE_DC}" "${FILE_DC}"."${existing_file_timestamp_dc}"
fi

##
## Loop through each device
##

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

# ╦═╗┌─┐┌┬┐┌─┐┌┬┐┌─┐  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐
# ╠╦╝├┤ ││││ │ │ ├┤   ║│││├─┘│ │├┬┘ │ 
# ╩╚═└─┘┴ ┴└─┘ ┴ └─┘  ╩┴ ┴┴  └─┘┴└─ ┴ 

FILE_import_remote[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-remote-import.sh"
if test -f "${FILE_import_remote[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_remote[$station_number]}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE_import_remote[$station_number]} file found. Backup up file to ${FILE_import_remote[$station_number]}.${existing_file_timestamp[$station_number]}"

mv "${FILE_import_remote[$station_number]}" "${FILE_import_remote[$station_number]}"."${existing_file_timestamp[$station_number]}"

fi

##
## Only create Loki Import files if logcli_host_url is set
##

if [ -n "$logcli_host_url" ]

then

# ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬  ┌─┐┌─┐┌─┐┬   ┬ ┬┌┬┐┌─┐
# ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  │  │ ││  ├─┤│───│ │ ││├─┘
# ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴─┘└─┘└─┘┴ ┴┴─┘ └─┘─┴┘┴  

FILE_import_loki_local_udp[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-loki-local-udp.sh"
if test -f "${FILE_import_loki_local_udp[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_local_udp[$station_number]}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE_import_loki_local_udp[$station_number]} file found. Backup up file to ${FILE_import_loki_local_udp[$station_number]}.${existing_file_timestamp[$station_number]}"

mv "${FILE_import_loki_local_udp[$station_number]}" "${FILE_import_loki_local_udp[$station_number]}"."${existing_file_timestamp[$station_number]}"

fi

# ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐┌─┐┌┬┐
# ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───├┤ │ │├┬┘├┤ │  ├─┤└─┐ │ 
# ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └  └─┘┴└─└─┘└─┘┴ ┴└─┘ ┴ 

FILE_import_loki_remote_forecast[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-loki-remote-forecast.sh"
if test -f "${FILE_import_loki_remote_forecast[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_remote_forecast[$station_number]}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE_import_loki_remote_forecast[$station_number]} file found. Backup up file to ${FILE_import_loki_remote_forecast[$station_number]}.${existing_file_timestamp[$station_number]}"

mv "${FILE_import_loki_remote_forecast[$station_number]}" "${FILE_import_loki_remote_forecast[$station_number]}"."${existing_file_timestamp[$station_number]}"

fi

# ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┬─┐┌─┐┌─┐┌┬┐
# ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───├┬┘├┤ └─┐ │ 
# ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  ┴└─└─┘└─┘ ┴ 

FILE_import_loki_remote_rest[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-loki-remote-rest.sh"
if test -f "${FILE_import_loki_remote_rest[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_remote_rest[$station_number]}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE_import_loki_remote_rest[$station_number]} file found. Backup up file to ${FILE_import_loki_remote_rest[$station_number]}.${existing_file_timestamp[$station_number]}"

mv "${FILE_import_loki_remote_rest[$station_number]}" "${FILE_import_loki_remote_rest[$station_number]}"."${existing_file_timestamp[$station_number]}"

fi

# ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┌─┐┬┌─┌─┐┌┬┐
# ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───└─┐│ ││  ├┴┐├┤  │ 
# ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └─┘└─┘└─┘┴ ┴└─┘ ┴ 

FILE_import_loki_remote_socket[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-loki-remote-socket.sh"
if test -f "${FILE_import_loki_remote_socket[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_remote_socket[$station_number]}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE_import_loki_remote_socket[$station_number]} file found. Backup up file to ${FILE_import_loki_remote_socket[$station_number]}.${existing_file_timestamp[$station_number]}"

mv "${FILE_import_loki_remote_socket[$station_number]}" "${FILE_import_loki_remote_socket[$station_number]}"."${existing_file_timestamp[$station_number]}"

fi

fi



# ┌┬┐┌─┐┌─┐┬┌─┌─┐┬─┐   ┌─┐┌─┐┌┬┐┌─┐┌─┐┌─┐┌─┐┬ ┬┌┬┐┬  
#  │││ ││  ├┴┐├┤ ├┬┘───│  │ ││││├─┘│ │└─┐├┤ └┬┘││││  
# ─┴┘└─┘└─┘┴ ┴└─┘┴└─   └─┘└─┘┴ ┴┴  └─┘└─┘└─┘o┴ ┴ ┴┴─┘

echo "
services:
  weatherflow-collector:
    container_name: weatherflow-collector-$(hostname | awk -F. '{ print $1 }')-${collector_key}
    environment:
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEBUG_CURL: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_HEALTH_CHECK: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_HOST_PERFORMANCE: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_LOCAL_UDP: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_FORECAST: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_REST: \"false\"
      WEATHERFLOW_COLLECTOR_DISABLE_REMOTE_SOCKET: \"false\"
      WEATHERFLOW_COLLECTOR_FUNCTION: collector
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: ${influxdb_password}
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: ${influxdb_url}
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: ${influxdb_username}
" > docker-compose.yml

if [ -n "$loki_client_url" ]

then

echo "
      WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL: ${loki_client_url}
" >> docker-compose.yml

fi

echo "
      WEATHERFLOW_COLLECTOR_THREADS: ${threads}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    ports:
    - protocol: udp
      published: 50222
      target: 50222
    restart: always
version: '3.3'
" >> docker-compose.yml



# ╦═╗┌─┐┌┬┐┌─┐┌┬┐┌─┐  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐
# ╠╦╝├┤ ││││ │ │ ├┤   ║│││├─┘│ │├┬┘ │ 
# ╩╚═└─┘┴ ┴└─┘ ┴ └─┘  ╩┴ ┴┴  └─┘┴└─ ┴ 

echo "

docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-remote-import \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-import \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEBUG_CURL=false \\
  -e WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED=false \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=${influxdb_password} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=${influxdb_url} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=${influxdb_username} \\
  -e WEATHERFLOW_COLLECTOR_LOGCLI_URL=${logcli_host_url} \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_remote[$station_number]}"

echo "${FILE_import_remote[$station_number]} file created"

##
## Only create Loki Import files if logcli_host_url is set
##

if [ -n "$logcli_host_url" ]

then

# ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐┌─┐┌┬┐
# ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───├┤ │ │├┬┘├┤ │  ├─┤└─┐ │ 
# ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └  └─┘┴└─└─┘└─┘┴ ┴└─┘ ┴ 



echo "

docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-loki-remote-forecast \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-forecast \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEBUG_CURL=false \\
  -e WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED=false \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
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

echo "${FILE_import_loki_remote_forecast[$station_number]} file created"

# ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┬─┐┌─┐┌─┐┌┬┐
# ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───├┬┘├┤ └─┐ │ 
# ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  ┴└─└─┘└─┘ ┴ 

echo "

docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-loki-remote-rest \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-rest \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEBUG_CURL=false \\
  -e WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED=false \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
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

echo "${FILE_import_loki_remote_rest[$station_number]} file created"

# ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬─┐┌─┐┌┬┐┌─┐┌┬┐┌─┐  ┌─┐┌─┐┌─┐┬┌─┌─┐┌┬┐
# ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  ├┬┘├┤ ││││ │ │ ├┤───└─┐│ ││  ├┴┐├┤  │ 
# ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴└─└─┘┴ ┴└─┘ ┴ └─┘  └─┘└─┘└─┘┴ ┴└─┘ ┴ 

echo "

docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-loki-remote-socket \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-socket \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEBUG_CURL=false \\
  -e WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED=false \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
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

echo "${FILE_import_loki_remote_socket[$station_number]} file created"

# ╦  ┌─┐┬┌─┬  ╦┌┬┐┌─┐┌─┐┬─┐┌┬┐       ┬  ┌─┐┌─┐┌─┐┬   ┬ ┬┌┬┐┌─┐
# ║  │ │├┴┐│  ║│││├─┘│ │├┬┘ │   ───  │  │ ││  ├─┤│───│ │ ││├─┘
# ╩═╝└─┘┴ ┴┴  ╩┴ ┴┴  └─┘┴└─ ┴        ┴─┘└─┘└─┘┴ ┴┴─┘ └─┘─┴┘┴  

echo "

docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-loki-local-udp \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=local-udp \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEBUG_CURL=false \\
  -e WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED=false \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
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

echo "${FILE_import_loki_local_udp[$station_number]} file created"

fi



done

echo "${FILE_DC} file created"

fi