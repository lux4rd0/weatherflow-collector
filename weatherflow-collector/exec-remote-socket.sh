#!/bin/bash

##
## WeatherFlow Collector - exec-remote-socket.sh
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
token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Set Specific Variables
##

collector_type="remote-socket"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (exec-remote-socket.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
debug_curl=${debug_curl}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
import_days=${import_days}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
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

while read -r line; do

##
## Health Check Function
##

health_check

##
## Print STDIN
##

if [ "$debug" == "true" ]
then

echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} ${line}"

fi

##
## ╔╦╗┌─┐┌┬┐┌─┐┌─┐┌─┐┌┬┐
##  ║ ├┤ │││├─┘├┤ └─┐ │ 
##  ╩ └─┘┴ ┴┴  └─┘└─┘ ┴ 
##

if [[ $line == *"obs_st"* ]]; then

##
## We need the HUB serial number. Skip the message if it's missing.
## This tends to only happen on startup.
##

if  [ "${function}" == "import" ]
then

hub_sn=$(echo "${line}" | jq -r '.[1].hub_sn')

fi

if  [ "${function}" == "collector" ]
then

hub_sn=$(echo "${line}" | jq -r '.hub_sn')

fi

if [ "${hub_sn}" = "null" ]

then

echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} $(date) - Skipping first socket message to InfluxDB - (Missing hub_sn)"

else

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

device_id=$(echo "${line}" | jq -r '.[0].device_id')
firmware_revision=$(echo "${line}" | jq -r '.[0].firmware_revision')
serial_number=$(echo "${line}" | jq -r '.[0].serial_number')

obs=($(echo "${line}" | jq -r '.[0].obs[0] | @sh') )

eval "$(echo "${line}" | jq -r '.[0].summary | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

if  [ "${function}" == "collector" ]
then

device_id=$(echo "${line}" | jq -r '.device_id')
firmware_revision=$(echo "${line}" | jq -r '.firmware_revision')
serial_number=$(echo "${line}" | jq -r '.serial_number')

obs=($(echo "${line}" | jq -r '.obs[0] | @sh') )

eval "$(echo "${line}" | jq -r '.summary | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

time_epoch=${obs[0]}
wind_lull=${obs[1]}
wind_avg=${obs[2]}
wind_gust=${obs[3]}
wind_direction=${obs[4]}
wind_sample_interval=${obs[5]}
station_pressure=${obs[6]}
air_temperature=${obs[7]}
relative_humidity=${obs[8]}
illuminance=${obs[9]}
uv=${obs[10]}
solar_radiation=${obs[11]}
precip_accumulated=${obs[12]}
precipitation_type=${obs[13]}
lightning_strike_avg_distance=${obs[14]}
lightning_strike_count=${obs[15]}
battery=${obs[16]}
report_interval=${obs[17]}
local_daily_rain_accumulation=${obs[18]}

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

pressure_trend=${pressure_trend}
strike_count_1h=${strike_count_1h}
strike_count_3h=${strike_count_3h}
precip_total_1h=${precip_total_1h}
strike_last_dist=${strike_last_dist}
strike_last_epoch=${strike_last_epoch}
precip_accum_local_yesterday=${precip_accum_local_yesterday}
precip_analysis_type_yesterday=${precip_analysis_type_yesterday}
feels_like=${feels_like}
heat_index=${heat_index}
wind_chill=${wind_chill}
pulse_adj_ob_time=${pulse_adj_ob_time}
pulse_adj_ob_wind_avg=${pulse_adj_ob_wind_avg}
pulse_adj_ob_temp=${pulse_adj_ob_temp}
dew_point=${dew_point}
wet_bulb_temperature=${wet_bulb_temperature}
air_density=${air_density}
delta_t=${delta_t}
precip_minutes_local_day=${precip_minutes_local_day}"

fi

##
## Map Pressure Trend
##

if [ "${pressure_trend}" = "falling" ]; then pressure_trend="-1"; fi

if [ "${pressure_trend}" = "steady" ]; then pressure_trend="0"; fi

if [ "${pressure_trend}" = "rising" ]; then pressure_trend="1"; fi

##
## Source Variables
##

