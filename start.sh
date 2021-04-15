#!/bin/bash

##
## WeatherFlow Collector - startup.sh
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

## Check for required intervals

if [ -z "${forecast_interval}" ] && [ "$collector_type" == "remote-forecast" ]
  then
    echo "WEATHERFLOW_COLLECTOR_forecast_interval environmental variable not set. Defaulting to 60 seconds"

forecast_interval="60"

fi

if [ -z "${rest_interval}" ] && [ "$collector_type" == "remote-rest" ]
  then
    echo "WEATHERFLOW_COLLECTOR_rest_interval environmental variable not set. Defaulting to 60 seconds"

rest_interval="60"

fi

# Random ID

random_id=$(od -A n -t d -N 1 /dev/urandom |tr -d ' ')

# Curl Command

if [ "${debug}" = "true" ]
then

curl=(  )

else

curl=( --silent --show-error --fail)

fi


if [ "${debug}" = "true" ]
then

echo "
Starting WeatherFlow Collector (startup.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

backend_type=${backend_type}
collector_type=${collector_type}
debug=${debug}
device_id=${device_id}
elevation=${elevation}
forecast_interval=${forecast_interval}
host_hostname=${host_hostname}
hub_sn=${hub_sn}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
latitude=${latitude}
loki_client_url=${loki_client_url}
longitude=${longitude}
public_name=${public_name}
rest_interval=${rest_interval}
station_id=${station_id}
station_name=${station_name}
timezone=${timezone}
token=${token}

"

else

echo ""
echo "Starting WeatherFlow Collector (startup.sh) - https://github.com/lux4rd0/weatherflow-collector"
echo ""

fi

##
## COLLECTOR TYPE = LOCAL-UDP
##

if [ "${collector_type}" = "local-udp" ]
then

echo "collector_type=${collector_type}"

##
## BACKEND TYPE = LOKI
##

if [ "${backend_type}" = "loki" ]
then

echo "backend_type=${backend_type}"

/usr/bin/stdbuf -oL /usr/bin/python /weatherflow-collector/weatherflow-listener.py | /usr/bin/promtail --stdin --client.url "$loki_client_url" --client.external-labels=collector_type=local-udp,host_hostname="${host_hostname}" --config.file=/weatherflow-collector/loki-config.yml

##
## BACKEND TYPE = INFLUXDB
##

elif  [ "${backend_type}" = "influxdb" ]
then

echo "backend_type=${backend_type}"

/usr/bin/stdbuf -oL /usr/bin/python /weatherflow-collector/weatherflow-listener.py | /weatherflow-collector/local-udp-influxdb.sh

else

echo "No Backend Configured"

fi

##
## COLLECTOR TYPE = REMOTE-SOCKET
##

elif [ "${collector_type}" = "remote-socket" ]
then

echo "collector_type=${collector_type}"

if [ "${backend_type}" = "loki" ]
then

echo "backend_type=${backend_type}"

JSON='\n{"type":"listen_start", "device_id": "'"${device_id}"'", "id":"weatherflow-collector-start_'"${random_id}"'"}\n{"type":"listen_start_events", "station_id": "'"${station_id}"'", "id":"weatherflow-collector-start_events_'"${random_id}"'"}\n{"type":"listen_rapid_start", "device_id": "'"${device_id}"'", "id":"weatherflow-collector-rapid_start_'"${random_id}"'"}\n'

echo -e "$JSON" | /weatherflow-collector/websocat_amd64-linux-static -n "wss://ws.weatherflow.com/swd/data?token=${token}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type=remote-socket,host_hostname="${host_hostname}" --config.file=/weatherflow-collector/loki-config.yml

##
## BACKEND TYPE = INFLUXDB
##

elif  [ "${backend_type}" = "influxdb" ]
then

echo "backend_type=${backend_type}"

JSON='\n{"type":"listen_start", "device_id": "'"${device_id}"'", "id":"weatherflow-collector-start_'"${random_id}"'"}\n{"type":"listen_start_events", "station_id": "'"${station_id}"'", "id":"weatherflow-collector-start_events_'"${random_id}"'"}\n{"type":"listen_rapid_start", "device_id": "'"${device_id}"'", "id":"weatherflow-collector-rapid_start_'"${random_id}"'"}\n'

echo -e "$JSON" | /weatherflow-collector/websocat_amd64-linux-static -n "wss://ws.weatherflow.com/swd/data?token=${token}" | /weatherflow-collector/remote-socket-influxdb.sh

else

echo "No Backend Configured"

fi

##
## COLLECTOR TYPE = REMOTE-FORECAST
##

elif [ "${collector_type}" = "remote-forecast" ]
then

echo "collector_type=${collector_type}"

##
## BACKEND TYPE = LOKI
##

if [ "${backend_type}" = "loki" ]
then

echo "backend_type=${backend_type}"

while ( true ); do
  before=$(date +%s)
  curl "${curl[@]}" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${station_id}&token=${token}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type=remote-forecast,host_hostname="${host_hostname}" --config.file=/weatherflow-collector/loki-config.yml
  after=$(date +%s)
  DELAY=$(echo "${forecast_interval}-($after-$before)" | bc)
  echo "Sleeping ${DELAY}"
  sleep "$DELAY"
done

##
## BACKEND TYPE = INFLUXDB
##

elif  [ "${backend_type}" = "influxdb" ]
then

echo "backend_type=${backend_type}"

startup_check=0

while ( true ); do
  before=$(date +%s%N)

## Only run the hourly forecasts at 0, 15, 30, 45 minutes except on startup

hourly_time_build_check_minute=$(date +"%M")

if [ "$hourly_time_build_check_minute" == "0" ] || [ "$hourly_time_build_check_minute" == "15" ] || [ "$hourly_time_build_check_minute" == "30" ] || [ "$hourly_time_build_check_minute" == "45" ]

then

hourly_time_build_check_flag="true"

echo "Running Hourly Forecast - Quarter Hour Time Interval - ${hourly_time_build_check_minute} Minute"

else

hourly_time_build_check_flag="false"

echo "Skipping Hourly Forecast - Quarter Hour Time Interval - ${hourly_time_build_check_minute} Minute"

fi

## Run on startup

if [ "$startup_check" == "0" ]

then

hourly_time_build_check_flag="true"

echo "Running Hourly Forecast - First Time Startup"

fi

  curl "${curl[@]}" -w "\n" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${station_id}&token=${token}" | WEATHERFLOW_COLLECTOR_HOURLY_FORECAST_RUN=${hourly_time_build_check_flag} /weatherflow-collector/remote-forecast-influxdb.sh
  after=$(date +%s%N)
  DELAY=$(echo "scale=4;(${forecast_interval}-($after-$before) / 1000000000)" | bc)
  echo "Sleeping: ${DELAY} seconds"
  ((startup_check=startup_check+1))
  echo "Loop: ${startup_check}"
  sleep "$DELAY"
done

else

echo "No Backend Configured"

fi

##
## COLLECTOR TYPE = REMOTE-REST
##

elif [ "${collector_type}" = "remote-rest" ]
then

echo "collector_type=${collector_type}"

##
## BACKEND TYPE = LOKI
##

if [ "${backend_type}" = "loki" ]
then

echo "backend_type=${backend_type}"

while ( true ); do
  before=$(date +%s)
  curl "${curl[@]}" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${station_id}&token=${token}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type=remote-rest,host_hostname="${host_hostname}" --config.file=/weatherflow-collector/loki-config.yml
  after=$(date +%s)
  DELAY=$(echo "${rest_interval}-($after-$before)" | bc)
  echo "Sleeping ${DELAY}"
  sleep "$DELAY"
done

##
## BACKEND TYPE = INFLUXDB
##

elif  [ "${backend_type}" = "influxdb" ]
then

echo "backend_type=${backend_type}"

while ( true ); do
  before=$(date +%s)
  curl "${curl[@]}" -w "\n" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/observations/station/${station_id}?token=${token}" | /weatherflow-collector/remote-rest-influxdb.sh
  after=$(date +%s)
  DELAY=$(echo "${rest_interval}-($after-$before)" | bc)
  echo "Sleeping ${DELAY}"
  sleep "$DELAY"
done

else

echo "No Backend Configured"

fi

else

echo "No Remote Collector Configured"

fi
