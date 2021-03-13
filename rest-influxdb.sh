#!/bin/bash

debug=$WEATHERFLOW_LISTENER_DEBUG

# InfluxDB Endpoint

influxdb_url=$WEATHERFLOW_LISTENER_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_LISTENER_INFLUXDB_USERNAME
influxdb_password=$WEATHERFLOW_LISTENER_INFLUXDB_PASSWORD
api=$WEATHERFLOW_LISTENER_API_TYPE

# Curl Command

if [ "$debug" == "true" ]
then

curl=(  )

else

curl=( --silent --output /dev/null --show-error --fail )

fi

#
# Start Reading in STDIN
#

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

obs_device_id=$(echo "${line}" | jq -r .device_id)

obs_time_epoch=$(echo "${line}" | jq ".obs[0][0]")
obs_wind_lull=$(echo "${line}" | jq ".obs[0][1]")
obs_wind_avg=$(echo "${line}" | jq ".obs[0][2]")
obs_wind_gust=$(echo "${line}" | jq ".obs[0][3]")
obs_wind_direction=$(echo "${line}" | jq ".obs[0][4]")
obs_wind_sample_interval=$(echo "${line}" | jq ".obs[0][5]")
obs_station_pressure=$(echo "${line}" | jq ".obs[0][6]")
obs_air_temperature=$(echo "${line}" | jq ".obs[0][7]")
obs_relative_humidity=$(echo "${line}" | jq ".obs[0][8]")
obs_illuminance=$(echo "${line}" | jq ".obs[0][9]")
obs_uv=$(echo "${line}" | jq ".obs[0][10]")
obs_solar_radiation=$(echo "${line}" | jq ".obs[0][11]")
obs_precip_accumulated=$(echo "${line}" | jq ".obs[0][12]")
obs_precipitation_type=$(echo "${line}" | jq ".obs[0][13]")
obs_lightning_strike_avg_distance=$(echo "${line}" | jq ".obs[0][14]")
obs_lightning_strike_count=$(echo "${line}" | jq ".obs[0][15]")
obs_battery=$(echo "${line}" | jq ".obs[0][16]")
obs_report_interval=$(echo "${line}" | jq ".obs[0][17]")
obs_local_daily_rain_accumulation=$(echo "${line}" | jq ".obs[0][18]")
obs_rain_accumulated_final_rain_check=$(echo "${line}" | jq ".obs[0][19]")
obs_local_daily_rain_accumulation_final_rain_check=$(echo "${line}" | jq ".obs[0][20]")
obs_precipitation_analysis_type=$(echo "${line}" | jq ".obs[0][21]")

#
# Remove Null Entries
#

if [ "$obs_rain_accumulated_final_rain_check" = "null" ]
then
obs_rain_accumulated_final_rain_check="0"
fi

if [ "$obs_local_daily_rain_accumulation_final_rain_check" = "null" ]
then
obs_local_daily_rain_accumulation_final_rain_check="0"
fi



if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "obs,device_id ${obs_device_id}"

