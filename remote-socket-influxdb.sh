#!/bin/bash

debug=$WEATHERFLOW_LISTENER_DEBUG

# InfluxDB Endpoint

influxdb_url=$WEATHERFLOW_LISTENER_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_LISTENER_INFLUXDB_USERNAME
influxdb_password=$WEATHERFLOW_LISTENER_INFLUXDB_PASSWORD
collector_type=$WEATHERFLOW_LISTENER_COLLECTOR_TYPE

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
obs_hub_sn=$(echo "${line}" | jq -r .hub_sn)
obs_serial_number=$(echo "${line}" | jq -r .serial_number)
obs_firmware_revision=$(echo "${line}" | jq -r .firmware_revision)

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

obs_summary_pressure_trend=$(echo "${line}" | jq -r .summary.pressure_trend)
obs_summary_strike_count_1h=$(echo "${line}" | jq -r .summary.strike_count_1h)
obs_summary_strike_count_3h=$(echo "${line}" | jq -r .summary.strike_count_3h)
obs_summary_precip_total_1h=$(echo "${line}" | jq -r .summary.precip_total_1h)
obs_summary_strike_last_dist=$(echo "${line}" | jq -r .summary.strike_last_dist)
obs_summary_strike_last_epoch=$(echo "${line}" | jq -r .summary.strike_last_epoch)
obs_summary_precip_accum_local_yesterday=$(echo "${line}" | jq -r .summary.precip_accum_local_yesterday)
obs_summary_precip_accum_local_yesterday_final=$(echo "${line}" | jq -r .summary.precip_accum_local_yesterday_final)
obs_summary_precip_analysis_type_yesterday=$(echo "${line}" | jq -r .summary.precip_analysis_type_yesterday)
obs_summary_feels_like=$(echo "${line}" | jq -r .summary.feels_like)
obs_summary_heat_index=$(echo "${line}" | jq -r .summary.heat_index)
obs_summary_wind_chill=$(echo "${line}" | jq -r .summary.wind_chill)
obs_summary_pulse_adj_ob_time=$(echo "${line}" | jq -r .summary.pulse_adj_ob_time)
obs_summary_pulse_adj_ob_wind_avg=$(echo "${line}" | jq -r .summary.pulse_adj_ob_wind_avg)
obs_summary_pulse_adj_ob_temp=$(echo "${line}" | jq -r .summary.pulse_adj_ob_temp)
obs_summary_raining_minutes_00=$(echo "${line}" | jq ".summary.raining_minutes[0]")
obs_summary_raining_minutes_01=$(echo "${line}" | jq ".summary.raining_minutes[1]")
obs_summary_raining_minutes_02=$(echo "${line}" | jq ".summary.raining_minutes[2]")
obs_summary_raining_minutes_03=$(echo "${line}" | jq ".summary.raining_minutes[3]")
obs_summary_raining_minutes_04=$(echo "${line}" | jq ".summary.raining_minutes[4]")
obs_summary_raining_minutes_05=$(echo "${line}" | jq ".summary.raining_minutes[5]")
obs_summary_raining_minutes_06=$(echo "${line}" | jq ".summary.raining_minutes[6]")
obs_summary_raining_minutes_07=$(echo "${line}" | jq ".summary.raining_minutes[7]")
obs_summary_raining_minutes_08=$(echo "${line}" | jq ".summary.raining_minutes[8]")
obs_summary_raining_minutes_09=$(echo "${line}" | jq ".summary.raining_minutes[9]")
obs_summary_raining_minutes_10=$(echo "${line}" | jq ".summary.raining_minutes[10]")
obs_summary_raining_minutes_11=$(echo "${line}" | jq ".summary.raining_minutes[11]")
obs_summary_dew_point=$(echo "${line}" | jq -r .summary.dew_point)
obs_summary_wet_bulb_temperature=$(echo "${line}" | jq -r .summary.wet_bulb_temperature)
obs_summary_air_density=$(echo "${line}" | jq -r .summary.air_density)
obs_summary_delta_t=$(echo "${line}" | jq -r .summary.delta_t)
obs_summary_precip_minutes_local_day=$(echo "${line}" | jq -r .summary.precip_minutes_local_day)
obs_summary_precip_minutes_local_yesterday=$(echo "${line}" | jq -r .summary.precip_minutes_local_yesterday)


#
# Pressure Trend
#

if [ "$obs_summary_pressure_trend" = "falling" ]
then
obs_summary_pressure_trend="-1"
fi

