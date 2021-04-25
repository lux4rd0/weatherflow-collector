#!/bin/bash

##
## WeatherFlow Collector - remote-rest-influxdb.sh
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

echo "Starting WeatherFlow Collector (remote-rest-influxdb.sh) - https://github.com/lux4rd0/weatherflow-collector

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
## Start Reading in STDIN
##

while read -r line; do

##
## Health Check
##

if [ "$healthcheck" == "true" ]
then

health_check_file="/weatherflow-collector/health_check.txt"
touch ${health_check_file}

fi

if [ "$debug" == "true" ]
then

echo ""
echo "${line}"
echo ""

fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

if [ -n "$loki_client_url" ]

then

echo "${line}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type="${collector_type}",host_hostname="${host_hostname}",public_name="${public_name_escaped}",station_id="${station_id}",station_name="${station_name}",timezone="${timezone}" --config.file=/weatherflow-collector/loki-config.yml

fi

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
## Observations
##

##
## Start Timer
##

observations_start=$(date +%s%N)

##
## Read Observations
##

timestamp=$(echo "${line}" | jq -r .obs[].timestamp)
air_temperature=$(echo "${line}" | jq -r .obs[].air_temperature)
barometric_pressure=$(echo "${line}" | jq -r .obs[].barometric_pressure)
station_pressure=$(echo "${line}" | jq -r .obs[].station_pressure)
sea_level_pressure=$(echo "${line}" | jq -r .obs[].sea_level_pressure)
relative_humidity=$(echo "${line}" | jq -r .obs[].relative_humidity)
precip=$(echo "${line}" | jq -r .obs[].precip)
precip_accum_last_1hr=$(echo "${line}" | jq -r .obs[].precip_accum_last_1hr)
precip_accum_local_day=$(echo "${line}" | jq -r .obs[].precip_accum_local_day)
precip_accum_local_yesterday=$(echo "${line}" | jq -r .obs[].precip_accum_local_yesterday)
precip_accum_local_yesterday_final=$(echo "${line}" | jq -r .obs[].precip_accum_local_yesterday_final)
precip_minutes_local_day=$(echo "${line}" | jq -r .obs[].precip_minutes_local_day)
precip_minutes_local_yesterday=$(echo "${line}" | jq -r .obs[].precip_minutes_local_yesterday)
precip_minutes_local_yesterday_final=$(echo "${line}" | jq -r .obs[].precip_minutes_local_yesterday_final)
precip_analysis_type_yesterday=$(echo "${line}" | jq -r .obs[].precip_analysis_type_yesterday)
wind_avg=$(echo "${line}" | jq -r .obs[].wind_avg)
wind_direction=$(echo "${line}" | jq -r .obs[].wind_direction)
wind_gust=$(echo "${line}" | jq -r .obs[].wind_gust)
wind_lull=$(echo "${line}" | jq -r .obs[].wind_lull)
solar_radiation=$(echo "${line}" | jq -r .obs[].solar_radiation)
uv=$(echo "${line}" | jq -r .obs[].uv)
brightness=$(echo "${line}" | jq -r .obs[].brightness)
lightning_strike_last_epoch=$(echo "${line}" | jq -r .obs[].lightning_strike_last_epoch)
lightning_strike_last_distance=$(echo "${line}" | jq -r .obs[].lightning_strike_last_distance)
lightning_strike_count=$(echo "${line}" | jq -r .obs[].lightning_strike_count)
lightning_strike_count_last_1hr=$(echo "${line}" | jq -r .obs[].lightning_strike_count_last_1hr)
lightning_strike_count_last_3hr=$(echo "${line}" | jq -r .obs[].lightning_strike_count_last_3hr)
feels_like=$(echo "${line}" | jq -r .obs[].feels_like)
heat_index=$(echo "${line}" | jq -r .obs[].heat_index)
wind_chill=$(echo "${line}" | jq -r .obs[].wind_chill)
dew_point=$(echo "${line}" | jq -r .obs[].dew_point)
wet_bulb_temperature=$(echo "${line}" | jq -r .obs[].wet_bulb_temperature)
delta_t=$(echo "${line}" | jq -r .obs[].delta_t)
air_density=$(echo "${line}" | jq -r .obs[].air_density)
pressure_trend=$(echo "${line}" | jq -r .obs[].pressure_trend)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "collector_type=${collector_type},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},station_id=${station_id},station_name=${station_name},timezone=${timezone}"

