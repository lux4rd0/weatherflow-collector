#!/bin/bash

# Debug

debug=$WEATHERFLOW_COLLECTOR_DEBUG

# InfluxDB Endpoint

influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
station_id=$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_STATION_ID

if [ "$debug" == "true" ]
then

#
# Print Environmental Variables
#

echo "$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE"
echo "$WEATHERFLOW_COLLECTOR_BACKEND_TYPE"
echo "$WEATHERFLOW_COLLECTOR_DEBUG"
echo "$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD"
echo "$WEATHERFLOW_COLLECTOR_INFLUXDB_URL"
echo "$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME"
echo "$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_DEVICE_ID"
echo "$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_STATION_ID"
echo "$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_TOKEN"

else

#
# Print Environmental Variables
#

echo "$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE"
echo "$WEATHERFLOW_COLLECTOR_BACKEND_TYPE"
echo "$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_DEVICE_ID"
echo "$WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_STATION_ID"

fi

# Curl Command

if [ "$debug" == "true" ]
then

curl=(  )

else

curl=( --silent --output /dev/null --show-error --fail )

fi

#
# Start Reading in STDIN
#

while read -r line; do

if [ "$debug" == "true" ]
then

echo ""
echo "${line}"
echo ""

fi

## Daily Forecast

## Start Timer

daily_start=$(date +%s%N)

for day in {0..9}

do

day_start_local=$(echo "${line}" |jq ".forecast.daily | .[$day].day_start_local")
day_num=$(echo "${line}" |jq ".forecast.daily | .[$day].day_num")
month_num=$(echo "${line}" |jq ".forecast.daily | .[$day].month_num")
conditions=$(echo "${line}" |jq ".forecast.daily | .[$day].conditions")
icon=$(echo "${line}" |jq ".forecast.daily | .[$day].icon")
sunrise=$(echo "${line}" |jq ".forecast.daily | .[$day].sunrise")
sunset=$(echo "${line}" |jq ".forecast.daily | .[$day].sunset")
air_temp_high=$(echo "${line}" |jq ".forecast.daily | .[$day].air_temp_high")
air_temp_low=$(echo "${line}" |jq ".forecast.daily | .[$day].air_temp_low")
precip_probability=$(echo "${line}" |jq ".forecast.daily | .[$day].precip_probability")

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo ""
echo "${day}"
echo ""

echo "forecast_daily_day_start_local ${day_start_local}"
echo "forecast_daily_day_num ${day_num}"
echo "forecast_daily_month_num ${month_num}"
echo "forecast_daily_conditions ${conditions}"
echo "forecast_daily_icon ${icon}"
echo "forecast_daily_sunrise ${sunrise}"
echo "forecast_daily_sunset ${sunset}"
echo "forecast_daily_air_temp_high ${air_temp_high}"
echo "forecast_daily_air_temp_low ${air_temp_low}"
echo "forecast_daily_precip_probability ${precip_probability}"

else

echo ""
echo "Day Loop: ${day} High: ${air_temp_high} Low: ${air_temp_low}"
echo ""

fi

## Send Data To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_forecast_daily,station_id=${station_id} day_num=${day_num} ${day_start_local}000000000
weatherflow_forecast_daily,station_id=${station_id} month_num=${month_num} ${day_start_local}000000000
weatherflow_forecast_daily,station_id=${station_id} conditions=${conditions} ${day_start_local}000000000
weatherflow_forecast_daily,station_id=${station_id} icon=${icon} ${day_start_local}000000000
weatherflow_forecast_daily,station_id=${station_id} sunrise=${sunrise}000 ${day_start_local}000000000
weatherflow_forecast_daily,station_id=${station_id} sunset=${sunset}000 ${day_start_local}000000000
weatherflow_forecast_daily,station_id=${station_id} air_temp_high=${air_temp_high} ${day_start_local}000000000
weatherflow_forecast_daily,station_id=${station_id} air_temp_low=${air_temp_low} ${day_start_local}000000000
weatherflow_forecast_daily,station_id=${station_id} precip_probability=${precip_probability} ${day_start_local}000000000"

done

## End Timer

daily_end=$(date +%s%N)
daily_duration=$((daily_end-daily_start))

echo "daily_duration:${daily_duration}"

## Send Timer Metrics To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_forecast_daily,station_id=${station_id} duration=${daily_duration}"

## Hourly Forecast

## Start Timer

hourly_start=$(date +%s%N)

for hour in {0..240}

do

time=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].time")
conditions=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].conditions")
icon=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].icon")
air_temperature=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].air_temperature")
sea_level_pressure=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].sea_level_pressure")
relative_humidity=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].relative_humidity")
precip=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].precip")
precip_probability=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].precip_probability")
precip_type=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].precip_type")
precip_icon=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].precip_icon")
wind_avg=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].wind_avg")
wind_direction=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].wind_direction")
wind_direction_cardinal=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].wind_direction_cardinal")
wind_gust=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].wind_gust")
uv=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].uv")
feels_like=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].feels_like")
local_hour=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].local_hour")
local_day=$(echo "${line}" |jq -r ".forecast.hourly | .[$hour].local_day")

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo ""
echo "${hour}"
echo ""

echo "forecast_hourly_time ${time}"
echo "forecast_hourly_conditions ${conditions}"
echo "forecast_hourly_icon ${icon}"
echo "forecast_hourly_air_temperature ${air_temperature}"
echo "forecast_hourly_sea_level_pressure ${sea_level_pressure}"
echo "forecast_hourly_relative_humidity ${relative_humidity}"
echo "forecast_hourly_precip ${precip}"
echo "forecast_hourly_precip_probability ${precip_probability}"
echo "forecast_hourly_precip_type ${precip_type}"
echo "forecast_hourly_precip_icon ${precip_icon}"
echo "forecast_hourly_wind_avg ${wind_avg}"
echo "forecast_hourly_wind_direction ${wind_direction}"
echo "forecast_hourly_wind_direction_cardinal ${wind_direction_cardinal}"
echo "forecast_hourly_wind_gust ${wind_gust}"
echo "forecast_hourly_uv ${uv}"
echo "forecast_hourly_feels_like ${feels_like}"
echo "forecast_hourly_local_hour ${local_hour}"
echo "forecast_hourly_local_day ${local_day}"

else

echo ""
echo "Hour Loop: ${hour} Time: ${time} Temperature: ${air_temperature}"
echo ""

fi

## Send Data To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_forecast_hourly,station_id=${station_id} conditions=\"${conditions}\" ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} icon=\"${icon}\" ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} air_temperature=${air_temperature} ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} sea_level_pressure=${sea_level_pressure} ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} relative_humidity=${relative_humidity} ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} precip=${precip} ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} precip_probability=${precip_probability} ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} wind_avg=${wind_avg} ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} wind_direction=${wind_direction} ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} wind_direction_cardinal=\"${wind_direction_cardinal}\" ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} wind_gust=${wind_gust} ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} uv=${uv} ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} feels_like=${feels_like} ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} local_hour=${local_hour} ${time}000000000
weatherflow_forecast_hourly,station_id=${station_id} local_day=${local_day} ${time}000000000"

done

## End Timer

hourly_end=$(date +%s%N)
hourly_duration=$((hourly_end-hourly_start))

echo "hourly_duration:${hourly_duration}"

## Send Timer Metrics To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_forecast_hourly,station_id=${station_id} duration=${hourly_duration}"

done < /dev/stdin
