#!/bin/bash

##
## WeatherFlow Collector - REMOTE-REST
##

collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE
collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE
debug=$WEATHERFLOW_COLLECTOR_DEBUG
elevation=$WEATHERFLOW_COLLECTOR_ELEVATION
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
latitude=$WEATHERFLOW_COLLECTOR_LATITUDE
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
longitude=$WEATHERFLOW_COLLECTOR_LONGITUDE
public_name=$WEATHERFLOW_COLLECTOR_PUBLIC_NAME
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID
station_name=$WEATHERFLOW_COLLECTOR_STATION_NAME
timezone=$WEATHERFLOW_COLLECTOR_TIMEZONE

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

##
## Health Check
##

health_check_file="/weatherflow-collector/health_check.txt"
touch ${health_check_file}

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

echo ${line} | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type="${collector_type}",host_hostname="${host_hostname}",public_name="${public_name}",station_id="${station_id}",station_name="${station_name}",timezone="${timezone}" --config.file=/weatherflow-collector/loki-config.yml

fi

## Escape Names

## Spaces

public_name=$(echo "${public_name}" | sed 's/ /\\ /g')
station_name=$(echo "${station_name}" | sed 's/ /\\ /g')

## Commas

public_name=$(echo "${public_name}" | sed 's/,/\\,/g')
station_name=$(echo "${station_name}" | sed 's/,/\\,/g')

## Equal Signs

public_name=$(echo "${public_name}" | sed 's/=/\\=/g')
station_name=$(echo "${station_name}" | sed 's/=/\\=/g')


## Observations

## Start Timer

observations_start=$(date +%s%N)

## Read Observations

#elevation=$(echo "${line}" | jq -r .elevation)
#latitude=$(echo "${line}" | jq -r .latitude)
#longitude=$(echo "${line}" | jq -r .longitude)
#public_name=$(echo "${line}" | jq -r .public_name)
#station_id=$(echo "${line}" | jq -r .station_id)
#station_name=$(echo "${line}" | jq -r .station_name)
#timezone=$(echo "${line}" | jq -r .timezone)

air_density=$(echo "${line}" | jq -r .obs[].air_density)
air_temperature=$(echo "${line}" | jq -r .obs[].air_temperature)
barometric_pressure=$(echo "${line}" | jq -r .obs[].barometric_pressure)
brightness=$(echo "${line}" | jq -r .obs[].brightness)
delta_t=$(echo "${line}" | jq -r .obs[].delta_t)
dew_point=$(echo "${line}" | jq -r .obs[].dew_point)
feels_like=$(echo "${line}" | jq -r .obs[].feels_like)
heat_index=$(echo "${line}" | jq -r .obs[].heat_index)
lightning_strike_count=$(echo "${line}" | jq -r .obs[].lightning_strike_count)
lightning_strike_count_last_1hr=$(echo "${line}" | jq -r .obs[].lightning_strike_count_last_1hr)
lightning_strike_count_last_3hr=$(echo "${line}" | jq -r .obs[].lightning_strike_count_last_3hr)
lightning_strike_last_distance=$(echo "${line}" | jq -r .obs[].lightning_strike_last_distance)
lightning_strike_last_epoch=$(echo "${line}" | jq -r .obs[].lightning_strike_last_epoch)
precip=$(echo "${line}" | jq -r .obs[].precip)
precip_accum_last_1hr=$(echo "${line}" | jq -r .obs[].precip_accum_last_1hr)
precip_accum_local_day=$(echo "${line}" | jq -r .obs[].precip_accum_local_day)
precip_accum_local_yesterday=$(echo "${line}" | jq -r .obs[].precip_accum_local_yesterday)
precip_accum_local_yesterday_final=$(echo "${line}" | jq -r .obs[].precip_accum_local_yesterday_final)
precip_analysis_type_yesterday=$(echo "${line}" | jq -r .obs[].precip_analysis_type_yesterday)
precip_minutes_local_day=$(echo "${line}" | jq -r .obs[].precip_minutes_local_day)
precip_minutes_local_yesterday=$(echo "${line}" | jq -r .obs[].precip_minutes_local_yesterday)
precip_minutes_local_yesterday_final=$(echo "${line}" | jq -r .obs[].precip_minutes_local_yesterday_final)
pressure_trend=$(echo "${line}" | jq -r -r .obs[].pressure_trend)
relative_humidity=$(echo "${line}" | jq -r .obs[].relative_humidity)
sea_level_pressure=$(echo "${line}" | jq -r .obs[].sea_level_pressure)
solar_radiation=$(echo "${line}" | jq -r .obs[].solar_radiation)
station_pressure=$(echo "${line}" | jq -r .obs[].station_pressure)
uv=$(echo "${line}" | jq -r .obs[].uv)
wet_bulb_temperature=$(echo "${line}" | jq -r .obs[].wet_bulb_temperature)
wind_avg=$(echo "${line}" | jq -r .obs[].wind_avg)
wind_chill=$(echo "${line}" | jq -r .obs[].wind_chill)
wind_direction=$(echo "${line}" | jq -r .obs[].wind_direction)
wind_gust=$(echo "${line}" | jq -r .obs[].wind_gust)
wind_lull=$(echo "${line}" | jq -r .obs[].wind_lull)