if [ -n "$logcli_host_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source remote-socket-device_id-"${device_id}"-lookup.txt; fi

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

loki_meta="{\"collector_type\":\"${collector_type}\",\"device_id\":\"${device_id}\",\"elevation\":\"${elevation}\",\"source\":\"${function}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_type="${collector_type}",device_id="${device_id}",source="${function}",hub_sn="${hub_sn}",host_hostname="${host_hostname}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Timer
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
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

##
## Push to InfluxDB
##

curl_message="weatherflow_obs,collector_key=${collector_key},collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${firmware_revision}" != "null" ]; then curl_message="${curl_message}firmware_revision=${firmware_revision}000,"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} firmware_revision is null"; fi
if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${wind_lull}" != "null" ]; then curl_message="${curl_message}wind_lull=${wind_lull},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_lull is null"; fi
if [ "${wind_avg}" != "null" ]; then curl_message="${curl_message}wind_avg=${wind_avg},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_avg is null"; fi
if [ "${wind_gust}" != "null" ]; then curl_message="${curl_message}wind_gust=${wind_gust},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_gust is null"; fi
if [ "${wind_direction}" != "null" ]; then curl_message="${curl_message}wind_direction=${wind_direction},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_direction is null"; fi
if [ "${wind_sample_interval}" != "null" ]; then curl_message="${curl_message}wind_sample_interval=${wind_sample_interval},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_sample_interval is null"; fi
if [ "${station_pressure}" != "null" ]; then curl_message="${curl_message}station_pressure=${station_pressure},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} station_pressure is null"; fi
if [ "${air_temperature}" != "null" ]; then curl_message="${curl_message}air_temperature=${air_temperature},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} air_temperature is null"; fi
if [ "${relative_humidity}" != "null" ]; then curl_message="${curl_message}relative_humidity=${relative_humidity},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} relative_humidity is null"; fi
if [ "${illuminance}" != "null" ]; then curl_message="${curl_message}illuminance=${illuminance},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} illuminance is null"; fi
if [ "${uv}" != "null" ]; then curl_message="${curl_message}uv=${uv},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} uv is null"; fi
if [ "${solar_radiation}" != "null" ]; then curl_message="${curl_message}solar_radiation=${solar_radiation},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} solar_radiation is null"; fi
if [ "${precip_accumulated}" != "null" ]; then curl_message="${curl_message}precip_accumulated=${precip_accumulated},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precip_accumulated is null"; fi
if [ "${precipitation_type}" != "null" ]; then curl_message="${curl_message}precipitation_type=${precipitation_type},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precipitation_type is null"; fi
if [ "${lightning_strike_avg_distance}" != "null" ]; then curl_message="${curl_message}lightning_strike_avg_distance=${lightning_strike_avg_distance},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} lightning_strike_avg_distance is null"; fi
if [ "${lightning_strike_count}" != "null" ]; then curl_message="${curl_message}lightning_strike_count=${lightning_strike_count},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} lightning_strike_count is null"; fi
if [ "${battery}" != "null" ]; then curl_message="${curl_message}battery=${battery},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} battery is null"; fi
if [ "${report_interval}" != "null" ]; then curl_message="${curl_message}report_interval=${report_interval},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} report_interval is null"; fi
if [ "${local_daily_rain_accumulation}" != "null" ]; then curl_message="${curl_message}local_daily_rain_accumulation=${local_daily_rain_accumulation},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} local_daily_rain_accumulation is null"; fi

if [ -n "${pressure_trend}" ]; then curl_message="${curl_message}pressure_trend=${pressure_trend},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} pressure_trend is null"; fi
if [ -n "${strike_count_1h}" ]; then curl_message="${curl_message}strike_count_1h=${strike_count_1h},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} strike_count_1h is null"; fi
if [ -n "${strike_count_3h}" ]; then curl_message="${curl_message}strike_count_3h=${strike_count_3h},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} strike_count_3h is null"; fi
if [ -n "${precip_total_1h}" ]; then curl_message="${curl_message}precip_total_1h=${precip_total_1h},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precip_total_1h is null"; fi
if [ -n "${strike_last_dist}" ]; then curl_message="${curl_message}strike_last_dist=${strike_last_dist},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} strike_last_dist is null"; fi
if [ -n "${strike_last_epoch}" ]; then curl_message="${curl_message}strike_last_epoch=${strike_last_epoch}000,"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} strike_last_epoch is null"; fi
if [ -n "${precip_accum_local_yesterday}" ]; then curl_message="${curl_message}precip_accum_local_yesterday=${precip_accum_local_yesterday},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precip_accum_local_yesterday is null"; fi
if [ -n "${precip_analysis_type_yesterday}" ]; then curl_message="${curl_message}precip_analysis_type_yesterday=${precip_analysis_type_yesterday},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precip_analysis_type_yesterday is null"; fi
if [ -n "${feels_like}" ]; then curl_message="${curl_message}feels_like=${feels_like},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} feels_like is null"; fi
if [ -n "${heat_index}" ]; then curl_message="${curl_message}heat_index=${heat_index},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} heat_index is null"; fi
if [ -n "${wind_chill}" ]; then curl_message="${curl_message}wind_chill=${wind_chill},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_chill is null"; fi
if [ -n "${pulse_adj_ob_time}" ]; then curl_message="${curl_message}pulse_adj_ob_time=${pulse_adj_ob_time},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} pulse_adj_ob_time is null"; fi
if [ -n "${pulse_adj_ob_wind_avg}" ]; then curl_message="${curl_message}pulse_adj_ob_wind_avg=${pulse_adj_ob_wind_avg},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} pulse_adj_ob_wind_avg is null"; fi
if [ -n "${pulse_adj_ob_temp}" ]; then curl_message="${curl_message}pulse_adj_ob_temp=${pulse_adj_ob_temp},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} pulse_adj_ob_temp is null"; fi
if [ -n "${dew_point}" ]; then curl_message="${curl_message}dew_point=${dew_point},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} dew_point is null"; fi
if [ -n "${wet_bulb_temperature}" ]; then curl_message="${curl_message}wet_bulb_temperature=${wet_bulb_temperature},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wet_bulb_temperature is null"; fi
if [ -n "${air_density}" ]; then curl_message="${curl_message}air_density=${air_density},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} air_density is null"; fi
if [ -n "${delta_t}" ]; then curl_message="${curl_message}delta_t=${delta_t},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} delta_t is null"; fi
if [ -n "${precip_minutes_local_day}" ]; then curl_message="${curl_message}precip_minutes_local_day=${precip_minutes_local_day}"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precip_minutes_local_day is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi
fi

