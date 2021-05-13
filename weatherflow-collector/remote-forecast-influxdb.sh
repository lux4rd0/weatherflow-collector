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

# Run hourly build flag

hourly_time_build_check=$WEATHERFLOW_COLLECTOR_HOURLY_FORECAST_RUN

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

if [ "$debug" == "true" ]
then

echo ""
echo "${line}"
echo ""

fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

if [ -n "$loki_client_url" ] && [ "${function}" == "collector" ]

then

echo "${line}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type="${collector_type}",host_hostname="${host_hostname}",public_name="${public_name}",station_id="${station_id}",station_name="${station_name}",timezone="${timezone}" --config.file=/weatherflow-collector/loki-config.yml

fi

##
## Escape Names
##

##
## Spaces
##

public_name_escaped="${public_name// /\\ }"
station_name_escaped="${station_name// /\\ }"

##
## Commas
##

public_name_escaped="${public_name_escaped//,/\\,}"
station_name_escaped="${station_name_escaped//,/\\,}"

##
## Equal Signs
##

public_name_escaped="${public_name_escaped//=/\\=}"
station_name_escaped="${station_name_escaped//=/\\=}"

##
## ProgressBar - https://github.com/fearside/ProgressBar/
##

function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:                           
# 1.2.1.1 Progress : [########################################] 100%
printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}



##
## Only run Current Conditions in collector mode
##

if [ "$function" == "collector" ]
then

##
## Current Conditions
##

conditions=$(echo "${line}" | jq -r ".current_conditions.conditions")
icon=$(echo "${line}" | jq -r ".current_conditions.icon")

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "conditions ${conditions}"
echo "icon ${icon}"

fi

##
## Send Data To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_forecast_current,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} conditions=\"${conditions}\"
weatherflow_forecast_current,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} icon=\"${icon}\""

##
## Daily Forecast
##

##
## Start Timer
##

daily_start=$(date +%s%N)

##
## Start "threading"
##

num_of_days=$(echo "${line}" | jq -r ".forecast.daily | length")

if [ "$debug" == "true" ]
then

echo "Number of forecast days: ${num_of_days}"

fi

num_of_days_minus_one=$((num_of_days-1))

for day in $(seq 0 $num_of_days_minus_one) ; do

(

eval "$(echo "${line}" | jq -r '.forecast.daily['"${day}"'] | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

##
## Add 86399 seconds to provide end of day data points if viewing graphs after midnight
##

day_start_local_eod=$((day_start_local + 86399))

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "${day}"

echo "forecast_daily_air_temp_high ${air_temp_high}"
echo "forecast_daily_air_temp_low ${air_temp_low}"
echo "forecast_daily_conditions ${conditions}"
echo "forecast_daily_day_num ${day_num}"
echo "forecast_daily_day_start_local ${day_start_local}"
echo "forecast_daily_icon ${icon}"
echo "forecast_daily_month_num ${month_num}"
echo "forecast_daily_precip_probability ${precip_probability}"
echo "forecast_daily_sunrise ${sunrise}"
echo "forecast_daily_sunset ${sunset}"

fi

##
## Send Data To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_forecast_daily,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} air_temp_high=${air_temp_high} ${day_start_local_eod}000000000
weatherflow_forecast_daily,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} air_temp_low=${air_temp_low} ${day_start_local_eod}000000000
weatherflow_forecast_daily,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} conditions=\"${conditions}\" ${day_start_local_eod}000000000
weatherflow_forecast_daily,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} day_num=${day_num} ${day_start_local_eod}000000000
weatherflow_forecast_daily,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} day_start_local=${day_start_local}000 ${day_start_local_eod}000000000
weatherflow_forecast_daily,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} icon=\"${icon}\" ${day_start_local_eod}000000000
weatherflow_forecast_daily,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} month_num=${month_num} ${day_start_local_eod}000000000
weatherflow_forecast_daily,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_probability=${precip_probability} ${day_start_local_eod}000000000
weatherflow_forecast_daily,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} sunrise=${sunrise}000 ${day_start_local_eod}000000000
weatherflow_forecast_daily,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} sunset=${sunset}000 ${day_start_local_eod}000000000"