echo "obs,time_epoch ${obs_time_epoch}"
echo "obs,wind_lull ${obs_wind_lull}"
echo "obs,wind_avg ${obs_wind_avg}"
echo "obs,wind_gust ${obs_wind_gust}"
echo "obs,wind_direction ${obs_wind_direction}"
echo "obs,wind_sample_interval ${obs_wind_sample_interval}"
echo "obs,station_pressure ${obs_station_pressure}"
echo "obs,air_temperature ${obs_air_temperature}"
echo "obs,relative_humidity ${obs_relative_humidity}"
echo "obs,illuminance ${obs_illuminance}"
echo "obs,uv ${obs_uv}"
echo "obs,solar_radiation ${obs_solar_radiation}"
echo "obs,precip_accumulated ${obs_precip_accumulated}"
echo "obs,precipitation_type ${obs_precipitation_type}"
echo "obs,lightning_strike_avg_distance ${obs_lightning_strike_avg_distance}"
echo "obs,lightning_strike_count ${obs_lightning_strike_count}"
echo "obs,battery ${obs_battery}"
echo "obs,report_interval ${obs_report_interval}"
echo "obs,local_daily_rain_accumulation ${obs_local_daily_rain_accumulation}"
echo "obs,rain_accumulated_final_rain_check ${obs_rain_accumulated_final_rain_check}"
echo "obs,local_daily_rain_accumulation_final_rain_check ${obs_local_daily_rain_accumulation_final_rain_check}"
echo "obs,precipitation_analysis_type ${obs_precipitation_analysis_type}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,device_id=${obs_device_id},api=${api} time_epoch=${obs_time_epoch}
weatherflow_obs,device_id=${obs_device_id},api=${api} wind_lull=${obs_wind_lull}
weatherflow_obs,device_id=${obs_device_id},api=${api} wind_avg=${obs_wind_avg}
weatherflow_obs,device_id=${obs_device_id},api=${api} wind_gust=${obs_wind_gust}
weatherflow_obs,device_id=${obs_device_id},api=${api} wind_direction=${obs_wind_direction}
weatherflow_obs,device_id=${obs_device_id},api=${api} wind_sample_interval=${obs_wind_sample_interval}
weatherflow_obs,device_id=${obs_device_id},api=${api} station_pressure=${obs_station_pressure}
weatherflow_obs,device_id=${obs_device_id},api=${api} air_temperature=${obs_air_temperature}
weatherflow_obs,device_id=${obs_device_id},api=${api} relative_humidity=${obs_relative_humidity}
weatherflow_obs,device_id=${obs_device_id},api=${api} illuminance=${obs_illuminance}
weatherflow_obs,device_id=${obs_device_id},api=${api} uv=${obs_uv}
weatherflow_obs,device_id=${obs_device_id},api=${api} solar_radiation=${obs_solar_radiation}
weatherflow_obs,device_id=${obs_device_id},api=${api} precip_accumulated=${obs_precip_accumulated}
weatherflow_obs,device_id=${obs_device_id},api=${api} precipitation_type=${obs_precipitation_type}
weatherflow_obs,device_id=${obs_device_id},api=${api} lightning_strike_avg_distance=${obs_lightning_strike_avg_distance}
weatherflow_obs,device_id=${obs_device_id},api=${api} lightning_strike_count=${obs_lightning_strike_count}
weatherflow_obs,device_id=${obs_device_id},api=${api} battery=${obs_battery}
weatherflow_obs,device_id=${obs_device_id},api=${api} report_interval=${obs_report_interval}
weatherflow_obs,device_id=${obs_device_id},api=${api} local_daily_rain_accumulation=${obs_local_daily_rain_accumulation}
weatherflow_obs,device_id=${obs_device_id},api=${api} rain_accumulated_final_rain_check=${obs_rain_accumulated_final_rain_check}
weatherflow_obs,device_id=${obs_device_id},api=${api} local_daily_rain_accumulation_final_rain_check=${obs_local_daily_rain_accumulation_final_rain_check}
weatherflow_obs,device_id=${obs_device_id},api=${api} precipitation_analysis_type=${obs_precipitation_analysis_type}"

fi

#
# Observation (Air)
#

if [[ $line == *"obs_air"* ]]; then

#
# Extract Metrics
#

obs_device_id=$(echo "${line}" | jq -r .device_id)

obs_time_epoch=$(echo "${line}" | jq ".obs[0][0]")
obs_station_pressure=$(echo "${line}" | jq ".obs[0][1]")
obs_air_temperature=$(echo "${line}" | jq ".obs[0][2]")
obs_relative_humidity=$(echo "${line}" | jq ".obs[0][3]")
obs_lightning_strike_count=$(echo "${line}" | jq ".obs[0][4]")
obs_lightning_strike_avg_distance=$(echo "${line}" | jq ".obs[0][5]")
obs_battery=$(echo "${line}" | jq ".obs[0][6]")
obs_report_interval=$(echo "${line}" | jq ".obs[0][7]")

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "obs,device_id ${obs_device_id}"

echo "obs,time_epoch ${obs_time_epoch}"
echo "obs,station_pressure ${obs_station_pressure}"
echo "obs,air_temperature ${obs_air_temperature}"
echo "obs,relative_humidity ${obs_relative_humidity}"
echo "obs,lightning_strike_count ${obs_lightning_strike_count}"
echo "obs,lightning_strike_avg_distance ${obs_lightning_strike_avg_distance}"
echo "obs,battery ${obs_battery}"
echo "obs,report_interval ${obs_report_interval}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,device_id=${obs_device_id},api=${api} time_epoch${obs_time_epoch}
weatherflow_obs,device_id=${obs_device_id},api=${api} station_pressure=${obs_station_pressure}
weatherflow_obs,device_id=${obs_device_id},api=${api} air_temperature=${obs_air_temperature}
weatherflow_obs,device_id=${obs_device_id},api=${api} relative_humidity=${obs_relative_humidity}
weatherflow_obs,device_id=${obs_device_id},api=${api} lightning_strike_count=${obs_lightning_strike_count}
weatherflow_obs,device_id=${obs_device_id},api=${api} lightning_strike_avg_distance=${obs_lightning_strike_avg_distance}
weatherflow_obs,device_id=${obs_device_id},api=${api} battery=${obs_battery}
weatherflow_obs,device_id=${obs_device_id},api=${api} report_interval=${obs_report_interval}"

