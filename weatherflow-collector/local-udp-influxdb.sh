#!/bin/bash

##
## WeatherFlow Collector - local-udp-influxdb.sh
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

# Print Line

echo ""
echo "${line}"
echo ""

fi

##
## Push to Loki if WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL is set
##

if [ -n "$loki_client_url" ]

then

echo "${line}" | /usr/bin/promtail --stdin --client.url "${loki_client_url}" --client.external-labels=collector_type="${collector_type}",host_hostname="${host_hostname}",public_name="${public_name}",station_id="${station_id}",station_name="${station_name}",timezone="${timezone}" --config.file=/weatherflow-collector/loki-config.yml

fi

##
## Observation (Tempest)
##

if [[ $line == *"obs_st"* ]]; then

##
## Extract Metrics
##

serial_number=$(echo "${line}" | jq -r .serial_number)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
firmware_revision=$(echo "${line}" | jq -r .firmware_revision)

time_epoch=$(echo "${line}" | jq ".obs[0][0]")
wind_lull=$(echo "${line}" | jq ".obs[0][1]")
wind_avg=$(echo "${line}" | jq ".obs[0][2]")
wind_gust=$(echo "${line}" | jq ".obs[0][3]")
wind_direction=$(echo "${line}" | jq ".obs[0][4]")
wind_sample_interval=$(echo "${line}" | jq ".obs[0][5]")
station_pressure=$(echo "${line}" | jq ".obs[0][6]")
air_temperature=$(echo "${line}" | jq ".obs[0][7]")
relative_humidity=$(echo "${line}" | jq ".obs[0][8]")
illuminance=$(echo "${line}" | jq ".obs[0][9]")
uv=$(echo "${line}" | jq ".obs[0][10]")
solar_radiation=$(echo "${line}" | jq ".obs[0][11]")
precip_accumulated=$(echo "${line}" | jq ".obs[0][12]")
precipitation_type=$(echo "${line}" | jq ".obs[0][13]")
lightning_strike_avg_distance=$(echo "${line}" | jq ".obs[0][14]")
lightning_strike_count=$(echo "${line}" | jq ".obs[0][15]")
battery=$(echo "${line}" | jq ".obs[0][16]")
report_interval=$(echo "${line}" | jq ".obs[0][17]")

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "obs,serial_number ${serial_number}"
echo "obs,hub_sn ${hub_sn}"
echo "obs,firmware_revision ${firmware_revision}"

echo "obs,time_epoch ${time_epoch}"
echo "obs,wind_lull ${wind_lull}"
echo "obs,wind_avg ${wind_avg}"
echo "obs,wind_gust ${wind_gust}"
echo "obs,wind_direction ${wind_direction}"
echo "obs,wind_sample_interval ${wind_sample_interval}"
echo "obs,station_pressure ${station_pressure}"
echo "obs,air_temperature ${air_temperature}"
echo "obs,relative_humidity ${relative_humidity}"
echo "obs,illuminance ${illuminance}"
echo "obs,uv ${uv}"
echo "obs,solar_radiation ${solar_radiation}"
echo "obs,precip_accumulated ${precip_accumulated}"
echo "obs,precipitation_type ${precipitation_type}"
echo "obs,lightning_strike_avg_distance ${lightning_strike_avg_distance}"
echo "obs,lightning_strike_count ${lightning_strike_count}"
echo "obs,battery ${battery}"
echo "obs,report_interval ${report_interval}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} firmware_revision=${firmware_revision} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_lull=${wind_lull} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_avg=${wind_avg} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_gust=${wind_gust} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_direction=${wind_direction} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_sample_interval=${wind_sample_interval} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} station_pressure=${station_pressure} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} air_temperature=${air_temperature} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} relative_humidity=${relative_humidity} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} illuminance=${illuminance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} uv=${uv} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} solar_radiation=${solar_radiation} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_accumulated=${precip_accumulated} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precipitation_type=${precipitation_type} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} lightning_strike_avg_distance=${lightning_strike_avg_distance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} lightning_strike_count=${lightning_strike_count} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} battery=${battery} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} report_interval=${report_interval} ${time_epoch}000000000"

fi

##
## Observation (Air)
##

if [[ $line == *"obs_air"* ]]; then

##
## Extract Metrics
##

serial_number=$(echo "${line}" | jq -r .serial_number)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
firmware_revision=$(echo "${line}" | jq -r .firmware_revision)

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

echo "obs,serial_number ${serial_number}"
echo "obs,hub_sn ${hub_sn}"
echo "obs,firmware_revision ${firmware_revision}"

echo "obs,time_epoch ${time_epoch}"
echo "obs,station_pressure ${station_pressure}"
echo "obs,air_temperature ${air_temperature}"
echo "obs,relative_humidity ${relative_humidity}"
echo "obs,lightning_strike_count ${lightning_strike_count}"
echo "obs,lightning_strike_avg_distance ${lightning_strike_avg_distance}"
echo "obs,battery ${battery}"
echo "obs,report_interval ${report_interval}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} firmware_revision=${firmware_revision} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} station_pressure=${station_pressure} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} air_temperature=${air_temperature} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} relative_humidity=${relative_humidity} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} lightning_strike_count=${lightning_strike_count} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} lightning_strike_avg_distance=${lightning_strike_avg_distance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} battery=${battery} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} report_interval=${report_interval} ${time_epoch}000000000"

