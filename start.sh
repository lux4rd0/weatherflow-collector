#!/bin/bash

debug=$WEATHERFLOW_LISTENER_DEBUG
api_type=$WEATHERFLOW_LISTENER_API_TYPE
backend_type=$WEATHERFLOW_LISTENER_BACKEND_TYPE
rest_device_id=$WEATHERFLOW_LISTENER_REST_DEVICE_ID
rest_station_id=$WEATHERFLOW_LISTENER_REST_STATION_ID
rest_token=$WEATHERFLOW_LISTENER_REST_TOKEN
loki_client_url=$WEATHERFLOW_LISTENER_LOKI_CLIENT_URL

# Random ID

random_id=$(od -A n -t d -N 1 /dev/urandom |tr -d ' ')

# Curl Command

if [ "$debug" = "true" ]
then

curl=(  )

else

curl=( --silent --show-error --fail)

fi


if [ "$debug" = "true" ]
then

echo ""
echo "Starting WeatherFlow Listener"
echo ""
echo "Debug Environmental Variables"
echo ""
echo "api_type=$WEATHERFLOW_LISTENER_API_TYPE"
echo "backend_type=$WEATHERFLOW_LISTENER_BACKEND_TYPE"
echo "rest_device_id=$WEATHERFLOW_LISTENER_REST_DEVICE_ID"
echo "rest_station_id=$WEATHERFLOW_LISTENER_REST_STATION_ID"
echo "rest_token=$WEATHERFLOW_LISTENER_REST_TOKEN"
echo "loki_client_url=$WEATHERFLOW_LISTENER_LOKI_CLIENT_URL"
echo ""

else

echo ""
echo "Starting WeatherFlow Listener"
echo ""

fi

if [ "$api_type" = "UDP" ]
then

echo "api_type=$api_type"

if [ "$backend_type" = "loki" ]
then

echo "backend_type=$backend_type"

/usr/bin/stdbuf -oL /usr/bin/python /weatherflow-listener/weatherflow-listener.py | /usr/bin/promtail --stdin --client.url "$loki_client_url" --client.external-labels=api=UDP --config.file=/weatherflow-listener/loki-config.yml

elif  [ "$backend_type" = "influxdb" ]
then

echo "backend_type=$backend_type"

/usr/bin/stdbuf -oL /usr/bin/python /weatherflow-listener/weatherflow-listener.py | /weatherflow-listener/udp-influxdb.sh

else

echo "No Backend Configured"

fi

elif [ "$api_type" = "REST" ]
then

echo "api_type=$api_type"

if [ "$backend_type" = "loki" ]
then

echo "backend_type=$backend_type"

JSON='\n{"type":"listen_start", "device_id": "'"${rest_device_id}"'", "id":"weatherflow_listener-start_'"${random_id}"'"}\n{"type":"listen_start_events", "station_id": "'"${rest_station_id}"'", "id":"weatherflow_listener-start_events_'"${random_id}"'"}\n{"type":"listen_rapid_start", "device_id": "'"${rest_device_id}"'", "id":"weatherflow_listener-rapid_start_'"${random_id}"'"}\n'

echo -e "$JSON" | /weatherflow-listener/websocat_amd64-linux-static -n "wss://ws.weatherflow.com/swd/data?token=${rest_token}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=api=REST --config.file=/weatherflow-listener/loki-config.yml

elif  [ "$backend_type" = "influxdb" ]
then

echo "backend_type=$backend_type"

JSON='\n{"type":"listen_start", "device_id": "'"${rest_device_id}"'", "id":"weatherflow_listener-start_'"${random_id}"'"}\n{"type":"listen_start_events", "station_id": "'"${rest_station_id}"'", "id":"weatherflow_listener-start_events_'"${random_id}"'"}\n{"type":"listen_rapid_start", "device_id": "'"${rest_device_id}"'", "id":"weatherflow_listener-rapid_start_'"${random_id}"'"}\n'

echo -e "$JSON" | /weatherflow-listener/websocat_amd64-linux-static -n "wss://ws.weatherflow.com/swd/data?token=${rest_token}" | /weatherflow-listener/rest-influxdb.sh

else

echo "No Backend Configured"

fi

elif [ "$api_type" = "FORECAST" ]
then

echo "api_type=$api_type"

if [ "$backend_type" = "loki" ]
then

echo "backend_type=$backend_type"

while ( true ); do
  before=$(date +%s)
  curl "${curl[@]}" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${rest_station_id}&token=${rest_token}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=api=FORECAST --config.file=/weatherflow-listener/loki-config.yml
  after=$(date +%s)
  DELAY=$(echo "3600-($after-$before)" | bc)
  sleep "$DELAY"
done

elif  [ "$backend_type" = "influxdb" ]
then

echo "backend_type=$backend_type"

while ( true ); do
  before=$(date +%s)
  curl "${curl[@]}" -w "\n" -X GET --header "Accept: application/json" "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${rest_station_id}&token=${rest_token}" | WEATHERFLOW_LISTENER_DEBUG=$WEATHERFLOW_LISTENER_DEBUG WEATHERFLOW_LISTENER_API_TYPE=$WEATHERFLOW_LISTENER_API_TYPE WEATHERFLOW_LISTENER_REST_DEVICE_ID=$WEATHERFLOW_LISTENER_REST_DEVICE_ID WEATHERFLOW_LISTENER_REST_STATION_ID=$WEATHERFLOW_LISTENER_REST_STATION_ID WEATHERFLOW_LISTENER_REST_TOKEN=$WEATHERFLOW_LISTENER_REST_TOKEN WEATHERFLOW_LISTENER_LOKI_CLIENT_URL=$WEATHERFLOW_LISTENER_LOKI_CLIENT_URL /weatherflow-listener/forecast-influxdb.sh
  after=$(date +%s)
  DELAY=$(echo "3600-($after-$before)" | bc)
  sleep "$DELAY"
done

else

echo "No Backend Configured"

fi

else

echo "No API Configured"

fi
