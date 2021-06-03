#!/bin/bash

##
## WeatherFlow Collector - local-udp.sh
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
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
logcli_host_url=$WEATHERFLOW_COLLECTOR_LOGCLI_URL
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
public_name=$WEATHERFLOW_COLLECTOR_PUBLIC_NAME
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID
station_name=$WEATHERFLOW_COLLECTOR_STATION_NAME
token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Set Specific Variables
##

collector_type="local-udp"

if [ "$debug" == "true" ]

then

echo "Starting WeatherFlow Collector (local-udp.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
debug_curl=${debug_curl}
function=${function}
host_hostname=${host_hostname}
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

if [ "$debug" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

##
## Start Reading in STDIN
##

while read -r line; do

##
## Check for null value coming in from the forecast collector/importer
##

if [ "${line}" == "null" ]; then echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} No valid udp-local data."; exit 0; fi

##
## Health Check Function
##

health_check

##
## Print STDIN
##

if [ "$debug" == "true" ]
then

echo "${line}"

fi

# ╔╦╗┌─┐┌┬┐┌─┐┌─┐┌─┐┌┬┐
#  ║ ├┤ │││├─┘├┤ └─┐ │ 
#  ╩ └─┘┴ ┴┴  └─┘└─┘ ┴ 

if [[ $line == *"obs_st"* ]]; then

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

serial_number=$(echo "${line}" | jq -r '.[0].serial_number')
hub_sn=$(echo "${line}" | jq -r '.[0].hub_sn')
firmware_revision=$(echo "${line}" | jq -r '.[0].firmware_revision')

obs=($(echo "${line}" | jq -r '.[0].obs[] | @sh') )

fi

if  [ "${function}" == "collector" ]
then

serial_number=$(echo "${line}" | jq -r '.serial_number')
hub_sn=$(echo "${line}" | jq -r '.hub_sn')
firmware_revision=$(echo "${line}" | jq -r '.firmware_revision')

obs=($(echo "${line}" | jq -r '.obs[] | @sh') )

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

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "serial_number=${serial_number}
hub_sn=${hub_sn}
firmware_revision=${firmware_revision}

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
report_interval=${report_interval}"

fi

##
## Source Variables
##

if [ -n "$loki_client_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source local-udp-hub_sn-"${hub_sn}"-lookup.txt; fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

##
## Add meta information to raw JSON to enable importing .[1]
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

loki_meta="{\"collector_type\":\"${collector_type}\",\"elevation\":\"${elevation}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"source\":\"${function}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.external-labels=collector_key="${collector_key}",collector_type="${collector_type}",host_hostname="${host_hostname}",hub_sn="${hub_sn}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml; fi

##
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

##
## Push to InfluxDB
##

curl_message="weatherflow_obs,collector_key=${collector_key},collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${firmware_revision}" != "null" ]; then curl_message="${curl_message}firmware_revision=${firmware_revision},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} firmware_revision is null"; fi
if [ "${wind_lull}" != "null" ]; then curl_message="${curl_message}wind_lull=${wind_lull},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_lull is null"; fi
if [ "${wind_avg}" != "null" ]; then curl_message="${curl_message}wind_avg=${wind_avg},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_avg is null"; fi
if [ "${wind_gust}" != "null" ]; then curl_message="${curl_message}wind_gust=${wind_gust},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_gust is null"; fi
if [ "${wind_direction}" != "null" ]; then curl_message="${curl_message}wind_direction=${wind_direction},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_direction is null"; fi
if [ "${wind_sample_interval}" != "null" ]; then curl_message="${curl_message}wind_sample_interval=${wind_sample_interval},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_sample_interval is null"; fi
if [ "${station_pressure}" != "null" ]; then curl_message="${curl_message}station_pressure=${station_pressure},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} station_pressure is null"; fi
if [ "${air_temperature}" != "null" ]; then curl_message="${curl_message}air_temperature=${air_temperature},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} air_temperature is null"; fi
if [ "${relative_humidity}" != "null" ]; then curl_message="${curl_message}relative_humidity=${relative_humidity},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} relative_humidity is null"; fi
if [ "${illuminance}" != "null" ]; then curl_message="${curl_message}illuminance=${illuminance},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} illuminance is null"; fi
if [ "${uv}" != "null" ]; then curl_message="${curl_message}uv=${uv},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} uv is null"; fi
if [ "${solar_radiation}" != "null" ]; then curl_message="${curl_message}solar_radiation=${solar_radiation},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} solar_radiation is null"; fi
if [ "${precip_accumulated}" != "null" ]; then curl_message="${curl_message}precip_accumulated=${precip_accumulated},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} precip_accumulated is null"; fi
if [ "${precipitation_type}" != "null" ]; then curl_message="${curl_message}precipitation_type=${precipitation_type},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} precipitation_type is null"; fi
if [ "${lightning_strike_avg_distance}" != "null" ]; then curl_message="${curl_message}lightning_strike_avg_distance=${lightning_strike_avg_distance},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} lightning_strike_avg_distance is null"; fi
if [ "${lightning_strike_count}" != "null" ]; then curl_message="${curl_message}lightning_strike_count=${lightning_strike_count},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} lightning_strike_count is null"; fi
if [ "${battery}" != "null" ]; then curl_message="${curl_message}battery=${battery},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} battery is null"; fi
if [ "${report_interval}" != "null" ]; then curl_message="${curl_message}report_interval=${report_interval}"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} report_interval is null"; fi

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

