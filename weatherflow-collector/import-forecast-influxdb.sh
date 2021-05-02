#!/bin/bash

##
## WeatherFlow Collector - remote-forecast-influxdb.sh
##

backend_type=$WEATHERFLOW_COLLECTOR_BACKEND_TYPE
collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE
debug=$WEATHERFLOW_COLLECTOR_DEBUG
device_id=$WEATHERFLOW_COLLECTOR_DEVICE_ID
elevation=$WEATHERFLOW_COLLECTOR_ELEVATION
forecast_interval=$WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL
function=$WEATHERFLOW_COLLECTOR_FUNCTION
healthcheck=$WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
hub_sn=$WEATHERFLOW_COLLECTOR_HUB_SN
import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
latitude=$WEATHERFLOW_COLLECTOR_LATITUDE
logcli_host_url=$WEATHERFLOW_COLLECTOR_LOGCLI_URL
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
longitude=$WEATHERFLOW_COLLECTOR_LONGITUDE
public_name=$WEATHERFLOW_COLLECTOR_PUBLIC_NAME
rest_interval=$WEATHERFLOW_COLLECTOR_REST_INTERVAL
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID
station_name=$WEATHERFLOW_COLLECTOR_STATION_NAME
threads=$WEATHERFLOW_COLLECTOR_THREADS
timezone=$WEATHERFLOW_COLLECTOR_TIMEZONE
token=$WEATHERFLOW_COLLECTOR_TOKEN

if [ "$debug" == "true" ]

then

echo "Starting WeatherFlow Collector (remote-forecast-influxdb.sh) - https://github.com/lux4rd0/weatherflow-collector

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
## Curl Command
##

if [ "$debug" == "true" ]
then

curl=(  )

else

curl=( --silent --output /dev/null --show-error --fail )

fi

##
## Set Threads
##

if [ -z "$threads" ]

then

N=1

else

N=${threads}

fi

##
## Start Reading in STDIN
##

if [ "$healthcheck" == "true" ]
then

health_check_file="/weatherflow-collector/health_check.txt"
touch ${health_check_file}

fi

while read -r line; do

##
## Escape Names
##

## Spaces

public_name_escaped=$(echo "${public_name}" | sed 's/ /\\ /g')
station_name_escaped=$(echo "${station_name}" | sed 's/ /\\ /g')

## Commas

public_name_escaped=$(echo "${public_name_escaped}" | sed 's/,/\\,/g')
station_name_escaped=$(echo "${station_name_escaped}" | sed 's/,/\\,/g')

## Equal Signs

public_name_escaped=$(echo "${public_name_escaped}" | sed 's/=/\\=/g')
station_name_escaped=$(echo "${station_name_escaped}" | sed 's/=/\\=/g')

##
## Hourly Forecast
##

##
## Start Timer
##

hourly_start=$(date +%s%N)

##
## Start "threading"
##

num_of_hours=$(echo "${line}" | jq -r ".forecast.hourly | length")

if [ "$debug" == "true" ]
then

echo "Number of forecast hours: ${num_of_hours}"

fi

num_of_hours_minus_one=$((num_of_hours-1))

for hour in $(seq 0 $num_of_hours_minus_one) ; do

(

air_temperature=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].air_temperature")
conditions=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].conditions")
feels_like=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].feels_like")
icon=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].icon")
local_day=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].local_day")
local_hour=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].local_hour")
precip=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].precip")
precip_icon=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].precip_icon")
precip_probability=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].precip_probability")
precip_type=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].precip_type")
relative_humidity=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].relative_humidity")
sea_level_pressure=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].sea_level_pressure")
time=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].time")
uv=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].uv")
wind_avg=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].wind_avg")
wind_direction=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].wind_direction")
wind_direction_cardinal=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].wind_direction_cardinal")
wind_gust=$(echo "${line}" | jq -r ".forecast.hourly | .[$hour].wind_gust")

##
## Calculate Number of Days out for the Forecast
##