fi

##
## Observation (Sky)
##

if [[ $line == *"obs_sky"* ]]; then

##
## Extract Metrics
##

serial_number=$(echo "${line}" | jq -r .serial_number)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
firmware_revision=$(echo "${line}" | jq -r .firmware_revision)

time_epoch=$(echo "${line}" | jq ".obs[0][0]")
illuminance=$(echo "${line}" | jq ".obs[0][1]")
uv=$(echo "${line}" | jq ".obs[0][2]")
precip_accumulated=$(echo "${line}" | jq ".obs[0][3]")
wind_lull=$(echo "${line}" | jq ".obs[0][4]")
wind_avg=$(echo "${line}" | jq ".obs[0][5]")
wind_gust=$(echo "${line}" | jq ".obs[0][6]")
wind_direction=$(echo "${line}" | jq ".obs[0][7]")
battery=$(echo "${line}" | jq ".obs[0][8]")
report_interval=$(echo "${line}" | jq ".obs[0][9]")
solar_radiation=$(echo "${line}" | jq ".obs[0][10]")
precip_accumulated=$(echo "${line}" | jq ".obs[0][11]")
precipitation_type=$(echo "${line}" | jq ".obs[0][12]")
wind_sample_interval=$(echo "${line}" | jq ".obs[0][13]")

##
## Remove Null Entries from precip_accumulated
##

if [ "$precip_accumulated" = "null" ]
then
precip_accumulated="0"
fi

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "obs,serial_number ${serial_number}"
echo "obs,hub_sn ${hub_sn}"
echo "obs,firmware_revision ${firmware_revision}"

echo "obs,time_epoch ${time_epoch}"
echo "obs,illuminance ${illuminance}"
echo "obs,uv ${uv}"
echo "obs,precip_accumulated ${precip_accumulated}"
echo "obs,wind_lull ${wind_lull}"
echo "obs,wind_avg ${wind_avg}"
echo "obs,wind_gust ${wind_gust}"
echo "obs,wind_direction ${wind_direction}"
echo "obs,battery ${battery}"
echo "obs,report_interval ${report_interval}"
echo "obs,solar_radiation ${solar_radiation}"
echo "obs,precip_accumulated ${precip_accumulated}"
echo "obs,precipitation_type ${precipitation_type}"
echo "obs,wind_sample_interval ${wind_sample_interval}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} firmware_revision=${firmware_revision} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} illuminance=${illuminance} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} uv=${uv} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_accumulated=${precip_accumulated} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_lull=${wind_lull} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_avg=${wind_avg} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_gust=${wind_gust} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_direction=${wind_direction} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} battery=${battery} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} report_interval=${report_interval} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} solar_radiation=${solar_radiation} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precip_accumulated=${precip_accumulated} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} precipitation_type=${precipitation_type} ${time_epoch}000000000
weatherflow_obs,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_sample_interval=${wind_sample_interval} ${time_epoch}000000000"

fi

##
## Rapid Wind
##

if [[ $line == *"rapid_wind"* ]]; then

##
## Extract Metrics
##

serial_number=$(echo "${line}" | jq -r .serial_number)
hub_sn=$(echo "${line}" | jq -r .hub_sn)

time_epoch=$(echo "${line}" | jq ".ob[0]")
wind_speed=$(echo "${line}" | jq ".ob[1]")
wind_direction=$(echo "${line}" | jq ".ob[2]")

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "rapid_wind,serial_number ${serial_number}"
echo "rapid_wind,hub_sn ${hub_sn}"

echo "rapid_wind,time_epoch ${time_epoch}"
echo "rapid_wind,wind_speed ${wind_speed}"
echo "rapid_wind,wind_direction ${wind_direction}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_rapid_wind,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000
weatherflow_rapid_wind,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_speed=${wind_speed} ${time_epoch}000000000
weatherflow_rapid_wind,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} wind_direction=${wind_direction} ${time_epoch}000000000"

fi

##
## Lightning Strike Event
##

if [[ $line == *"evt_strike"* ]]; then

##
## Extract Metrics
##

serial_number=$(echo "${line}" | jq -r .serial_number)
hub_sn=$(echo "${line}" | jq -r .hub_sn)

time_epoch=$(echo "${line}" | jq ".evt[0]")
distance=$(echo "${line}" | jq ".evt[1]")
energy=$(echo "${line}" | jq ".evt[2]")

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "evt_strike,serial_number ${serial_number}"
echo "evt_strike,hub_sn ${hub_sn}"

echo "evt_strike,time_epoch ${time_epoch}"
echo "evt_strike,distance ${distance}"
echo "evt_strike,energy ${energy}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_strike,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000
weatherflow_evt_strike,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} distance=${distance} ${time_epoch}000000000
weatherflow_evt_strike,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} energy=${energy} ${time_epoch}000000000"

fi