# ╔═╗┬┬─┐
# ╠═╣│├┬┘
# ╩ ╩┴┴└─

if [[ $line == *"obs_air"* ]]; then

##
## Extract Metrics
##

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

serial_number=$(echo "${line}" | jq -r '.[0].serial_number')
hub_sn=$(echo "${line}" | jq -r '.[0].hub_sn')
firmware_revision=$(echo "${line}" | jq -r '.[0].firmware_revision')

obs=($(echo "${line}" | jq -r '.[0].obs[] | @sh') )

fi

if  [ "${function}" == "collector" ]
then

serial_number=$(echo "${line}" | jq -r '.serial_number')
hub_sn=$(echo "${line}" | jq -r '.hub_sn')
firmware_revision=$(echo "${line}" | jq -r '.firmware_revision')

obs=($(echo "${line}" | jq -r '.obs[] | @sh') )

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

echo "
serial_number=${serial_number}
hub_sn=${hub_sn}
firmware_revision=${firmware_revision}

time_epoch=${time_epoch}
station_pressure=${station_pressure}
air_temperature=${air_temperature}
relative_humidity=${relative_humidity}
lightning_strike_count=${lightning_strike_count}
lightning_strike_avg_distance=${lightning_strike_avg_distance}
battery=${battery}
report_interval=${report_interval}"

fi

##
## Source Variables
##

if [ -n "$loki_client_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source local-udp-hub_sn-"${hub_sn}"-lookup.txt; fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

##
## Add meta information to raw JSON to enable importing .[1]
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

loki_meta="{\"collector_type\":\"${collector_type}\",\"elevation\":\"${elevation}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"source\":\"${function}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.external-labels=collector_key="${collector_key}",collector_type="${collector_type}",host_hostname="${host_hostname}",hub_sn="${hub_sn}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml; fi

##
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_obs,collector_key=${collector_key},collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${firmware_revision}" != "null" ]; then curl_message="${curl_message}firmware_revision=${firmware_revision}000,"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} firmware_revision is null"; fi
if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${station_pressure}" != "null" ]; then curl_message="${curl_message}station_pressure=${station_pressure},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} station_pressure is null"; fi
if [ "${air_temperature}" != "null" ]; then curl_message="${curl_message}air_temperature=${air_temperature},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} air_temperature is null"; fi
if [ "${relative_humidity}" != "null" ]; then curl_message="${curl_message}relative_humidity=${relative_humidity},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} relative_humidity is null"; fi
if [ "${lightning_strike_count}" != "null" ]; then curl_message="${curl_message}lightning_strike_count=${lightning_strike_count},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} lightning_strike_count is null"; fi
if [ "${lightning_strike_avg_distance}" != "null" ]; then curl_message="${curl_message}lightning_strike_avg_distance=${lightning_strike_avg_distance},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} lightning_strike_avg_distance is null"; fi
if [ "${battery}" != "null" ]; then curl_message="${curl_message}battery=${battery},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} battery is null"; fi
if [ "${report_interval}" != "null" ]; then curl_message="${curl_message}report_interval=${report_interval}"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} report_interval is null"; fi

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