##
## ╔═╗┬┬─┐
## ╠═╣│├┬┘
## ╩ ╩┴┴└─
##

if [[ $line == *"obs_air"* ]]; then

##
## We need the HUB serial number. Skip the message if it's missing.
## This tends to only happen on startup.
##

if  [ "${function}" == "import" ]
then

hub_sn=$(echo "${line}" | jq -r '.[1].hub_sn')

fi

if  [ "${function}" == "collector" ]
then

hub_sn=$(echo "${line}" | jq -r '.hub_sn')

fi

if [ "${hub_sn}" = "null" ]

then
echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} Skipping first socket message to InfluxDB - (Missing hub_sn)"

else

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

device_id=$(echo "${line}" | jq -r '.[0].device_id')
firmware_revision=$(echo "${line}" | jq -r '.[0].firmware_revision')
serial_number=$(echo "${line}" | jq -r '.[0].serial_number')

obs=($(echo "${line}" | jq -r '.[0].obs[0] | @sh') )

##
## Summary
##

eval "$(echo "${line}" | jq -r '.[0].summary | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

if  [ "${function}" == "collector" ]
then

device_id=$(echo "${line}" | jq -r '.device_id')
firmware_revision=$(echo "${line}" | jq -r '.firmware_revision')
serial_number=$(echo "${line}" | jq -r '.serial_number')

obs=($(echo "${line}" | jq -r '.obs[0] | @sh') )

##
## Summary
##

eval "$(echo "${line}" | jq -r '.summary | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

time_epoch=${obs[0]}
station_pressure=${obs[1]}
air_temperature=${obs[2]}
relative_humidity=${obs[3]}
lightning_strike_count=${obs[4]}
lightning_strike_avg_distance=${obs[5]}
battery=${obs[6]}
report_interval=${obs[7]}

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
station_pressure=${station_pressure}
air_temperature=${air_temperature}
relative_humidity=${relative_humidity}
lightning_strike_count=${lightning_strike_count}
lightning_strike_avg_distance=${lightning_strike_avg_distance}
battery=${battery}
report_interval=${report_interval}

pressure_trend=${pressure_trend}
strike_count_1h=${strike_count_1h}
strike_count_3h=${strike_count_3h}
strike_last_dist=${strike_last_dist}
strike_last_epoch=${strike_last_epoch}
feels_like=${feels_like}
heat_index=${heat_index}
wind_chill=${wind_chill}
pulse_adj_ob_time=${pulse_adj_ob_time}
pulse_adj_ob_temp=${pulse_adj_ob_temp}
dew_point=${dew_point}
wet_bulb_temperature=${wet_bulb_temperature}
air_density=${air_density}
delta_t=${delta_t}"

fi

##
## Map Pressure Trend
##

if [ "${pressure_trend}" = "falling" ]; then pressure_trend="-1"; fi

if [ "${pressure_trend}" = "steady" ]; then pressure_trend="0"; fi

if [ "${pressure_trend}" = "rising" ]; then pressure_trend="1"; fi

##
## Source Variables
##

