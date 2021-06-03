#!/bin/bash

##
## WeatherFlow Importer - exec-remote-import.sh
##

##
## WeatherFlow-Collector Details
##

source weatherflow-collector_details.sh

##
## Read Environmental Variables
##

debug=$WEATHERFLOW_COLLECTOR_DEBUG

host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID
threads=$WEATHERFLOW_COLLECTOR_THREADS
token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Overrides for import
##

collector_type="local-udp"
function="import"

##
## Set InfluxDB Precision to seconds
##

if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Check for required intervals
##

##
## Set Threads
##

if [ -z "${threads}" ]; then echo "WEATHERFLOW_COLLECTOR_THREADS environmental variable not set. Defaulting to 4 threads."; threads="4"; fi

##
## Curl Command
##

if [ "$debug" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

if [ "$debug" == "true" ]

then

echo "Starting WeatherFlow Collector (exec-remote-import.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
function=${function}
host_hostname=${host_hostname}
import_days=${import_days}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
station_id=${station_id}
threads=${threads}
token=${token}"

fi

##
## Start Reading in STDIN
##

while read -r line; do

obs_type=$(echo "${line}" | jq -r '.type')
device_id=$(echo "${line}" | jq -r '.device_id')

num_of_metrics=$(echo "${line}" | jq '.obs | length')

echo "Number of time slices: ${num_of_metrics}"

num_of_metrics_minus_one=$((num_of_metrics-1))

#echo "num_of_metrics_minus_one=${num_of_metrics_minus_one}"

##
## Start Timer
##

import_start=$(date +%s%N)

##
## Start "threading"
##

for metric in $(seq 0 $num_of_metrics_minus_one) ; do

(

# ╔╦╗┌─┐┌┬┐┌─┐┌─┐┌─┐┌┬┐
#  ║ ├┤ │││├─┘├┤ └─┐ │ 
#  ╩ └─┘┴ ┴┴  └─┘└─┘ ┴ 

if [ "$obs_type" == "obs_st" ]

then

obs=($(echo "${line}" | jq -r '.obs['"$metric"'] | @sh') )

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

echo "
obs_type=${obs_type}
device_id=${device_id}
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
report_interval=${report_interval}"

fi

##
## Source Variables
##

source remote-import-device_id-"${device_id}"-lookup.txt

##
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB
##

curl_message="weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${wind_lull}" != "null" ]; then curl_message="${curl_message}wind_lull=${wind_lull},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} wind_lull is null"; fi
if [ "${wind_avg}" != "null" ]; then curl_message="${curl_message}wind_avg=${wind_avg},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} wind_avg is null"; fi
if [ "${wind_gust}" != "null" ]; then curl_message="${curl_message}wind_gust=${wind_gust},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} wind_gust is null"; fi
if [ "${wind_direction}" != "null" ]; then curl_message="${curl_message}wind_direction=${wind_direction},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} wind_direction is null"; fi
if [ "${wind_sample_interval}" != "null" ]; then curl_message="${curl_message}wind_sample_interval=${wind_sample_interval},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} wind_sample_interval is null"; fi
if [ "${station_pressure}" != "null" ]; then curl_message="${curl_message}station_pressure=${station_pressure},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} station_pressure is null"; fi
if [ "${air_temperature}" != "null" ]; then curl_message="${curl_message}air_temperature=${air_temperature},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} air_temperature is null"; fi
if [ "${relative_humidity}" != "null" ]; then curl_message="${curl_message}relative_humidity=${relative_humidity},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} relative_humidity is null"; fi
if [ "${illuminance}" != "null" ]; then curl_message="${curl_message}illuminance=${illuminance},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} illuminance is null"; fi
if [ "${uv}" != "null" ]; then curl_message="${curl_message}uv=${uv},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} uv is null"; fi
if [ "${solar_radiation}" != "null" ]; then curl_message="${curl_message}solar_radiation=${solar_radiation},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} solar_radiation is null"; fi
if [ "${precip_accumulated}" != "null" ]; then curl_message="${curl_message}precip_accumulated=${precip_accumulated},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} precip_accumulated is null"; fi
if [ "${precipitation_type}" != "null" ]; then curl_message="${curl_message}precipitation_type=${precipitation_type},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} precipitation_type is null"; fi
if [ "${lightning_strike_avg_distance}" != "null" ]; then curl_message="${curl_message}lightning_strike_avg_distance=${lightning_strike_avg_distance},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} lightning_strike_avg_distance is null"; fi
if [ "${lightning_strike_count}" != "null" ]; then curl_message="${curl_message}lightning_strike_count=${lightning_strike_count},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} lightning_strike_count is null"; fi
if [ "${battery}" != "null" ]; then curl_message="${curl_message}battery=${battery},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} battery is null"; fi
if [ "${report_interval}" != "null" ]; then curl_message="${curl_message}report_interval=${report_interval},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} report_interval is null"; fi

##
## Remove the trailing comma in curl_message even if there happens to be nulls
## (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi

# ╔═╗┬┬─┐
# ╠═╣│├┬┘
# ╩ ╩┴┴└─

if [ "$obs_type" == "obs_air" ]

then

obs=($(echo "${line}" | jq -r '.obs['"$metric"'] | @sh') )

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
obs_type=${obs_type}
device_id=${device_id}
hub_sn=${hub_sn}
serial_number=${serial_number}

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

source remote-import-device_id-"${device_id}"-lookup.txt

##
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB
##

curl_message="weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${station_pressure}" != "null" ]; then curl_message="${curl_message}station_pressure=${station_pressure},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} station_pressure is null"; fi
if [ "${air_temperature}" != "null" ]; then curl_message="${curl_message}air_temperature=${air_temperature},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} air_temperature is null"; fi
if [ "${relative_humidity}" != "null" ]; then curl_message="${curl_message}relative_humidity=${relative_humidity},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} relative_humidity is null"; fi
if [ "${lightning_strike_count}" != "null" ]; then curl_message="${curl_message}lightning_strike_count=${lightning_strike_count},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} lightning_strike_count is null"; fi
if [ "${lightning_strike_avg_distance}" != "null" ]; then curl_message="${curl_message}lightning_strike_avg_distance=${lightning_strike_avg_distance},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} lightning_strike_avg_distance is null"; fi
if [ "${battery}" != "null" ]; then curl_message="${curl_message}battery=${battery},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} battery is null"; fi
if [ "${report_interval}" != "null" ]; then curl_message="${curl_message}report_interval=${report_interval},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} report_interval is null"; fi

