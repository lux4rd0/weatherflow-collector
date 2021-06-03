#!/bin/bash

##
## WeatherFlow Collector - remote-forecast.sh
## version 3.0
##

##
## WeatherFlow-Collector Details
##

source weatherflow-collector_details.sh

##
## Set Variables from Environmental Variables
##

debug=$WEATHERFLOW_COLLECTOR_DEBUG
forecast_interval=$WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL
function=$WEATHERFLOW_COLLECTOR_FUNCTION
healthcheck=$WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
logcli_host_url=$WEATHERFLOW_COLLECTOR_LOGCLI_URL
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
threads=$WEATHERFLOW_COLLECTOR_THREADS
token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Set Specific Variables
##

collector_type="remote-forecast"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} Starting WeatherFlow Collector (remote-forecast.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

backend_type=${backend_type}
collector_type=${collector_type}
debug=${debug}
device_id=${device_id}
elevation=${elevation}
forecast_interval=${forecast_interval}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
hub_sn=${hub_sn}
import_days=${import_days}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
latitude=${latitude}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
longitude=${longitude}
public_name=${public_name}
rest_interval=${rest_interval}
station_id=${station_id}
station_name=${station_name}
threads=${threads}
timezone=${timezone}
token=${token}"

fi

##
## Set InfluxDB Precision to seconds
##

if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Check for required intervals
##

if [ -z "${forecast_interval}" ] && [ "$collector_type" == "remote-forecast" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL environmental variable not set. Defaulting to 60 seconds"; forecast_interval="60"; fi

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

#url_forecasts="https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${station_id}&token=${token}"

#echo "url_forecasts=${url_forecasts}"

#url_observations="https://swd.weatherflow.com/swd/rest/observations/station/${station_id}?token=${token}"

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

> remote-forecast-url_station_list.txt

for station_number in $(seq 0 $number_of_stations_minus_one); do

#echo "Station Number Loop: $station_number"
#echo "station_number: ${station_number} station_id: ${station_ids[${station_number}]}"
#number_of_devices=$(echo "${body_station}" |jq '.stations['"${station_number}"'].devices | length')
#echo "number_of_devices: ${number_of_devices}"
#number_of_devices_minus_one=$((number_of_devices-1))

echo "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${station_ids[${station_number}]}&token=${token},${station_ids[${station_number}]}" >> remote-forecast-url_station_list.txt

echo "hub_sn=\"$(echo "${body_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "HB") | .serial_number')\"" > remote-forecast-station_id-"${station_ids[${station_number}]}"-lookup.txt
echo "device_id=\"$(echo "${body_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "HB") | .device_id')\"" >> remote-forecast-station_id-"${station_ids[${station_number}]}"-lookup.txt


echo "${body_station}" | jq -r '.stations['"${station_number}"'] | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' >> remote-forecast-station_id-"${station_ids[${station_number}]}"-lookup.txt

echo "elevation=\"$(echo "${body_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> remote-forecast-station_id-"${station_ids[${station_number}]}"-lookup.txt

#echo "${body_station}" | jq -r '.stations['"${station_number}"'] | {"location_id", "station_id", "name", "public_name", "latitude", "longitude", "timezone", "station_meta"}' > remote-forecast-station_id-"${station_ids[${station_number}]}"-lookup.json

done

startup_check=0

quarter_hour_offset=$(shuf -i 0-14 -n 1)

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} quarter_hour_offset: ${quarter_hour_offset}"; fi

echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} Running at $quarter_hour_offset, $((quarter_hour_offset + 15)), $((quarter_hour_offset + 30)), and $((quarter_hour_offset + 45)) minutes after the hour"

##
## Start Forecast Continuous Loop
##

while ( true ); do

##
## Read URLs for Remote Forecast
##

#echo "${station_json[0]}"

before=$(date +%s%N)

##
## Run the hourly forecasts every 15 minutes at a random quarter hour offset
## This help (kind of) stagger usge if there is more than one Forecast
## container running
##

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} quarter_hour_offset: ${quarter_hour_offset}"; fi

hourly_time_build_check_minute=$(date +"%-M")

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} hourly_time_build_check_minute: ${hourly_time_build_check_minute}"; fi

if [[ "$hourly_time_build_check_minute" == "$quarter_hour_offset" ]] || [[ "$hourly_time_build_check_minute" == "$((quarter_hour_offset + 15))" ]] || [[ "$hourly_time_build_check_minute" == "$((quarter_hour_offset + 30))" ]] || [[ "$hourly_time_build_check_minute" == "$((quarter_hour_offset + 45))" ]]

then

hourly_time_build_check_flag="true"

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} Running Hourly Forecast Interval Build - ${hourly_time_build_check_minute} Minute"; fi

else

hourly_time_build_check_flag="false"

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} Skipping Hourly Forecast Interval Build - ${hourly_time_build_check_minute} Minute"; fi

fi

##
## Run on startup
##

if [ "$startup_check" == "0" ]; then hourly_time_build_check_flag="true"; echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} Running Hourly Forecast Interval Build - First Time Startup"; fi

remote_forecast_url="remote-forecast-url_station_list.txt"

while IFS=, read -r lookup_forecast_url lookup_station_id; do

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} lookup_forecast_url: ${lookup_forecast_url} lookup_station_id: ${lookup_station_id}"; fi

curl "${curl[@]}" -w "\n" -X GET --header "Accept: application/json" "${lookup_forecast_url}" | WEATHERFLOW_COLLECTOR_HOURLY_FORECAST_RUN=${hourly_time_build_check_flag} WEATHERFLOW_COLLECTOR_STATION_ID="${lookup_station_id}" ./exec-remote-forecast.sh

#echo "${forecast_json}" | jq -s '.' | WEATHERFLOW_COLLECTOR_DEViCE_ID="${lookup_station_id}"
#echo "${forecast_json}$(cat remote-forecast-station_id-${lookup_station_id}-lookup.json)" | jq -s '.' | WEATHERFLOW_COLLECTOR_HOURLY_FORECAST_RUN=${hourly_time_build_check_flag} | ./exec-remote-forecast.sh
#echo "${forecast_json}$(cat remote-forecast-station_id-${lookup_station_id}-lookup.json)" | jq -s '.' | ./remote-forecast.sh

done < ${remote_forecast_url}

after=$(date +%s%N)
DELAY=$(echo "scale=4;(${forecast_interval}-($after-$before) / 1000000000)" | bc)

if [ "$debug_sleeping" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} Sleeping: ${DELAY} seconds"; fi

((startup_check=startup_check+1))
if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} Loop: ${startup_check}"; fi
sleep "$DELAY"
done