# ╔═╗┬┌─┬ ┬
# ╚═╗├┴┐└┬┘
# ╚═╝┴ ┴ ┴ 

if [[ $line == *"obs_sky"* ]]; then

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

serial_number=$(echo "${line}" | jq -r '.[0].serial_number')
hub_sn=$(echo "${line}" | jq -r '.[0].hub_sn')
firmware_revision=$(echo "${line}" | jq -r '.[0].firmware_revision')

obs=($(echo "${line}" | jq -r '.[0].obs[] | @sh') )

fi

if  [ "${function}" == "collector" ]
then

serial_number=$(echo "${line}" | jq -r '.serial_number')
hub_sn=$(echo "${line}" | jq -r '.hub_sn')
firmware_revision=$(echo "${line}" | jq -r '.firmware_revision')

obs=($(echo "${line}" | jq -r '.obs[] | @sh') )

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

echo "
serial_number=${serial_number}
hub_sn=${hub_sn}
firmware_revision=${firmware_revision}

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
wind_sample_interval=${wind_sample_interval}"

fi

##
## Source Variables
##

if [ -n "$loki_client_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source local-udp-hub_sn-"${hub_sn}"-lookup.txt; fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

##
## Add meta information to raw JSON to enable importing .[1]
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

loki_meta="{\"collector_type\":\"${collector_type}\",\"elevation\":\"${elevation}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"source\":\"${function}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.external-labels=collector_key="${collector_key}",collector_type="${collector_type}",host_hostname="${host_hostname}",hub_sn="${hub_sn}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml; fi

##
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_obs,collector_key=${collector_key},collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${firmware_revision}" != "null" ]; then curl_message="${curl_message}firmware_revision=${firmware_revision},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} firmware_revision is null"; fi
if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${illuminance}" != "null" ]; then curl_message="${curl_message}illuminance=${illuminance},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} illuminance is null"; fi
if [ "${uv}" != "null" ]; then curl_message="${curl_message}uv=${uv},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} uv is null"; fi
if [ "${precip_accumulated}" != "null" ]; then curl_message="${curl_message}precip_accumulated=${precip_accumulated},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} precip_accumulated is null"; fi
if [ "${wind_lull}" != "null" ]; then curl_message="${curl_message}wind_lull=${wind_lull},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_lull is null"; fi
if [ "${wind_avg}" != "null" ]; then curl_message="${curl_message}wind_avg=${wind_avg},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_avg is null"; fi
if [ "${wind_gust}" != "null" ]; then curl_message="${curl_message}wind_gust=${wind_gust},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_gust is null"; fi
if [ "${wind_direction}" != "null" ]; then curl_message="${curl_message}wind_direction=${wind_direction},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_direction is null"; fi
if [ "${battery}" != "null" ]; then curl_message="${curl_message}battery=${battery},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} battery is null"; fi
if [ "${report_interval}" != "null" ]; then curl_message="${curl_message}report_interval=${report_interval},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} report_interval is null"; fi
if [ "${solar_radiation}" != "null" ]; then curl_message="${curl_message}solar_radiation=${solar_radiation},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} solar_radiation is null"; fi
if [ "${precipitation_type}" != "null" ]; then curl_message="${curl_message}precipitation_type=${precipitation_type},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} precipitation_type is null"; fi
if [ "${wind_sample_interval}" != "null" ]; then curl_message="${curl_message}wind_sample_interval=${wind_sample_interval}"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_sample_interval is null"; fi

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

# ┬─┐┌─┐┌─┐┬┌┬┐   ┬ ┬┬┌┐┌┌┬┐
# ├┬┘├─┤├─┘│ ││───│││││││ ││
# ┴└─┴ ┴┴  ┴─┴┘   └┴┘┴┘└┘─┴┘

if [[ $line == *"rapid_wind"* ]]; then

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

serial_number=$(echo "${line}" | jq -r '.[0].serial_number')
hub_sn=$(echo "${line}" | jq -r '.[0].hub_sn')

ob=($(echo "${line}" | jq -r '.[0].ob[] | @sh') )

fi

if  [ "${function}" == "collector" ]
then

serial_number=$(echo "${line}" | jq -r '.serial_number')
hub_sn=$(echo "${line}" | jq -r '.hub_sn')

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

echo "serial_number=${serial_number}
hub_sn=${hub_sn}

time_epoch=${time_epoch}
wind_speed=${wind_speed}
wind_direction=${wind_direction}"