##
## Remove the trailing comma in curl_message even if there happens to be nulls
## (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi

# ╔═╗┬┌─┬ ┬
# ╚═╗├┴┐└┬┘
# ╚═╝┴ ┴ ┴ 

if [ "$obs_type" == "obs_sky" ]

then

obs=($(echo "${line}" | jq -r '.obs['"$metric"'] | @sh') )

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
local_daily_rain_accumulation=${obs[11]}
precipitation_type=${obs[12]}
wind_sample_interval=${obs[13]}

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "
obs_type=${obs_type}
device_id=${device_id}
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
local_daily_rain_accumulation=${local_daily_rain_accumulation}
precipitation_type=${precipitation_type}
wind_sample_interval=${wind_sample_interval}"

fi

##
## Source Variables
##

source remote-import-device_id-"${device_id}"-lookup.txt

##
## Escape Names (Function)
##

escape_names

##
## Push to InfluxDB
##

curl_message="weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} "

if [ "${time_epoch}" != "null" ]; then curl_message="${curl_message}time_epoch=${time_epoch}000,"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} time_epoch is null"; fi
if [ "${illuminance}" != "null" ]; then curl_message="${curl_message}illuminance=${illuminance},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} illuminance is null"; fi
if [ "${uv}" != "null" ]; then curl_message="${curl_message}uv=${uv},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} uv is null"; fi
if [ "${precip_accumulated}" != "null" ]; then curl_message="${curl_message}precip_accumulated=${precip_accumulated},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} precip_accumulated is null"; fi
if [ "${wind_lull}" != "null" ]; then curl_message="${curl_message}wind_lull=${wind_lull},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} wind_lull is null"; fi
if [ "${wind_avg}" != "null" ]; then curl_message="${curl_message}wind_avg=${wind_avg},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} wind_avg is null"; fi
if [ "${wind_gust}" != "null" ]; then curl_message="${curl_message}wind_gust=${wind_gust},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} wind_gust is null"; fi
if [ "${wind_direction}" != "null" ]; then curl_message="${curl_message}wind_direction=${wind_direction},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} wind_direction is null"; fi
if [ "${battery}" != "null" ]; then curl_message="${curl_message}battery=${battery},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} battery is null"; fi
if [ "${report_interval}" != "null" ]; then curl_message="${curl_message}report_interval=${report_interval},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} report_interval is null"; fi
if [ "${solar_radiation}" != "null" ]; then curl_message="${curl_message}solar_radiation=${solar_radiation},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} solar_radiation is null"; fi
if [ "${local_daily_rain_accumulation}" != "null" ]; then curl_message="${curl_message}local_daily_rain_accumulation=${local_daily_rain_accumulation},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} local_daily_rain_accumulation is null"; fi
if [ "${precipitation_type}" != "null" ]; then curl_message="${curl_message}precipitation_type=${precipitation_type},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} precipitation_type is null"; fi
if [ "${wind_sample_interval}" != "null" ]; then curl_message="${curl_message}wind_sample_interval=${wind_sample_interval},"; else echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} wind_sample_interval is null"; fi

##
## Remove the trailing comma in curl_message even if there happens to be nulls
## (so that there's still a properly formatted InfluxDB mmessage)
##

curl_message="$(echo "${curl_message}" | sed 's/,$//')"

##
## Add the proper timestamp at the end of the curl_message
##

curl_message="${curl_message} ${time_epoch}";

#echo "${curl_message}"

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "${curl_message}"

fi

) &

if [[ $(jobs -r -p | wc -l) -ge $threads ]]; then wait -n; ProgressBar "${metric}" ${num_of_metrics_minus_one}; fi

done

wait

printf '\nFinished!\n'

##
## End "threading"
##

## End Timer

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

#echo "import_duration:${import_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_key=${collector_key},collector_type=${collector_type},host_hostname=${host_hostname},source=${function} duration=${import_duration}"

done < /dev/stdin