if [ "$obs_summary_pressure_trend" = "steady" ]
then
obs_summary_pressure_trend="0"
fi

if [ "$obs_summary_pressure_trend" = "rising" ]
then
obs_summary_pressure_trend="1"
fi

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

if [ "$obs_summary_strike_last_dist" = "null" ]
then
obs_summary_strike_last_dist="0"
fi

if [ "$obs_summary_strike_last_epoch" = "null" ]
then
obs_summary_strike_last_epoch="0"
fi

if [ "$obs_summary_precip_accum_local_yesterday_final" = "null" ]
then
obs_summary_precip_accum_local_yesterday_final="0"
fi

if [ "$obs_summary_precip_minutes_local_yesterday" = "null" ]
then
obs_summary_precip_minutes_local_yesterday="0"
fi


if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "obs,device_id ${obs_device_id}"
echo "obs,hub_sn ${obs_hub_sn}"
echo "obs,serial_number ${obs_serial_number}"
echo "obs,firmware_revision ${obs_firmware_revision}"

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

echo "obs,summary_pressure_trend ${obs_summary_pressure_trend}"
echo "obs,summary_strike_count_1h ${obs_summary_strike_count_1h}"
echo "obs,summary_strike_count_3h ${obs_summary_strike_count_3h}"
echo "obs,summary_precip_total_1h ${obs_summary_precip_total_1h}"
echo "obs,summary_strike_last_dist ${obs_summary_strike_last_dist}"
echo "obs,summary_strike_last_epoch ${obs_summary_strike_last_epoch}"
echo "obs,summary_precip_accum_local_yesterday ${obs_summary_precip_accum_local_yesterday}"
echo "obs,summary_precip_accum_local_yesterday_final ${obs_summary_precip_accum_local_yesterday_final}"
echo "obs,summary_precip_analysis_type_yesterday ${obs_summary_precip_analysis_type_yesterday}"
echo "obs,summary_feels_like ${obs_summary_feels_like}"
echo "obs,summary_heat_index ${obs_summary_heat_index}"
echo "obs,summary_wind_chill ${obs_summary_wind_chill}"
echo "obs,summary_pulse_adj_ob_time ${obs_summary_pulse_adj_ob_time}"
echo "obs,summary_pulse_adj_ob_wind_avg ${obs_summary_pulse_adj_ob_wind_avg}"
echo "obs,summary_pulse_adj_ob_temp ${obs_summary_pulse_adj_ob_temp}"
echo "obs,summary_raining_minutes_00 ${obs_summary_raining_minutes_00}"
echo "obs,summary_raining_minutes_01 ${obs_summary_raining_minutes_01}"
echo "obs,summary_raining_minutes_02 ${obs_summary_raining_minutes_02}"
echo "obs,summary_raining_minutes_03 ${obs_summary_raining_minutes_03}"
echo "obs,summary_raining_minutes_04 ${obs_summary_raining_minutes_04}"
echo "obs,summary_raining_minutes_05 ${obs_summary_raining_minutes_05}"
echo "obs,summary_raining_minutes_06 ${obs_summary_raining_minutes_06}"
echo "obs,summary_raining_minutes_07 ${obs_summary_raining_minutes_07}"
echo "obs,summary_raining_minutes_08 ${obs_summary_raining_minutes_08}"
echo "obs,summary_raining_minutes_09 ${obs_summary_raining_minutes_09}"
echo "obs,summary_raining_minutes_10 ${obs_summary_raining_minutes_10}"
echo "obs,summary_raining_minutes_11 ${obs_summary_raining_minutes_11}"
echo "obs,summary_dew_point ${obs_summary_dew_point}"
echo "obs,summary_wet_bulb_temperature ${obs_summary_wet_bulb_temperature}"
echo "obs,summary_air_density ${obs_summary_air_density}"
echo "obs,summary_delta_t ${obs_summary_delta_t}"
echo "obs,summary_precip_minutes_local_day ${obs_summary_precip_minutes_local_day}"
echo "obs,summary_precip_minutes_local_yesterday ${obs_summary_precip_minutes_local_yesterday}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} time_epoch=${obs_time_epoch}000
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} wind_lull=${obs_wind_lull}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} wind_avg=${obs_wind_avg}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} wind_gust=${obs_wind_gust}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} wind_direction=${obs_wind_direction}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} wind_sample_interval=${obs_wind_sample_interval}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} station_pressure=${obs_station_pressure}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} air_temperature=${obs_air_temperature}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} relative_humidity=${obs_relative_humidity}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} illuminance=${obs_illuminance}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} uv=${obs_uv}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} solar_radiation=${obs_solar_radiation}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} precip_accumulated=${obs_precip_accumulated}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} precipitation_type=${obs_precipitation_type}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} lightning_strike_avg_distance=${obs_lightning_strike_avg_distance}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} lightning_strike_count=${obs_lightning_strike_count}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} battery=${obs_battery}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} report_interval=${obs_report_interval}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} local_daily_rain_accumulation=${obs_local_daily_rain_accumulation}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} rain_accumulated_final_rain_check=${obs_rain_accumulated_final_rain_check}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} local_daily_rain_accumulation_final_rain_check=${obs_local_daily_rain_accumulation_final_rain_check}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} precipitation_analysis_type=${obs_precipitation_analysis_type}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} pressure_trend=${obs_summary_pressure_trend}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} strike_count_1h=${obs_summary_strike_count_1h}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} strike_count_3h=${obs_summary_strike_count_3h}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} precip_total_1h=${obs_summary_precip_total_1h}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} strike_last_dist=${obs_summary_strike_last_dist}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} strike_last_epoch=${obs_summary_strike_last_epoch}000
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} precip_accum_local_yesterday=${obs_summary_precip_accum_local_yesterday}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} precip_accum_local_yesterday_final=${obs_summary_precip_accum_local_yesterday_final}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} precip_analysis_type_yesterday=${obs_summary_precip_analysis_type_yesterday}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} feels_like=${obs_summary_feels_like}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} heat_index=${obs_summary_heat_index}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} wind_chill=${obs_summary_wind_chill}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} pulse_adj_ob_time=${obs_summary_pulse_adj_ob_time}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} pulse_adj_ob_wind_avg=${obs_summary_pulse_adj_ob_wind_avg}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} pulse_adj_ob_temp=${obs_summary_pulse_adj_ob_temp}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_00=${obs_summary_raining_minutes_00}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_01=${obs_summary_raining_minutes_01}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_02=${obs_summary_raining_minutes_02}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_03=${obs_summary_raining_minutes_03}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_04=${obs_summary_raining_minutes_04}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_05=${obs_summary_raining_minutes_05}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_06=${obs_summary_raining_minutes_06}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_07=${obs_summary_raining_minutes_07}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_08=${obs_summary_raining_minutes_08}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_09=${obs_summary_raining_minutes_09}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_10=${obs_summary_raining_minutes_10}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} raining_minutes_11=${obs_summary_raining_minutes_11}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} dew_point=${obs_summary_dew_point}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} wet_bulb_temperature=${obs_summary_wet_bulb_temperature}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} air_density=${obs_summary_air_density}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} delta_t=${obs_summary_delta_t}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} precip_minutes_local_day=${obs_summary_precip_minutes_local_day}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} precip_minutes_local_yesterday=${obs_summary_precip_minutes_local_yesterday}
weatherflow_obs,device_id=${obs_device_id},hub_sn=${obs_hub_sn},serial_number=${obs_serial_number},collector_type=${collector_type} firmware_revision=${obs_firmware_revision}"

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
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} time_epoch${obs_time_epoch}000
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} station_pressure=${obs_station_pressure}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} air_temperature=${obs_air_temperature}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} relative_humidity=${obs_relative_humidity}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} lightning_strike_count=${obs_lightning_strike_count}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} lightning_strike_avg_distance=${obs_lightning_strike_avg_distance}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} battery=${obs_battery}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} report_interval=${obs_report_interval}"

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
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} time_epoch${obs_time_epoch}000
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} illuminance=${obs_illuminance}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} uv=${obs_uv}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} precip_accumulated=${obs_precip_accumulated}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} wind_lull=${obs_wind_lull}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} wind_avg=${obs_wind_avg}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} wind_gust=${obs_wind_gust}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} wind_direction=${obs_wind_direction}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} battery=${obs_battery}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} report_interval=${obs_report_interval}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} solar_radiation=${obs_solar_radiation}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} precip_accumulated=${obs_precip_accumulated}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} precipitation_type=${obs_precipitation_type}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} wind_sample_interval=${obs_wind_sample_interval}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} rain_accumulated_final_rain_check=${obs_rain_accumulated_final_rain_check}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} local_daily_rain_accumulation_final_rain_check=${obs_local_daily_rain_accumulation_final_rain_check}
weatherflow_obs,device_id=${obs_device_id},collector_type=${collector_type} precipitation_analysis_type=${obs_precipitation_analysis_type}"