fi

##
## Source Variables
##

if [ -n "$loki_client_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source local-udp-hub_sn-"${hub_sn}"-lookup.txt; fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

##
## Add meta information to raw JSON to enable importing .[1]
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

loki_meta="{\"collector_type\":\"${collector_type}\",\"elevation\":\"${elevation}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"source\":\"${function}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.external-labels=collector_key="${collector_key}",collector_type="${collector_type}",host_hostname="${host_hostname}",hub_sn="${hub_sn}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml; fi

##
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_rapid_wind,collector_key=${collector_key},collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${wind_speed}" != "null" ]; then curl_message="${curl_message}wind_speed=${wind_speed},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_speed is null"; fi
if [ "${wind_direction}" != "null" ]; then curl_message="${curl_message}wind_direction=${wind_direction}"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} wind_direction is null"; fi

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

# ╦  ┬┌─┐┬ ┬┌┬┐┌┐┌┬┌┐┌┌─┐  ╔═╗┌┬┐┬─┐┬┬┌─┌─┐  ╔═╗┬  ┬┌─┐┌┐┌┌┬┐
# ║  ││ ┬├─┤ │ ││││││││ ┬  ╚═╗ │ ├┬┘│├┴┐├┤   ║╣ └┐┌┘├┤ │││ │ 
# ╩═╝┴└─┘┴ ┴ ┴ ┘└┘┴┘└┘└─┘  ╚═╝ ┴ ┴└─┴┴ ┴└─┘  ╚═╝ └┘ └─┘┘└┘ ┴ 

if [[ $line == *"evt_strike"* ]]; then

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

serial_number=$(echo "${line}" | jq -r '.[0].serial_number')
hub_sn=$(echo "${line}" | jq -r '.[0].hub_sn')

evt=($(echo "${line}" | jq -r '.[0].evt[] | @sh') )

fi

if  [ "${function}" == "collector" ]
then

serial_number=$(echo "${line}" | jq -r '.serial_number')
hub_sn=$(echo "${line}" | jq -r '.hub_sn')

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

echo "hub_sn=${hub_sn}
serial_number=${serial_number}

time_epoch=${time_epoch}
distance=${distance}
energy=${energy}"

fi

##
## Source Variables
##

if [ -n "$loki_client_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source local-udp-hub_sn-"${hub_sn}"-lookup.txt; fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

##
## Add meta information to raw JSON to enable importing .[1]
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

loki_meta="{\"collector_type\":\"${collector_type}\",\"elevation\":\"${elevation}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"source\":\"${function}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.external-labels=collector_key="${collector_key}",collector_type="${collector_type}",host_hostname="${host_hostname}",hub_sn="${hub_sn}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml; fi

##
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_evt_strike,collector_key=${collector_key},collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${distance}" != "null" ]; then curl_message="${curl_message}distance=${distance},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} distance is null"; fi
if [ "${energy}" != "null" ]; then curl_message="${curl_message}energy=${energy}"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} energy is null"; fi

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

# ╦═╗┌─┐┬┌┐┌  ╔═╗┌┬┐┌─┐┬─┐┌┬┐  ╔═╗┬  ┬┌─┐┌┐┌┌┬┐
# ╠╦╝├─┤││││  ╚═╗ │ ├─┤├┬┘ │   ║╣ └┐┌┘├┤ │││ │ 
# ╩╚═┴ ┴┴┘└┘  ╚═╝ ┴ ┴ ┴┴└─ ┴   ╚═╝ └┘ └─┘┘└┘ ┴ 

if [[ $line == *"evt_precip"* ]]; then

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

serial_number=$(echo "${line}" | jq -r '.[0].serial_number')
hub_sn=$(echo "${line}" | jq -r '.[0].hub_sn')

evt=($(echo "${line}" | jq -r '.[0].evt[0] | @sh') )

fi

if  [ "${function}" == "collector" ]
then

serial_number=$(echo "${line}" | jq -r '.serial_number')
hub_sn=$(echo "${line}" | jq -r '.hub_sn')

evt=($(echo "${line}" | jq -r '.evt[0] | @sh') )

fi

time_epoch=${evt[0]}

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo " 
hub_sn=${hub_sn}
serial_number=${serial_number}

time_epoch=${time_epoch}"

fi

##
## Source Variables
##

