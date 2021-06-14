#!/bin/bash

##
## WeatherFlow Collector - exec-remote-forecast.sh
##

##
## WeatherFlow-Collector Details
##

source weatherflow-collector_details.sh

##
## Set Variables from Environmental Variables
##

debug=$WEATHERFLOW_COLLECTOR_DEBUG
debug_curl=$WEATHERFLOW_COLLECTOR_DEBUG_CURL
function=$WEATHERFLOW_COLLECTOR_FUNCTION
healthcheck=$WEATHERFLOW_COLLECTOR_HEALTHCHECK
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
logcli_host_url=$WEATHERFLOW_COLLECTOR_LOGCLI_URL
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID
threads=$WEATHERFLOW_COLLECTOR_THREADS
token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Run hourly build flag
##

hourly_time_build_check=$WEATHERFLOW_COLLECTOR_HOURLY_FORECAST_RUN

##
## Set Specific Variables
##

collector_type="remote-forecast"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (exec-remote-forecast.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
debug_curl=${debug_curl}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
hourly_time_build_check=${hourly_time_build_check}
import_days=${import_days}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
station_id=${station_id}
threads=${threads}
token=${token}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Set InfluxDB Precision to seconds
##

if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Curl Command
##

if [ "$debug_curl" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

##
## Start Reading in STDIN
##

##
## Health Check Function
##

health_check

while read -r line; do

##
## Check for null value coming in from the forecast collector/importer (part of the JQ parser if Loki returns an empty response.)
##

if [ "${line}" == "null" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} No valid forecast data."; exit 0; fi

##
## Source Variables
##

if [ -n "$logcli_host_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source remote-forecast-station_id-"${station_id}"-lookup.txt; fi

##
## Escape Names (Function)
##

escape_names

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

##
## Start Loki Timer
##

timer_loki_start=$(date +%s%N)

##
## Add meta information to raw JSON to enable importing .[1]
##

loki_meta="{\"collector_type\":\"${collector_type}\",\"elevation\":\"${elevation}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_key="${collector_key}",collector_type="${collector_type}",host_hostname="${host_hostname}",hub_sn="${hub_sn}",public_name="${public_name}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Loki Timer
##

timer_loki_end=$(date +%s%N)
timer_loki_duration=$((timer_loki_end-timer_loki_start))

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} timer_loki_duration:${timer_loki_duration}"; fi

##
## Send Loki Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_key=${collector_key},collector_type=${collector_type},duration_type="loki_push",host_hostname=${host_hostname},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped} duration=${timer_loki_duration}"

fi

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

echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} conditions=${conditions}"
echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} icon=${icon}"

fi

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_forecast_current,collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${conditions}" != "null" ]; then curl_message="${curl_message}conditions=\"${conditions}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} conditions is null"; fi
if [ "${icon}" != "null" ]; then curl_message="${curl_message}icon=\"${icon}\""; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} icon is null"; fi

##
## Timestamp set to InfluxDB time (no specific timestamp set
##

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

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

if  [ "${function}" == "import" ]; then num_of_days=$(echo "${line}" | jq -r '.[0].forecast.daily | length'); fi

if  [ "${function}" == "collector" ]; then num_of_days=$(echo "${line}" | jq -r '.forecast.daily | length'); fi

if [ "$debug" == "true" ]
then

echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} Number of forecast days=${num_of_days}"

fi

num_of_days_minus_one=$((num_of_days-1))

for day in $(seq 0 $num_of_days_minus_one) ; do

