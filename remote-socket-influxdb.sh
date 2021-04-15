#!/bin/bash

##
## WeatherFlow Collector - remote-socket.sh
##

collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE
debug=$WEATHERFLOW_COLLECTOR_DEBUG
device_id=$WEATHERFLOW_COLLECTOR_DEVICE_ID
elevation=$WEATHERFLOW_COLLECTOR_ELEVATION
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
hub_sn=$WEATHERFLOW_COLLECTOR_HUB_SN
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
latitude=$WEATHERFLOW_COLLECTOR_LATITUDE
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

##
## Start Reading in STDIN
##

while read -r line; do

# Set seconds since Epoch for metric entries without it

time_epoch=$(date +%s)

if [ "$debug" == "true" ]
then

#
# Print Line
#

echo ""
echo "${line}"
echo ""

fi

#
# Observation (Tempest)
#

if [[ $line == *"obs_st"* ]]; then

# Extract Metrics

device_id=$(echo "${line}" | jq -r .device_id)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
serial_number=$(echo "${line}" | jq -r .serial_number)
firmware_revision=$(echo "${line}" | jq -r .firmware_revision)

air_temperature=$(echo "${line}" | jq ".obs[0][7]")
battery=$(echo "${line}" | jq ".obs[0][16]")
illuminance=$(echo "${line}" | jq ".obs[0][9]")
lightning_strike_avg_distance=$(echo "${line}" | jq ".obs[0][14]")
lightning_strike_count=$(echo "${line}" | jq ".obs[0][15]")
local_daily_rain_accumulation=$(echo "${line}" | jq ".obs[0][18]")
local_daily_rain_accumulation_final_rain_check=$(echo "${line}" | jq ".obs[0][20]")
precip_accumulated=$(echo "${line}" | jq ".obs[0][12]")
precipitation_analysis_type=$(echo "${line}" | jq ".obs[0][21]")
precipitation_type=$(echo "${line}" | jq ".obs[0][13]")
rain_accumulated_final_rain_check=$(echo "${line}" | jq ".obs[0][19]")
relative_humidity=$(echo "${line}" | jq ".obs[0][8]")
report_interval=$(echo "${line}" | jq ".obs[0][17]")
solar_radiation=$(echo "${line}" | jq ".obs[0][11]")
station_pressure=$(echo "${line}" | jq ".obs[0][6]")
time_epoch=$(echo "${line}" | jq ".obs[0][0]")
uv=$(echo "${line}" | jq ".obs[0][10]")
wind_avg=$(echo "${line}" | jq ".obs[0][2]")
wind_direction=$(echo "${line}" | jq ".obs[0][4]")
wind_gust=$(echo "${line}" | jq ".obs[0][3]")
wind_lull=$(echo "${line}" | jq ".obs[0][1]")
wind_sample_interval=$(echo "${line}" | jq ".obs[0][5]")