if [ -n "$logcli_host_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source remote-socket-device_id-"${device_id}"-lookup.txt; fi

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

loki_meta="{\"collector_type\":\"${collector_type}\",\"device_id\":\"${device_id}\",\"elevation\":\"${elevation}\",\"source\":\"${function}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_type="${collector_type}",device_id="${device_id}",source="${function}",hub_sn="${hub_sn}",host_hostname="${host_hostname}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Timer
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
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_obs,collector_key=${collector_key},collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${firmware_revision}" != "null" ]; then curl_message="${curl_message}firmware_revision=${firmware_revision}000,"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} firmware_revision is null"; fi
if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${station_pressure}" != "null" ]; then curl_message="${curl_message}station_pressure=${station_pressure},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} station_pressure is null"; fi
if [ "${air_temperature}" != "null" ]; then curl_message="${curl_message}air_temperature=${air_temperature},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} air_temperature is null"; fi
if [ "${relative_humidity}" != "null" ]; then curl_message="${curl_message}relative_humidity=${relative_humidity},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} relative_humidity is null"; fi
if [ "${lightning_strike_count}" != "null" ]; then curl_message="${curl_message}lightning_strike_count=${lightning_strike_count},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} lightning_strike_count is null"; fi
if [ "${lightning_strike_avg_distance}" != "null" ]; then curl_message="${curl_message}lightning_strike_avg_distance=${lightning_strike_avg_distance},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} lightning_strike_avg_distance is null"; fi
if [ "${battery}" != "null" ]; then curl_message="${curl_message}battery=${battery},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} battery is null"; fi
if [ "${report_interval}" != "null" ]; then curl_message="${curl_message}report_interval=${report_interval},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} report_interval is null"; fi

if [ -n "${pressure_trend}" ]; then curl_message="${curl_message}pressure_trend=${pressure_trend},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} pressure_trend is null"; fi
if [ -n "${strike_count_1h}" ]; then  curl_message="${curl_message}strike_count_1h=${strike_count_1h},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} strike_count_1h is null"; fi
if [ -n "${strike_count_3h}" ]; then curl_message="${curl_message}strike_count_3h=${strike_count_3h},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} strike_count_3h is null"; fi
if [ -n "${strike_last_dist}" ]; then curl_message="${curl_message}strike_last_dist=${strike_last_dist},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} strike_last_dist is null"; fi
if [ -n "${strike_last_epoch}" ]; then curl_message="${curl_message}strike_last_epoch=${strike_last_epoch}000,"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} strike_last_epoch is null"; fi
if [ -n "${feels_like}" ]; then curl_message="${curl_message}feels_like=${feels_like},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} feels_like is null"; fi
if [ -n "${heat_index}" ]; then curl_message="${curl_message}heat_index=${heat_index},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} heat_index is null"; fi
if [ -n "${wind_chill}" ]; then curl_message="${curl_message}wind_chill=${wind_chill},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_chill is null"; fi
if [ -n "${pulse_adj_ob_time}" ]; then curl_message="${curl_message}pulse_adj_ob_time=${pulse_adj_ob_time},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} pulse_adj_ob_time is null"; fi
if [ -n "${pulse_adj_ob_temp}" ]; then curl_message="${curl_message}pulse_adj_ob_temp=${pulse_adj_ob_temp},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} pulse_adj_ob_temp is null"; fi
if [ -n "${dew_point}" ]; then curl_message="${curl_message}dew_point=${dew_point},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} dew_point is null"; fi
if [ -n "${wet_bulb_temperature}" ]; then curl_message="${curl_message}wet_bulb_temperature=${wet_bulb_temperature},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wet_bulb_temperature is null"; fi
if [ -n "${air_density}" ]; then curl_message="${curl_message}air_density=${air_density},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} air_density is null"; fi
if [ -n "${delta_t}" ]; then curl_message="${curl_message}delta_t=${delta_t}"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} delta_t is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi
fi

##
## ╔═╗┬┌─┬ ┬
## ╚═╗├┴┐└┬┘
## ╚═╝┴ ┴ ┴ 
##

if [[ $line == *"obs_sky"* ]]; then

##
## We need the HUB serial number. Skip the message if it's missing.
## This tends to only happen on startup.
##

if  [ "${function}" == "import" ]
then

hub_sn=$(echo "${line}" | jq -r '.[1].hub_sn')

fi

if  [ "${function}" == "collector" ]
then

hub_sn=$(echo "${line}" | jq -r '.hub_sn')

fi

if [ "${hub_sn}" = "null" ]

then

echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} Skipping first socket message to InfluxDB - (Missing hub_sn)"

else

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

device_id=$(echo "${line}" | jq -r '.[0].device_id')
firmware_revision=$(echo "${line}" | jq -r '.[0].firmware_revision')
serial_number=$(echo "${line}" | jq -r '.[0].serial_number')

obs=($(echo "${line}" | jq -r '.[0].obs[0] | @sh') )

##
## Summary
##

eval "$(echo "${line}" | jq -r '.[0].summary | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

if  [ "${function}" == "collector" ]
then

device_id=$(echo "${line}" | jq -r '.device_id')
firmware_revision=$(echo "${line}" | jq -r '.firmware_revision')
serial_number=$(echo "${line}" | jq -r '.serial_number')

obs=($(echo "${line}" | jq -r '.obs[0] | @sh') )

##
## Summary
##

eval "$(echo "${line}" | jq -r '.summary | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