(

if  [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[0].forecast.daily['"${day}"'] | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi

if  [ "${function}" == "collector" ]; then eval "$(echo "${line}" | jq -r '.forecast.daily['"${day}"'] | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi

##
## Add 86399 seconds to provide end of day data points if viewing graphs after midnight
##

day_start_local_eod=$((day_start_local + 86399))

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} ${day}

air_temp_high=${air_temp_high}
air_temp_low=${air_temp_low}
conditions=${conditions}
day_num=${day_num}
day_relative=${day}
day_start_local=${day_start_local}
icon=${icon}
month_num=${month_num}
precip_probability=${precip_probability}
sunrise=${sunrise}
sunset=${sunset}"

fi

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_forecast_daily,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${air_temp_high}" != "null" ]; then curl_message="${curl_message}air_temp_high=${air_temp_high},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} air_temp_high is null"; fi
if [ "${air_temp_low}" != "null" ]; then curl_message="${curl_message}air_temp_low=${air_temp_low},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} air_temp_low is null"; fi
if [ "${conditions}" != "null" ]; then curl_message="${curl_message}conditions=\"${conditions}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} conditions is null"; fi
if [ "${day_num}" != "null" ]; then curl_message="${curl_message}day_num=${day_num},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} day_num is null"; fi
if [ "${day}" != "null" ]; then curl_message="${curl_message}day_relative=${day},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} day_relative is null"; fi
if [ "${day_start_local}" != "null" ]; then curl_message="${curl_message}day_start_local=${day_start_local}000,"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} day_start_local is null"; fi
if [ "${icon}" != "null" ]; then curl_message="${curl_message}icon=\"${icon}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} icon is null"; fi
if [ "${month_num}" != "null" ]; then curl_message="${curl_message}month_num=${month_num},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} month_num is null"; fi
if [ "${precip_probability}" != "null" ]; then curl_message="${curl_message}precip_probability=${precip_probability},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} precip_probability is null"; fi
if [ "${sunrise}" != "null" ]; then curl_message="${curl_message}sunrise=${sunrise}000,"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} sunrise is null"; fi
if [ "${sunset}" != "null" ]; then curl_message="${curl_message}sunset=${sunset}000"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} sunset is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${day_start_local_eod}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi

##
## Set Current Conditions Forecast (only for the collector)
##

if [ "$day" == "0" ] && [ "${function}" == "collector" ]; then

## icon and conditions are pulled from the rest-call
## timestamp set to the current pull time (no set InfluxDB timestamp)

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_forecast_current,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${day_num},forecast_month_num=${month_num},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${air_temp_high}" != "null" ]; then curl_message="${curl_message}air_temp_high=${air_temp_high},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} air_temp_high is null"; fi
if [ "${air_temp_low}" != "null" ]; then curl_message="${curl_message}air_temp_low=${air_temp_low},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} air_temp_low is null"; fi
if [ "${day_num}" != "null" ]; then curl_message="${curl_message}day_num=${day_num},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} day_num is null"; fi
if [ "${month_num}" != "null" ]; then curl_message="${curl_message}month_num=${month_num},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} month_num is null"; fi
if [ "${precip_probability}" != "null" ]; then curl_message="${curl_message}precip_probability=${precip_probability},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} precip_probability is null"; fi
if [ "${sunrise}" != "null" ]; then curl_message="${curl_message}sunrise=${sunrise}000,"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} sunrise is null"; fi
if [ "${sunset}" != "null" ]; then curl_message="${curl_message}sunset=${sunset}000"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} sunset is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

) &

if [[ $(jobs -r -p | wc -l) -ge $threads ]]; then wait -n; fi

done

wait

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} ${station_name} Forecast Daily Build Finished!"; fi

##
## End "threading"
##

##
## End Timer
##

daily_end=$(date +%s%N)
daily_duration=$((daily_end-daily_start))

if [ "$debug" == "true" ]; then echo "daily_duration:${daily_duration}"; fi

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_system_stats,collector_key=${collector_key},collector_type=${collector_type},duration_type="forecast_daily_build",host_hostname=${host_hostname},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped} duration=${daily_duration}"

#curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

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

if [ "$function" == "import" ]; then hourly_time_build_check="true"; fi

if [ "${hourly_time_build_check}" == "true" ]; then

##
## Start Timer
##

hourly_start=$(date +%s%N)

##
## Start "threading"
##

