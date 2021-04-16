#!/bin/bash

##
## WeatherFlow Importer - remote-import-influxdb.sh
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

##
## Override collector_type for import
##

collector_type="local-udp"

# Curl Command

if [ "$debug" == "true" ]
then

curl=(  )

else

curl=( --silent --output /dev/null --show-error --fail )

fi

echo "Station Name: ${station_name}"

echo "Device ID: ${device_id}"

## Escape

## Spaces

public_name=$(echo "${public_name}" | sed 's/ /\\ /g')
station_name=$(echo "${station_name}" | sed 's/ /\\ /g')

## Commas

public_name=$(echo "${public_name}" | sed 's/,/\\,/g')
station_name=$(echo "${station_name}" | sed 's/,/\\,/g')

## Equal Signs

public_name=$(echo "${public_name}" | sed 's/=/\\=/g')
station_name=$(echo "${station_name}" | sed 's/=/\\=/g')

if [ "$debug" == "true" ]
then

echo "

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

fi

#
# Start Reading in STDIN
#

while read -r line; do

num_of_metrics=$(echo "${line}" |jq '.obs | length')

echo "Number of time slices: ${num_of_metrics}"

num_of_metrics_minus_one=$((num_of_metrics-1))

#echo "num_of_metrics_minus_one=${num_of_metrics_minus_one}"

## Start Timer

import_start=$(date +%s%N)

#
# Start "threading"
#

N=4

for metric in $(seq 0 $num_of_metrics_minus_one) ; do

(

#
# Observation (Tempest)
#

time_epoch=$(echo "${line}" | jq ".obs[$metric][0]")
wind_lull=$(echo "${line}" | jq ".obs[$metric][1]")
wind_avg=$(echo "${line}" | jq ".obs[$metric][2]")
wind_gust=$(echo "${line}" | jq ".obs[$metric][3]")
wind_direction=$(echo "${line}" | jq ".obs[$metric][4]")
wind_sample_interval=$(echo "${line}" | jq ".obs[$metric][5]")
station_pressure=$(echo "${line}" | jq ".obs[$metric][6]")
air_temperature=$(echo "${line}" | jq ".obs[$metric][7]")
relative_humidity=$(echo "${line}" | jq ".obs[$metric][8]")
illuminance=$(echo "${line}" | jq ".obs[$metric][9]")
uv=$(echo "${line}" | jq ".obs[$metric][10]")
solar_radiation=$(echo "${line}" | jq ".obs[$metric][11]")
precip_accumulated=$(echo "${line}" | jq ".obs[$metric][12]")
precipitation_type=$(echo "${line}" | jq ".obs[$metric][13]")
lightning_strike_avg_distance=$(echo "${line}" | jq ".obs[$metric][14]")
lightning_strike_count=$(echo "${line}" | jq ".obs[$metric][15]")
battery=$(echo "${line}" | jq ".obs[$metric][16]")
report_interval=$(echo "${line}" | jq ".obs[$metric][17]")
local_daily_rain_accumulation=$(echo "${line}" | jq ".obs[$metric][18]")
rain_accumulated_final_rain_check=$(echo "${line}" | jq ".obs[$metric][19]")
local_daily_rain_accumulation_final_rain_check=$(echo "${line}" | jq ".obs[$metric][20]")
precipitation_analysis_type=$(echo "${line}" | jq ".obs[$metric][21]")

#
# Remove Null Entries
#

if [ "${rain_accumulated_final_rain_check}" = "null" ]
then
rain_accumulated_final_rain_check="0"
fi

if [ "${local_daily_rain_accumulation_final_rain_check}" = "null" ]
then
local_daily_rain_accumulation_final_rain_check="0"
fi

if [ "${strike_last_dist}" = "null" ]
then
strike_last_dist="0"
fi

if [ "${strike_last_epoch}" = "null" ]
then
strike_last_epoch="0"
fi

if [ "${precip_accum_local_yesterday_final}" = "null" ]
then
precip_accum_local_yesterday_final="0"
fi

if [ "${precip_minutes_local_yesterday}" = "null" ]
then
precip_minutes_local_yesterday="0"
fi

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "obs,air_temperature ${air_temperature}"
echo "obs,battery ${battery}"
echo "obs,illuminance ${illuminance}"
echo "obs,lightning_strike_avg_distance ${lightning_strike_avg_distance}"
echo "obs,lightning_strike_count ${lightning_strike_count}"
echo "obs,local_daily_rain_accumulation ${local_daily_rain_accumulation}"
echo "obs,local_daily_rain_accumulation_final_rain_check ${local_daily_rain_accumulation_final_rain_check}"
echo "obs,precip_accumulated ${precip_accumulated}"
echo "obs,precipitation_analysis_type ${precipitation_analysis_type}"
echo "obs,precipitation_type ${precipitation_type}"
echo "obs,rain_accumulated_final_rain_check ${rain_accumulated_final_rain_check}"
echo "obs,relative_humidity ${relative_humidity}"
echo "obs,report_interval ${report_interval}"
echo "obs,solar_radiation ${solar_radiation}"
echo "obs,station_pressure ${station_pressure}"
echo "obs,time_epoch ${time_epoch}"
echo "obs,uv ${uv}"
echo "obs,wind_avg ${wind_avg}"
echo "obs,wind_direction ${wind_direction}"
echo "obs,wind_gust ${wind_gust}"
echo "obs,wind_lull ${wind_lull}"
echo "obs,wind_sample_interval ${wind_sample_interval}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} air_temperature=${air_temperature} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} battery=${battery} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} illuminance=${illuminance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_avg_distance=${lightning_strike_avg_distance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_count=${lightning_strike_count} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} local_daily_rain_accumulation=${local_daily_rain_accumulation} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} local_daily_rain_accumulation_final_rain_check=${local_daily_rain_accumulation_final_rain_check} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accumulated=${precip_accumulated} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} precipitation_analysis_type=${precipitation_analysis_type} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} precipitation_type=${precipitation_type} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} rain_accumulated_final_rain_check=${rain_accumulated_final_rain_check} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} relative_humidity=${relative_humidity} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} report_interval=${report_interval} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} solar_radiation=${solar_radiation} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} station_pressure=${station_pressure} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} uv=${uv} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_avg=${wind_avg} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_direction=${wind_direction} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_gust=${wind_gust} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_lull=${wind_lull} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_sample_interval=${wind_sample_interval} ${time_epoch}000000000"

) &

    # allow to execute up to $N jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $N ]]; then
        # now there are $N jobs already running, so wait here for any job
        # to be finished so there is a place to start next one.
        wait -n
    fi

done

wait

#
# End "threading"
#

## End Timer

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

echo "import_duration:${import_duration}"

## Send Timer Metrics To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},source=import,station_id=${station_id},station_name=${station_name},timezone=${timezone} duration=${import_duration}"

done < /dev/stdin
