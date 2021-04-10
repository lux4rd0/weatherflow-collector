#!/bin/bash

debug=$WEATHERFLOW_COLLECTOR_DEBUG
collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE
backend_type=$WEATHERFLOW_COLLECTOR_BACKEND_TYPE
remote_collector_device_id=$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_DEVICE_ID
remote_collector_station_id=$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_STATION_ID
remote_collector_token=$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_TOKEN
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
remote_forecast_interval=$WEATHERFLOW_COLLECTOR_REMOTE_FORECAST_INTERVAL
remote_rest_interval=$WEATHERFLOW_COLLECTOR_REMOTE_REST_INTERVAL


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

echo ""
echo "Starting WeatherFlow Collector (startup.sh) - https://github.com/lux4rd0/weatherflow-collector"
echo ""
echo "Debug Environmental Variables"
echo ""
echo "collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE"
echo "backend_type=$WEATHERFLOW_COLLECTOR_BACKEND_TYPE"
echo "remote_collector_device_id=$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_DEVICE_ID"
echo "remote_collector_station_id=$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_STATION_ID"
echo "remote_collector_token=$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_TOKEN"
echo "loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL"
echo "remote_forecast_interval=$WEATHERFLOW_COLLECTOR_REMOTE_FORECAST_INTERVAL"
echo "remote_rest_interval=$WEATHERFLOW_COLLECTOR_REMOTE_REST_INTERVAL"

echo ""

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

JSON='\n{"type":"listen_start", "device_id": "'"${remote_collector_device_id}"'", "id":"weatherflow_listener-start_'"${random_id}"'"}\n{"type":"listen_start_events", "station_id": "'"${remote_collector_station_id}"'", "id":"weatherflow_listener-start_events_'"${random_id}"'"}\n{"type":"listen_rapid_start", "device_id": "'"${remote_collector_device_id}"'", "id":"weatherflow_listener-rapid_start_'"${random_id}"'"}\n'

echo -e "$JSON" | /weatherflow-collector/websocat_amd64-linux-static -n "wss://ws.weatherflow.com/swd/data?token=${remote_collector_token}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type=remote-socket,host_hostname="${host_hostname}" --config.file=/weatherflow-collector/loki-config.yml

##
## BACKEND TYPE = INFLUXDB
##

elif  [ "${backend_type}" = "influxdb" ]
then

echo "backend_type=${backend_type}"

JSON='\n{"type":"listen_start", "device_id": "'"${remote_collector_device_id}"'", "id":"weatherflow_listener-start_'"${random_id}"'"}\n{"type":"listen_start_events", "station_id": "'"${remote_collector_station_id}"'", "id":"weatherflow_listener-start_events_'"${random_id}"'"}\n{"type":"listen_rapid_start", "device_id": "'"${remote_collector_device_id}"'", "id":"weatherflow_listener-rapid_start_'"${random_id}"'"}\n'

echo -e "$JSON" | /weatherflow-collector/websocat_amd64-linux-static -n "wss://ws.weatherflow.com/swd/data?token=${remote_collector_token}" | /weatherflow-collector/remote-socket-influxdb.sh

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
  curl "${curl[@]}" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${remote_collector_station_id}&token=${remote_collector_token}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type=remote-forecast,host_hostname="${host_hostname}" --config.file=/weatherflow-collector/loki-config.yml
  after=$(date +%s)
  DELAY=$(echo "${remote_forecast_interval}-($after-$before)" | bc)
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
  curl "${curl[@]}" -w "\n" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${remote_collector_station_id}&token=${remote_collector_token}" | /weatherflow-collector/remote-forecast-influxdb.sh
  after=$(date +%s)
  DELAY=$(echo "${remote_forecast_interval}-($after-$before)" | bc)
  echo "Sleeping ${DELAY}"
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
  curl "${curl[@]}" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${remote_collector_station_id}&token=${remote_collector_token}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type=remote-rest,host_hostname="${host_hostname}" --config.file=/weatherflow-collector/loki-config.yml
  after=$(date +%s)
  DELAY=$(echo "${remote_rest_interval}-($after-$before)" | bc)
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
  curl "${curl[@]}" -w "\n" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/observations/station/${remote_collector_station_id}?token=${remote_collector_token}" | /weatherflow-collector/remote-rest-influxdb.sh
  after=$(date +%s)
  DELAY=$(echo "${remote_rest_interval}-($after-$before)" | bc)
  echo "Sleeping ${DELAY}"
  sleep "$DELAY"
done

else

echo "No Backend Configured"

fi

else

echo "No Remote Collector Configured"

fi
