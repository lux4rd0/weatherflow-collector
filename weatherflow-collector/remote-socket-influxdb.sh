#!/bin/bash

##
## WeatherFlow Collector - remote-socket-influxdb.sh
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

echo "Starting WeatherFlow Collector (remote-socket-influxdb.sh) - https://github.com/lux4rd0/weatherflow-collector

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
## Keep some names unescaped for Loki Tags
##

public_name_loki=$public_name
station_name_loki=$station_name

##
## Escape Names
##

## Spaces

public_name=$(echo "${public_name}" | sed 's/ /\\ /g')
station_name=$(echo "${station_name}" | sed 's/ /\\ /g')

## Commas

public_name=$(echo "${public_name}" | sed 's/,/\\,/g')
station_name=$(echo "${station_name}" | sed 's/,/\\,/g')

## Equal Signs

public_name=$(echo "${public_name}" | sed 's/=/\\=/g')
station_name=$(echo "${station_name}" | sed 's/=/\\=/g')

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

##
## Set seconds since Epoch for metric entries without it
##

time_epoch=$(date +%s)

if [ "$debug" == "true" ]
then

##
## Print Line
##

echo "${line}"

fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

if [ -n "$loki_client_url" ]

then

echo "${line}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type="${collector_type}",host_hostname="${host_hostname}",public_name="${public_name_loki}",station_id="${station_id}",station_name="${station_name_loki}",timezone="${timezone}" --config.file=/weatherflow-collector/loki-config.yml

fi

##
## Observation (Tempest)
##

if [[ $line == *"obs_st"* ]]; then

##
## Extract Metrics
##

device_id=$(echo "${line}" | jq -r .device_id)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
serial_number=$(echo "${line}" | jq -r .serial_number)
firmware_revision=$(echo "${line}" | jq -r .firmware_revision)

obs=($(echo "${line}" | jq -r '.obs[0] | @sh') )

time_epoch=$(echo "${obs[0]}")
wind_lull=$(echo "${obs[1]}")
wind_avg=$(echo "${obs[2]}")
wind_gust=$(echo "${obs[3]}")
wind_direction=$(echo "${obs[4]}")
wind_sample_interval=$(echo "${obs[5]}")
station_pressure=$(echo "${obs[6]}")
air_temperature=$(echo "${obs[7]}")
relative_humidity=$(echo "${obs[8]}")
illuminance=$(echo "${obs[9]}")
uv=$(echo "${obs[10]}")
solar_radiation=$(echo "${obs[11]}")
precip_accumulated=$(echo "${obs[12]}")
precipitation_type=$(echo "${obs[13]}")
lightning_strike_avg_distance=$(echo "${obs[14]}")
lightning_strike_count=$(echo "${obs[15]}")
battery=$(echo "${obs[16]}")
report_interval=$(echo "${obs[17]}")
local_daily_rain_accumulation=$(echo "${obs[18]}")
rain_accumulated_final_rain_check=$(echo "${obs[19]}")
local_daily_rain_accumulation_final_rain_check=$(echo "${obs[20]}")
precipitation_analysis_type=$(echo "${obs[21]}")

eval "$(echo "${line}" | jq -r '.summary | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

##
## Pressure Trend
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

if [ "${rain_accumulated_final_rain_check}" = "null" ] || [ -z "${rain_accumulated_final_rain_check}" ]
then
rain_accumulated_final_rain_check="0"
fi

if [ "${local_daily_rain_accumulation_final_rain_check}" = "null" ] || [ -z "${local_daily_rain_accumulation_final_rain_check}" ]
then
local_daily_rain_accumulation_final_rain_check="0"
fi

if [ "${strike_last_dist}" = "null" ] || [ -z "${strike_last_dist}" ]
then
strike_last_dist="0"
fi

if [ "${strike_last_epoch}" = "null" ] || [ -z "${strike_last_epoch}" ]
then
strike_last_epoch="0"
fi

if [ "${precip_accum_local_yesterday_final}" = "null" ] || [ -z "${precip_accum_local_yesterday_final}" ]
then
precip_accum_local_yesterday_final="0"
fi

if [ "${precip_minutes_local_yesterday}" = "null" ] || [ -z "${precip_minutes_local_yesterday}" ]
then
precip_minutes_local_yesterday="0"
fi

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "device_id=${device_id}
firmware_revision=${firmware_revision}
hub_sn=${hub_sn}
serial_number=${serial_number}

