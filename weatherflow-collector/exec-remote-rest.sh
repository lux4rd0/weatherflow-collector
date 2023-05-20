#!/bin/bash

##
## WeatherFlow Collector - exec-remote-rest.sh
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

collector_type="remote-rest"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (exec-remote-rest.sh) - https://github.com/lux4rd0/weatherflow-collector

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

#if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Curl Command
##

if [ "$debug_curl" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

##
## Start Reading in STDIN
##

while read -r line; do

if [ "$debug" == "true" ]
then

echo ""
echo "${line}"
echo ""

fi

##
## Start Timer
##

observations_start=$(date +%s%N)

##
## Read Observations
##

eval "$(echo "${line}" | jq -r '. | to_entries | .[0,2,3,4,5,6,7,8,11] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"
eval "$(echo "${line}" | jq -r '.obs[] | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

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

echo "${line}" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.min-backoff=100ms --client.max-backoff=2s --client.max-retries=3 --client.external-labels=collector_key="${collector_key}",collector_type="${collector_type}",host_hostname="${host_hostname}",public_name="${public_name}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml

##
## End Loki Timer
##

timer_loki_end=$(date +%s%N)
timer_loki_duration=$((timer_loki_end-timer_loki_start))

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} timer_loki_duration:${timer_loki_duration}"; fi

##
## Send Loki Timer Metrics To InfluxDB
##

if [ -n "$influxdb_url" ]; then

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_key=${collector_key},collector_type=${collector_type},duration_type="loki_push",host_hostname=${host_hostname},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped} duration=${timer_loki_duration}"

fi
fi

##
## Print Metrics
##

if [ "$debug" == "true" ]
then

echo "collector_key=${collector_key},collector_type=${collector_type},elevation=${elevation},source=${function},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone}

timestamp=${timestamp}
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
illuminance=${brightness}
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

if [ "${pressure_trend}" = "falling" ]; then pressure_trend="-1"; fi

if [ "${pressure_trend}" = "steady" ]; then pressure_trend="0"; fi

if [ "${pressure_trend}" = "rising" ]; then pressure_trend="1"; fi

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]; then

curl_message="weatherflow_obs,collector_key=${collector_key},collector_type=${collector_type},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ -n "${timestamp}" ]; then curl_message="${curl_message}timestamp=${timestamp}000,"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} timestamp is null"; fi
if [ -n "${air_temperature}" ]; then curl_message="${curl_message}air_temperature=${air_temperature},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} air_temperature is null"; fi
if [ -n "${barometric_pressure}" ]; then curl_message="${curl_message}barometric_pressure=${barometric_pressure},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} barometric_pressure is null"; fi
if [ -n "${station_pressure}" ]; then curl_message="${curl_message}station_pressure=${station_pressure},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} station_pressure is null"; fi
if [ -n "${sea_level_pressure}" ]; then curl_message="${curl_message}sea_level_pressure=${sea_level_pressure},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} sea_level_pressure is null"; fi
if [ -n "${relative_humidity}" ]; then curl_message="${curl_message}relative_humidity=${relative_humidity},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} relative_humidity is null"; fi
if [ -n "${precip}" ]; then curl_message="${curl_message}precip=${precip},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} precip is null"; fi
if [ -n "${precip_accum_last_1hr}" ]; then curl_message="${curl_message}precip_accum_last_1hr=${precip_accum_last_1hr},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} precip_accum_last_1hr is null"; fi
if [ -n "${precip_accum_local_day}" ]; then curl_message="${curl_message}precip_accum_local_day=${precip_accum_local_day},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} precip_accum_local_day is null"; fi
if [ -n "${precip_accum_local_yesterday}" ]; then curl_message="${curl_message}precip_accum_local_yesterday=${precip_accum_local_yesterday},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} precip_accum_local_yesterday is null"; fi
if [ -n "${precip_accum_local_yesterday_final}" ]; then curl_message="${curl_message}precip_accum_local_yesterday_final=${precip_accum_local_yesterday_final},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} precip_accum_local_yesterday_final is null"; fi
if [ -n "${precip_minutes_local_day}" ]; then curl_message="${curl_message}precip_minutes_local_day=${precip_minutes_local_day},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} precip_minutes_local_day is null"; fi
if [ -n "${precip_minutes_local_yesterday}" ]; then curl_message="${curl_message}precip_minutes_local_yesterday=${precip_minutes_local_yesterday},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} precip_minutes_local_yesterday is null"; fi
if [ -n "${precip_minutes_local_yesterday_final}" ]; then curl_message="${curl_message}precip_minutes_local_yesterday_final=${precip_minutes_local_yesterday_final},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} precip_minutes_local_yesterday_final is null"; fi
if [ -n "${precip_analysis_type_yesterday}" ]; then curl_message="${curl_message}precip_analysis_type_yesterday=${precip_analysis_type_yesterday},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} precip_analysis_type_yesterday is null"; fi
if [ -n "${wind_avg}" ]; then curl_message="${curl_message}wind_avg=${wind_avg},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} wind_avg is null"; fi
if [ -n "${wind_direction}" ]; then curl_message="${curl_message}wind_direction=${wind_direction},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} wind_direction is null"; fi
if [ -n "${wind_gust}" ]; then curl_message="${curl_message}wind_gust=${wind_gust},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} wind_gust is null"; fi
if [ -n "${wind_lull}" ]; then curl_message="${curl_message}wind_lull=${wind_lull},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} wind_lull is null"; fi
if [ -n "${solar_radiation}" ]; then curl_message="${curl_message}solar_radiation=${solar_radiation},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} solar_radiation is null"; fi
if [ -n "${uv}" ]; then curl_message="${curl_message}uv=${uv},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} uv is null"; fi
if [ -n "${brightness}" ]; then curl_message="${curl_message}brightness=${brightness},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} brightness is null"; fi