echo "timestamp=${timestamp}
air_temperature=${air_temperature}
barometric_pressure=${barometric_pressure}
station_pressure=${station_pressure}
sea_level_pressure=${sea_level_pressure}
relative_humidity=${relative_humidity}
precip=${precip}
precip_accum_last_1hr=${precip_accum_last_1hr}
precip_accum_local_day=${precip_accum_local_day}
precip_accum_local_yesterday=${precip_accum_local_yesterday}
precip_accum_local_yesterday_final=${precip_accum_local_yesterday_final}
precip_minutes_local_day=${precip_minutes_local_day}
precip_minutes_local_yesterday=${precip_minutes_local_yesterday}
precip_minutes_local_yesterday_final=${precip_minutes_local_yesterday_final}
precip_analysis_type_yesterday=${precip_analysis_type_yesterday}
wind_avg=${wind_avg}
wind_direction=${wind_direction}
wind_gust=${wind_gust}
wind_lull=${wind_lull}
solar_radiation=${solar_radiation}
uv=${uv}
brightness=${brightness}
lightning_strike_last_epoch=${lightning_strike_last_epoch}
lightning_strike_last_distance=${lightning_strike_last_distance}
lightning_strike_count=${lightning_strike_count}
lightning_strike_count_last_1hr=${lightning_strike_count_last_1hr}
lightning_strike_count_last_3hr=${lightning_strike_count_last_3hr}
feels_like=${feels_like}
heat_index=${heat_index}
wind_chill=${wind_chill}
dew_point=${dew_point}
wet_bulb_temperature=${wet_bulb_temperature}
delta_t=${delta_t}
air_density=${air_density}
pressure_trend=${pressure_trend}"

fi

##
## Map Pressure Trend
##

if [ "${pressure_trend}" = "falling" ]
then
pressure_trend="-1"
fi

if [ "${pressure_trend}" = "steady" ]
then
pressure_trend="0"
fi

if [ "${pressure_trend}" = "rising" ]
then
pressure_trend="1"
fi

##
## Remove Null Entries
##

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

if [ "${precip_accum_local_yesterday_final}" = "null" ]
then
precip_accum_local_yesterday_final="0"
fi

if [ "${precip_analysis_type_yesterday}" = "null" ]
then
precip_analysis_type_yesterday="0"
fi

if [ "${precip_minutes_local_yesterday_final}" = "null" ]
then
precip_minutes_local_yesterday_final="0"
fi

##
## Send Data To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} air_density=${air_density} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} air_temperature=${air_temperature} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} barometric_pressure=${barometric_pressure} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} brightness=${brightness} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} delta_t=${delta_t} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} dew_point=${dew_point} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} feels_like=${feels_like} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} heat_index=${heat_index} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} lightning_strike_count=${lightning_strike_count} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} lightning_strike_count_last_1hr=${lightning_strike_count_last_1hr} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} lightning_strike_count_last_3hr=${lightning_strike_count_last_3hr} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} lightning_strike_last_distance=${lightning_strike_last_distance} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} lightning_strike_last_epoch=${lightning_strike_last_epoch}000 ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip=${precip} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_accum_last_1hr=${precip_accum_last_1hr} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_accum_local_day=${precip_accum_local_day} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_accum_local_yesterday=${precip_accum_local_yesterday} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_accum_local_yesterday_final=${precip_accum_local_yesterday_final} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_analysis_type_yesterday=${precip_analysis_type_yesterday} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_minutes_local_day=${precip_minutes_local_day} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_minutes_local_yesterday=${precip_minutes_local_yesterday} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_minutes_local_yesterday_final=${precip_minutes_local_yesterday_final} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} pressure_trend=${pressure_trend} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} relative_humidity=${relative_humidity} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} sea_level_pressure=${sea_level_pressure} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} solar_radiation=${solar_radiation} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} station_pressure=${station_pressure} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} timestamp=${timestamp}000 ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} uv=${uv} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wet_bulb_temperature=${wet_bulb_temperature} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_avg=${wind_avg} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_chill=${wind_chill} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_direction=${wind_direction} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_gust=${wind_gust} ${timestamp}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_lull=${wind_lull} ${timestamp}000000000"

##
## End Timer
##

observations_end=$(date +%s%N)
observations_duration=$((observations_end-observations_start))

if [ "$debug" == "true" ]
then

echo "observations_duration:${observations_duration}"

fi

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},source=${function},public_name=${public_name_escaped},station_id=${station_id},station_name=${station_name_escaped} duration=${observations_duration}"

done < /dev/stdin