time_epoch=${time_epoch}
wind_lull=${wind_lull}
wind_avg=${wind_avg}
wind_gust=${wind_gust}
wind_direction=${wind_direction}
wind_sample_interval=${wind_sample_interval}
station_pressure=${station_pressure}
air_temperature=${air_temperature}
relative_humidity=${relative_humidity}
illuminance=${illuminance}
uv=${uv}
solar_radiation=${solar_radiation}
precip_accumulated=${precip_accumulated}
precipitation_type=${precipitation_type}
lightning_strike_avg_distance=${lightning_strike_avg_distance}
lightning_strike_count=${lightning_strike_count}
battery=${battery}
report_interval=${report_interval}
local_daily_rain_accumulation=${local_daily_rain_accumulation}
rain_accumulated_final_rain_check=${rain_accumulated_final_rain_check}
local_daily_rain_accumulation_final_rain_check=${local_daily_rain_accumulation_final_rain_check}
precipitation_analysis_type=${precipitation_analysis_type}

air_density=${air_density}
delta_t=${delta_t}
dew_point=${dew_point}
feels_like=${feels_like}
heat_index=${heat_index}
precip_accum_local_yesterday=${precip_accum_local_yesterday}
precip_accum_local_yesterday_final=${precip_accum_local_yesterday_final}
precip_analysis_type_yesterday=${precip_analysis_type_yesterday}
precip_minutes_local_day=${precip_minutes_local_day}
precip_minutes_local_yesterday=${precip_minutes_local_yesterday}
precip_total_1h=${precip_total_1h}
pressure_trend=${pressure_trend}
pulse_adj_ob_temp=${pulse_adj_ob_temp}
pulse_adj_ob_time=${pulse_adj_ob_time}
pulse_adj_ob_wind_avg=${pulse_adj_ob_wind_avg}
strike_count_1h=${strike_count_1h}
strike_count_3h=${strike_count_3h}
strike_last_dist=${strike_last_dist}
strike_last_epoch=${strike_last_epoch}
wet_bulb_temperature=${wet_bulb_temperature}
wind_chill=${wind_chill}"

fi

##
## Send metrics to InfluxDB
##

if [ "${hub_sn}" = "null" ]

  then
    echo "Skipping first socket message to InfluxDB - (Missing hub_sn)"

else

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} air_density=${air_density} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} air_temperature=${air_temperature} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} battery=${battery} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} delta_t=${delta_t} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} dew_point=${dew_point} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} feels_like=${feels_like} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} firmware_revision=${firmware_revision} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} heat_index=${heat_index} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} illuminance=${illuminance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_avg_distance=${lightning_strike_avg_distance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_count=${lightning_strike_count} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} local_daily_rain_accumulation=${local_daily_rain_accumulation} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} local_daily_rain_accumulation_final_rain_check=${local_daily_rain_accumulation_final_rain_check} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accum_local_yesterday=${precip_accum_local_yesterday} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accum_local_yesterday_final=${precip_accum_local_yesterday_final} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accumulated=${precip_accumulated} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_analysis_type_yesterday=${precip_analysis_type_yesterday} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_minutes_local_day=${precip_minutes_local_day} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_minutes_local_yesterday=${precip_minutes_local_yesterday} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_total_1h=${precip_total_1h} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precipitation_analysis_type=${precipitation_analysis_type} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precipitation_type=${precipitation_type} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} pressure_trend=${pressure_trend} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} pulse_adj_ob_temp=${pulse_adj_ob_temp} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} pulse_adj_ob_time=${pulse_adj_ob_time} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} pulse_adj_ob_wind_avg=${pulse_adj_ob_wind_avg} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} rain_accumulated_final_rain_check=${rain_accumulated_final_rain_check} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} relative_humidity=${relative_humidity} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} report_interval=${report_interval} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} solar_radiation=${solar_radiation} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} station_pressure=${station_pressure} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} strike_count_1h=${strike_count_1h} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} strike_count_3h=${strike_count_3h} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} strike_last_dist=${strike_last_dist} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} strike_last_epoch=${strike_last_epoch}000 ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} uv=${uv} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wet_bulb_temperature=${wet_bulb_temperature} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_avg=${wind_avg} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_chill=${wind_chill} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_direction=${wind_direction} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_gust=${wind_gust} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_lull=${wind_lull} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_sample_interval=${wind_sample_interval} ${time_epoch}000000000"

fi

fi

##
## Observation (Air)
##

if [[ $line == *"obs_air"* ]]; then

##
## Extract Metrics
##

device_id=$(echo "${line}" | jq -r .device_id)

