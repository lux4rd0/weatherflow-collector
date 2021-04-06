#!/bin/bash

# InfluxDB Endpoint

influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE
debug=$WEATHERFLOW_COLLECTOR_DEBUG

if [ "$debug" = "true" ]
then

echo ""
echo "Starting WeatherFlow Collector"
echo ""
echo "Debug Environmental Variables"
echo ""
echo "influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL"
echo "influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME"
echo "influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD"
echo "collector_type=$WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE"
echo ""

else

echo ""
echo "Starting WeatherFlow Collector"
echo ""

fi

# Curl Command

if [ "$debug" == "true" ]
then

curl=(  )

else

curl=( --silent --output /dev/null --show-error --fail )

fi

while read -r line; do

if [ "$debug" == "true" ]
then

# Print Line

echo ""
echo "${line}"
echo ""

fi

# Observation (Tempest)

if [[ $line == *"obs_st"* ]]; then

# Extract Metrics

obs_serial_number=$(echo "${line}" | jq -r .serial_number)
obs_hub_sn=$(echo "${line}" | jq -r .hub_sn)
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

if [ "$debug" == "true" ]
then

# Print Metrics

echo "obs,serial_number ${obs_serial_number}"
echo "obs,hub_sn ${obs_hub_sn}"
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

fi

# Send metrics to InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} firmware_revision=${obs_firmware_revision}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} wind_lull=${obs_wind_lull}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} wind_avg=${obs_wind_avg}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} wind_gust=${obs_wind_gust}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} wind_direction=${obs_wind_direction}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} wind_sample_interval=${obs_wind_sample_interval}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} station_pressure=${obs_station_pressure}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} air_temperature=${obs_air_temperature}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} relative_humidity=${obs_relative_humidity}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} illuminance=${obs_illuminance}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} uv=${obs_uv}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} solar_radiation=${obs_solar_radiation}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} precip_accumulated=${obs_precip_accumulated}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} precipitation_type=${obs_precipitation_type}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} lightning_strike_avg_distance=${obs_lightning_strike_avg_distance}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} lightning_strike_count=${obs_lightning_strike_count}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} battery=${obs_battery}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} report_interval=${obs_report_interval}"

fi

# Observation (Air)

if [[ $line == *"obs_air"* ]]; then

# Extract Metrics

obs_serial_number=$(echo "${line}" | jq -r .serial_number)
obs_hub_sn=$(echo "${line}" | jq -r .hub_sn)
obs_firmware_revision=$(echo "${line}" | jq -r .firmware_revision)

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

# Print Metrics

echo "obs,serial_number ${obs_serial_number}"
echo "obs,hub_sn ${obs_hub_sn}"
echo "obs,firmware_revision ${obs_firmware_revision}"

echo "obs,time_epoch ${obs_time_epoch}"
echo "obs,station_pressure ${obs_station_pressure}"
echo "obs,air_temperature ${obs_air_temperature}"
echo "obs,relative_humidity ${obs_relative_humidity}"
echo "obs,lightning_strike_count ${obs_lightning_strike_count}"
echo "obs,lightning_strike_avg_distance ${obs_lightning_strike_avg_distance}"
echo "obs,battery ${obs_battery}"
echo "obs,report_interval ${obs_report_interval}"

fi

# Send metrics to InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} firmware_revision=${obs_firmware_revision}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} time_epoch=${obs_time_epoch}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} station_pressure=${obs_station_pressure}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} air_temperature=${obs_air_temperature}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} relative_humidity=${obs_relative_humidity}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} lightning_strike_count=${obs_lightning_strike_count}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} lightning_strike_avg_distance=${obs_lightning_strike_avg_distance}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} battery=${obs_battery}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} report_interval=${obs_report_interval}"

fi

# Observation (Sky)

if [[ $line == *"obs_sky"* ]]; then

# Extract Metrics

obs_serial_number=$(echo "${line}" | jq -r .serial_number)
obs_hub_sn=$(echo "${line}" | jq -r .hub_sn)
obs_firmware_revision=$(echo "${line}" | jq -r .firmware_revision)

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

# Remove Null Entries from obs_precip_accumulated

if [ "$obs_precip_accumulated" = "null" ]
then
obs_precip_accumulated="0"
fi

if [ "$debug" == "true" ]
then

# Print Metrics

echo "obs,serial_number ${obs_serial_number}"
echo "obs,hub_sn ${obs_hub_sn}"
echo "obs,firmware_revision ${obs_firmware_revision}"

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

fi

# Send metrics to InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} firmware_revision=${obs_firmware_revision}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} time_epoch=${obs_time_epoch}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} illuminance=${obs_illuminance}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} uv=${obs_uv}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} precip_accumulated=${obs_precip_accumulated}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} wind_lull=${obs_wind_lull}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} wind_avg=${obs_wind_avg}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} wind_gust=${obs_wind_gust}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} wind_direction=${obs_wind_direction}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} battery=${obs_battery}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} report_interval=${obs_report_interval}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} solar_radiation=${obs_solar_radiation}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} precip_accumulated=${obs_precip_accumulated}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} precipitation_type=${obs_precipitation_type}
weatherflow_obs,serial_number=${obs_serial_number},hub_sn=${obs_hub_sn},collector_type=${collector_type} wind_sample_interval=${obs_wind_sample_interval}"

