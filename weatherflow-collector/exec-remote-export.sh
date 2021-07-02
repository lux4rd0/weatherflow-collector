#!/bin/bash

##
## WeatherFlow Collector - start-remote-export.sh
##

##
## WeatherFlow-Collector Details
##

source weatherflow-collector_details.sh

##
## Set Variables from Environmental Variables
##

debug=$WEATHERFLOW_COLLECTOR_DEBUG
debug_curl=$WEATHERFLOW_COLLECTOR_DEBUG_CURL
healthcheck=$WEATHERFLOW_COLLECTOR_HEALTHCHECK
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
token=$WEATHERFLOW_COLLECTOR_TOKEN
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID

##
## Set Specific Variables
##

collector_type="remote-export"
function="export"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (start-remote-export.sh) - https://github.com/lux4rd0/weatherflow-collector

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
loki_client_url=${loki_client_url}
station_id=${station_id}
token=${token}
weatherflow_collector_version=${weatherflow_collector_version}"

fi



##
## Curl Command
##

if [ "$debug_curl" == "true" ]; then curl=(  ); else curl=( --silent --show-error --fail ); fi

##
## Get Stations IDs from Token
##

url_stations="https://swd.weatherflow.com/swd/rest/stations?token=${token}"

#echo "url_stations=${url_stations}"

response_url_stations=$(curl -si -w "\n%{size_header},%{size_download}" "${url_stations}")

#echo ${response_url_stations}

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

#echo "${body_station}"

number_of_devices=$(echo "${body_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "AR" or .device_type == "SK" or .device_type == "ST")' | jq -s '. | length')

#echo "${body_station}" | jq -r '.stations[] | select(.location_id == ${station_id}) | .devices'

echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - number_of_devices: ${echo_bold}${number_of_devices}${echo_normal}, station_id: ${station_id}"


number_of_devices_minus_one=$((number_of_devices-1))

> remote-import-url_"${station_id}"-station_list.txt
    
for device_number in $(seq 0 $number_of_devices_minus_one) ; do

#echo "device_number=${device_number}"

device_ar=($(echo "${body_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "AR") |  .device_id | @sh') )
device_sk=($(echo "${body_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "SK") |  .device_id | @sh') )
device_st=($(echo "${body_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "ST") |  .device_id | @sh') )
        
if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} device_ar=${device_ar[*]} device_sk=${device_sk[*]} device_st=${device_st[*]}" ; fi

if [ -n "${device_ar[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_id} device_number: ${device_number} device_ar: ${device_ar[${device_number}]}"
echo "${body_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-import-device_id-"${device_ar[${device_number}]}"-lookup.txt
echo "elevation=\"$(echo "${body_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .station_meta.elevation')\"" >> remote-import-device_id-"${device_ar[${device_number}]}"-lookup.txt
echo "hub_sn=\"$(echo "${body_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "HB") | .serial_number')\"" >> remote-import-device_id-"${device_ar[${device_number}]}"-lookup.txt
echo "https://swd.weatherflow.com/swd/rest/observations/device/${device_ar[${device_number}]}?token=${token}" >> remote-import-url_"${station_id}"-station_list.txt

fi

if [ -n "${device_sk[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_id} device_number: ${device_number} device_sk: ${device_sk[${device_number}]}"
echo "${body_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-import-device_id-"${device_sk[${device_number}]}"-lookup.txt
echo "elevation=\"$(echo "${body_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .station_meta.elevation')\"" >> remote-import-device_id-"${device_sk[${device_number}]}"-lookup.txt
echo "hub_sn=\"$(echo "${body_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "HB") | .serial_number')\"" >> remote-import-device_id-"${device_sk[${device_number}]}"-lookup.txt
echo "https://swd.weatherflow.com/swd/rest/observations/device/${device_sk[${device_number}]}?token=${token}" >> remote-import-url_"${station_id}"-station_list.txt
fi

if [ -n "${device_st[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_id} device_number: ${device_number} device_st: ${device_st[${device_number}]}"
echo "${body_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-import-device_id-"${device_st[${device_number}]}"-lookup.txt
echo "elevation=\"$(echo "${body_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .station_meta.elevation')\"" >> remote-import-device_id-"${device_st[${device_number}]}"-lookup.txt
echo "hub_sn=\"$(echo "${body_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "HB") | .serial_number')\"" >> remote-import-device_id-"${device_st[${device_number}]}"-lookup.txt
echo "https://swd.weatherflow.com/swd/rest/observations/device/${device_st[${device_number}]}?token=${token}" >> remote-import-url_"${station_id}"-station_list.txt

fi

done

##
## Init Progress Bar
##

init_progress_full $(((import_days + 1) * number_of_devices))

##
## Init Export
##

export_number=0

##
## Loop through the days for a full import
##

for days_loop in $(seq "$import_days" -1 0) ; do

##
## Reset full import timer if reset_progress_total_full.txt file exists
##

if [ -f "reset_progress_total_full.txt" ]; then progress_start_date_full=$(date +%s); progress_total_full="$(((days_loop + 1) * number_of_devices))"; progress_count_full=0; rm reset_progress_total_full.txt; fi

time_start=$(date --date="${days_loop} days ago 00:00" +%s)
time_end=$((time_start + 86399))

time_start_echo=$(date -d @"${time_start}")
time_end_echo=$(date -d @${time_end})

#echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - Day: ${echo_bold}${days_loop}${echo_normal} days ago"
#echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - time_start: ${time_start} - ${time_start_echo}"
#echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - time_end: ${time_end} - ${time_end_echo}"

remote_import_url="remote-import-url_${station_id}-station_list.txt"
while IFS=, read -r lookup_import_url lookup_station_id; do
if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - lookup_import_url: ${lookup_import_url} lookup_station_id: ${lookup_station_id}"; fi

# curl "${curl[@]}" -w "\n" -X GET --header 'Accept: application/json' "${lookup_import_url}&time_start=${time_start}&time_end=${time_end}" | ./exec-remote-import.sh

##
## Capture csv data
##

csv_data=$(curl "${curl[@]}" -w "\n" -X GET --header 'Accept: application/json' "${lookup_import_url}&time_start=${time_start}&time_end=${time_end}&format=csv")
#csv_head=$(echo "${csv_data}" | head -1)
csv_tail=$(echo "${csv_data}" | tail -n +2)

#echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - lookup_import_url: ${lookup_import_url} lookup_station_id: ${lookup_station_id}"

#echo "days_loop=${days_loop}"
if [ $export_number = "0" ]; then 

echo "${csv_data}" > export/export-"${station_id}".csv

else

echo "${csv_tail}" >> export/export-"${station_id}".csv

fi


#curl "${curl[@]}" -w "\n" -X GET --header 'Accept: application/json' "${lookup_import_url}&time_start=${time_start}&time_end=${time_end}&format=csv"

#echo "${curl[@]}" -w "\n" -X GET --header 'Accept: application/json' "${lookup_import_url}&time_start=${time_start}&time_end=${time_end}"

##
## Increment Progress Bar
##

#echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} Full Import Status Details"

inc_progress_full



((export_number=export_number+1))

done < "${remote_import_url}"



done