time_epoch=$(echo "${line}" | jq ".obs[0][0]")
station_pressure=$(echo "${line}" | jq ".obs[0][1]")
air_temperature=$(echo "${line}" | jq ".obs[0][2]")
relative_humidity=$(echo "${line}" | jq ".obs[0][3]")
lightning_strike_count=$(echo "${line}" | jq ".obs[0][4]")
lightning_strike_avg_distance=$(echo "${line}" | jq ".obs[0][5]")
battery=$(echo "${line}" | jq ".obs[0][6]")
report_interval=$(echo "${line}" | jq ".obs[0][7]")

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "obs,device_id ${device_id}"
echo "obs,air_temperature ${air_temperature}"
echo "obs,battery ${battery}"
echo "obs,lightning_strike_avg_distance ${lightning_strike_avg_distance}"
echo "obs,lightning_strike_count ${lightning_strike_count}"
echo "obs,relative_humidity ${relative_humidity}"
echo "obs,report_interval ${report_interval}"
echo "obs,station_pressure ${station_pressure}"
echo "obs,time_epoch ${time_epoch}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} air_temperature=${air_temperature} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} battery=${battery} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_avg_distance=${lightning_strike_avg_distance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_count=${lightning_strike_count} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} relative_humidity=${relative_humidity} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} report_interval=${report_interval} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} station_pressure=${station_pressure} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch${time_epoch}000 ${time_epoch}000000000"

fi

##
## Observation (Sky)
##

if [[ $line == *"obs_sky"* ]]; then

##
## Extract Metrics
##

device_id=$(echo "${line}" | jq -r .device_id)

battery=$(echo "${line}" | jq ".obs[0][8]")
illuminance=$(echo "${line}" | jq ".obs[0][1]")
local_daily_rain_accumulation_final_rain_check=$(echo "${line}" | jq ".obs[0][15]")
precip_accumulated=$(echo "${line}" | jq ".obs[0][11]")
precip_accumulated=$(echo "${line}" | jq ".obs[0][3]")
precipitation_analysis_type=$(echo "${line}" | jq ".obs[0][16]")
precipitation_type=$(echo "${line}" | jq ".obs[0][12]")
rain_accumulated_final_rain_check=$(echo "${line}" | jq ".obs[0][14]")
report_interval=$(echo "${line}" | jq ".obs[0][9]")
solar_radiation=$(echo "${line}" | jq ".obs[0][10]")
time_epoch=$(echo "${line}" | jq ".obs[0][0]")
uv=$(echo "${line}" | jq ".obs[0][2]")
wind_avg=$(echo "${line}" | jq ".obs[0][5]")
wind_direction=$(echo "${line}" | jq ".obs[0][7]")
wind_gust=$(echo "${line}" | jq ".obs[0][6]")
wind_lull=$(echo "${line}" | jq ".obs[0][4]")
wind_sample_interval=$(echo "${line}" | jq ".obs[0][13]")

##
## Remove Null Entries
##

if [ "$precip_accumulated" = "null" ]
then
precip_accumulated="0"
fi

if [ "$rain_accumulated_final_rain_check" = "null" ]
then
rain_accumulated_final_rain_check="0"
fi

if [ "$local_daily_rain_accumulation_final_rain_check" = "null" ]
then
local_daily_rain_accumulation_final_rain_check="0"
fi

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "obs,device_id ${device_id}"
echo "obs,battery ${battery}"
echo "obs,illuminance ${illuminance}"
echo "obs,local_daily_rain_accumulation_final_rain_check ${local_daily_rain_accumulation_final_rain_check}"
echo "obs,precip_accumulated ${precip_accumulated}"
echo "obs,precip_accumulated ${precip_accumulated}"
echo "obs,precipitation_analysis_type ${precipitation_analysis_type}"
echo "obs,precipitation_type ${precipitation_type}"
echo "obs,rain_accumulated_final_rain_check ${rain_accumulated_final_rain_check}"
echo "obs,report_interval ${report_interval}"
echo "obs,solar_radiation ${solar_radiation}"
echo "obs,time_epoch ${time_epoch}"
echo "obs,uv ${uv}"
echo "obs,wind_avg ${wind_avg}"
echo "obs,wind_direction ${wind_direction}"
echo "obs,wind_gust ${wind_gust}"
echo "obs,wind_lull ${wind_lull}"
echo "obs,wind_sample_interval ${wind_sample_interval}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} battery=${battery} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} illuminance=${illuminance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} local_daily_rain_accumulation_final_rain_check=${local_daily_rain_accumulation_final_rain_check} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accumulated=${precip_accumulated} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accumulated=${precip_accumulated} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precipitation_analysis_type=${precipitation_analysis_type} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precipitation_type=${precipitation_type} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} rain_accumulated_final_rain_check=${rain_accumulated_final_rain_check} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} report_interval=${report_interval} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} solar_radiation=${solar_radiation} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch${time_epoch}000 ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} uv=${uv} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_avg=${wind_avg} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_direction=${wind_direction} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_gust=${wind_gust} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_lull=${wind_lull} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_sample_interval=${wind_sample_interval} ${time_epoch}000000000"

