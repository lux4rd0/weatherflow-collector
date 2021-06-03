#!/bin/bash

##
## WeatherFlow Collector - start-local-udp.sh
##

##
## WeatherFlow-Collector Details
##

source weatherflow-collector_details.sh

##
## Set Variables from Environmental Variables
##

debug=$WEATHERFLOW_COLLECTOR_DEBUG
function=$WEATHERFLOW_COLLECTOR_FUNCTION
healthcheck=$WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
logcli_host_url=$WEATHERFLOW_COLLECTOR_LOGCLI_URL
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Set Specific Variables
##

collector_type="local-udp"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${collector_type}:${normal} Starting WeatherFlow Collector (start-local-udp.sh) - https://github.com/lux4rd0/weatherflow-collector

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
threads=${threads}
token=${token}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Set InfluxDB Precision to seconds
##

if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Send Startup Event Timestamp to InfluxDB
##

docker_startup

##
## Curl Command
##

if [ "$debug" == "true" ]; then curl=(  ); else curl=( --silent --show-error --fail ); fi

##
## Get Stations IDs from Token
##

url_stations="https://swd.weatherflow.com/swd/rest/stations?token=${token}"

#echo "url_stations=${url_stations}"

response_url_stations=$(curl -si -w "\n%{size_header},%{size_download}" "${url_stations}")

#echo ${response_url_stations}

#response_url_forecasts=$(curl -si -w "\n%{size_header},%{size_download}" "${url_forecasts}")

# Extract the response header size
header_size_stations=$(sed -n '$ s/^\([0-9]*\),.*$/\1/ p' <<< "${response_url_stations}")

# Extract the response body size
body_size_stations=$(sed -n '$ s/^.*,\([0-9]*\)$/\1/ p' <<< "${response_url_stations}")

# Extract the response headers
#headers_station="${response_url_stations:0:${header_size_stations}}"

# Extract the response body
body_station="${response_url_stations:${header_size_stations}:${body_size_stations}}"

#echo "${body_station}"

number_of_stations=$(echo "${body_station}" |jq '.stations | length')
station_sns=($(echo "${body_station}" | jq -r '.stations[].devices[] | select(.device_type == "HB") | .serial_number') )

#echo "Number of Stations: ${number_of_stations}"

number_of_stations_minus_one=$((number_of_stations-1))

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

    #echo "Station Number Loop: $station_number"
    #echo "station_number: ${station_number} station_id: ${station_sns[${station_number}]}"

    #number_of_devices=$(echo "${body_station}" |jq '.stations['"${station_number}"'].devices | length')

    #echo "number_of_devices: ${number_of_devices}"

    #number_of_devices_minus_one=$((number_of_devices-1))

    #device_hb=($(echo "${body_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "HB") | .serial)number | @sh') )
    #json_variable=${station_sns[${station_number}]}
    #socket_json="${socket_json}{\"type\":\"listen_start_events\",\"station_id\":\"$json_variable\",\"id\":\"weatherflow-collector-listen_start_events_${random_id}\"}\n"

    echo "${body_station}" | jq -r '.stations['"${station_number}"'] | {"location_id", "station_id", "name", "public_name", "latitude", "longitude", "timezone"}' | jq -r '. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > local-udp-hub_sn-"${station_sns[${station_number}]}"-lookup.txt
    echo "elevation=\"$(echo "${body_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> local-udp-hub_sn-"${station_sns[${station_number}]}"-lookup.txt
    
    #echo "${body_station}" |jq -r '.stations['"${station_number}"'] | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > ${station_sns[${station_number}]}-lookup.txt
    #echo "elevation=\"$(echo "${body_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> ${station_sns[${station_number}]}-lookup.txt
    #echo "${socket_json}"
    
done
#echo "${socket_json}"

#/usr/bin/stdbuf -oL /usr/bin/python weatherflow-listener.py
/usr/bin/stdbuf -oL /usr/bin/python weatherflow-listener.py | ./exec-local-udp.sh
