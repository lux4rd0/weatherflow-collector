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

##
## Override collector_type for import
##

collector_type="local-udp"

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

echo "Station Name: ${station_name}"
echo "Device ID: ${device_id}"

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

if [ "$debug" == "true" ]

then

echo "Starting WeatherFlow Collector (remote-import-influxdb.sh) - https://github.com/lux4rd0/weatherflow-collector

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
## Start Reading in STDIN
##

while read -r line; do

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

##
## Observation (Tempest)
##

obs=($(echo "${line}" | jq -r '.obs['$metric'] | @sh') )

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

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "time_epoch=${time_epoch}
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
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} air_temperature=${air_temperature} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} battery=${battery} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} illuminance=${illuminance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} lightning_strike_avg_distance=${lightning_strike_avg_distance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} lightning_strike_count=${lightning_strike_count} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_accumulated=${precip_accumulated} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precipitation_type=${precipitation_type} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} relative_humidity=${relative_humidity} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} report_interval=${report_interval} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} solar_radiation=${solar_radiation} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} station_pressure=${station_pressure} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} uv=${uv} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_avg=${wind_avg} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_direction=${wind_direction} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_gust=${wind_gust} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_lull=${wind_lull} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_sample_interval=${wind_sample_interval} ${time_epoch}000000000"

) &

    # allow to execute up to $N jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $N ]]; then
        wait -n

    ProgressBar "${metric}" ${num_of_metrics_minus_one}

    fi

done

wait

printf '\nFinished!\n'

##
## End "threading"
##

## End Timer

import_end=$(date +%s%N)
import_duration=$((import_end-import_start))

echo "import_duration:${import_duration}"

##
## Send Timer Metrics To InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_system_stats,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} duration=${import_duration}"

done < /dev/stdin