time_epoch=${obs[0]}
illuminance=${obs[1]}
uv=${obs[2]}
precip_accumulated=${obs[3]}
wind_lull=${obs[4]}
wind_avg=${obs[5]}
wind_gust=${obs[6]}
wind_direction=${obs[7]}
battery=${obs[8]}
report_interval=${obs[9]}
solar_radiation=${obs[10]}
precipitation_type=${obs[12]}
wind_sample_interval=${obs[13]}

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
illuminance=${illuminance}
uv=${uv}
precip_accumulated=${precip_accumulated}
wind_lull=${wind_lull}
wind_avg=${wind_avg}
wind_gust=${wind_gust}
wind_direction=${wind_direction}
battery=${battery}
report_interval=${report_interval}
solar_radiation=${solar_radiation}
precipitation_type=${precipitation_type}
wind_sample_interval=${wind_sample_interval}
precip_total_1h=${precip_total_1h}
precip_accum_local_yesterday=${precip_accum_local_yesterday}
precip_analysis_type_yesterday=${precip_analysis_type_yesterday}
pulse_adj_ob_time=${pulse_adj_ob_time}
pulse_adj_ob_wind_avg=${pulse_adj_ob_wind_avg}
precip_minutes_local_day=${precip_minutes_local_day}"

fi

##
## Source Variables
##

if [ -n "$logcli_host_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source remote-socket-device_id-"${device_id}"-lookup.txt; fi

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

loki_meta="{\"collector_type\":\"${collector_type}\",\"device_id\":\"${device_id}\",\"elevation\":\"${elevation}\",\"source\":\"${function}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_type="${collector_type}",device_id="${device_id}",source="${function}",hub_sn="${hub_sn}",host_hostname="${host_hostname}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Timer
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
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_obs,collector_key=${collector_key},collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${firmware_revision}" != "null" ]; then curl_message="${curl_message}firmware_revision=${firmware_revision}000,"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} firmware_revision is null"; fi
if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${illuminance}" != "null" ]; then curl_message="${curl_message}illuminance=${illuminance},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} illuminance is null"; fi
if [ "${uv}" != "null" ]; then curl_message="${curl_message}uv=${uv},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} uv is null"; fi
if [ "${precip_accumulated}" != "null" ]; then curl_message="${curl_message}precip_accumulated=${precip_accumulated},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precip_accumulated is null"; fi
if [ "${wind_lull}" != "null" ]; then curl_message="${curl_message}wind_lull=${wind_lull},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_lull is null"; fi
if [ "${wind_avg}" != "null" ]; then curl_message="${curl_message}wind_avg=${wind_avg},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_avg is null"; fi
if [ "${wind_gust}" != "null" ]; then curl_message="${curl_message}wind_gust=${wind_gust},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_gust is null"; fi
if [ "${wind_direction}" != "null" ]; then curl_message="${curl_message}wind_direction=${wind_direction},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_direction is null"; fi
if [ "${battery}" != "null" ]; then curl_message="${curl_message}battery=${battery},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} battery is null"; fi
if [ "${report_interval}" != "null" ]; then curl_message="${curl_message}report_interval=${report_interval},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} report_interval is null"; fi
if [ "${solar_radiation}" != "null" ]; then curl_message="${curl_message}solar_radiation=${solar_radiation},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} solar_radiation is null"; fi
if [ "${local_daily_rain_accumulation}" != "null" ]; then curl_message="${curl_message}local_daily_rain_accumulation=${local_daily_rain_accumulation},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} local_daily_rain_accumulation is null"; fi
if [ "${precipitation_type}" != "null" ]; then curl_message="${curl_message}precipitation_type=${precipitation_type},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precipitation_type is null"; fi
if [ "${wind_sample_interval}" != "null" ]; then curl_message="${curl_message}wind_sample_interval=${wind_sample_interval},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_sample_interval is null"; fi

if [ -n "${precip_total_1h}" ]; then curl_message="${curl_message}precip_total_1h=${precip_total_1h},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precip_total_1h is null"; fi
if [ -n "${precip_accum_local_yesterday}" ]; then curl_message="${curl_message}precip_accum_local_yesterday=${precip_accum_local_yesterday},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precip_accum_local_yesterday is null"; fi
if [ -n "${precip_analysis_type_yesterday}" ]; then curl_message="${curl_message}precip_analysis_type_yesterday=${precip_analysis_type_yesterday},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precip_analysis_type_yesterday is null"; fi
if [ -n "${pulse_adj_ob_time}" ]; then curl_message="${curl_message}pulse_adj_ob_time=${pulse_adj_ob_time},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} pulse_adj_ob_time is null"; fi
if [ -n "${pulse_adj_ob_wind_avg}" ]; then curl_message="${curl_message}pulse_adj_ob_wind_avg=${pulse_adj_ob_wind_avg},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} pulse_adj_ob_wind_avg is null"; fi
if [ -n "${precip_minutes_local_day}" ]; then curl_message="${curl_message}precip_minutes_local_day=${precip_minutes_local_day}"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} precip_minutes_local_day is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi
fi