if  [ "${function}" == "import" ]; then num_of_hours=$(echo "${line}" | jq -r '.[0].forecast.hourly | length'); fi

if  [ "${function}" == "collector" ]; then num_of_hours=$(echo "${line}" | jq -r '.forecast.hourly | length'); fi

if [ "$debug" == "true" ]; then echo "Number of forecast hours=${num_of_hours}"; fi

num_of_hours_minus_one=$((num_of_hours-1))

if [ "$function" == "import" ]; then

##
## Init Progress Bar
##

init_progress ${num_of_hours}

fi

for hour in $(seq 0 $num_of_hours_minus_one) ; do

(

if  [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[0].forecast.hourly['"${hour}"'] | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi

if  [ "${function}" == "collector" ]; then eval "$(echo "${line}" | jq -r '.forecast.hourly['"${hour}"'] | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi

##
## Calculate Number of Days Out for the Forecast
##

if [[ $hour -ge "0" ]] && [[ $hour -le "23" ]]; then forecast_hourly_days_out="0"; fi
if [[ $hour -ge "24" ]] && [[ $hour -le "47" ]]; then forecast_hourly_days_out="1"; fi
if [[ $hour -ge "48" ]] && [[ $hour -le "71" ]]; then forecast_hourly_days_out="2"; fi
if [[ $hour -ge "72" ]] && [[ $hour -le "95" ]]; then forecast_hourly_days_out="3"; fi
if [[ $hour -ge "96" ]] && [[ $hour -le "119" ]]; then forecast_hourly_days_out="4"; fi
if [[ $hour -ge "120" ]] && [[ $hour -le "143" ]]; then forecast_hourly_days_out="5"; fi
if [[ $hour -ge "144" ]] && [[ $hour -le "167" ]]; then forecast_hourly_days_out="6"; fi
if [[ $hour -ge "168" ]] && [[ $hour -le "191" ]]; then forecast_hourly_days_out="7"; fi
if [[ $hour -ge "192" ]] && [[ $hour -le "215" ]]; then forecast_hourly_days_out="8"; fi

##
## Sometimes there are a few extra hours available but we're going to include them as nine days out instead of 10
##

if [[ $hour -ge "216" ]] && [[ $hour -le "263" ]]; then forecast_hourly_days_out="9"; fi

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "
${hour}

air_temperature=${air_temperature}
conditions=${conditions}
feels_like=${feels_like}
icon=${icon}
local_day=${local_day}
local_hour=${local_hour}
precip=${precip}
precip_icon=${precip_icon}
precip_probability=${precip_probability}
precip_type=${precip_type}
relative_humidity=${relative_humidity}
sea_level_pressure=${sea_level_pressure}
time=${time}
uv=${uv}
wind_avg=${wind_avg}
wind_direction=${wind_direction}
wind_direction_cardinal=${wind_direction_cardinal}
wind_gust=${wind_gust}
days_out=${forecast_hourly_days_out}"

fi

##
## Send Data To InfluxDB
##

##
## Pad the $local_day variable and turn it into a string in order for Grafana to sort dashboard variables correctly
##

printf -v local_day_padded "%02d" "${local_day}"

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${air_temperature}" != "null" ]; then curl_message="${curl_message}air_temperature=${air_temperature},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} air_temperature is null"; fi
if [ "${conditions}" != "null" ]; then curl_message="${curl_message}conditions=\"${conditions}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} conditions is null"; fi
if [ "${feels_like}" != "null" ]; then curl_message="${curl_message}feels_like=${feels_like},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} feels_like is null"; fi
if [ "${icon}" != "null" ]; then curl_message="${curl_message}icon=\"${icon}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} icon is null"; fi
if [ "${local_day}" != "null" ]; then curl_message="${curl_message}local_day=${local_day},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} local_day is null"; fi
if [ "${local_day_padded}" != "null" ]; then curl_message="${curl_message}local_day_padded=\"${local_day_padded}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} local_day_padded is null"; fi
if [ "${local_hour}" != "null" ]; then curl_message="${curl_message}local_hour=${local_hour},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} local_hour is null"; fi
if [ "${precip}" != "null" ]; then curl_message="${curl_message}precip=${precip},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} precip is null"; fi
if [ "${precip_probability}" != "null" ]; then curl_message="${curl_message}precip_probability=${precip_probability},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} precip_probability is null"; fi
if [ "${relative_humidity}" != "null" ]; then curl_message="${curl_message}relative_humidity=${relative_humidity},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} relative_humidity is null"; fi
if [ "${sea_level_pressure}" != "null" ]; then curl_message="${curl_message}sea_level_pressure=${sea_level_pressure},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} sea_level_pressure is null"; fi
if [ "${uv}" != "null" ]; then curl_message="${curl_message}uv=${uv},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} uv is null"; fi
if [ "${wind_avg}" != "null" ]; then curl_message="${curl_message}wind_avg=${wind_avg},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_avg is null"; fi
if [ "${wind_direction}" != "null" ]; then curl_message="${curl_message}wind_direction=${wind_direction},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_direction is null"; fi
if [ "${wind_direction_cardinal}" != "null" ]; then curl_message="${curl_message}wind_direction_cardinal=\"${wind_direction_cardinal}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_direction_cardinal is null"; fi
if [ "${wind_gust}" != "null" ]; then curl_message="${curl_message}wind_gust=${wind_gust}"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_gust is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi

##
## Send a duplicate set of metrics with a forecast_hourly_days_out value of "0" since InfluxDB
## will consider am exact match (to overwrite and use in Forecasts)
##

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day},forecast_day_num_padded=${local_day_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=0,latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${air_temperature}" != "null" ]; then curl_message="${curl_message}air_temperature=${air_temperature},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} air_temperature is null"; fi
if [ "${conditions}" != "null" ]; then curl_message="${curl_message}conditions=\"${conditions}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} conditions is null"; fi
if [ "${feels_like}" != "null" ]; then curl_message="${curl_message}feels_like=${feels_like},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} feels_like is null"; fi
if [ "${icon}" != "null" ]; then curl_message="${curl_message}icon=\"${icon}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} icon is null"; fi
if [ "${local_day}" != "null" ]; then curl_message="${curl_message}local_day=${local_day},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} local_day is null"; fi
if [ "${local_day_padded}" != "null" ]; then curl_message="${curl_message}local_day_padded=\"${local_day_padded}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} local_day_padded is null"; fi
if [ "${local_hour}" != "null" ]; then curl_message="${curl_message}local_hour=${local_hour},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} local_hour is null"; fi
if [ "${precip}" != "null" ]; then curl_message="${curl_message}precip=${precip},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} precip is null"; fi
if [ "${precip_probability}" != "null" ]; then curl_message="${curl_message}precip_probability=${precip_probability},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} precip_probability is null"; fi
if [ "${relative_humidity}" != "null" ]; then curl_message="${curl_message}relative_humidity=${relative_humidity},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} relative_humidity is null"; fi
if [ "${sea_level_pressure}" != "null" ]; then curl_message="${curl_message}sea_level_pressure=${sea_level_pressure},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} sea_level_pressure is null"; fi
if [ "${uv}" != "null" ]; then curl_message="${curl_message}uv=${uv},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} uv is null"; fi
if [ "${wind_avg}" != "null" ]; then curl_message="${curl_message}wind_avg=${wind_avg},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_avg is null"; fi
if [ "${wind_direction}" != "null" ]; then curl_message="${curl_message}wind_direction=${wind_direction},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_direction is null"; fi
if [ "${wind_direction_cardinal}" != "null" ]; then curl_message="${curl_message}wind_direction_cardinal=\"${wind_direction_cardinal}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_direction_cardinal is null"; fi
if [ "${wind_gust}" != "null" ]; then curl_message="${curl_message}wind_gust=${wind_gust}"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_gust is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi

