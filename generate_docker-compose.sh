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
perf_interval=$WEATHERFLOW_COLLECTOR_PERF_INTERVAL
threads=$WEATHERFLOW_COLLECTOR_THREADS
token=$WEATHERFLOW_COLLECTOR_TOKEN

echo "
import_days=${import_days}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
perf_interval=${perf_interval}}
threads=${threads}
token=${token}
"

if [ -z "${import_days}" ]
  then
    echo "WEATHERFLOW_COLLECTOR_IMPORT_DAYS variable not set. Defaulting to 365 days"

import_days="365"

fi

if [ -z "${influxdb_url}" ]
  then
    echo "WEATHERFLOW_COLLECTOR_INFLUXDB_URL was not set. Setting defaults: http://influxdb:8086/write?db=weatherflow"

influxdb_url="http://influxdb:8086/write?db=weatherflow"

fi

if [ -z "${influxdb_username}" ]
  then
    echo "WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME was not set. Setting defaults: influxdb."

influxdb_username="influxdb"

fi

if [ -z "${influxdb_password}" ]
  then
    echo "WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD was not set. Setting defaults: password"

influxdb_password="password"

fi

if [ -z "${threads}" ]
  then
    echo "WEATHERFLOW_COLLECTOR_THREADS was not set. Setting defaults: 4"

threads="4"

fi

if [ -z "${perf_interval}" ]
  then
    echo "WEATHERFLOW_COLLECTOR_PERF_INTERVAL environmental variable not set. Defaulting to 60 seconds"

perf_interval="60"


if [ -z "$token" ]

then
      echo "Missing authentication token. Please provide your token as a command parameter."
else

url_stations="https://swd.weatherflow.com/swd/rest/stations?token=${token}"

#echo "url_stations=${url_stations}"

url_forecasts="https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${station_id}&token=${token}"

#echo "url_forecasts=${url_forecasts}"

url_observations="https://swd.weatherflow.com/swd/rest/observations/station/${station_id}?token=${token}"

#echo "url_observations=${url_observations}"

response_url_stations=$(curl -si -w "\n%{size_header},%{size_download}" "${url_stations}")
response_url_forecasts=$(curl -si -w "\n%{size_header},%{size_download}" "${url_forecasts}")
response_url_observations=$(curl -si -w "\n%{size_header},%{size_download}" "${url_observations}")

# Extract the response header size
header_size_stations=$(sed -n '$ s/^\([0-9]*\),.*$/\1/ p' <<< "${response_url_stations}")

# Extract the response body size
body_size_stations=$(sed -n '$ s/^.*,\([0-9]*\)$/\1/ p' <<< "${response_url_stations}")

# Extract the response headers
headers_station="${response_url_stations:0:${header_size_stations}}"

# Extract the response body
body_station="${response_url_stations:${header_size_stations}:${body_size_stations}}"


#echo "URL Results"

#echo "${header_size_stations}"

#echo "${body_size_stations}"

#echo "${headers_station}"

#echo "${body_station}"

number_of_stations=$(echo "${body_station}" |jq '.stations | length')

#echo "Number of Stations: ${number_of_stations}"

number_of_stations_minus_one=$((number_of_stations-1))

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

#echo "Station Number Loop: $station_number"

timezone[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].timezone)
latitude[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].latitude)
longitude[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].longitude)
elevation[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].station_meta.elevation)
public_name[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].public_name)
station_name[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].name)
station_name_dc[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].name | sed 's/ /\_/g' | sed 's/.*/\L&/' | sed 's|[<>,]||g')
station_id[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].station_id)
device_id[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].devices[1].device_id)
hub_sn[$station_number]=$(echo "${body_station}" |jq -r .stations[$station_number].devices[0].serial_number)

done

FILE_DC="${PWD}/docker-compose.yml"
if test -f "${FILE_DC}"; then