air_density=$(echo "${line}" | jq -r .summary.air_density)
delta_t=$(echo "${line}" | jq -r .summary.delta_t)
dew_point=$(echo "${line}" | jq -r .summary.dew_point)
feels_like=$(echo "${line}" | jq -r .summary.feels_like)
heat_index=$(echo "${line}" | jq -r .summary.heat_index)
precip_accum_local_yesterday=$(echo "${line}" | jq -r .summary.precip_accum_local_yesterday)
precip_accum_local_yesterday_final=$(echo "${line}" | jq -r .summary.precip_accum_local_yesterday_final)
precip_analysis_type_yesterday=$(echo "${line}" | jq -r .summary.precip_analysis_type_yesterday)
precip_minutes_local_day=$(echo "${line}" | jq -r .summary.precip_minutes_local_day)
precip_minutes_local_yesterday=$(echo "${line}" | jq -r .summary.precip_minutes_local_yesterday)
precip_total_1h=$(echo "${line}" | jq -r .summary.precip_total_1h)
pressure_trend=$(echo "${line}" | jq -r .summary.pressure_trend)
pulse_adj_ob_temp=$(echo "${line}" | jq -r .summary.pulse_adj_ob_temp)
pulse_adj_ob_time=$(echo "${line}" | jq -r .summary.pulse_adj_ob_time)
pulse_adj_ob_wind_avg=$(echo "${line}" | jq -r .summary.pulse_adj_ob_wind_avg)
raining_minutes_00=$(echo "${line}" | jq ".summary.raining_minutes[0]")
raining_minutes_01=$(echo "${line}" | jq ".summary.raining_minutes[1]")
raining_minutes_02=$(echo "${line}" | jq ".summary.raining_minutes[2]")
raining_minutes_03=$(echo "${line}" | jq ".summary.raining_minutes[3]")
raining_minutes_04=$(echo "${line}" | jq ".summary.raining_minutes[4]")
raining_minutes_05=$(echo "${line}" | jq ".summary.raining_minutes[5]")
raining_minutes_06=$(echo "${line}" | jq ".summary.raining_minutes[6]")
raining_minutes_07=$(echo "${line}" | jq ".summary.raining_minutes[7]")
raining_minutes_08=$(echo "${line}" | jq ".summary.raining_minutes[8]")
raining_minutes_09=$(echo "${line}" | jq ".summary.raining_minutes[9]")
raining_minutes_10=$(echo "${line}" | jq ".summary.raining_minutes[10]")
raining_minutes_11=$(echo "${line}" | jq ".summary.raining_minutes[11]")
strike_count_1h=$(echo "${line}" | jq -r .summary.strike_count_1h)
strike_count_3h=$(echo "${line}" | jq -r .summary.strike_count_3h)
strike_last_dist=$(echo "${line}" | jq -r .summary.strike_last_dist)
strike_last_epoch=$(echo "${line}" | jq -r .summary.strike_last_epoch)
wet_bulb_temperature=$(echo "${line}" | jq -r .summary.wet_bulb_temperature)
wind_chill=$(echo "${line}" | jq -r .summary.wind_chill)

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


if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "obs,device_id ${device_id}"
echo "obs,firmware_revision ${firmware_revision}"
echo "obs,hub_sn ${hub_sn}"
echo "obs,serial_number ${serial_number}"

echo "obs,air_temperature ${air_temperature}"
echo "obs,battery ${battery}"
echo "obs,illuminance ${illuminance}"
echo "obs,lightning_strike_avg_distance ${lightning_strike_avg_distance}"
echo "obs,lightning_strike_count ${lightning_strike_count}"
echo "obs,local_daily_rain_accumulation ${local_daily_rain_accumulation}"
echo "obs,local_daily_rain_accumulation_final_rain_check ${local_daily_rain_accumulation_final_rain_check}"
echo "obs,precip_accumulated ${precip_accumulated}"
echo "obs,precipitation_analysis_type ${precipitation_analysis_type}"
echo "obs,precipitation_type ${precipitation_type}"
echo "obs,rain_accumulated_final_rain_check ${rain_accumulated_final_rain_check}"
echo "obs,relative_humidity ${relative_humidity}"
echo "obs,report_interval ${report_interval}"
echo "obs,solar_radiation ${solar_radiation}"
echo "obs,station_pressure ${station_pressure}"
echo "obs,time_epoch ${time_epoch}"
echo "obs,uv ${uv}"
echo "obs,wind_avg ${wind_avg}"
echo "obs,wind_direction ${wind_direction}"
echo "obs,wind_gust ${wind_gust}"
echo "obs,wind_lull ${wind_lull}"
echo "obs,wind_sample_interval ${wind_sample_interval}"