##
## Rain Start Event
##

if [[ $line == *"evt_precip"* ]]; then

##
## Extract Metrics
##

serial_number=$(echo "${line}" | jq -r .serial_number)
hub_sn=$(echo "${line}" | jq -r .hub_sn)

time_epoch=$(echo "${line}" | jq ".evt[0]")

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "evt_precip,serial_number ${serial_number}"
echo "evt_precip,hub_sn ${hub_sn}"
echo "evt_precip,time_epoch ${time_epoch}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_precip,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} time_epoch=${time_epoch}000 ${time_epoch}000000000"

fi

##
## Status (device)
##

if [[ $line == *"device_status"* ]]; then

##
## Extract Metrics
##

serial_number=$(echo "${line}" | jq -r .serial_number)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
timestamp=$(echo "${line}" | jq -r .timestamp)
uptime=$(echo "${line}" | jq -r .uptime)
voltage=$(echo "${line}" | jq -r .voltage)
firmware_revision=$(echo "${line}" | jq -r .firmware_revision)
rssi=$(echo "${line}" | jq -r .rssi)
hub_rssi=$(echo "${line}" | jq -r .hub_rssi)
sensor_status=$(echo "${line}" | jq -r .sensor_status)

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "device_status,serial_number ${serial_number}"
echo "device_status,hub_sn ${hub_sn}"

echo "device_status,timestamp ${timestamp}"
echo "device_status,uptime ${uptime}"
echo "device_status,voltage ${voltage}"
echo "device_status,firmware_revision ${firmware_revision}"
echo "device_status,rssi ${rssi}"
echo "device_status,hub_rssi ${hub_rssi}"
echo "device_status,sensor_status ${sensor_status}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_device_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} timestamp=${timestamp} ${timestamp}000000000
weatherflow_device_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} uptime=${uptime} ${timestamp}000000000
weatherflow_device_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} voltage=${voltage} ${timestamp}000000000
weatherflow_device_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} firmware_revision=${firmware_revision} ${timestamp}000000000
weatherflow_device_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} rssi=${rssi} ${timestamp}000000000
weatherflow_device_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} hub_rssi=${hub_rssi} ${timestamp}000000000
weatherflow_device_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},serial_number=${serial_number},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} sensor_status=${sensor_status} ${timestamp}000000000"

fi

##
## Status (hub)
##

if [[ $line == *"hub_status"* ]]; then

##
## Extract Metrics
##

hub_sn=$(echo "${line}" | jq -r .serial_number)
uptime=$(echo "${line}" | jq -r .uptime)
firmware_revision=$(echo "${line}" | jq -r .firmware_revision)
rssi=$(echo "${line}" | jq -r .rssi)
timestamp=$(echo "${line}" | jq -r .timestamp)
radio_stats_version=$(echo "${line}" | jq ".radio_stats[0]")
radio_stats_reboot_count=$(echo "${line}" | jq ".radio_stats[1]")
radio_stats_i2c_bus_error_count=$(echo "${line}" | jq ".radio_stats[2]")
radio_stats_radio_status=$(echo "${line}" | jq ".radio_stats[3]")
radio_stats_radio_network_id=$(echo "${line}" | jq ".radio_stats[4]")

if [ "$debug" == "true" ]
then

##
## Print Metrics
##

echo "hub_status,hub_sn ${hub_sn}"
echo "hub_status,uptime ${uptime}"
echo "hub_status,firmware_revision ${firmware_revision}"
echo "hub_status,rssi ${rssi}"
echo "hub_status,timestamp ${timestamp}"
echo "hub_status,radio_stats_version ${radio_stats_version}"
echo "hub_status,radio_stats_reboot_count ${radio_stats_reboot_count}"
echo "hub_status,radio_stats_i2c_bus_error_count ${radio_stats_i2c_bus_error_count}"
echo "hub_status,radio_stats_radio_status ${radio_stats_radio_status}"
echo "hub_status,radio_stats_radio_network_id ${radio_stats_radio_network_id}"

fi

##
## Send metrics to InfluxDB
##

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_hub_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} uptime=${uptime} ${timestamp}000000000
weatherflow_hub_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} firmware_revision=${firmware_revision} ${timestamp}000000000
weatherflow_hub_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} rssi=${rssi} ${timestamp}000000000
weatherflow_hub_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} timestamp=${timestamp} ${timestamp}000000000
weatherflow_hub_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} radio_stats_version=${radio_stats_version} ${timestamp}000000000
weatherflow_hub_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} radio_stats_reboot_count=${radio_stats_reboot_count} ${timestamp}000000000
weatherflow_hub_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} radio_stats_i2c_bus_error_count=${radio_stats_i2c_bus_error_count} ${timestamp}000000000
weatherflow_hub_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} radio_stats_radio_status=${radio_stats_radio_status} ${timestamp}000000000
weatherflow_hub_status,collector_type=${collector_type},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name_escaped},source=${function},station_id=${station_id},station_name=${station_name_escaped},timezone=${timezone} radio_stats_radio_network_id=${radio_stats_radio_network_id} ${timestamp}000000000"

fi

done < /dev/stdin