##
## ┬─┐┌─┐┌─┐┬┌┬┐   ┬ ┬┬┌┐┌┌┬┐
## ├┬┘├─┤├─┘│ ││───│││││││ ││
## ┴└─┴ ┴┴  ┴─┴┘   └┴┘┴┘└┘─┴┘
##

if [[ $line == *"rapid_wind"* ]]; then

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

device_id=$(echo "${line}" | jq -r '.[0].device_id')
firmware_revision=$(echo "${line}" | jq -r '.[0].firmware_revision')
hub_sn=$(echo "${line}" | jq -r '.[0].hub_sn')
serial_number=$(echo "${line}" | jq -r '.[0].serial_number')

ob=($(echo "${line}" | jq -r '.[0].ob[] | @sh') )

fi

if  [ "${function}" == "collector" ]
then

device_id=$(echo "${line}" | jq -r '.device_id')
firmware_revision=$(echo "${line}" | jq -r '.firmware_revision')
hub_sn=$(echo "${line}" | jq -r '.hub_sn')
serial_number=$(echo "${line}" | jq -r '.serial_number')

ob=($(echo "${line}" | jq -r '.ob[] | @sh') )

fi

time_epoch=${ob[0]}
wind_speed=${ob[1]}
wind_direction=${ob[2]}

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "device_id=${device_id}
hub_sn=${hub_sn}
serial_number=${serial_number}

time_epoch=${time_epoch}
wind_speed=${wind_speed}
wind_direction=${wind_direction}"

fi

##
## Source Variables
##

if [ -n "$logcli_host_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source remote-socket-device_id-"${device_id}"-lookup.txt; fi

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

loki_meta="{\"collector_type\":\"${collector_type}\",\"device_id\":\"${device_id}\",\"elevation\":\"${elevation}\",\"source\":\"${function}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_type="${collector_type}",device_id="${device_id}",source="${function}",hub_sn="${hub_sn}",host_hostname="${host_hostname}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Timer
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
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_rapid_wind,collector_key=${collector_key},collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${wind_speed}" != "null" ]; then curl_message="${curl_message}wind_speed=${wind_speed},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_speed is null"; fi
if [ "${wind_direction}" != "null" ]; then curl_message="${curl_message}wind_direction=${wind_direction}"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} wind_direction is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

##
## ╦  ┬┌─┐┬ ┬┌┬┐┌┐┌┬┌┐┌┌─┐  ╔═╗┌┬┐┬─┐┬┬┌─┌─┐  ╔═╗┬  ┬┌─┐┌┐┌┌┬┐
## ║  ││ ┬├─┤ │ ││││││││ ┬  ╚═╗ │ ├┬┘│├┴┐├┤   ║╣ └┐┌┘├┤ │││ │ 
## ╩═╝┴└─┘┴ ┴ ┴ ┘└┘┴┘└┘└─┘  ╚═╝ ┴ ┴└─┴┴ ┴└─┘  ╚═╝ └┘ └─┘┘└┘ ┴ 
##

if [[ $line == *"evt_strike"* ]]; then

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

device_id=$(echo "${line}" | jq -r '.[0].device_id')

evt=($(echo "${line}" | jq -r '.[0].evt[] | @sh') )

fi

if  [ "${function}" == "collector" ]
then

device_id=$(echo "${line}" | jq -r '.device_id')

evt=($(echo "${line}" | jq -r '.evt[] | @sh') )

fi

time_epoch=${evt[0]}
distance=${evt[1]}
energy=${evt[2]}

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "device_id=${device_id}
hub_sn=${hub_sn}
serial_number=${serial_number}

time_epoch=${time_epoch}
distance=${distance}
energy=${energy}"

fi

##
## Source Variables
##

if [ -n "$logcli_host_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source remote-socket-device_id-"${device_id}"-lookup.txt; fi

hub_sn=$(echo "${line}" | jq -r .hub_sn)
serial_number=$(echo "${line}" | jq -r .serial_number)

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

loki_meta="{\"collector_type\":\"${collector_type}\",\"device_id\":\"${device_id}\",\"elevation\":\"${elevation}\",\"source\":\"${function}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_type="${collector_type}",device_id="${device_id}",source="${function}",hub_sn="${hub_sn}",host_hostname="${host_hostname}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Timer
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
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_evt_strike,collector_key=${collector_key},collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${distance}" != "null" ]; then curl_message="${curl_message}distance=${distance},"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} distance is null"; fi
if [ "${energy}" != "null" ]; then curl_message="${curl_message}energy=${energy}"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} energy is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

##
## ╦═╗┌─┐┬┌┐┌  ╔═╗┌┬┐┌─┐┬─┐┌┬┐  ╔═╗┬  ┬┌─┐┌┐┌┌┬┐
## ╠╦╝├─┤││││  ╚═╗ │ ├─┤├┬┘ │   ║╣ └┐┌┘├┤ │││ │ 
## ╩╚═┴ ┴┴┘└┘  ╚═╝ ┴ ┴ ┴┴└─ ┴   ╚═╝ └┘ └─┘┘└┘ ┴ 
##