##
## Set Current Conditions Forecast (only for the collector)
##

if [ "$day" == "0" ] && [ "${function}" == "collector" ]

then

## icon and conditions are pulled from the rest-call
## timestamp set to the current pull time (no set InfluxDB timestamp)

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_forecast_current,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} air_temp_high=${air_temp_high}
weatherflow_forecast_current,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} air_temp_low=${air_temp_low}
weatherflow_forecast_current,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} day_num=${day_num}
weatherflow_forecast_current,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} month_num=${month_num}
weatherflow_forecast_current,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_probability=${precip_probability}
weatherflow_forecast_current,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} sunrise=${sunrise}000
weatherflow_forecast_current,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} sunset=${sunset}000"

fi

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

##
## End Timer
##

daily_end=$(date +%s%N)
daily_duration=$((daily_end-daily_start))

if [ "$debug" == "true" ]
then

echo "daily_duration:${daily_duration}"

fi

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} forecast_daily_build_duration=${daily_duration}"

fi

##
## Hourly Forecast
##

##
## Only run the hourly forecasts at 0, 15, 30, 45 minutes - check for flag
##

##
## Set the flag if we're importing data so that we make sure this runs
##

if [ "$function" == "import" ]
then

hourly_time_build_check="true"

fi

if [ "${hourly_time_build_check}" == "true" ]

then

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

eval "$(echo "${line}" | jq -r '.forecast.hourly['${hour}'] | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

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

##
## Sometimes there are a few extra hours available but we're going to include them as nine days out instead of 10
##

if [[ $hour -ge "216" ]] && [[ $hour -le "263" ]]
then
forecast_hourly_days_out="9"
fi

##
## Forecast considers local_hour=0 (midnight) to be part of the previous day.
## We're going to push that into the next day so that midnight is part
## of the next day
##

if [[ $local_hour == "0" ]]
then
local_day=$((local_day + 1))
fi

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "
${hour}

air_temperature: ${air_temperature}
conditions: ${conditions}
feels_like: ${feels_like}
icon: ${icon}
local_day: ${local_day}
local_hour: ${local_hour}
precip: ${precip}
precip_icon: ${precip_icon}
precip_probability: ${precip_probability}
precip_type: ${precip_type}
relative_humidity: ${relative_humidity}
sea_level_pressure: ${sea_level_pressure}
time: ${time}
uv: ${uv}
wind_avg: ${wind_avg}
wind_direction: ${wind_direction}
wind_direction_cardinal: ${wind_direction_cardinal}
wind_gust: ${wind_gust}
days_out: ${forecast_hourly_days_out}"

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

##
## Send a duplicate set of metrics with a forecast_hourly_days_out value of "0" since InfluxDB will consider am exact match (to overwrite and use in Forecasts)
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} air_temperature=${air_temperature} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} conditions=\"${conditions}\" ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} feels_like=${feels_like} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} icon=\"${icon}\" ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} local_day=${local_day} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} local_day_padded=\"${local_day_padded}\" ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} local_hour=${local_hour} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip=${precip} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_probability=${precip_probability} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} relative_humidity=${relative_humidity} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} sea_level_pressure=${sea_level_pressure} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} uv=${uv} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_avg=${wind_avg} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_direction=${wind_direction} ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_direction_cardinal=\"${wind_direction_cardinal}\" ${time}000000000
weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_gust=${wind_gust} ${time}000000000"

) &

    # allow to execute up to $N jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $N ]]; then
        # now there are $N jobs already running, so wait here for any job
        # to be finished so there is a place to start next one.
        wait -n

if [ "$function" == "import" ]
then

    ProgressBar "${hour}" ${num_of_hours_minus_one}

fi

    fi

done

wait

echo "
Finished!
"

##
## End "threading"
##

## End Timer

hourly_end=$(date +%s%N)
hourly_duration=$((hourly_end-hourly_start))

if [ "$debug" == "true" ]
then

echo "hourly_duration:${hourly_duration}"

fi

## Send Timer Metrics To InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} forecast_hourly_build_duration=${hourly_duration}"

fi

done < /dev/stdin
