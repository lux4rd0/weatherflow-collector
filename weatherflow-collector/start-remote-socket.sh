#!/bin/bash

##
## WeatherFlow Collector - start-remote-socket.sh
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

collector_type="remote-socket"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} Starting WeatherFlow Collector (remote-socket.sh) - https://github.com/lux4rd0/weatherflow-collector

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

if [ "$debug" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

##
## Random ID
##

random_id=$(od -A n -t d -N 1 /dev/urandom |tr -d ' ')

##
## Get Stations IDs from Token
##

url_stations="https://swd.weatherflow.com/swd/rest/stations?token=${token}"

#echo "url_stations=${url_stations}"

url_forecasts="https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${station_id}&token=${token}"

#echo "url_forecasts=${url_forecasts}"

url_observations="https://swd.weatherflow.com/swd/rest/observations/station/${station_id}?token=${token}"

#echo "url_observations=${url_observations}"

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
station_ids=($(echo "${body_station}" | jq -r '.stations[].station_id | @sh') )

#echo "Number of Stations: ${number_of_stations}"

number_of_stations_minus_one=$((number_of_stations-1))

socket_json="\n"

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

    #echo "Station Number Loop: $station_number"

    #echo "station_number: ${station_number} station_id: ${station_ids[${station_number}]}"

    number_of_devices=$(echo "${body_station}" |jq '.stations['"${station_number}"'].devices | length')

    #echo "number_of_devices: ${number_of_devices}"

    number_of_devices_minus_one=$((number_of_devices-1))

    #device_hb=($(echo "${body_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "HB") | .device_id | @sh') )
    json_variable=${station_ids[${station_number}]}
    socket_json="${socket_json}{\"type\":\"listen_start_events\",\"station_id\":\"$json_variable\",\"id\":\"weatherflow-collector-listen_start_events_${random_id}\"}\n"

    echo "${body_station}" | jq -r '.stations['"${station_number}"'] | {"location_id", "station_id", "name", "public_name", "latitude", "longitude", "timezone"}' | jq -r '. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-socket-station_id-"${station_ids[${station_number}]}"-lookup.txt
    echo "elevation=\"$(echo "${body_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> remote-socket-station_id-"${station_ids[${station_number}]}"-lookup.txt
    
    #echo "${body_station}" |jq -r '.stations['"${station_number}"'] | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > ${station_ids[${station_number}]}-lookup.txt
    #echo "elevation=\"$(echo "${body_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> ${station_ids[${station_number}]}-lookup.txt

    #echo "${socket_json}"
    
    for device_number in $(seq 0 $number_of_devices_minus_one) ; do

        #echo "device_number: ${device_number}"
        #device_ids=($(echo "${body_station}" | jq -r '.stations[${station_ids[${station_number}]}].devices | @sh') )

        device_ar=($(echo "${body_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "AR") | .device_id | @sh') )
        device_sk=($(echo "${body_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "SK") | .device_id | @sh') )
        device_st=($(echo "${body_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "ST") | .device_id | @sh') )
        

if [ -n "${device_ar[${device_number}]}" ]; then
        #echo "station_number: ${station_number} station_id: ${station_ids[${station_number}]} device_number: ${device_number} device_ar: ${device_ar[${device_number}]}"
        json_variable=${device_ar[${device_number}]}
        socket_json="${socket_json}{\"type\":\"listen_start\",\"device_id\":\"$json_variable\",\"id\":\"weatherflow-collector-listen_start_${random_id}\"}\n"
        socket_json="${socket_json}{\"type\":\"listen_rapid_start\",\"device_id\":\"$json_variable\",\"id\":\"weatherflow-collector-listen_rapid_start_${random_id}\"}\n"

        echo "${body_station}" |jq -r '.stations['"${station_number}"'] | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-socket-device_id-"${device_ar[${device_number}]}"-lookup.txt
        echo "elevation=\"$(echo "${body_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> remote-socket-device_id-"${device_ar[${device_number}]}"-lookup.txt

        #echo "${socket_json}"
fi

if [ -n "${device_sk[${device_number}]}" ]; then
        #echo "station_number: ${station_number} station_id: ${station_ids[${station_number}]} device_number: ${device_number} device_sk: ${device_sk[${device_number}]}"
        json_variable=${device_sk[${device_number}]}
        socket_json="${socket_json}{\"type\":\"listen_start\",\"device_id\":\"$json_variable\",\"id\":\"weatherflow-collector-start_${random_id}\"}\n"

        echo "${body_station}" |jq -r '.stations['"${station_number}"'] | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-socket-device_id-"${device_sk[${device_number}]}"-lookup.txt
        echo "elevation=\"$(echo "${body_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> remote-socket-device_id-"${device_sk[${device_number}]}"-lookup.txt

        #echo "${socket_json}"
fi

if [ -n "${device_st[${device_number}]}" ]; then
        #echo "station_number: ${station_number} station_id: ${station_ids[${station_number}]} device_number: ${device_number} device_st: ${device_st[${device_number}]}"
        json_variable=${device_st[${device_number}]}
        socket_json="${socket_json}{\"type\":\"listen_start\",\"device_id\":\"$json_variable\",\"id\":\"weatherflow-collector-start_${random_id}\"}\n"
        socket_json="${socket_json}{\"type\":\"listen_rapid_start\",\"device_id\":\"$json_variable\",\"id\":\"weatherflow-collector-listen_rapid_start_${random_id}\"}\n"

        echo "${body_station}" |jq -r '.stations['"${station_number}"'] | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-socket-device_id-"${device_st[${device_number}]}"-lookup.txt
        echo "elevation=\"$(echo "${body_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> remote-socket-device_id-"${device_st[${device_number}]}"-lookup.txt

        #echo "${socket_json}"
fi

    done

done
#echo "${socket_json}"
echo -e "${socket_json}" | ./websocat_amd64-linux-static -n "wss://ws.weatherflow.com/swd/data?token=${token}" | ./exec-remote-socket.sh