if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone}"

echo "air_density=${air_density}
air_temperature=${air_temperature}
barometric_pressure=${barometric_pressure}
brightness=${brightness}
delta_t=${delta_t}
dew_point=${dew_point}
feels_like=${feels_like}
heat_index=${heat_index}
lightning_strike_count=${lightning_strike_count}
lightning_strike_count_last_1hr=${lightning_strike_count_last_1hr}
lightning_strike_count_last_3hr=${lightning_strike_count_last_3hr}
lightning_strike_last_distance=${lightning_strike_last_distance}
lightning_strike_last_epoch=${lightning_strike_last_epoch}000
precip=${precip}
precip_accum_last_1hr=${precip_accum_last_1hr}
precip_accum_local_day=${precip_accum_local_day}
precip_accum_local_yesterday=${precip_accum_local_yesterday}
precip_accum_local_yesterday_final=${precip_accum_local_yesterday_final}
precip_analysis_type_yesterday=${precip_analysis_type_yesterday}
precip_minutes_local_day=${precip_minutes_local_day}
precip_minutes_local_yesterday=${precip_minutes_local_yesterday}
precip_minutes_local_yesterday_final=${precip_minutes_local_yesterday_final}
pressure_trend=${pressure_trend}
relative_humidity=${relative_humidity}
sea_level_pressure=${sea_level_pressure}
solar_radiation=${solar_radiation}
station_pressure=${station_pressure}
uv=${uv}
wet_bulb_temperature=${wet_bulb_temperature}
wind_avg=${wind_avg}
wind_chill=${wind_chill}
wind_direction=${wind_direction}
wind_gust=${wind_gust}
wind_lull=${wind_lull}"

fi



#
# Pressure Trend
#

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

## Send Data To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} air_density=${air_density}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} air_temperature=${air_temperature}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} barometric_pressure=${barometric_pressure}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} brightness=${brightness}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} delta_t=${delta_t}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} dew_point=${dew_point}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} feels_like=${feels_like}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} heat_index=${heat_index}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_count=${lightning_strike_count}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_count_last_1hr=${lightning_strike_count_last_1hr}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_count_last_3hr=${lightning_strike_count_last_3hr}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_last_distance=${lightning_strike_last_distance}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_last_epoch=${lightning_strike_last_epoch}000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip=${precip}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accum_last_1hr=${precip_accum_last_1hr}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accum_local_day=${precip_accum_local_day}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accum_local_yesterday=${precip_accum_local_yesterday}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accum_local_yesterday_final=${precip_accum_local_yesterday_final}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_analysis_type_yesterday=${precip_analysis_type_yesterday}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_minutes_local_day=${precip_minutes_local_day}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_minutes_local_yesterday=${precip_minutes_local_yesterday}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_minutes_local_yesterday_final=${precip_minutes_local_yesterday_final}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} pressure_trend=${pressure_trend}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} relative_humidity=${relative_humidity}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} sea_level_pressure=${sea_level_pressure}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} solar_radiation=${solar_radiation}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} station_pressure=${station_pressure}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} uv=${uv}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} wet_bulb_temperature=${wet_bulb_temperature}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_avg=${wind_avg}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_chill=${wind_chill}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_direction=${wind_direction}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_gust=${wind_gust}
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_lull=${wind_lull}"

## End Timer

observations_end=$(date +%s%N)
observations_duration=$((observations_end-observations_start))

echo "observations_duration:${observations_duration}"

## Send Timer Metrics To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},public_name=${public_name},station_id=${station_id},station_name=${station_name} duration=${observations_duration}"

done < /dev/stdin