existing_file_timestamp_dc=$(date -r "${FILE_DC}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE_DC} with a timestamp of ${existing_file_timestamp_dc} file found. Backup up file to ${FILE_DC}.${existing_file_timestamp_dc}"

mv "${FILE_DC}" "${FILE_DC}"."${existing_file_timestamp_dc}"

fi

##
## Print docker-compose.yml file
##

##
## Only one UDP per location
##

##
## Environmental Variables
##

echo "
services:

" > docker-compose.yml

##
## Loop through each device
##

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

##
## Remote import
##

FILE_import_remote[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-remote.sh"
if test -f "${FILE_import_remote[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_remote[$station_number]}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE_import_remote[$station_number]} file found. Backup up file to ${FILE_import_remote[$station_number]}.${existing_file_timestamp[$station_number]}"

mv "${FILE_import_remote[$station_number]}" "${FILE_import_remote[$station_number]}"."${existing_file_timestamp[$station_number]}"

fi

##
## Loki import - remote-forecast
##

FILE_import_loki_remote_forecast[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-loki-remote-forecast.sh"
if test -f "${FILE_import_loki_remote_forecast[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_remote_forecast[$station_number]}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE_import_loki_remote_forecast[$station_number]} file found. Backup up file to ${FILE_import_loki_remote_forecast[$station_number]}.${existing_file_timestamp[$station_number]}"

mv "${FILE_import_loki_remote_forecast[$station_number]}" "${FILE_import_loki_remote_forecast[$station_number]}"."${existing_file_timestamp[$station_number]}"

fi


##
## Loki import - remote-rest
##

FILE_import_loki_remote_rest[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-loki-remote-rest.sh"
if test -f "${FILE_import_loki_remote_rest[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_remote_rest[$station_number]}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE_import_loki_remote_rest[$station_number]} file found. Backup up file to ${FILE_import_loki_remote_rest[$station_number]}.${existing_file_timestamp[$station_number]}"

mv "${FILE_import_loki_remote_rest[$station_number]}" "${FILE_import_loki_remote_rest[$station_number]}"."${existing_file_timestamp[$station_number]}"

fi

##
## Loki import - remote-socket
##

FILE_import_loki_remote_socket[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-loki-remote-socket.sh"
if test -f "${FILE_import_loki_remote_socket[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_remote_socket[$station_number]}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE_import_loki_remote_socket[$station_number]} file found. Backup up file to ${FILE_import_loki_remote_socket[$station_number]}.${existing_file_timestamp[$station_number]}"

mv "${FILE_import_loki_remote_socket[$station_number]}" "${FILE_import_loki_remote_socket[$station_number]}"."${existing_file_timestamp[$station_number]}"

fi

##
## Loki import - local-udp
##

FILE_import_loki_local_udp[$station_number]="${PWD}/import-${station_name_dc[$station_number]}-loki-local-udp.sh"
if test -f "${FILE_import_loki_local_udp[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE_import_loki_local_udp[$station_number]}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE_import_loki_local_udp[$station_number]} file found. Backup up file to ${FILE_import_loki_local_udp[$station_number]}.${existing_file_timestamp[$station_number]}"

mv "${FILE_import_loki_local_udp[$station_number]}" "${FILE_import_loki_local_udp[$station_number]}"."${existing_file_timestamp[$station_number]}"

fi



echo "

device_id: ${device_id[$station_number]}
timezone: ${timezone[$station_number]}
latitude: ${latitude[$station_number]}
longitude: ${longitude[$station_number]}
elevation: ${elevation[$station_number]}
station_name: ${station_name[$station_number]}
station_id: ${station_id[$station_number]}
public_name: ${public_name[$station_number]}
hub_sn: ${hub_sn[$station_number]}

"

echo "

  weatherflow-collector-${station_name_dc[$station_number]}-$(hostname | awk -F. '{ print $1 }')-host-performance-influxdb:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-$(hostname | awk -F. '{ print $1 }')-host-performance-influxdb
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: host-performance
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEVICE_ID: ${device_id[$station_number]}
      WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED: \"true\"
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_FUNCTION: collector
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: ${influxdb_password}
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: ${influxdb_url}
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: ${influxdb_username}
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PERF_INTERVAL: ${perf_interval}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
    image: lux4rd0/weatherflow-collector:latest
    restart: always

  weatherflow-collector-${station_name_dc[$station_number]}-local-udp:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-local-udp
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: local-udp
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED: \"true\"
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_FUNCTION: collector
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: ${influxdb_password}
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: ${influxdb_url}
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: ${influxdb_username}
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL: ${loki_client_url}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_THREADS: ${threads}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    ports:
    - protocol: udp
      published: 50222
      target: 50222
    restart: always

  weatherflow-collector-${station_name_dc[$station_number]}-remote-forecast-influxdb:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-remote-forecast-influxdb
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: remote-forecast
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEVICE_ID: ${device_id[$station_number]}
      WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED: \"true\"
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_FUNCTION: collector
      WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL: 60
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: ${influxdb_password}
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: ${influxdb_url}
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: ${influxdb_username}
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL: ${loki_client_url}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_REST_INTERVAL: 60
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_THREADS: ${threads}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    restart: always

  weatherflow-collector-${station_name_dc[$station_number]}-remote-rest-influxdb:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-remote-rest-influxdb
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: remote-rest
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEVICE_ID: ${device_id[$station_number]}
      WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED: \"true\"
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_FUNCTION: collector
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: ${influxdb_password}
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: ${influxdb_url}
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: ${influxdb_username}
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL: ${loki_client_url}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_THREADS: ${threads}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    restart: always

  weatherflow-collector-${station_name_dc[$station_number]}-remote-socket-influxdb:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-remote-socket-influxdb
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: remote-socket
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEVICE_ID: ${device_id[$station_number]}
      WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED: \"true\"
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_FUNCTION: collector
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: ${influxdb_password}
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: ${influxdb_url}
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: ${influxdb_username}
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL: ${loki_client_url}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_THREADS: ${threads}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    restart: always

" >> docker-compose.yml

##
## remote-import
##

echo "

docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-remote-import \\
  -e WEATHERFLOW_COLLECTOR_BACKEND_TYPE=influxdb \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-import \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED=false \\
  -e WEATHERFLOW_COLLECTOR_DEVICE_ID=${device_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_ELEVATION=${elevation[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_HUB_SN=${hub_sn[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=${influxdb_password} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=${influxdb_url} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=${influxdb_username} \\
  -e WEATHERFLOW_COLLECTOR_LATITUDE=${latitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_LOGCLI_URL=${logcli_host_url} \\
  -e WEATHERFLOW_COLLECTOR_LONGITUDE=${longitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_PUBLIC_NAME=\"${public_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_STATION_ID=${station_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_STATION_NAME=\"${station_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TIMEZONE=\"${timezone[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  -e TZ=\"${timezone[$station_number]}\" \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_remote[$station_number]}"

echo "${FILE_import_remote[$station_number]} file created"

##
## loki remote-forecast
##

echo "

docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-loki-remote-forecast \\
  -e WEATHERFLOW_COLLECTOR_BACKEND_TYPE=influxdb \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-forecast \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEVICE_ID=${device_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED=false \\
  -e WEATHERFLOW_COLLECTOR_ELEVATION=${elevation[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_HUB_SN=${hub_sn[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=${influxdb_password} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=${influxdb_url} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=${influxdb_username} \\
  -e WEATHERFLOW_COLLECTOR_LATITUDE=${latitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_LOGCLI_URL=${logcli_host_url} \\
  -e WEATHERFLOW_COLLECTOR_LONGITUDE=${longitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_PUBLIC_NAME=\"${public_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_STATION_ID=${station_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_STATION_NAME=\"${station_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TIMEZONE=\"${timezone[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  -e TZ=\"${timezone[$station_number]}\" \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_loki_remote_forecast[$station_number]}"

echo "${FILE_import_loki_remote_forecast[$station_number]} file created"

##
## loki remote-rest
##

echo "

docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-loki-remote-rest \\
  -e WEATHERFLOW_COLLECTOR_BACKEND_TYPE=influxdb \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-rest \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEVICE_ID=${device_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED=false \\
  -e WEATHERFLOW_COLLECTOR_ELEVATION=${elevation[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_HUB_SN=${hub_sn[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=${influxdb_password} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=${influxdb_url} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=${influxdb_username} \\
  -e WEATHERFLOW_COLLECTOR_LATITUDE=${latitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_LOGCLI_URL=${logcli_host_url} \\
  -e WEATHERFLOW_COLLECTOR_LONGITUDE=${longitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_PUBLIC_NAME=\"${public_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_STATION_ID=${station_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_STATION_NAME=\"${station_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TIMEZONE=\"${timezone[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  -e TZ=\"${timezone[$station_number]}\" \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_loki_remote_rest[$station_number]}"

echo "${FILE_import_loki_remote_rest[$station_number]} file created"

##
## loki remote-socket
##

echo "

docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-loki-remote-socket \\
  -e WEATHERFLOW_COLLECTOR_BACKEND_TYPE=influxdb \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-socket \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEVICE_ID=${device_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED=false \\
  -e WEATHERFLOW_COLLECTOR_ELEVATION=${elevation[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_HUB_SN=${hub_sn[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=${influxdb_password} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=${influxdb_url} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=${influxdb_username} \\
  -e WEATHERFLOW_COLLECTOR_LATITUDE=${latitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_LOGCLI_URL=${logcli_host_url} \\
  -e WEATHERFLOW_COLLECTOR_LONGITUDE=${longitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_PUBLIC_NAME=\"${public_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_STATION_ID=${station_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_STATION_NAME=\"${station_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TIMEZONE=\"${timezone[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  -e TZ=\"${timezone[$station_number]}\" \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_loki_remote_socket[$station_number]}"

echo "${FILE_import_loki_remote_socket[$station_number]} file created"

##
## loki local-udp
##

echo "

docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-import-loki-local-udp \\
  -e WEATHERFLOW_COLLECTOR_BACKEND_TYPE=influxdb \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=local-udp \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEVICE_ID=${device_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED=false \\
  -e WEATHERFLOW_COLLECTOR_ELEVATION=${elevation[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_HUB_SN=${hub_sn[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=${influxdb_password} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=${influxdb_url} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=${influxdb_username} \\
  -e WEATHERFLOW_COLLECTOR_LATITUDE=${latitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_LOGCLI_URL=${logcli_host_url} \\
  -e WEATHERFLOW_COLLECTOR_LONGITUDE=${longitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_PUBLIC_NAME=\"${public_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_STATION_ID=${station_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_STATION_NAME=\"${station_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_THREADS=${threads} \\
  -e WEATHERFLOW_COLLECTOR_TIMEZONE=\"${timezone[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  -e TZ=\"${timezone[$station_number]}\" \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE_import_loki_local_udp[$station_number]}"

echo "${FILE_import_loki_local_udp[$station_number]} file created"

done

echo "
version: '3.3'" >> docker-compose.yml

echo "${FILE_DC} file created"

fi