fi

##
## Rapid Wind
##

if [[ $line == *"rapid_wind"* ]]; then

##
## Extract Metrics
##

device_id=$(echo "${line}" | jq -r .device_id)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
serial_number=$(echo "${line}" | jq -r .serial_number)

time_epoch=$(echo "${line}" | jq ".ob[0]")
wind_speed=$(echo "${line}" | jq ".ob[1]")
wind_direction=$(echo "${line}" | jq ".ob[2]")

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "rapid_wind,device_id ${device_id}"
echo "rapid_wind,hub_sn ${hub_sn}"
echo "rapid_wind,serial_number ${serial_number}"
echo "rapid_wind,time_epoch ${time_epoch}"
echo "rapid_wind,wind_speed ${wind_speed}"
echo "rapid_wind,wind_direction ${wind_direction}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_rapid_wind,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000
weatherflow_rapid_wind,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_speed=${wind_speed} ${time_epoch}000000000
weatherflow_rapid_wind,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_direction=${wind_direction} ${time_epoch}000000000"

fi

##
## Lightning Strike Event
##

if [[ $line == *"evt_strike"* ]]; then

##
## Extract Metrics
##

device_id=$(echo "${line}" | jq -r .device_id)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
serial_number=$(echo "${line}" | jq -r .serial_number)

time_epoch=$(echo "${line}" | jq ".evt[0]")
distance=$(echo "${line}" | jq ".evt[1]")
energy=$(echo "${line}" | jq ".evt[2]")

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "evt_strike,device_id ${device_id}"
echo "evt_strike,hub_sn ${hub_sn}"
echo "evt_strike,serial_number ${serial_number}"
echo "evt_strike,time_epoch ${time_epoch}"
echo "evt_strike,distance ${distance}"
echo "evt_strike,energy ${energy}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_strike,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000
weatherflow_evt_strike,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} distance=${distance} ${time_epoch}000000000
weatherflow_evt_strike,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} energy=${energy} ${time_epoch}000000000"

fi

##
## Rain Start Event
##

if [[ $line == *"evt_precip"* ]]; then

##
## Extract Metrics
##

device_id=$(echo "${line}" | jq -r .device_id)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
serial_number=$(echo "${line}" | jq -r .serial_number)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "evt_precip,device_id ${device_id}"
echo "evt_precip,hub_sn ${hub_sn}"
echo "evt_precip,serial_number ${serial_number}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_precip,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000"

fi

##
## Acknowledgement
##

if [[ $line == *"ack"* ]]; then

##
## Extract Metrics
##

ack_id=$(echo "${line}" | jq -r .id)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "ack,id ${ack_id}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_ack,id=${ack_id},collector_type=${collector_type},source=${function} time_epoch=${time_epoch}000 ${time_epoch}000000000"

fi

##
## Device Online Event
##

if [[ $line == *"evt_device_online"* ]]; then

##
## Extract Metrics
##

evt_device_online_device_id=$(echo "${line}" | jq -r .device_id)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "evt_device_online,device_id ${evt_device_online_device_id}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_device_online,device_id=${evt_device_online_device_id},collector_type=${collector_type},source=${function} time_epoch=${time_epoch}000 ${time_epoch}000000000"

fi

##
## Device Offline Event
##

if [[ $line == *"evt_device_offline"* ]]; then

# Extract Metrics

evt_device_offline_device_id=$(echo "${line}" | jq -r .device_id)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "evt_device_offline,device_id ${evt_device_offline_device_id}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_device_offline,device_id=${evt_device_offline_device_id},collector_type=${collector_type},source=${function} time_epoch=${time_epoch}000 ${time_epoch}000000000"

fi

##
## Station Online Event
##

if [[ $line == *"evt_station_online"* ]]; then

##
## Extract Metrics
##

evt_station_online_station_id=$(echo "${line}" | jq -r .station_id)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "evt_station_online,station_id ${evt_station_online_station_id}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_station_online,station_id=${evt_station_online_station_id},collector_type=${collector_type},source=${function} time_epoch=${time_epoch}000 ${time_epoch}000000000"

fi

##
## Station Offline Event
##

if [[ $line == *"evt_station_offline"* ]]; then

##
## Extract Metrics
##

evt_station_offline_station_id=$(echo "${line}" | jq -r .station_id)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "evt_station_offline,station_id ${evt_station_offline_station_id}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_station_offline,station_id=${evt_station_offline_station_id},collector_type=${collector_type},source=${function} time_epoch=${time_epoch}000 ${time_epoch}000000000"

fi

done < /dev/stdin