fi

#
# Observation (Sky)
#

if [[ $line == *"obs_sky"* ]]; then

#
# Extract Metrics
#

obs_device_id=$(echo "${line}" | jq -r .device_id)

obs_time_epoch=$(echo "${line}" | jq ".obs[0][0]")
obs_illuminance=$(echo "${line}" | jq ".obs[0][1]")
obs_uv=$(echo "${line}" | jq ".obs[0][2]")
obs_precip_accumulated=$(echo "${line}" | jq ".obs[0][3]")
obs_wind_lull=$(echo "${line}" | jq ".obs[0][4]")
obs_wind_avg=$(echo "${line}" | jq ".obs[0][5]")
obs_wind_gust=$(echo "${line}" | jq ".obs[0][6]")
obs_wind_direction=$(echo "${line}" | jq ".obs[0][7]")
obs_battery=$(echo "${line}" | jq ".obs[0][8]")
obs_report_interval=$(echo "${line}" | jq ".obs[0][9]")
obs_solar_radiation=$(echo "${line}" | jq ".obs[0][10]")
obs_precip_accumulated=$(echo "${line}" | jq ".obs[0][11]")
obs_precipitation_type=$(echo "${line}" | jq ".obs[0][12]")
obs_wind_sample_interval=$(echo "${line}" | jq ".obs[0][13]")
obs_rain_accumulated_final_rain_check=$(echo "${line}" | jq ".obs[0][14]")
obs_local_daily_rain_accumulation_final_rain_check=$(echo "${line}" | jq ".obs[0][15]")
obs_precipitation_analysis_type=$(echo "${line}" | jq ".obs[0][16]")

#
# Remove Null Entries
#

if [ "$obs_precip_accumulated" = "null" ]
then
obs_precip_accumulated="0"
fi

if [ "$obs_rain_accumulated_final_rain_check" = "null" ]
then
obs_rain_accumulated_final_rain_check="0"
fi

if [ "$obs_local_daily_rain_accumulation_final_rain_check" = "null" ]
then
obs_local_daily_rain_accumulation_final_rain_check="0"
fi

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "obs,device_id ${obs_device_id}"

echo "obs,time_epoch ${obs_time_epoch}"
echo "obs,illuminance ${obs_illuminance}"
echo "obs,uv ${obs_uv}"
echo "obs,precip_accumulated ${obs_precip_accumulated}"
echo "obs,wind_lull ${obs_wind_lull}"
echo "obs,wind_avg ${obs_wind_avg}"
echo "obs,wind_gust ${obs_wind_gust}"
echo "obs,wind_direction ${obs_wind_direction}"
echo "obs,battery ${obs_battery}"
echo "obs,report_interval ${obs_report_interval}"
echo "obs,solar_radiation ${obs_solar_radiation}"
echo "obs,precip_accumulated ${obs_precip_accumulated}"
echo "obs,precipitation_type ${obs_precipitation_type}"
echo "obs,wind_sample_interval ${obs_wind_sample_interval}"
echo "obs,rain_accumulated_final_rain_check ${obs_rain_accumulated_final_rain_check}"
echo "obs,local_daily_rain_accumulation_final_rain_check ${obs_local_daily_rain_accumulation_final_rain_check}"
echo "obs,precipitation_analysis_type ${obs_precipitation_analysis_type}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,device_id=${obs_device_id},api=${api} time_epoch${obs_time_epoch}
weatherflow_obs,device_id=${obs_device_id},api=${api} illuminance=${obs_illuminance}
weatherflow_obs,device_id=${obs_device_id},api=${api} uv=${obs_uv}
weatherflow_obs,device_id=${obs_device_id},api=${api} precip_accumulated=${obs_precip_accumulated}
weatherflow_obs,device_id=${obs_device_id},api=${api} wind_lull=${obs_wind_lull}
weatherflow_obs,device_id=${obs_device_id},api=${api} wind_avg=${obs_wind_avg}
weatherflow_obs,device_id=${obs_device_id},api=${api} wind_gust=${obs_wind_gust}
weatherflow_obs,device_id=${obs_device_id},api=${api} wind_direction=${obs_wind_direction}
weatherflow_obs,device_id=${obs_device_id},api=${api} battery=${obs_battery}
weatherflow_obs,device_id=${obs_device_id},api=${api} report_interval=${obs_report_interval}
weatherflow_obs,device_id=${obs_device_id},api=${api} solar_radiation=${obs_solar_radiation}
weatherflow_obs,device_id=${obs_device_id},api=${api} precip_accumulated=${obs_precip_accumulated}
weatherflow_obs,device_id=${obs_device_id},api=${api} precipitation_type=${obs_precipitation_type}
weatherflow_obs,device_id=${obs_device_id},api=${api} wind_sample_interval=${obs_wind_sample_interval}
weatherflow_obs,device_id=${obs_device_id},api=${api} rain_accumulated_final_rain_check=${obs_rain_accumulated_final_rain_check}
weatherflow_obs,device_id=${obs_device_id},api=${api} local_daily_rain_accumulation_final_rain_check=${obs_local_daily_rain_accumulation_final_rain_check}
weatherflow_obs,device_id=${obs_device_id},api=${api} precipitation_analysis_type=${obs_precipitation_analysis_type}"