##
## Set illuminance to brightness so that the different collectors can use the same names
##

if [ -n "${brightness}" ]; then curl_message="${curl_message}illuminance=${brightness},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} illuminance is null"; fi
if [ -n "${lightning_strike_last_epoch}" ]; then curl_message="${curl_message}lightning_strike_last_epoch=${lightning_strike_last_epoch}000,"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} lightning_strike_last_epoch is null"; fi
if [ -n "${lightning_strike_last_distance}" ]; then curl_message="${curl_message}lightning_strike_last_distance=${lightning_strike_last_distance},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} lightning_strike_last_distance is null"; fi
if [ -n "${lightning_strike_count}" ]; then curl_message="${curl_message}lightning_strike_count=${lightning_strike_count},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} lightning_strike_count is null"; fi
if [ -n "${lightning_strike_count_last_1hr}" ]; then curl_message="${curl_message}lightning_strike_count_last_1hr=${lightning_strike_count_last_1hr},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} lightning_strike_count_last_1hr is null"; fi
if [ -n "${lightning_strike_count_last_3hr}" ]; then curl_message="${curl_message}lightning_strike_count_last_3hr=${lightning_strike_count_last_3hr},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} lightning_strike_count_last_3hr is null"; fi
if [ -n "${feels_like}" ]; then curl_message="${curl_message}feels_like=${feels_like},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} feels_like is null"; fi
if [ -n "${heat_index}" ]; then curl_message="${curl_message}heat_index=${heat_index},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} heat_index is null"; fi
if [ -n "${wind_chill}" ]; then curl_message="${curl_message}wind_chill=${wind_chill},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} wind_chill is null"; fi
if [ -n "${dew_point}" ]; then curl_message="${curl_message}dew_point=${dew_point},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} dew_point is null"; fi
if [ -n "${wet_bulb_temperature}" ]; then curl_message="${curl_message}wet_bulb_temperature=${wet_bulb_temperature},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} wet_bulb_temperature is null"; fi
if [ -n "${delta_t}" ]; then curl_message="${curl_message}delta_t=${delta_t},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} delta_t is null"; fi
if [ -n "${air_density}" ]; then curl_message="${curl_message}air_density=${air_density},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} air_density is null"; fi
if [ -n "${pressure_trend}" ]; then curl_message="${curl_message}pressure_trend=${pressure_trend},"; else echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} pressure_trend is null"; fi

##
## Remove the trailing comma in curl_message even if there happens to be nulls
## (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${timestamp}000000000";

#echo "${curl_message}"

exec 3>&1

curl_status_code=$(curl "${curl[@]}" -i -XPOST -w "%{http_code}" -o >(cat >&3) "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

)

##
## Health Check Function
##

if [ "$curl_status_code" == "204" ]; then health_check; fi

##
## Send CURL Metrics To InfluxDB
##

#if [ -n "$influxdb_url" ]; then

#time_epoch=$(date +%s)

#curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
#weatherflow_system_stats,backend_function=obs,backend_status_code=${curl_status_code},backend_type=curl,collector_key=${collector_key},collector_type=${collector_type},host_hostname=${host_hostname},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped} time_epoch=${time_epoch}000"


#fi
fi

##
## End Timer
##

observations_end=$(date +%s%N)
observations_duration=$((observations_end-observations_start))

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}${station_name}${echo_normal} observations_duration:${observations_duration}"; fi

##
## Send Timer Metrics To InfluxDB
##

if [ -n "$influxdb_url" ]; then

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_key=${collector_key},collector_type=${collector_type},duration_type="observations",host_hostname=${host_hostname},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped} duration=${observations_duration}"

fi

##
## Health Check Function
##

if [ -z "$influxdb_url" ]; then health_check; fi

done < /dev/stdin