fi

# Rapid Wind

if [[ $line == *"rapid_wind"* ]]; then

# Extract Metrics

rapid_wind_serial_number=$(echo "${line}" | jq -r .serial_number)
rapid_wind_hub_sn=$(echo "${line}" | jq -r .hub_sn)

rapid_wind_time_epoch=$(echo "${line}" | jq ".ob[0]")
rapid_wind_wind_speed=$(echo "${line}" | jq ".ob[1]")
rapid_wind_wind_direction=$(echo "${line}" | jq ".ob[2]")

if [ "$debug" == "true" ]
then

# Print Metrics

echo "rapid_wind,serial_number ${rapid_wind_serial_number}"
echo "rapid_wind,hub_sn ${rapid_wind_hub_sn}"

echo "rapid_wind,time_epoch ${rapid_wind_time_epoch}"
echo "rapid_wind,wind_speed ${rapid_wind_wind_speed}"
echo "rapid_wind,wind_direction ${rapid_wind_wind_direction}"

fi

# Send metrics to InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_rapid_wind,serial_number=${rapid_wind_serial_number},hub_sn=${rapid_wind_hub_sn},collector_type=${collector_type} time_epoch=${rapid_wind_time_epoch}
weatherflow_rapid_wind,serial_number=${rapid_wind_serial_number},hub_sn=${rapid_wind_hub_sn},collector_type=${collector_type} wind_speed=${rapid_wind_wind_speed}
weatherflow_rapid_wind,serial_number=${rapid_wind_serial_number},hub_sn=${rapid_wind_hub_sn},collector_type=${collector_type} wind_direction=${rapid_wind_wind_direction}"

fi

# Lightning Strike Event

if [[ $line == *"evt_strike"* ]]; then

# Extract Metrics

evt_strike_serial_number=$(echo "${line}" | jq -r .serial_number)
evt_strike_hub_sn=$(echo "${line}" | jq -r .hub_sn)

evt_strike_time_epoch=$(echo "${line}" | jq ".evt[0]")
evt_strike_distance=$(echo "${line}" | jq ".evt[1]")
evt_strike_energy=$(echo "${line}" | jq ".evt[2]")

if [ "$debug" == "true" ]
then

# Print Metrics

echo "evt_strike,serial_number ${evt_strike_serial_number}"
echo "evt_strike,hub_sn ${evt_strike_hub_sn}"

echo "evt_strike,time_epoch ${evt_strike_time_epoch}"
echo "evt_strike,distance ${evt_strike_distance}"
echo "evt_strike,energy ${evt_strike_energy}"

fi

# Send metrics to InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_strike,serial_number=${evt_strike_serial_number},hub_sn=${evt_strike_hub_sn},collector_type=${collector_type} time_epoch=${evt_strike_time_epoch}
weatherflow_evt_strike,serial_number=${evt_strike_serial_number},hub_sn=${evt_strike_hub_sn},collector_type=${collector_type} distance=${evt_strike_distance}
weatherflow_evt_strike,serial_number=${evt_strike_serial_number},hub_sn=${evt_strike_hub_sn},collector_type=${collector_type} energy=${evt_strike_energy}"

fi

# Rain Start Event

if [[ $line == *"evt_precip"* ]]; then

# Extract Metrics

evt_precip_serial_number=$(echo "${line}" | jq -r .serial_number)
evt_precip_hub_sn=$(echo "${line}" | jq -r .hub_sn)

evt_precip_time_epoch=$(echo "${line}" | jq ".evt[0]")

if [ "$debug" == "true" ]
then

# Print Metrics

echo "evt_precip,serial_number ${evt_precip_serial_number}"
echo "evt_precip,hub_sn ${evt_precip_hub_sn}"

echo "evt_precip,time_epoch ${evt_precip_time_epoch}"

fi

# Send metrics to InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_evt_precip,serial_number=${evt_precip_serial_number},hub_sn=${evt_precip_hub_sn},collector_type=${collector_type} time_epoch=${evt_precip_time_epoch}"

fi

# Status (device)

if [[ $line == *"device_status"* ]]; then

# Extract Metrics

device_status_serial_number=$(echo "${line}" | jq -r .serial_number)
device_status_hub_sn=$(echo "${line}" | jq -r .hub_sn)
device_status_uptime=$(echo "${line}" | jq -r .uptime)
device_status_voltage=$(echo "${line}" | jq -r .voltage)
device_status_firmware_revision=$(echo "${line}" | jq -r .firmware_revision)
device_status_rssi=$(echo "${line}" | jq -r .rssi)
device_status_hub_rssi=$(echo "${line}" | jq -r .hub_rssi)
device_status_sensor_status=$(echo "${line}" | jq -r .sensor_status)