fi

#
# Rapid Wind
#

if [[ $line == *"rapid_wind"* ]]; then

# Extract Metrics

rapid_wind_device_id=$(echo "${line}" | jq -r .device_id)
rapid_wind_hub_sn=$(echo "${line}" | jq -r .hub_sn)
rapid_wind_serial_number=$(echo "${line}" | jq -r .serial_number)

rapid_wind_time_epoch=$(echo "${line}" | jq ".ob[0]")
rapid_wind_wind_speed=$(echo "${line}" | jq ".ob[1]")
rapid_wind_wind_direction=$(echo "${line}" | jq ".ob[2]")

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "rapid_wind,device_id ${rapid_wind_device_id}"
echo "rapid_wind,hub_sn ${rapid_wind_hub_sn}"
echo "rapid_wind,serial_number ${rapid_wind_serial_number}"

echo "rapid_wind,time_epoch ${rapid_wind_time_epoch}"
echo "rapid_wind,wind_speed ${rapid_wind_wind_speed}"
echo "rapid_wind,wind_direction ${rapid_wind_wind_direction}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_rapid_wind,device_id=${rapid_wind_device_id},hub_sn=${rapid_wind_hub_sn},serial_number=${rapid_wind_serial_number},collector_type=${collector_type} time_epoch=${rapid_wind_time_epoch}000
weatherflow_rapid_wind,device_id=${rapid_wind_device_id},hub_sn=${rapid_wind_hub_sn},serial_number=${rapid_wind_serial_number},collector_type=${collector_type} wind_speed=${rapid_wind_wind_speed}
weatherflow_rapid_wind,device_id=${rapid_wind_device_id},hub_sn=${rapid_wind_hub_sn},serial_number=${rapid_wind_serial_number},collector_type=${collector_type} wind_direction=${rapid_wind_wind_direction}"