if [ -n "$loki_client_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source local-udp-hub_sn-"${hub_sn}"-lookup.txt; fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

##
## Add meta information to raw JSON to enable importing .[1]
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

loki_meta="{\"collector_type\":\"${collector_type}\",\"elevation\":\"${elevation}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"source\":\"${function}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.external-labels=collector_key="${collector_key}",collector_type="${collector_type}",host_hostname="${host_hostname}",hub_sn="${hub_sn}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml; fi

##
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_evt_precip,collector_key=${collector_key},collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} time_epoch is null"; fi

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

# ╔═╗┌┬┐┌─┐┌┬┐┬ ┬┌─┐  ╔╦╗┌─┐┬  ┬┬┌─┐┌─┐
# ╚═╗ │ ├─┤ │ │ │└─┐   ║║├┤ └┐┌┘││  ├┤ 
# ╚═╝ ┴ ┴ ┴ ┴ └─┘└─┘  ═╩╝└─┘ └┘ ┴└─┘└─┘

if [[ $line == *"device_status"* ]]; then

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

eval "$(echo "${line}" | jq -r '.[0] | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

if  [ "${function}" == "collector" ]
then

eval "$(echo "${line}" | jq -r '. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

fi

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "
serial_number:${serial_number}
hub_sn:${hub_sn}
timestamp:${timestamp}
uptime:${uptime}
voltage:${voltage}
firmware_revision:${firmware_revision}
rssi:${rssi}
hub_rssi:${hub_rssi}
sensor_status:${sensor_status}"

fi

##
## Source Variables
##

if [ -n "$loki_client_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source local-udp-hub_sn-"${hub_sn}"-lookup.txt; fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

##
## Add meta information to raw JSON to enable importing .[1]
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

loki_meta="{\"collector_type\":\"${collector_type}\",\"elevation\":\"${elevation}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"serial_number\":\"${serial_number}\",\"source\":\"${function}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.external-labels=collector_key="${collector_key}",collector_type="${collector_type}",host_hostname="${host_hostname}",hub_sn="${hub_sn}",public_name="${public_name}",serial_number="${serial_number}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml; fi

##
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_device_status,collector_key=${collector_key},collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${timestamp}" != "null" ]; then curl_message="${curl_message}timestamp=${timestamp}000,"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} timestamp is null"; fi
if [ "${uptime}" != "null" ]; then curl_message="${curl_message}uptime=${uptime},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} uptime is null"; fi
if [ "${voltage}" != "null" ]; then curl_message="${curl_message}voltage=${voltage},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} voltage is null"; fi
if [ "${firmware_revision}" != "null" ]; then curl_message="${curl_message}firmware_revision=${firmware_revision},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} firmware_revision is null"; fi
if [ "${rssi}" != "null" ]; then curl_message="${curl_message}rssi=${rssi},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} rssi is null"; fi
if [ "${hub_rssi}" != "null" ]; then curl_message="${curl_message}hub_rssi=${hub_rssi},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} hub_rssi is null"; fi
if [ "${sensor_status}" != "null" ]; then curl_message="${curl_message}sensor_status=${sensor_status}"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} sensor_status is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${timestamp}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

# ╔═╗┌┬┐┌─┐┌┬┐┬ ┬┌─┐  ╦ ╦┬ ┬┌┐ 
# ╚═╗ │ ├─┤ │ │ │└─┐  ╠═╣│ │├┴┐
# ╚═╝ ┴ ┴ ┴ ┴ └─┘└─┘  ╩ ╩└─┘└─┘

if [[ $line == *"hub_status"* ]]; then

##
## Extract Metrics
##

if  [ "${function}" == "import" ]
then

eval "$(echo "${line}" | jq -r '.[0] | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

##
## Set hub_sn to the serial_number field to be consistent in the logs and dashboards
##

hub_sn=$(echo "${line}" | jq -r .[0].serial_number)
radio_stats=($(echo "${line}" | jq -r '.[0].radio_stats[] | @sh') )

fi

if  [ "${function}" == "collector" ]
then

eval "$(echo "${line}" | jq -r '. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""')"

##
## Set hub_sn to the serial_number field to be consistent in the logs and dashboards
##

hub_sn=$(echo "${line}" | jq -r .serial_number)
radio_stats=($(echo "${line}" | jq -r '.radio_stats[] | @sh') )

