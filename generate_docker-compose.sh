#!/bin/bash

##
## WeatherFlow Collector - docker-compose.yml generator

token=$1

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


FILE="${PWD}/docker-compose.yml"
if test -f "$FILE"; then



existing_file_timestamp=$(date -r "$FILE" "+%Y%m%d-%H%M%S")

echo "Existing docker-compose.yml file found. Backup up file to $FILE.${existing_file_timestamp}"

mv "$FILE" "$FILE"."${existing_file_timestamp}"

fi



##
## Print docker-compose.yml file
##

##
## Only one UDP per location
##



## Environmental Variables







echo "

services:
" > docker-compose.yml





## Loop through each device

for station_number in $(seq 0 $number_of_stations_minus_one) ; do


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

  weatherflow-collector-${station_name_dc[$station_number]}-local-udp-influxdb01:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-local-udp-influxdb01
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: local-udp
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: 4L851Jtjet7AJoFoFYR3di5Zniew28
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: http://influxdb01.tylephony.com:8086/write?db=weatherflow
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: influxdb
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    ports:
    - protocol: udp
      published: 50222
      target: 50222
    restart: always


  weatherflow-collector-${station_name_dc[$station_number]}-remote-forecast-influxdb-influxdb01:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-remote-forecast-influxdb-influxdb01
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: remote-forecast
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEVICE_ID: ${device_id[$station_number]}
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL: 60
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: 4L851Jtjet7AJoFoFYR3di5Zniew28
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: http://influxdb01.tylephony.com:8086/write?db=weatherflow
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: influxdb
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_REST_INTERVAL: 60
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    logging:
      driver: loki
      options:
        loki-url: http://log01.tylephony.com:3100/loki/api/v1/push
    restart: always

  weatherflow-collector-${station_name_dc[$station_number]}-remote-rest-influxdb-influxdb01:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-remote-rest-influxdb-influxdb01
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: remote-rest
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEVICE_ID: ${device_id[$station_number]}
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: 4L851Jtjet7AJoFoFYR3di5Zniew28
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: http://influxdb01.tylephony.com:8086/write?db=weatherflow
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: influxdb
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    logging:
      driver: loki
      options:
        loki-url: http://log01.tylephony.com:3100/loki/api/v1/push
    restart: always

  weatherflow-collector-${station_name_dc[$station_number]}-remote-socket-influxdb-influxdb01:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-remote-socket-influxdb-influxdb01
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: remote-socket
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEVICE_ID: ${device_id[$station_number]}
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: 4L851Jtjet7AJoFoFYR3di5Zniew28
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: http://influxdb01.tylephony.com:8086/write?db=weatherflow
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: influxdb
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    logging:
      driver: loki
      options:
        loki-url: http://log01.tylephony.com:3100/loki/api/v1/push
    restart: always

" >> docker-compose.yml

done

echo "
version: '3.3'" >> docker-compose.yml

echo "${PWD}/docker-compose.yml file created"

fi