##
## Forecast considers local_hour=0 (midnight) to be part of the previous day.
## We're going to push that into the next day so that midnight is part of the next day as well.
##

if [[ $local_hour == "0" ]]
then
local_day_midnight=$((local_day + 1))
printf -v local_day_midnight_padded "%02d" "${local_day_midnight}"

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_forecast_hourly,collector_type=${collector_type},elevation=${elevation},forecast_day_num=${local_day_midnight},forecast_day_num_padded=${local_day_midnight_padded},forecast_hour_num=${local_hour},forecast_hourly_days_out=${forecast_hourly_days_out},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${air_temperature}" != "null" ]; then curl_message="${curl_message}air_temperature=${air_temperature},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} air_temperature is null"; fi
if [ "${conditions}" != "null" ]; then curl_message="${curl_message}conditions=\"${conditions}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} conditions is null"; fi
if [ "${feels_like}" != "null" ]; then curl_message="${curl_message}feels_like=${feels_like},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} feels_like is null"; fi
if [ "${icon}" != "null" ]; then curl_message="${curl_message}icon=\"${icon}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} icon is null"; fi
if [ "${local_day}" != "null" ]; then curl_message="${curl_message}local_day=${local_day},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} local_day is null"; fi
if [ "${local_day_padded}" != "null" ]; then curl_message="${curl_message}local_day_padded=\"${local_day_padded}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} local_day_padded is null"; fi
if [ "${local_hour}" != "null" ]; then curl_message="${curl_message}local_hour=${local_hour},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} local_hour is null"; fi
if [ "${precip}" != "null" ]; then curl_message="${curl_message}precip=${precip},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} precip is null"; fi
if [ "${precip_probability}" != "null" ]; then curl_message="${curl_message}precip_probability=${precip_probability},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} precip_probability is null"; fi
if [ "${relative_humidity}" != "null" ]; then curl_message="${curl_message}relative_humidity=${relative_humidity},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} relative_humidity is null"; fi
if [ "${sea_level_pressure}" != "null" ]; then curl_message="${curl_message}sea_level_pressure=${sea_level_pressure},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} sea_level_pressure is null"; fi
if [ "${uv}" != "null" ]; then curl_message="${curl_message}uv=${uv},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} uv is null"; fi
if [ "${wind_avg}" != "null" ]; then curl_message="${curl_message}wind_avg=${wind_avg},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_avg is null"; fi
if [ "${wind_direction}" != "null" ]; then curl_message="${curl_message}wind_direction=${wind_direction},"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_direction is null"; fi
if [ "${wind_direction_cardinal}" != "null" ]; then curl_message="${curl_message}wind_direction_cardinal=\"${wind_direction_cardinal}\","; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_direction_cardinal is null"; fi
if [ "${wind_gust}" != "null" ]; then curl_message="${curl_message}wind_gust=${wind_gust}"; else echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} wind_gust is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

) &

if [[ $(jobs -r -p | wc -l) -ge $threads ]]; then wait -n

fi

##
## Increment Progress Bar
##

if [ "$function" == "import" ]; then inc_progress; fi

done

wait

if [ "$function" == "import" ]; then printf '\nFinished!\n'; fi

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} ${station_name} Forecast Hourly Build Finished!"; fi

##
## End "threading"
##

## End Timer

hourly_end=$(date +%s%N)
hourly_duration=$((hourly_end-hourly_start))

if [ "$function" == "import" ]; then

hourly_duration_seconds=$((hourly_duration/1000000000))

echo -n "${echo_bold}${echo_color_start}${collector_type}:${echo_normal} $(date) - Import Duration: ${echo_bold}"; show_progress_time ${hourly_duration_seconds}

echo "${echo_normal}
"
fi


if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} hourly_duration:${hourly_duration}"; fi

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_system_stats,collector_key=${collector_key},collector_type=${collector_type},duration_type="forecast_hourly_build",host_hostname=${host_hostname},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped} duration=${hourly_duration}"

#curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

done < /dev/stdin