fi

#
# Lightning Strike Event
#

if [[ $line == *"evt_strike"* ]]; then

#
# Extract Metrics
#

evt_strike_device_id=$(echo "${line}" | jq -r .device_id)
evt_strike_hub_sn=$(echo "${line}" | jq -r .hub_sn)
evt_strike_serial_number=$(echo "${line}" | jq -r .serial_number)

evt_strike_time_epoch=$(echo "${line}" | jq ".evt[0]")
evt_strike_distance=$(echo "${line}" | jq ".evt[1]")
evt_strike_energy=$(echo "${line}" | jq ".evt[2]")

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "evt_strike,device_id ${evt_strike_device_id}"
echo "evt_strike,hub_sn ${evt_strike_hub_sn}"
echo "evt_strike,serial_number ${evt_strike_serial_number}"

echo "evt_strike,time_epoch ${evt_strike_time_epoch}"
echo "evt_strike,distance ${evt_strike_distance}"
echo "evt_strike,energy ${evt_strike_energy}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_strike,device_id=${evt_strike_device_id},hub_sn=${evt_strike_hub_sn},serial_number=${evt_strike_serial_number},collector_type=${collector_type} time_epoch=${evt_strike_time_epoch}000
weatherflow_evt_strike,device_id=${evt_strike_device_id},hub_sn=${evt_strike_hub_sn},serial_number=${evt_strike_serial_number},collector_type=${collector_type} distance=${evt_strike_distance}
weatherflow_evt_strike,device_id=${evt_strike_device_id},hub_sn=${evt_strike_hub_sn},serial_number=${evt_strike_serial_number},collector_type=${collector_type} energy=${evt_strike_energy}"

fi

#
# Rain Start Event
#

if [[ $line == *"evt_precip"* ]]; then

#
# Extract Metrics
#

evt_precip_device_id=$(echo "${line}" | jq -r .device_id)
evt_precip_hub_sn=$(echo "${line}" | jq -r .hub_sn)
evt_precip_serial_number=$(echo "${line}" | jq -r .serial_number)

if [ "$debug" == "true" ]
then

#
# Print Metrics
#

echo "evt_precip,device_id ${evt_precip_device_id}"
echo "evt_precip,hub_sn ${evt_precip_hub_sn}"
echo "evt_precip,serial_number ${evt_precip_serial_number}"

fi

#
# Send metrics to InfluxDB
#

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_precip,device_id=${evt_precip_device_id},hub_sn=${evt_precip_hub_sn},serial_number=${evt_precip_serial_number},collector_type=${collector_type}  time_epoch=${time_epoch}000"


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
