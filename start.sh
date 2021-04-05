#!/bin/bash

debug=$WEATHERFLOW_LISTENER_DEBUG
collector_type=$WEATHERFLOW_LISTENER_COLLECTOR_TYPE
backend_type=$WEATHERFLOW_LISTENER_BACKEND_TYPE
remote_collector_device_id=$WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_DEVICE_ID
remote_collector_station_id=$WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_STATION_ID
remote_collector_token=$WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_TOKEN
loki_client_url=$WEATHERFLOW_LISTENER_LOKI_CLIENT_URL

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
echo "Starting WeatherFlow Listener"
echo ""
echo "Debug Environmental Variables"
echo ""
echo "collector_type=$WEATHERFLOW_LISTENER_COLLECTOR_TYPE"
echo "backend_type=$WEATHERFLOW_LISTENER_BACKEND_TYPE"
echo "remote_collector_device_id=$WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_DEVICE_ID"
echo "remote_collector_station_id=$WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_STATION_ID"
echo "remote_collector_token=$WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_TOKEN"
echo "loki_client_url=$WEATHERFLOW_LISTENER_LOKI_CLIENT_URL"
echo ""

else

echo ""
echo "Starting WeatherFlow Listener"
echo ""

fi

if [ "${collector_type}" = "local-udp" ]
then

echo "collector_type=${collector_type}"

if [ "${backend_type}" = "loki" ]
then

echo "backend_type=${backend_type}"

/usr/bin/stdbuf -oL /usr/bin/python /weatherflow-listener/weatherflow-listener.py | /usr/bin/promtail --stdin --client.url "$loki_client_url" --client.external-labels=collector_type=local-udp --config.file=/weatherflow-listener/loki-config.yml

elif  [ "${backend_type}" = "influxdb" ]
then

echo "backend_type=${backend_type}"

/usr/bin/stdbuf -oL /usr/bin/python /weatherflow-listener/weatherflow-listener.py | /weatherflow-listener/local-udp-influxdb.sh

else

echo "No Backend Configured"

fi

elif [ "${collector_type}" = "remote-socket" ]
then

echo "collector_type=${collector_type}"

if [ "${backend_type}" = "loki" ]
then

echo "backend_type=${backend_type}"

JSON='\n{"type":"listen_start", "device_id": "'"${remote_collector_device_id}"'", "id":"weatherflow_listener-start_'"${random_id}"'"}\n{"type":"listen_start_events", "station_id": "'"${remote_collector_station_id}"'", "id":"weatherflow_listener-start_events_'"${random_id}"'"}\n{"type":"listen_rapid_start", "device_id": "'"${remote_collector_device_id}"'", "id":"weatherflow_listener-rapid_start_'"${random_id}"'"}\n'

echo -e "$JSON" | /weatherflow-listener/websocat_amd64-linux-static -n "wss://ws.weatherflow.com/swd/data?token=${remote_collector_token}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type=remote-socket --config.file=/weatherflow-listener/loki-config.yml

elif  [ "${backend_type}" = "influxdb" ]
then

echo "backend_type=${backend_type}"

JSON='\n{"type":"listen_start", "device_id": "'"${remote_collector_device_id}"'", "id":"weatherflow_listener-start_'"${random_id}"'"}\n{"type":"listen_start_events", "station_id": "'"${remote_collector_station_id}"'", "id":"weatherflow_listener-start_events_'"${random_id}"'"}\n{"type":"listen_rapid_start", "device_id": "'"${remote_collector_device_id}"'", "id":"weatherflow_listener-rapid_start_'"${random_id}"'"}\n'

echo -e "$JSON" | /weatherflow-listener/websocat_amd64-linux-static -n "wss://ws.weatherflow.com/swd/data?token=${remote_collector_token}" | /weatherflow-listener/remote-socket-influxdb.sh

else

echo "No Backend Configured"

fi

elif [ "${collector_type}" = "remote-rest" ]
then

echo "collector_type=${collector_type}"

if [ "${backend_type}" = "loki" ]
then

echo "backend_type=${backend_type}"

while ( true ); do
  before=$(date +%s)
  curl "${curl[@]}" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${remote_collector_station_id}&token=${remote_collector_token}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type=remote-rest --config.file=/weatherflow-listener/loki-config.yml
  after=$(date +%s)
  DELAY=$(echo "3600-($after-$before)" | bc)
  sleep "$DELAY"
done

elif  [ "${backend_type}" = "influxdb" ]
then

echo "backend_type=${backend_type}"

while ( true ); do
  before=$(date +%s)
  curl "${curl[@]}" -w "\n" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${remote_collector_station_id}&token=${remote_collector_token}" | WEATHERFLOW_LISTENER_DEBUG=$WEATHERFLOW_LISTENER_DEBUG WEATHERFLOW_LISTENER_COLLECTOR_TYPE=$WEATHERFLOW_LISTENER_COLLECTOR_TYPE WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_DEVICE_ID=$WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_DEVICE_ID WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_STATION_ID=$WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_STATION_ID WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_TOKEN=$WEATHERFLOW_LISTENER_REMOTE_COLLECTOR_TOKEN WEATHERFLOW_LISTENER_LOKI_CLIENT_URL=$WEATHERFLOW_LISTENER_LOKI_CLIENT_URL /weatherflow-listener/remote-rest-influxdb.sh
  after=$(date +%s)
  DELAY=$(echo "3600-($after-$before)" | bc)
  sleep "$DELAY"
done

else

echo "No Backend Configured"

fi

else

echo "No Remote Collector Configured"

fi
