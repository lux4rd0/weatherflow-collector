#!/bin/bash

##
## WeatherFlow Collector - generate_docker-compose_aio.sh
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

echo "${echo_bold}WeatherFlow Collector${echo_normal} (generate_docker-compose_aio.sh) - https://github.com/lux4rd0/weatherflow-collector

collector_key=${echo_bold}${collector_key}${echo_normal} (using partial API key)
import_days=${echo_bold}${import_days}${echo_normal}
threads=${echo_bold}${threads}${echo_normal}
token=${echo_bold}${token}${echo_normal}
"

if [ -z "${import_days}" ]; then echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${echo_bold}WEATHERFLOW_COLLECTOR_IMPORT_DAYS${echo_normal} variable was not set. Setting defaults: ${echo_bold}10${echo_normal} days"; import_days="10"; fi

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
## ┌┬┐┌─┐┌─┐┬┌─┌─┐┬─┐   ┌─┐┌─┐┌┬┐┌─┐┌─┐┌─┐┌─┐┬ ┬┌┬┐┬  
##  │││ ││  ├┴┐├┤ ├┬┘───│  │ ││││├─┘│ │└─┐├┤ └┬┘││││  
## ─┴┘└─┘└─┘┴ ┴└─┘┴└─   └─┘└─┘┴ ┴┴  └─┘└─┘└─┘o┴ ┴ ┴┴─┘
##

echo "

networks:
  wxfdashboardsaio: {}
services:
  wxfdashboardsaio_grafana:
    container_name: wxfdashboardsaio_grafana
    environment:
      GF_AUTH_ANONYMOUS_ENABLED: \"true\"
      GF_AUTH_ANONYMOUS_ORG_ROLE: Viewer
      GF_AUTH_BASIC_ENABLED: \"true\"
      GF_AUTH_DISABLE_LOGIN_FORM: \"false\"
      GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH: /var/lib/grafana/dashboards/weatherflow_collector/weatherflow_collector-overview-influxdb.json
      GF_INSTALL_PLUGINS: grafana-worldmap-panel
    image: grafana/grafana:8.0.1
    networks:
      wxfdashboardsaio:
    ports:
    - protocol: tcp
      published: 3000
      target: 3000
    restart: always
    volumes:
    - ./config/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources:ro
    - ./config/grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards:ro
    - ./config/grafana/dashboards:/var/lib/grafana/dashboards:ro
  wxfdashboardsaio_influxdb:
    container_name: wxfdashboardsaio_influxdb
    environment: 
      INFLUXDB_ADMIN_PASSWORD: Gk372Qm70E0xGVIcUpSyRiwqfAyhuwkS
      INFLUXDB_ADMIN_USER: admin
      INFLUXDB_DATA_ENGINE: tsm1
      INFLUXDB_DB: weatherflow
      INFLUXDB_HTTP_LOG_ENABLED: \"false\"
      INFLUXDB_LOGGING_FORMAT: json
      INFLUXDB_LOGGING_LEVEL: info
      INFLUXDB_MONITOR_STORE_DATABASE: _internal
      INFLUXDB_MONITOR_STORE_ENABLED: \"true\"
      INFLUXDB_REPORTING_DISABLED: \"true\"
      INFLUXDB_USER: weatherflow
      INFLUXDB_USER_PASSWORD: x8egQTrf4bGl8Cs3XGyF1yE0b06pfgJe
    image: influxdb:1.8
    networks:
      wxfdashboardsaio:
    ports:
    - protocol: tcp
      published: 8086
      target: 8086
    restart: always
    volumes:
    - ./data/influxdb:/var/lib/influxdb:rw
  wxfdashboardsaio-collector:
    container_name: wxfdashboardsaio-collector
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
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: x8egQTrf4bGl8Cs3XGyF1yE0b06pfgJe
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: http://wxfdashboardsaio_influxdb:8086/write?db=weatherflow
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: weatherflow
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    networks:
      wxfdashboardsaio:
    restart: always
    depends_on:
      - \"wxfdashboardsaio_influxdb\"
    image: lux4rd0/weatherflow-collector:latest
    ports:
    - protocol: udp
      published: 50222
      target: 50222
    restart: always
version: '3.3'" >> docker-compose.yml


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

echo "docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-remote-import \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-import \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEBUG_CURL=false \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HEALTHCHECK=true \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=x8egQTrf4bGl8Cs3XGyF1yE0b06pfgJe \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=http://$(hostname):8086/write?db=weatherflow \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=weatherflow \\
  -e WEATHERFLOW_COLLECTOR_STATION_ID=\"${station_id[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_remote[$station_number]}"

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${FILE_import_remote[$station_number]} file created"

done

echo "${echo_bold}${echo_color_weatherflow}weatherflow-collector:${echo_normal} ${FILE_DC} file created"

fi