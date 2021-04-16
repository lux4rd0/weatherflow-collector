#!/bin/bash

##
## WeatherFlow Importer - import.sh
##

##
## Read Environmental Variables
##

backend_type=$WEATHERFLOW_COLLECTOR_BACKEND_TYPE
collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE
debug=$WEATHERFLOW_COLLECTOR_DEBUG
device_id=$WEATHERFLOW_COLLECTOR_DEVICE_ID
elevation=$WEATHERFLOW_COLLECTOR_ELEVATION
forecast_interval=$WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
hub_sn=$WEATHERFLOW_COLLECTOR_HUB_SN
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
latitude=$WEATHERFLOW_COLLECTOR_LATITUDE
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
longitude=$WEATHERFLOW_COLLECTOR_LONGITUDE
public_name=$WEATHERFLOW_COLLECTOR_PUBLIC_NAME
rest_interval=$WEATHERFLOW_COLLECTOR_REST_INTERVAL
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID
station_name=$WEATHERFLOW_COLLECTOR_STATION_NAME
timezone=$WEATHERFLOW_COLLECTOR_TIMEZONE
token=$WEATHERFLOW_COLLECTOR_TOKEN
days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS



# Curl Command

if [ "$debug" == "true" ]
then

curl=(  )

else

curl=( --silent --output /dev/null --show-error --fail )

fi


## Example

# Buzzard Bend

# ./fetch_import.sh 132821 token 5 | WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_STATION_ID=45249 ./remote-import-influxdb.sh

# Savannah Crossing

# ./fetch_import.sh 122367 token 5 | WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_STATION_ID=40907 ./remote-import-influxdb.sh


# Loop through the days for a full import



for days_loop in $(seq "$days" -1 0) ; do

time_start=$(date --date="${days_loop} days ago 00:00" +%s)

time_end=$(("$time_start" + 86340))

# time_end=$(date +%s)


#time_start_long=$(date --date="${days} days ago")
#time_end_long=$(date)

#echo "time_start epoch: ${time_start}"
#echo "time_end epoch: ${time_end}"

#echo ""

#echo "time_start long: ${time_start_long}"
#echo "time_end epoch: ${time_end_long}"

#echo ""

#echo "https://swd.weatherflow.com/swd/rest/observations/device/122367?time_start=${time_start}&time_end=${time_end}&token=597e83fe-8a13-4c30-aaf3-d10f1c7fbe3b"

#echo ""



#echo "Day: $days_loop"

#echo "time_start: $time_start"

#echo "time_end: $time_end"

curl "${curl[@]}" -w "\n" -X GET --header 'Accept: application/json' "https://swd.weatherflow.com/swd/rest/observations/device/${device_id}?time_start=${time_start}&time_end=${time_end}&token=${token}" | /weatherflow-collector/remote-import-influxdb.sh

done