fi

#
# Rapid Wind
#

if [[ $line == *"rapid_wind"* ]]; then

# Extract Metrics

rapid_wind_device_id=$(echo "${line}" | jq -r .device_id)

rapid_wind_time_epoch=$(echo "${line}" | jq ".ob[0]")
rapid_wind_wind_speed=$(echo "${line}" | jq ".ob[1]")
rapid_wind_wind_direction=$(echo "${line}" | jq ".ob[2]")

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "rapid_wind,device_id ${rapid_wind_device_id}"

echo "rapid_wind,time_epoch ${rapid_wind_time_epoch}"
echo "rapid_wind,wind_speed ${rapid_wind_wind_speed}"
echo "rapid_wind,wind_direction ${rapid_wind_wind_direction}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_rapid_wind,device_id=${rapid_wind_device_id},api=${api} time_epoch=${rapid_wind_time_epoch}
weatherflow_rapid_wind,device_id=${rapid_wind_device_id},api=${api} wind_speed=${rapid_wind_wind_speed}
weatherflow_rapid_wind,device_id=${rapid_wind_device_id},api=${api} wind_direction=${rapid_wind_wind_direction}"

fi

#
# Lightning Strike Event
#

if [[ $line == *"evt_strike"* ]]; then

#
# Extract Metrics
#

evt_strike_device_id=$(echo "${line}" | jq -r .device_id)

evt_strike_time_epoch=$(echo "${line}" | jq ".evt[0]")
evt_strike_distance=$(echo "${line}" | jq ".evt[1]")
evt_strike_energy=$(echo "${line}" | jq ".evt[2]")

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "evt_strike,device_id ${evt_strike_device_id}"

echo "evt_strike,time_epoch ${evt_strike_time_epoch}"
echo "evt_strike,distance ${evt_strike_distance}"
echo "evt_strike,energy ${evt_strike_energy}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_strike,device_id=${evt_strike_device_id},api=${api} time_epoch=${evt_strike_time_epoch}
weatherflow_evt_strike,device_id=${evt_strike_device_id},api=${api} distance=${evt_strike_distance}
weatherflow_evt_strike,device_id=${evt_strike_device_id},api=${api} energy=${evt_strike_energy}"

fi

#
# Rain Start Event
#

if [[ $line == *"evt_precip"* ]]; then

#
# Extract Metrics
#

evt_precip_device_id=$(echo "${line}" | jq -r .device_id)

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "evt_precip,device_id ${evt_precip_device_id}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_precip,device_id=${evt_precip_device_id},api=${api} time_epoch=${time_epoch}"

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
weatherflow_ack,id=${ack_id},api=${api} time_epoch=${time_epoch}"

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
weatherflow_evt_device_online,device_id=${evt_device_online_device_id},api=${api} time_epoch=${time_epoch}"

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
weatherflow_evt_device_offline,device_id=${evt_device_offline_device_id},api=${api} time_epoch=${time_epoch}"

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
weatherflow_evt_station_online,station_id=${evt_station_online_station_id},api=${api} time_epoch=${time_epoch}"

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
weatherflow_evt_station_offline,station_id=${evt_station_offline_station_id},api=${api} time_epoch=${time_epoch}"

fi

done < /dev/stdin