echo "obs,air_density ${air_density}"
echo "obs,delta_t ${delta_t}"
echo "obs,dew_point ${dew_point}"
echo "obs,feels_like ${feels_like}"
echo "obs,heat_index ${heat_index}"
echo "obs,precip_accum_local_yesterday ${precip_accum_local_yesterday}"
echo "obs,precip_accum_local_yesterday_final ${precip_accum_local_yesterday_final}"
echo "obs,precip_analysis_type_yesterday ${precip_analysis_type_yesterday}"
echo "obs,precip_minutes_local_day ${precip_minutes_local_day}"
echo "obs,precip_minutes_local_yesterday ${precip_minutes_local_yesterday}"
echo "obs,precip_total_1h ${precip_total_1h}"
echo "obs,pressure_trend ${pressure_trend}"
echo "obs,pulse_adj_ob_temp ${pulse_adj_ob_temp}"
echo "obs,pulse_adj_ob_time ${pulse_adj_ob_time}"
echo "obs,pulse_adj_ob_wind_avg ${pulse_adj_ob_wind_avg}"
echo "obs,raining_minutes_00 ${raining_minutes_00}"
echo "obs,raining_minutes_01 ${raining_minutes_01}"
echo "obs,raining_minutes_02 ${raining_minutes_02}"
echo "obs,raining_minutes_03 ${raining_minutes_03}"
echo "obs,raining_minutes_04 ${raining_minutes_04}"
echo "obs,raining_minutes_05 ${raining_minutes_05}"
echo "obs,raining_minutes_06 ${raining_minutes_06}"
echo "obs,raining_minutes_07 ${raining_minutes_07}"
echo "obs,raining_minutes_08 ${raining_minutes_08}"
echo "obs,raining_minutes_09 ${raining_minutes_09}"
echo "obs,raining_minutes_10 ${raining_minutes_10}"
echo "obs,raining_minutes_11 ${raining_minutes_11}"
echo "obs,strike_count_1h ${strike_count_1h}"
echo "obs,strike_count_3h ${strike_count_3h}"
echo "obs,strike_last_dist ${strike_last_dist}"
echo "obs,strike_last_epoch ${strike_last_epoch}"
echo "obs,wet_bulb_temperature ${wet_bulb_temperature}"
echo "obs,wind_chill ${wind_chill}"

fi

#
# Send metrics to InfluxDB
#

if [ "${hub_sn}" = "null" ]

  then
    echo "Skipping first socket message to InfluxDB - (Missing hub_sn)"

else

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} air_density=${air_density}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} air_temperature=${air_temperature}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} battery=${battery}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} delta_t=${delta_t}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} dew_point=${dew_point}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} feels_like=${feels_like}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} firmware_revision=${firmware_revision}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} heat_index=${heat_index}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} illuminance=${illuminance}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_avg_distance=${lightning_strike_avg_distance}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_count=${lightning_strike_count}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} local_daily_rain_accumulation=${local_daily_rain_accumulation}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} local_daily_rain_accumulation_final_rain_check=${local_daily_rain_accumulation_final_rain_check}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accum_local_yesterday=${precip_accum_local_yesterday}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accum_local_yesterday_final=${precip_accum_local_yesterday_final}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accumulated=${precip_accumulated}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_analysis_type_yesterday=${precip_analysis_type_yesterday}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_minutes_local_day=${precip_minutes_local_day}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_minutes_local_yesterday=${precip_minutes_local_yesterday}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_total_1h=${precip_total_1h}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precipitation_analysis_type=${precipitation_analysis_type}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precipitation_type=${precipitation_type}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} pressure_trend=${pressure_trend}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} pulse_adj_ob_temp=${pulse_adj_ob_temp}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} pulse_adj_ob_time=${pulse_adj_ob_time}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} pulse_adj_ob_wind_avg=${pulse_adj_ob_wind_avg}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} rain_accumulated_final_rain_check=${rain_accumulated_final_rain_check}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_00=${raining_minutes_00}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_01=${raining_minutes_01}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_02=${raining_minutes_02}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_03=${raining_minutes_03}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_04=${raining_minutes_04}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_05=${raining_minutes_05}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_06=${raining_minutes_06}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_07=${raining_minutes_07}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_08=${raining_minutes_08}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_09=${raining_minutes_09}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_10=${raining_minutes_10}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} raining_minutes_11=${raining_minutes_11}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} relative_humidity=${relative_humidity}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} report_interval=${report_interval}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} solar_radiation=${solar_radiation}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} station_pressure=${station_pressure}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} strike_count_1h=${strike_count_1h}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} strike_count_3h=${strike_count_3h}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} strike_last_dist=${strike_last_dist}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} strike_last_epoch=${strike_last_epoch}000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch=${time_epoch}000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} uv=${uv}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wet_bulb_temperature=${wet_bulb_temperature}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_avg=${wind_avg}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_chill=${wind_chill}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_direction=${wind_direction}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_gust=${wind_gust}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_lull=${wind_lull}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_sample_interval=${wind_sample_interval}"

