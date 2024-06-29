# udp.py


import config


from utils.calculate_weather_metrics import CalculateWeatherMetrics


import time
import pytz
from datetime import datetime, timedelta
import json
import inspect
import os
import asyncio
import traceback

import multiprocessing

# from concurrent.futures import ThreadPoolExecutor

from concurrent.futures import ProcessPoolExecutor


import logger
import utils.utils as utils

logger_BaseDataHandler = logger.get_module_logger(__name__ + ".BaseDataHandler")


class BaseDataHandler:
    def process_data(self):
        raise NotImplementedError("This method should be implemented by subclasses.")


logger_UDPHandler = logger.get_module_logger(__name__ + ".UDPHandler")


class UDPHandler(BaseDataHandler):
    def __init__(self, event_manager):

        self.collector_type = "collector_udp"
        self.event_manager = event_manager

        # Define a dictionary mapping data types to handler functions
        self.data_handlers = {
            "device_status": self.handle_device_status,
            "evt_strike": self.handle_evt_strike,
            "hub_status": self.handle_hub_status,
            "obs_air": self.handle_obs_air,
            "obs_sky": self.handle_obs_sky,
            "obs_st": self.handle_obs_st,
            "rapid_wind": self.handle_rapid_wind,
        }

    async def process_data(self, full_data):
        logger_UDPHandler.debug("Processing data in UDPHandler")

        # Extract the data type from the nested 'data'
        data_type = full_data.get("data", {}).get("type")

        if data_type in self.data_handlers:
            handler = self.data_handlers[data_type]
            await handler(full_data)  # Pass the entire full_data structure
        else:
            logger_UDPHandler.error(f"Unknown data type: {data_type}")

        logger_UDPHandler.debug("Data processed by UDPHandler")

    # @utils.measure_execution_time("handle_rapid_wind")
    @utils.calculate_timestamp_delta("handle_rapid_wind")
    async def handle_rapid_wind(self, full_data):
        logger_UDPHandler.debug(f"rapid_wind data: {full_data}")

        logger_UDPHandler.debug(f"event_manager ID: {id(self.event_manager)}")

        # Extract serial number and observation data
        serial_number = full_data.get("data", {}).get("serial_number")
        rapid_wind_data = full_data.get("data", {}).get("ob", [])

        if len(rapid_wind_data) == 3:
            timestamp, wind_speed, wind_direction = rapid_wind_data

            obs_fields = {
                "timestamp": timestamp,
                "wind_speed": wind_speed,
                "wind_direction": wind_direction,
            }

            # Extract station information
            station_info = full_data.get("station_info", {})
            logger_UDPHandler.debug(f"Station info: {station_info}")

            # Extract device information
            device_info = full_data.get("device_info", {})
            logger_UDPHandler.debug(f"Device info: {device_info}")

            # Construct the tags
            tags = {
                "collector_type": self.collector_type,
                "station_name": station_info.get("station_name"),
                "station_latitude": station_info.get("station_latitude"),
                "station_longitude": station_info.get("station_longitude"),
                "station_elevation": station_info.get("station_elevation"),
                "station_time_zone": station_info.get("station_time_zone"),
                "device_id": device_info.get("device_id"),
            }

            # Add device information as tags, if available
            for key in [
                "device_id",
                "device_name",
                "device_type",
                "serial_number",
            ]:
                if key in device_info and device_info[key] is not None:
                    tags[key] = device_info[key]

            logger_UDPHandler.debug(f"Tags: {tags}")

            obs_fields = utils.normalize_fields(obs_fields)

            collector_data_with_meta = {
                "data_type": "single",  # or "batch" for batch processing
                "measurement": "weatherflow_rapid_wind",
                "tags": tags,
                "fields": obs_fields,
                "timestamp": timestamp,
                # Include other necessary data or metadata
            }

            # Publish the data using the event manager
            await self.event_manager.publish(
                "influxdb_storage_event",
                collector_data_with_meta,
                publisher="UDPHandler.handle_rapid_wind",
            )

            logger_UDPHandler.debug(
                f"Published rapid_wind data to event manager for device {serial_number}"
            )

            logger_UDPHandler.debug(
                f"collector_data_with_meta: {collector_data_with_meta}"
            )

            # Setting attirbutes for the delta timestamp decorator

            # Loop through tags and set them as attributes
            for key, value in tags.items():
                setattr(self, f"current_{key}", value)

            # Update the current state
            self.current_timestamp = timestamp

        else:
            logger_UDPHandler.warning(
                f"Invalid or incomplete rapid_wind data received: {full_data}"
            )

    # @utils.measure_execution_time("handle_evt_strike")
    @utils.calculate_timestamp_delta("handle_evt_strike")
    async def handle_evt_strike(self, full_data):
        logger_UDPHandler.debug(f"evt_strike data: {full_data}")

        # Extract serial number and event data
        serial_number = full_data.get("data", {}).get("serial_number")
        evt_data = full_data.get("data", {}).get("evt", [])

        if len(evt_data) == 3:
            timestamp, distance, energy = evt_data

            evt_fields = {
                "timestamp": timestamp,
                "distance": distance,
                "energy": energy,
            }

            # Extract station information
            station_info = full_data.get("station_info", {})
            logger_UDPHandler.debug(f"Station info: {station_info}")

            # Extract device information
            device_info = full_data.get("device_info", {})
            logger_UDPHandler.debug(f"Device info: {device_info}")

            # Construct the tags
            tags = {
                "collector_type": self.collector_type,
                "station_name": station_info.get("station_name"),
                "station_latitude": station_info.get("station_latitude"),
                "station_longitude": station_info.get("station_longitude"),
                "station_elevation": station_info.get("station_elevation"),
                "station_time_zone": station_info.get("station_time_zone"),
                "device_id": device_info.get("device_id"),
            }

            # Add device information as tags, if available
            for key in [
                "device_id",
                "device_name",
                "device_type",
                "serial_number",
            ]:
                if key in device_info and device_info[key] is not None:
                    tags[key] = device_info[key]

            logger_UDPHandler.debug(f"Tags: {tags}")

            evt_fields = utils.normalize_fields(evt_fields)

            collector_data_with_meta = {
                "data_type": "single",  # or "batch" for batch processing
                "measurement": "weatherflow_evt_strike",
                "tags": tags,
                "fields": evt_fields,
                "timestamp": timestamp,
                # Include other necessary data or metadata
            }

            # Publish the data using the event manager
            await self.event_manager.publish(
                "influxdb_storage_event",
                collector_data_with_meta,
                publisher="UDPHandler.handle_evt_strike",
            )

            logger_UDPHandler.debug(
                f"Published rapid_wind data to event manager for device {serial_number}"
            )

            # Setting attirbutes for the delta timestamp decorator

            # Loop through tags and set them as attributes
            for key, value in tags.items():
                setattr(self, f"current_{key}", value)

            # Update the current state
            self.current_timestamp = timestamp

        else:
            logger_UDPHandler.warning(
                f"Invalid or incomplete evt_strike data received: {full_data}"
            )

    # @utils.measure_execution_time("handle_device_status")
    @utils.calculate_timestamp_delta("handle_device_status")
    async def handle_device_status(self, full_data):
        logger_UDPHandler.debug(f"device_status data: {full_data}")

        # Extract device status data and serial numbers
        device_data = full_data.get("data", {})
        serial_number = device_data.get("serial_number")
        hub_sn = device_data.get("hub_sn")
        identifier = serial_number if serial_number else hub_sn

        self.current_serial_number = identifier  # Set as an instance attribute

        # Extract timestamp and other device status fields
        timestamp = device_data.get("timestamp", 0)
        fields = {
            "timestamp": timestamp,
            "uptime": device_data.get("uptime", 0),
            "voltage": device_data.get("voltage", 0),
            "firmware_revision": device_data.get("firmware_revision", 0),
            "rssi": device_data.get("rssi", 0),
            "hub_rssi": device_data.get("hub_rssi", 0),
            "sensor_status": device_data.get("sensor_status", 0),
            "debug": device_data.get("debug", 0),
        }

        # Extract station information
        station_info = full_data.get("station_info", {})
        logger_UDPHandler.debug(f"Station info: {station_info}")

        # Extract device information
        device_info = full_data.get("device_info", {})
        logger_UDPHandler.debug(f"Device info: {device_info}")

        # Construct the tags
        tags = {
            "collector_type": self.collector_type,
            "station_name": station_info.get("station_name"),
            "station_latitude": station_info.get("station_latitude"),
            "station_longitude": station_info.get("station_longitude"),
            "station_elevation": station_info.get("station_elevation"),
            "station_time_zone": station_info.get("station_time_zone"),
            "device_id": device_info.get("device_id"),
        }

        # Add device information as tags, if available
        for key in [
            "device_id",
            "device_name",
            "device_type",
            "serial_number",
        ]:
            if key in device_info and device_info[key] is not None:
                tags[key] = device_info[key]

        logger_UDPHandler.debug(f"Tags: {tags}")

        fields = utils.normalize_fields(fields)

        collector_data_with_meta = {
            "data_type": "single",  # or "batch" for batch processing
            "measurement": "weatherflow_device_status",
            "tags": tags,
            "fields": fields,
            "timestamp": timestamp,
            # Include other necessary data or metadata
        }

        # Publish the data using the event manager
        await self.event_manager.publish(
            "influxdb_storage_event",
            collector_data_with_meta,
            publisher="UDPHandler.handle_device_status",
        )

        logger_UDPHandler.debug(
            f"Published weatherflow_device_status data to event manager for device {serial_number}"
        )

        # Setting attirbutes for the delta timestamp decorator

        # Loop through tags and set them as attributes
        for key, value in tags.items():
            setattr(self, f"current_{key}", value)

        # Update the current state
        self.current_timestamp = timestamp

    # @utils.measure_execution_time("handle_hub_status")
    @utils.calculate_timestamp_delta("handle_hub_status")
    async def handle_hub_status(self, data):
        logger_UDPHandler.debug(f"Hub status data: {data}")

        # Extract hub status data and serial number
        hub_status_data = data.get("data", {})
        hub_sn = hub_status_data.get("serial_number")

        timestamp = hub_status_data.get("timestamp", 0)

        fields = {
            "timestamp": timestamp,
            "firmware_revision": hub_status_data.get("firmware_revision", 0),
            "uptime": hub_status_data.get("uptime", 0),
            "rssi": hub_status_data.get("rssi", 0),
            "seq": hub_status_data.get("seq", 0),
            # Process reset_flags, radio_stats, mqtt_stats, and other fields here
        }

        # Process reset_flags
        reset_flags = hub_status_data.get("reset_flags", "")
        if isinstance(reset_flags, str):
            reset_flags = reset_flags.split(",")
            for flag in reset_flags:
                fields[f"reset_flag_{flag}"] = True

        # Process radio_stats
        radio_stats = hub_status_data.get("radio_stats", [])
        if len(radio_stats) >= 5:
            fields.update(
                {
                    "radio_stats_version": radio_stats[0],
                    "radio_stats_reboot_count": radio_stats[1],
                    "radio_stats_i2c_bus_error_count": radio_stats[2],
                    "radio_stats_status": radio_stats[3],
                    "radio_stats_network_id": radio_stats[4],
                }
            )

        # Process mqtt_stats
        mqtt_stats = hub_status_data.get("mqtt_stats", [])
        if len(mqtt_stats) >= 2:
            fields.update(
                {
                    "mqtt_stats_0": mqtt_stats[0],
                    "mqtt_stats_1": mqtt_stats[1],
                }
            )

        # Extract station information
        station_info = data.get("station_info", {})
        logger_UDPHandler.debug(f"Station info: {station_info}")

        tags = {
            "collector_type": self.collector_type,
            "station_name": station_info.get("station_name"),
            "station_latitude": station_info.get("station_latitude"),
            "station_longitude": station_info.get("station_longitude"),
            "station_elevation": station_info.get("station_elevation"),
            "station_time_zone": station_info.get("station_time_zone"),
            "hub_sn": hub_sn,
        }

        logger_UDPHandler.debug(f"Tags: {tags}")

        fields = utils.normalize_fields(fields)

        collector_data_with_meta = {
            "data_type": "single",  # or "batch" for batch processing
            "measurement": "weatherflow_hub_status",
            "tags": tags,
            "fields": fields,
            "timestamp": timestamp,
            # Include other necessary data or metadata
        }

        # Publish the data using the event manager
        await self.event_manager.publish(
            "influxdb_storage_event",
            collector_data_with_meta,
            publisher="UDPHandler.handle_hub_status",
        )

        logger_UDPHandler.debug(
            f"Published weatherflow_hub_status data to event manager for device {hub_sn}"
        )

        # Setting attirbutes for the delta timestamp decorator

        # Loop through tags and set them as attributes
        for key, value in tags.items():
            setattr(self, f"current_{key}", value)

        # Update the current state
        self.current_timestamp = timestamp

    # @utils.measure_execution_time("handle_obs_st")
    @utils.calculate_timestamp_delta("handle_obs_st")
    async def handle_obs_st(self, full_data):
        # Extract the nested 'data' dictionary
        data = full_data.get("data", {})

        # Extract serial number and hub serial number
        serial_number = data.get("serial_number")
        hub_sn = data.get("hub_sn")
        identifier = serial_number if serial_number else hub_sn

        self.current_serial_number = identifier  # Set as an instance attribute

        # Check if observation data is present
        if "obs" in data and len(data["obs"]) > 0:
            obs_data = data["obs"][0]

            # Map fields according to their positions in obs_data
            field_mapping = {
                "timestamp": 0,
                "wind_lull": 1,
                "wind_avg": 2,
                "wind_gust": 3,
                "wind_direction": 4,
                "wind_sample_interval": 5,
                "station_pressure": 6,
                "air_temperature": 7,
                "relative_humidity": 8,
                "illuminance": 9,
                "uv": 10,
                "solar_radiation": 11,
                "rain_accumulated": 12,
                "precipitation_type": 13,
                "lightning_strike_avg_distance": 14,
                "lightning_strike_count": 15,
                "battery": 16,
                "report_interval": 17,
            }

            fields = {
                field_name: obs_data[position]
                for field_name, position in field_mapping.items()
                if position < len(obs_data)
            }

            timestamp = fields.get("timestamp", None)

            # Extract weather data for additional calculations
            weather_data_keys = [
                "air_temperature",
                "relative_humidity",
                "station_pressure",
                "wind_avg",
            ]
            weather_data = {k: fields[k] for k in weather_data_keys if k in fields}
            weather_data["elevation"] = data.get("station_elevation")

            # Calculate additional weather metrics
            additional_metrics = CalculateWeatherMetrics.calculate_weather_metrics(
                weather_data
            )
            fields.update(additional_metrics)

            # Extract station information
            station_info = full_data.get("station_info", {})
            logger_UDPHandler.debug(f"Station info: {station_info}")

            # Extract device information
            device_info = full_data.get("device_info", {})
            logger_UDPHandler.debug(f"Device info: {device_info}")

            # Construct tags with station information
            tags = {
                "collector_type": self.collector_type,
                "station_name": station_info.get("station_name"),
                "station_latitude": station_info.get("station_latitude"),
                "station_longitude": station_info.get("station_longitude"),
                "station_elevation": station_info.get("station_elevation"),
                "station_time_zone": station_info.get("station_time_zone"),
                "device_id": device_info.get("device_id"),
                "hub_sn": hub_sn,
            }

            # Add device information as tags, if available
            for key in [
                "device_id",
                "device_name",
                "device_type",
                "serial_number",
            ]:
                if key in device_info and device_info[key] is not None:
                    tags[key] = device_info[key]

            logger_UDPHandler.debug(f"Tags: {tags}")

            # Normalize the fields
            fields = utils.normalize_fields(fields)

            collector_data_with_meta = {
                "data_type": "single",  # or "batch" for batch processing
                "measurement": "weatherflow_obs",
                "tags": tags,
                "fields": fields,
                "timestamp": timestamp,
                # Include other necessary data or metadata
            }

            # Publish the data using the event manager
            await self.event_manager.publish(
                "influxdb_storage_event",
                collector_data_with_meta,
                publisher="UDPHandler.handle_obs_st",
            )

            logger_UDPHandler.debug(
                f"Published weatherflow_obs data to event manager for device {serial_number}"
            )

            # Setting attirbutes for the delta timestamp decorator

            # Loop through tags and set them as attributes
            for key, value in tags.items():
                setattr(self, f"current_{key}", value)

            # Update the current state
            self.current_timestamp = timestamp

        else:
            logger_UDPHandler.warning(
                f"Invalid or incomplete obs_st data received: {full_data}"
            )

    # @utils.measure_execution_time("handle_obs_air")
    @utils.calculate_timestamp_delta("handle_obs_air")
    async def handle_obs_air(self, full_data):
        # Extract the nested 'data' dictionary
        data = full_data.get("data", {})

        # Extract serial number and hub serial number
        serial_number = data.get("serial_number")
        hub_sn = data.get("hub_sn")
        identifier = serial_number if serial_number else hub_sn

        self.current_serial_number = identifier  # Set as an instance attribute

        # Check if observation data is present
        if "obs" in data and len(data["obs"]) == 1:
            obs_air_data = data["obs"][0]

            # Map fields according to their positions in obs_air_data
            field_mapping = {
                "timestamp": 0,
                "station_pressure": 1,
                "air_temperature": 2,
                "relative_humidity": 3,
                "lightning_strike_count": 4,
                "lightning_strike_avg_distance": 5,
                "battery": 6,
                "report_interval": 7,
            }

            fields = {
                field_name: obs_air_data[position]
                for field_name, position in field_mapping.items()
                if position < len(obs_air_data)
            }

            timestamp = fields.get("timestamp", None)

            # Extract weather data for additional calculations
            weather_data_keys = [
                "air_temperature",
                "relative_humidity",
                "station_pressure",
            ]
            weather_data = {k: fields[k] for k in weather_data_keys if k in fields}
            weather_data["elevation"] = data.get("station_elevation")

            # Calculate additional weather metrics
            additional_metrics = CalculateWeatherMetrics.calculate_weather_metrics(
                weather_data
            )
            fields.update(additional_metrics)

            # Extract station information
            station_info = full_data.get("station_info", {})
            logger_UDPHandler.debug(f"Station info: {station_info}")

            # Extract device information
            device_info = full_data.get("device_info", {})
            logger_UDPHandler.debug(f"Device info: {device_info}")

            # Construct tags with station information
            tags = {
                "collector_type": self.collector_type,
                "station_name": station_info.get("station_name"),
                "station_latitude": station_info.get("station_latitude"),
                "station_longitude": station_info.get("station_longitude"),
                "station_elevation": station_info.get("station_elevation"),
                "station_time_zone": station_info.get("station_time_zone"),
                "device_id": device_info.get("device_id"),
                "hub_sn": hub_sn,
            }

            # Add device information as tags, if available
            for key in [
                "device_id",
                "device_name",
                "device_type",
                "serial_number",
            ]:
                if key in device_info and device_info[key] is not None:
                    tags[key] = device_info[key]

            logger_UDPHandler.debug(f"Tags: {tags}")

            # Normalize the fields
            fields = utils.normalize_fields(fields)

            collector_data_with_meta = {
                "data_type": "single",  # or "batch" for batch processing
                "measurement": "weatherflow_obs_air",
                "tags": tags,
                "fields": fields,
                "timestamp": timestamp,
                # Include other necessary data or metadata
            }

            # Publish the data using the event manager
            await self.event_manager.publish(
                "influxdb_storage_event",
                collector_data_with_meta,
                publisher="UDPHandler.handle_obs_air",
            )

            logger_UDPHandler.debug(
                f"Published weatherflow_obs_air data to event manager for device {serial_number}"
            )

            # Setting attirbutes for the delta timestamp decorator

            # Loop through tags and set them as attributes
            for key, value in tags.items():
                setattr(self, f"current_{key}", value)

            # Update the current state
            self.current_timestamp = timestamp

        else:
            logger_UDPHandler.warning(
                f"Invalid or incomplete obs_air data received: {full_data}"
            )

    # @utils.measure_execution_time("handle_obs_sky")
    @utils.calculate_timestamp_delta("handle_obs_sky")
    async def handle_obs_sky(self, full_data):
        # Extract the nested 'data' dictionary
        data = full_data.get("data", {})

        # Extract serial number and hub serial number
        serial_number = data.get("serial_number")
        hub_sn = data.get("hub_sn")
        identifier = serial_number if serial_number else hub_sn

        self.current_serial_number = identifier  # Set as an instance attribute

        # Check if observation data is present
        if "obs" in data and len(data["obs"]) == 1:
            obs_sky_data = data["obs"][0]

            # Map fields according to their positions in obs_sky_data
            field_mapping = {
                "timestamp": 0,
                "illuminance": 1,
                "uv": 2,
                "rain_amount": 3,
                "wind_lull": 4,
                "wind_avg": 5,
                "wind_gust": 6,
                "wind_direction": 7,
                "battery": 8,
                "report_interval": 9,
                "solar_radiation": 10,
                "local_day_rain_accumulation": 11,
                "precipitation_type": 12,
                "wind_sample_interval": 13,
            }

            fields = {
                field_name: obs_sky_data[position]
                if position < len(obs_sky_data) and obs_sky_data[position] is not None
                else None
                for field_name, position in field_mapping.items()
            }

            timestamp = fields.get("timestamp", None)

            # Extract station information
            station_info = full_data.get("station_info", {})
            logger_UDPHandler.debug(f"Station info: {station_info}")

            # Extract device information
            device_info = full_data.get("device_info", {})
            logger_UDPHandler.debug(f"Device info: {device_info}")

            # Construct tags with station information
            tags = {
                "collector_type": self.collector_type,
                "station_name": station_info.get("station_name"),
                "station_latitude": station_info.get("station_latitude"),
                "station_longitude": station_info.get("station_longitude"),
                "station_elevation": station_info.get("station_elevation"),
                "station_time_zone": station_info.get("station_time_zone"),
                "device_id": device_info.get("device_id"),
                "hub_sn": hub_sn,
            }

            # Add device information as tags, if available
            for key in [
                "device_id",
                "device_name",
                "device_type",
                "serial_number",
            ]:
                if key in device_info and device_info[key] is not None:
                    tags[key] = device_info[key]

            logger_UDPHandler.debug(f"Tags: {tags}")

            # Normalize the fields
            fields = utils.normalize_fields(fields)

            collector_data_with_meta = {
                "data_type": "single",  # or "batch" for batch processing
                "measurement": "weatherflow_obs_sky",
                "tags": tags,
                "fields": fields,
                "timestamp": timestamp,
                # Include other necessary data or metadata
            }

            # Publish the data using the event manager
            await self.event_manager.publish(
                "influxdb_storage_event",
                collector_data_with_meta,
                publisher="UDPHandler.handle_obs_sky",
            )

            logger_UDPHandler.debug(
                f"Published weatherflow_obs_sky data to event manager for device {serial_number}"
            )

            # Setting attirbutes for the delta timestamp decorator

            # Loop through tags and set them as attributes
            for key, value in tags.items():
                setattr(self, f"current_{key}", value)

            # Update the current state
            self.current_timestamp = timestamp

        else:
            logger_UDPHandler.warning(
                f"Invalid or incomplete obs_sky data received: {full_data}"
            )