if [[ $hour -ge "0" ]] && [[ $hour -le "23" ]]
then
forecast_hourly_days_out="0"
fi

if [[ $hour -ge "24" ]] && [[ $hour -le "47" ]]
then
forecast_hourly_days_out="1"
fi

if [[ $hour -ge "48" ]] && [[ $hour -le "71" ]]
then
forecast_hourly_days_out="2"
fi

if [[ $hour -ge "72" ]] && [[ $hour -le "95" ]]
then
forecast_hourly_days_out="3"
fi

if [[ $hour -ge "96" ]] && [[ $hour -le "119" ]]
then
forecast_hourly_days_out="4"
fi

if [[ $hour -ge "120" ]] && [[ $hour -le "143" ]]
then
forecast_hourly_days_out="5"
fi

if [[ $hour -ge "144" ]] && [[ $hour -le "167" ]]
then
forecast_hourly_days_out="6"
fi

if [[ $hour -ge "168" ]] && [[ $hour -le "191" ]]
then
forecast_hourly_days_out="7"
fi

if [[ $hour -ge "192" ]] && [[ $hour -le "215" ]]
then
forecast_hourly_days_out="8"
fi

if [[ $hour -ge "216" ]] && [[ $hour -le "240" ]]
then
forecast_hourly_days_out="9"
fi


if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo ""
echo "${hour}"
echo ""

echo "forecast_hourly_air_temperature ${air_temperature}"
echo "forecast_hourly_conditions ${conditions}"
echo "forecast_hourly_feels_like ${feels_like}"
echo "forecast_hourly_icon ${icon}"
echo "forecast_hourly_local_day ${local_day}"
echo "forecast_hourly_local_hour ${local_hour}"
echo "forecast_hourly_precip ${precip}"
echo "forecast_hourly_precip_icon ${precip_icon}"
echo "forecast_hourly_precip_probability ${precip_probability}"
echo "forecast_hourly_precip_type ${precip_type}"
echo "forecast_hourly_relative_humidity ${relative_humidity}"
echo "forecast_hourly_sea_level_pressure ${sea_level_pressure}"
echo "forecast_hourly_time ${time}"
echo "forecast_hourly_uv ${uv}"
echo "forecast_hourly_wind_avg ${wind_avg}"
echo "forecast_hourly_wind_direction ${wind_direction}"
echo "forecast_hourly_wind_direction_cardinal ${wind_direction_cardinal}"
echo "forecast_hourly_wind_gust ${wind_gust}"

fi

##
## Send Data To InfluxDB
##

##
## Pad the $local_day variable and turn it into a string in order for Grafana to sort dashboard variables correctly
##

printf -v local_day_padded "%02d" "${local_day}"

#if [ "$debug" == "true" ]
#then

#echo "local_day: ${local_day}
#local_day: ${local_day}"

#fi

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} air_temperature=${air_temperature} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} conditions=\"${conditions}\" ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} feels_like=${feels_like} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} icon=\"${icon}\" ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} local_day=${local_day} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} local_day_padded=\"${local_day_padded}\" ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} local_hour=${local_hour} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip=${precip} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_probability=${precip_probability} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} relative_humidity=${relative_humidity} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} sea_level_pressure=${sea_level_pressure} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} uv=${uv} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_avg=${wind_avg} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_direction=${wind_direction} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_direction_cardinal=\"${wind_direction_cardinal}\" ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_gust=${wind_gust} ${time}000000000"

) &

    # allow to execute up to $N jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $N ]]; then
        # now there are $N jobs already running, so wait here for any job
        # to be finished so there is a place to start next one.
        wait -n
    fi

done

wait

##
## End "threading"
##

## End Timer

hourly_end=$(date +%s%N)
hourly_duration=$((hourly_end-hourly_start))

if [ "$debug" == "true" ]
then

echo "hourly_duration:${hourly_duration}"

## Send Timer Metrics To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} forecast_hourly_build_duration=${hourly_duration}"

fi

done < /dev/stdin