if [[ $line == *"evt_precip"* ]]; then

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

device_id=$(echo "${line}" | jq -r '.[0].device_id')
hub_sn=$(echo "${line}" | jq -r '.[0].hub_sn')
serial_number=$(echo "${line}" | jq -r '.[0].serial_number')

evt=($(echo "${line}" | jq -r '.[0].evt[] | @sh') )

fi

if  [ "${function}" == "collector" ]
then

device_id=$(echo "${line}" | jq -r '.device_id')
hub_sn=$(echo "${line}" | jq -r '.hub_sn')
serial_number=$(echo "${line}" | jq -r '.serial_number')

evt=($(echo "${line}" | jq -r '.evt[] | @sh') )

fi

time_epoch=${evt[0]}

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "device_id=${device_id}
hub_sn=${hub_sn}
serial_number=${serial_number}

time_epoch=${time_epoch}"

fi

##
## Source Variables
##

if [ -n "$logcli_host_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source remote-socket-device_id-"${device_id}"-lookup.txt; fi

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

loki_meta="{\"collector_type\":\"${collector_type}\",\"device_id\":\"${device_id}\",\"elevation\":\"${elevation}\",\"source\":\"${function}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_type="${collector_type}",device_id="${device_id}",source="${function}",hub_sn="${hub_sn}",host_hostname="${host_hostname}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Timer
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
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_evt_precip,collector_key=${collector_key},collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} time_epoch is null"; fi

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

##
## ╔╦╗┌─┐┬  ┬┬┌─┐┌─┐  ╔═╗┌┐┌┬  ┬┌┐┌┌─┐  ╔═╗┬  ┬┌─┐┌┐┌┌┬┐
##  ║║├┤ └┐┌┘││  ├┤   ║ ║││││  ││││├┤   ║╣ └┐┌┘├┤ │││ │ 
## ═╩╝└─┘ └┘ ┴└─┘└─┘  ╚═╝┘└┘┴─┘┴┘└┘└─┘  ╚═╝ └┘ └─┘┘└┘ ┴ 
##

if [[ $line == *"evt_device_online"* ]]; then

if  [ "${function}" == "import" ]
then

eval "$(echo "${line}" | jq -r '.[0]. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

if  [ "${function}" == "collector" ]
then

eval "$(echo "${line}" | jq -r '. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

##
## Set seconds since epoch to create our own timestamp
##

time_epoch=$(date +%s)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "device_id=${device_id}
serial_number=${serial_number}

time_epoch=${time_epoch}"

fi

##
## Source Variables
##

if [ -n "$logcli_host_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source remote-socket-device_id-"${device_id}"-lookup.txt; fi

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

loki_meta="{\"time_epoch\":\"${time_epoch}\",\"collector_type\":\"${collector_type}\",\"device_id\":\"${device_id}\",\"elevation\":\"${elevation}\",\"source\":\"${function}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_type="${collector_type}",device_id="${device_id}",source="${function}",hub_sn="${hub_sn}",host_hostname="${host_hostname}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Timer
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
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_evt_device_online,collector_key=${collector_key},collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ -n "${time_epoch}" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} time_epoch is null"; fi

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

##
## ╔╦╗┌─┐┬  ┬┬┌─┐┌─┐  ╔═╗┌─┐┌─┐┬  ┬┌┐┌┌─┐  ╔═╗┬  ┬┌─┐┌┐┌┌┬┐
##  ║║├┤ └┐┌┘││  ├┤   ║ ║├┤ ├┤ │  ││││├┤   ║╣ └┐┌┘├┤ │││ │ 
## ═╩╝└─┘ └┘ ┴└─┘└─┘  ╚═╝└  └  ┴─┘┴┘└┘└─┘  ╚═╝ └┘ └─┘┘└┘ ┴ 
##

if [[ $line == *"evt_device_offline"* ]]; then

if  [ "${function}" == "import" ]
then

eval "$(echo "${line}" | jq -r '.[0]. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

if  [ "${function}" == "collector" ]
then

eval "$(echo "${line}" | jq -r '. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

##
## Set seconds since epoch to create our own timestamp
##

time_epoch=$(date +%s)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "device_id=${device_id}

time_epoch=${time_epoch}"

fi

##
## Source Variables
##

if [ -n "$logcli_host_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source remote-socket-device_id-"${device_id}"-lookup.txt; fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

##
## Start Loki Timer
##

timer_loki_start=$(date +%s%N)

##
## Add meta information to raw JSON to enable importing .[1] (Added time_epoch since it's not stored anywhere in the logs)
##

##
## no hub_sn, no serial_number in JSON
##

loki_meta="{\"time_epoch\":\"${time_epoch}\",\"collector_type\":\"${collector_type}\",\"device_id\":\"${device_id}\",\"elevation\":\"${elevation}\",\"source\":\"${function}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_type="${collector_type}",device_id="${device_id}",source="${function}",host_hostname="${host_hostname}",public_name="${public_name}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Timer
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
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

##
## no hub_sn, no serial_number in JSON
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_evt_device_offline,collector_key=${collector_key},collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ -n "${time_epoch}" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} time_epoch is null"; fi

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