fi

fi

#
# Observation (Air)
#

if [[ $line == *"obs_air"* ]]; then

#
# Extract Metrics
#

device_id=$(echo "${line}" | jq -r .device_id)

air_temperature=$(echo "${line}" | jq ".obs[0][2]")
battery=$(echo "${line}" | jq ".obs[0][6]")
lightning_strike_avg_distance=$(echo "${line}" | jq ".obs[0][5]")
lightning_strike_count=$(echo "${line}" | jq ".obs[0][4]")
relative_humidity=$(echo "${line}" | jq ".obs[0][3]")
report_interval=$(echo "${line}" | jq ".obs[0][7]")
station_pressure=$(echo "${line}" | jq ".obs[0][1]")
time_epoch=$(echo "${line}" | jq ".obs[0][0]")

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

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

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} air_temperature=${air_temperature}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} battery=${battery}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_avg_distance=${lightning_strike_avg_distance}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} lightning_strike_count=${lightning_strike_count}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} relative_humidity=${relative_humidity}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} report_interval=${report_interval}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} station_pressure=${station_pressure}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch${time_epoch}000"

fi

#
# Observation (Sky)
#

if [[ $line == *"obs_sky"* ]]; then

#
# Extract Metrics
#

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

#
# Remove Null Entries
#

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

#
# Print Metrics
#

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

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} battery=${battery}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} illuminance=${illuminance}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} local_daily_rain_accumulation_final_rain_check=${local_daily_rain_accumulation_final_rain_check}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accumulated=${precip_accumulated}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precip_accumulated=${precip_accumulated}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precipitation_analysis_type=${precipitation_analysis_type}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} precipitation_type=${precipitation_type}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} rain_accumulated_final_rain_check=${rain_accumulated_final_rain_check}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} report_interval=${report_interval}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} solar_radiation=${solar_radiation}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch${time_epoch}000
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} uv=${uv}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_avg=${wind_avg}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_direction=${wind_direction}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_gust=${wind_gust}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_lull=${wind_lull}
weatherflow_obs,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_sample_interval=${wind_sample_interval}"

fi

#
# Rapid Wind
#

if [[ $line == *"rapid_wind"* ]]; then

# Extract Metrics

device_id=$(echo "${line}" | jq -r .device_id)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
serial_number=$(echo "${line}" | jq -r .serial_number)

time_epoch=$(echo "${line}" | jq ".ob[0]")
wind_speed=$(echo "${line}" | jq ".ob[1]")
wind_direction=$(echo "${line}" | jq ".ob[2]")

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "rapid_wind,device_id ${device_id}"
echo "rapid_wind,hub_sn ${hub_sn}"
echo "rapid_wind,serial_number ${serial_number}"