if [ "$debug" == "true" ]
then

# Print Metrics

echo "device_status,serial_number ${device_status_serial_number}"
echo "device_status,hub_sn ${device_status_hub_sn}"

echo "device_status,uptime ${device_status_uptime}"
echo "device_status,voltage ${device_status_voltage}"
echo "device_status,firmware_revision ${device_status_firmware_revision}"
echo "device_status,rssi ${device_status_rssi}"
echo "device_status,hub_rssi ${device_status_hub_rssi}"
echo "device_status,sensor_status ${device_status_sensor_status}"

fi

# Send metrics to InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_device_status,serial_number=${device_status_serial_number},hub_sn=${device_status_hub_sn},collector_type=${collector_type} uptime=${device_status_uptime}
weatherflow_device_status,serial_number=${device_status_serial_number},hub_sn=${device_status_hub_sn},collector_type=${collector_type} voltage=${device_status_voltage}
weatherflow_device_status,serial_number=${device_status_serial_number},hub_sn=${device_status_hub_sn},collector_type=${collector_type} firmware_revision=${device_status_firmware_revision}
weatherflow_device_status,serial_number=${device_status_serial_number},hub_sn=${device_status_hub_sn},collector_type=${collector_type} rssi=${device_status_rssi}
weatherflow_device_status,serial_number=${device_status_serial_number},hub_sn=${device_status_hub_sn},collector_type=${collector_type} hub_rssi=${device_status_hub_rssi}
weatherflow_device_status,serial_number=${device_status_serial_number},hub_sn=${device_status_hub_sn},collector_type=${collector_type} sensor_status=${device_status_sensor_status}"

fi

# Status (hub)

if [[ $line == *"hub_status"* ]]; then

# Extract Metrics

hub_status_hub_sn=$(echo "${line}" | jq -r .serial_number)
hub_status_uptime=$(echo "${line}" | jq -r .uptime)
hub_status_firmware_revision=$(echo "${line}" | jq -r .firmware_revision)
hub_status_rssi=$(echo "${line}" | jq -r .rssi)
hub_status_radio_stats_version=$(echo "${line}" | jq ".radio_stats[0]")
hub_status_radio_stats_reboot_count=$(echo "${line}" | jq ".radio_stats[1]")
hub_status_radio_stats_i2c_bus_error_count=$(echo "${line}" | jq ".radio_stats[2]")
hub_status_radio_stats_radio_status=$(echo "${line}" | jq ".radio_stats[3]")
hub_status_radio_stats_radio_network_id=$(echo "${line}" | jq ".radio_stats[4]")

if [ "$debug" == "true" ]
then

# Print Metrics

echo "hub_status,hub_sn ${hub_status_hub_sn}"
echo "hub_status,uptime ${hub_status_uptime}"
echo "hub_status,firmware_revision ${hub_status_firmware_revision}"
echo "hub_status,rssi ${hub_status_rssi}"
echo "hub_status,radio_stats_version ${hub_status_radio_stats_version}"
echo "hub_status,radio_stats_reboot_count ${hub_status_radio_stats_reboot_count}"
echo "hub_status,radio_stats_i2c_bus_error_count ${hub_status_radio_stats_i2c_bus_error_count}"
echo "hub_status,radio_stats_radio_status ${hub_status_radio_stats_radio_status}"
echo "hub_status,radio_stats_radio_network_id ${hub_status_radio_stats_radio_network_id}"

fi

# Send metrics to InfluxDB

curl "${curl[@]}" -i -XPOST "${influxdb_url}" -u "${influxdb_username}":"${influxdb_password}" --data-binary "
weatherflow_hub_status,hub_sn=${hub_status_hub_sn},collector_type=${collector_type} uptime=${hub_status_uptime}
weatherflow_hub_status,hub_sn=${hub_status_hub_sn},collector_type=${collector_type} firmware_revision=${hub_status_firmware_revision}
weatherflow_hub_status,hub_sn=${hub_status_hub_sn},collector_type=${collector_type} rssi=${hub_status_rssi}
weatherflow_hub_status,hub_sn=${hub_status_hub_sn},collector_type=${collector_type} radio_stats_version=${hub_status_radio_stats_version}
weatherflow_hub_status,hub_sn=${hub_status_hub_sn},collector_type=${collector_type} radio_stats_reboot_count=${hub_status_radio_stats_reboot_count}
weatherflow_hub_status,hub_sn=${hub_status_hub_sn},collector_type=${collector_type} radio_stats_i2c_bus_error_count=${hub_status_radio_stats_i2c_bus_error_count}
weatherflow_hub_status,hub_sn=${hub_status_hub_sn},collector_type=${collector_type} radio_stats_radio_status=${hub_status_radio_stats_radio_status}
weatherflow_hub_status,hub_sn=${hub_status_hub_sn},collector_type=${collector_type} radio_stats_radio_network_id=${hub_status_radio_stats_radio_network_id}"

fi

done < /dev/stdin