##
## ╔═╗┌┬┐┌─┐┌┬┐┬┌─┐┌┐┌  ╔═╗┌┐┌┬  ┬┌┐┌┌─┐  ╔═╗┬  ┬┌─┐┌┐┌┌┬┐
## ╚═╗ │ ├─┤ │ ││ ││││  ║ ║││││  ││││├┤   ║╣ └┐┌┘├┤ │││ │ 
## ╚═╝ ┴ ┴ ┴ ┴ ┴└─┘┘└┘  ╚═╝┘└┘┴─┘┴┘└┘└─┘  ╚═╝ └┘ └─┘┘└┘ ┴ 
##

if [[ $line == *"evt_station_online"* ]]; then

if  [ "${function}" == "import" ]
then

eval "$(echo "${line}" | jq -r '.[0]. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

if  [ "${function}" == "collector" ]
then

eval "$(echo "${line}" | jq -r '. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

##
## Set seconds since epoch to create our own timestamp
##

time_epoch=$(date +%s)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "
serial_number=${serial_number}

device_id=${device_id}
location_id=${location_id}
station_id=${station_id}"

fi

##
## Source Variables (Uses station_id instead of device_id)
##

if [ -n "$logcli_host_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source remote-socket-station_id-"${station_id}"-lookup.txt; fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

##
## Start Loki Timer
##

timer_loki_start=$(date +%s%N)

##
## Add meta information to raw JSON to enable importing .[1] (Added time_epoch since it's not stored anywhere in the logs)
##

##
## hub_sn=${serial_number} - no serial_number
##

loki_meta="{\"time_epoch\":\"${time_epoch}\",\"collector_type\":\"${collector_type}\",\"device_id\":\"${device_id}\",\"elevation\":\"${elevation}\",\"source\":\"${function}\",\"hub_sn\":\"${serial_number}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_type="${collector_type}",device_id="${device_id}",source="${function}",hub_sn="${serial_number}",host_hostname="${host_hostname}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Timer
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
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

##
## hub_sn=${serial_number} - no serial_number
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_evt_station_online,collector_key=${collector_key},collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${serial_number},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ -n "${time_epoch}" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} time_epoch is null"; fi

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

##
## ╔═╗┌┬┐┌─┐┌┬┐┬┌─┐┌┐┌  ╔═╗┌─┐┌─┐┬  ┬┌┐┌┌─┐  ╔═╗┬  ┬┌─┐┌┐┌┌┬┐
## ╚═╗ │ ├─┤ │ ││ ││││  ║ ║├┤ ├┤ │  ││││├┤   ║╣ └┐┌┘├┤ │││ │ 
## ╚═╝ ┴ ┴ ┴ ┴ ┴└─┘┘└┘  ╚═╝└  └  ┴─┘┴┘└┘└─┘  ╚═╝ └┘ └─┘┘└┘ ┴ 
##

if [[ $line == *"evt_station_offline"* ]]; then

if  [ "${function}" == "import" ]
then

eval "$(echo "${line}" | jq -r '.[0]. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

if  [ "${function}" == "collector" ]
then

eval "$(echo "${line}" | jq -r '. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

##
## Set seconds since epoch to create our own timestamp
##

time_epoch=$(date +%s)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "
serial_number=${serial_number}

device_id=${device_id}
location_id=${location_id}
station_id=${station_id}"

fi

##
## Source Variables (Uses station_id instead of device_id)
##

if [ -n "$logcli_host_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source remote-socket-station_id-"${station_id}"-lookup.txt; fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

##
## Start Loki Timer
##

timer_loki_start=$(date +%s%N)

##
## Add meta information to raw JSON to enable importing .[1] (Added time_epoch since it's not stored anywhere in the logs)
##

##
## hub_sn=${serial_number} - no serial_number
##

loki_meta="{\"time_epoch\":\"${time_epoch}\",\"collector_type\":\"${collector_type}\",\"device_id\":\"${device_id}\",\"elevation\":\"${elevation}\",\"source\":\"${function}\",\"hub_sn\":\"${serial_number}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_type="${collector_type}",device_id="${device_id}",source="${function}",hub_sn="${serial_number}",host_hostname="${host_hostname}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Timer
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
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

##
## hub_sn=${serial_number} - no serial_number
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_evt_station_offline,collector_key=${collector_key},collector_type=${collector_type},device_id=${device_id},elevation=${elevation},source=${function},hub_sn=${serial_number},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ -n "${time_epoch}" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000"; else echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} time_epoch is null"; fi

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

done < /dev/stdin