fi

radio_stats_version=${radio_stats[0]}
radio_stats_reboot_count=${radio_stats[1]}
radio_stats_i2c_bus_error_count=${radio_stats[2]}
radio_stats_radio_status=${radio_stats[3]}
radio_stats_radio_network_id=${radio_stats[4]}

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "
hub_sn=${hub_sn}
uptime=${uptime}
firmware_revision=${firmware_revision}
rssi=${rssi}
timestamp=${timestamp}
radio_stats_version=${radio_stats_version}
radio_stats_reboot_count=${radio_stats_reboot_count}
radio_stats_i2c_bus_error_count=${radio_stats_i2c_bus_error_count}
radio_stats_radio_status=${radio_stats_radio_status}
radio_stats_radio_network_id=${radio_stats_radio_network_id}"

fi

##
## Source Variables
##

if [ -n "$loki_client_url" ] && [ "${function}" == "import" ]; then eval "$(echo "${line}" | jq -r '.[1] | to_entries | .[]| .key + "=" + "\"" + ( .value|tostring ) + "\""')"; fi
if [ "${function}" == "collector" ]; then source local-udp-hub_sn-"${hub_sn}"-lookup.txt; fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

##
## Add meta information to raw JSON to enable importing .[1]
##

##
## Skip serial_number and only use hub_sn
##

if [ -n "$loki_client_url" ] &&  [ "${function}" == "collector" ]; then

loki_meta="{\"collector_type\":\"${collector_type}\",\"elevation\":\"${elevation}\",\"hub_sn\":\"${hub_sn}\",\"latitude\":\"${latitude}\",\"longitude\":\"${longitude}\",\"public_name\":\"${public_name}\",\"source\":\"${function}\",\"station_id\":\"${station_id}\",\"station_name\":\"${station_name}\",\"timezone\":\"${timezone}\"}"

if [ "$debug" == "true" ]; then echo "${loki_meta}"; fi

echo "[${line},${loki_meta}]" | ${grafana_loki_binary_path} --stdin --client.url "${loki_client_url}" --client.external-labels=collector_key="${collector_key}",collector_type="${collector_type}",host_hostname="${host_hostname}",hub_sn="${hub_sn}",public_name="${public_name}",station_id="${station_id}",station_name="${station_name}" --config.file=loki-config.yml; fi

##
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB if WEATHERFLOW_COLLECTOR_INFLUXDB_URL is set
##

if [ -n "$influxdb_url" ]

then

curl_message="weatherflow_hub_status,collector_key=${collector_key},collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${uptime}" != "null" ]; then curl_message="${curl_message}uptime=${uptime},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} uptime is null"; fi
if [ "${firmware_revision}" != "null" ]; then curl_message="${curl_message}firmware_revision=${firmware_revision},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} firmware_revision is null"; fi
if [ "${rssi}" != "null" ]; then curl_message="${curl_message}rssi=${rssi},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} rssi is null"; fi
if [ "${timestamp}" != "null" ]; then curl_message="${curl_message}timestamp=${timestamp}000,"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} timestamp is null"; fi
if [ "${radio_stats_version}" != "null" ]; then curl_message="${curl_message}radio_stats_version=${radio_stats_version},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} radio_stats_version is null"; fi
if [ "${radio_stats_reboot_count}" != "null" ]; then curl_message="${curl_message}radio_stats_reboot_count=${radio_stats_reboot_count},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} radio_stats_reboot_count is null"; fi
if [ "${radio_stats_i2c_bus_error_count}" != "null" ]; then curl_message="${curl_message}radio_stats_i2c_bus_error_count=${radio_stats_i2c_bus_error_count},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} radio_stats_i2c_bus_error_count is null"; fi
if [ "${radio_stats_radio_status}" != "null" ]; then curl_message="${curl_message}radio_stats_radio_status=${radio_stats_radio_status},"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} radio_stats_radio_status is null"; fi
if [ "${radio_stats_radio_network_id}" != "null" ]; then curl_message="${curl_message}radio_stats_radio_network_id=${radio_stats_radio_network_id}"; else echo "${echo_bold}${echo_color_local_udp}${collector_type}:${echo_normal} radio_stats_radio_network_id is null"; fi

##
## Remove a trailing comma in curl_message if the last element happens to be null (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${timestamp}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi
fi

done < /dev/stdin