echo "rapid_wind,time_epoch ${time_epoch}"
echo "rapid_wind,wind_speed ${wind_speed}"
echo "rapid_wind,wind_direction ${wind_direction}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_rapid_wind,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch=${time_epoch}000
weatherflow_rapid_wind,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_speed=${wind_speed}
weatherflow_rapid_wind,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} wind_direction=${wind_direction}"

fi

#
# Lightning Strike Event
#

if [[ $line == *"evt_strike"* ]]; then

#
# Extract Metrics
#

device_id=$(echo "${line}" | jq -r .device_id)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
serial_number=$(echo "${line}" | jq -r .serial_number)

time_epoch=$(echo "${line}" | jq ".evt[0]")
distance=$(echo "${line}" | jq ".evt[1]")
energy=$(echo "${line}" | jq ".evt[2]")

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "evt_strike,device_id ${device_id}"
echo "evt_strike,hub_sn ${hub_sn}"
echo "evt_strike,serial_number ${serial_number}"

echo "evt_strike,time_epoch ${time_epoch}"
echo "evt_strike,distance ${distance}"
echo "evt_strike,energy ${energy}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_strike,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch=${time_epoch}000
weatherflow_evt_strike,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} distance=${distance}
weatherflow_evt_strike,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} energy=${energy}"

fi

#
# Rain Start Event
#

if [[ $line == *"evt_precip"* ]]; then

#
# Extract Metrics
#

device_id=$(echo "${line}" | jq -r .device_id)
hub_sn=$(echo "${line}" | jq -r .hub_sn)
serial_number=$(echo "${line}" | jq -r .serial_number)

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "evt_precip,device_id ${device_id}"
echo "evt_precip,hub_sn ${hub_sn}"
echo "evt_precip,serial_number ${serial_number}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_precip,collector_type=${collector_type},device_id=${device_id},elevation=${elevation},hub_sn=${hub_sn},latitude=${latitude},longitude=${longitude},public_name=${public_name},serial_number=${serial_number},station_id=${station_id},station_name=${station_name},timezone=${timezone} time_epoch=${time_epoch}000"


fi

#
# Acknowledgement
#

if [[ $line == *"ack"* ]]; then

#
# Extract Metrics
#

ack_id=$(echo "${line}" | jq -r .id)

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "ack,id ${ack_id}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_ack,id=${ack_id},collector_type=${collector_type} time_epoch=${time_epoch}000"

fi

#
# Device Online Event
#

if [[ $line == *"evt_device_online"* ]]; then

#
# Extract Metrics
#

evt_device_online_device_id=$(echo "${line}" | jq -r .device_id)

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "evt_device_online,device_id ${evt_device_online_device_id}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_device_online,device_id=${evt_device_online_device_id},collector_type=${collector_type} time_epoch=${time_epoch}000"

fi

#
# Device Offline Event
#

if [[ $line == *"evt_device_offline"* ]]; then

# Extract Metrics

evt_device_offline_device_id=$(echo "${line}" | jq -r .device_id)

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "evt_device_offline,device_id ${evt_device_offline_device_id}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_device_offline,device_id=${evt_device_offline_device_id},collector_type=${collector_type} time_epoch=${time_epoch}000"

fi

#
# Station Online Event
#

if [[ $line == *"evt_station_online"* ]]; then

#
# Extract Metrics
#

evt_station_online_station_id=$(echo "${line}" | jq -r .station_id)

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "evt_station_online,station_id ${evt_station_online_station_id}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_station_online,station_id=${evt_station_online_station_id},collector_type=${collector_type} time_epoch=${time_epoch}000"

fi

#
# Station Offline Event
#

if [[ $line == *"evt_station_offline"* ]]; then

#
# Extract Metrics
#

evt_station_offline_station_id=$(echo "${line}" | jq -r .station_id)

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "evt_station_offline,station_id ${evt_station_offline_station_id}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_station_offline,station_id=${evt_station_offline_station_id},collector_type=${collector_type} time_epoch=${time_epoch}000"

fi

done < /dev/stdin
