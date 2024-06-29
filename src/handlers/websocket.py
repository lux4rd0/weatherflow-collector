# influxdb_handler.py

"""
WeatherFlow Collector Data Handlers

This module forms a part of the WeatherFlow Collector system, a robust application designed to 
gather, process, and store weather data from various sources. It caters to diverse data types 
and formats, making it an integral component of the WeatherFlow ecosystem.

Key Features:
- Multi-source data handling: Capable of processing data from UDP broadcasts, WebSocket 
  streams, and REST API responses.
- Data normalization: Transforms disparate data formats into a unified structure suitable for 
  storage and analysis.
- InfluxDB integration: Seamlessly stores processed data in InfluxDB, ensuring efficient 
  data management and retrieval.

Usage:
This module is used within the WeatherFlow Collector system and requires data inputs from 
UDP broadcasts, WebSocket connections, or RESTful APIs. It should be initialized with 
appropriate configurations for each data source and the InfluxDB instance.

Dependencies:
- influxdb_client: For interaction with InfluxDB.
- pytz: For time zone calculations.
- calculate_weather_metrics: Custom module for computing additional weather metrics.

Classes:
- BaseDataHandler: An abstract class providing a blueprint for all data handlers.
- UDPDataHandler: Processes data from UDP broadcasts.
- WebSocketHandler: Handles WebSocket stream data.
- RESTObservationsStationDataHandler: Manages observational data from REST APIs.
- RESTForecastsDataHandler: Handles forecast data from REST APIs.
- InfluxDBStorage: Interfaces with InfluxDB for data storage.

Methods:
Each class contains specific methods for processing its designated data type and communicating 
with the InfluxDB. Key methods include process_data(), handle_evt_strike(), handle_obs_st(), 
and save_data().

Author: [Your Name or Team's Name]
Last Update: [Last Update Date]

Note:
This module is part of the WeatherFlow Collector system and is not intended to be used as a 
standalone script. It requires a running instance of InfluxDB and access to WeatherFlow data 
streams.
"""

import config


from utils.calculate_weather_metrics import CalculateWeatherMetrics

# Import necessary libraries for InfluxDB communication and others

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
    def process_data(self, data):
        raise NotImplementedError("This method should be implemented by subclasses.")


logger_WebSocketHandler = logger.get_module_logger(__name__ + ".WebSocketHandler")


class WebSocketHandler(BaseDataHandler):
    def __init__(self, event_manager):

        self.collector_type = "collector_websocket"  # Directly set the collector type
        self.event_manager = event_manager

        # Define a dictionary mapping data types to handler functions
        self.data_handlers = {
            "evt_precip": self.handle_evt_precip,
            "evt_strike": self.handle_evt_strike,
            "rapid_wind": self.handle_rapid_wind,
            "obs_st": self.handle_obs_st,
            "obs_air": self.handle_obs_air,
            "obs_sky": self.handle_obs_sky,
            "geo_strike": self.handle_geo_strike,
            # Add other handlers as needed
        }

    async def process_data(self, full_data):
        logger_WebSocketHandler.debug(f"Processing WebSocket data: {full_data}")

        # Extract the nested 'data' dictionary
        data = full_data.get("data", {})

        # Extract the data type from the nested 'data'
        data_type = data.get("type")
        if data_type in self.data_handlers:
            # Pass the entire full_data structure to the handler
            handler = self.data_handlers[data_type]
            await handler(full_data)
        else:
            logger_WebSocketHandler.error(
                f"Unknown data type for WebSocket client: {data_type}"
            )

        logger_WebSocketHandler.debug("Data processed by WebSocketHandler")

    @utils.calculate_timestamp_delta("handle_evt_precip")
    async def handle_evt_precip(self, full_data):
        logger_WebSocketHandler.debug(f"Received evt_precip full data: {full_data}")

        # Extract the nested 'data' dictionary
        data = full_data.get("data", {})
        device_id = data.get("device_id")
        evt_data = data.get("evt", [])

        if len(evt_data) >= 1:
            timestamp = evt_data[0]  # The timestamp of the precipitation event

            fields = {
                "timestamp": timestamp,
                # Add other relevant fields as needed
            }

            # Extract station information
            station_info = full_data.get("station_info", {})
            logger_WebSocketHandler.debug(f"Station info: {station_info}")

            # Construct the tags
            tags = {
                "collector_type": self.collector_type,
                "station_name": station_info.get("station_name"),
                "station_latitude": station_info.get("station_latitude"),
                "station_longitude": station_info.get("station_longitude"),
                "station_elevation": station_info.get("station_elevation"),
                "station_time_zone": station_info.get("station_time_zone"),
            }

            # Extract device information
            device_info = full_data.get("device_info", {})
            logger_WebSocketHandler.debug(f"Device info: {device_info}")

            # Add device information as tags, if available
            for key in [
                "device_id",
                "device_name",
                "device_type",
                "serial_number",
            ]:
                if key in device_info and device_info[key] is not None:
                    tags[key] = device_info[key]

            logger_WebSocketHandler.debug(f"Tags: {tags}")

            fields = utils.normalize_fields(fields)

            measurement = "weatherflow_evt_precip"

            collector_data_with_meta = {
                "data_type": "single",  # or "batch" for batch processing
                "measurement": measurement,
                "tags": tags,
                "fields": fields,
                "timestamp": timestamp,
                # Include other necessary data or metadata
            }

            # Publish the data using the event manager
            await self.event_manager.publish(
                "influxdb_storage_event", collector_data_with_meta
            )

            logger_WebSocketHandler.debug(
                f"Published {measurement} data to event manager for device {device_id}."
            )

            # Setting attirbutes for the delta timestamp decorator

            # Loop through tags and set them as attributes
            for key, value in tags.items():
                setattr(self, f"current_{key}", value)

            # Update the current state
            self.current_timestamp = timestamp

        else:
            # Log a warning if the data is not in the expected format
            logger_WebSocketHandler.warning(
                f"Invalid evt_precip data format: {full_data}"
            )

    @utils.calculate_timestamp_delta("handle_evt_strike")
    async def handle_evt_strike(self, full_data):
        logger_WebSocketHandler.debug(f"Received evt_strike full data: {full_data}")

        # Extract the nested 'data' dictionary
        data = full_data.get("data", {})
        device_id = data.get("device_id")
        evt_data = data.get("evt", [])

        if len(evt_data) >= 3:
            timestamp, distance, energy = evt_data[:3]

            fields = {
                "timestamp": timestamp,
                "distance": distance,
                "energy": energy,
                # Add other relevant fields as needed
            }

            # Extract station information
            station_info = full_data.get("station_info", {})
            logger_WebSocketHandler.debug(f"Station info: {station_info}")

            # Construct the tags
            tags = {
                "collector_type": self.collector_type,
                "station_name": station_info.get("station_name"),
                "station_latitude": station_info.get("station_latitude"),
                "station_longitude": station_info.get("station_longitude"),
                "station_elevation": station_info.get("station_elevation"),
                "station_time_zone": station_info.get("station_time_zone"),
            }

            # Extract device information
            device_info = full_data.get("device_info", {})
            logger_WebSocketHandler.debug(f"Device info: {device_info}")

            # Add device information as tags, if available
            for key in [
                "device_id",
                "device_name",
                "device_type",
                "serial_number",
            ]:
                if key in device_info and device_info[key] is not None:
                    tags[key] = device_info[key]

            logger_WebSocketHandler.debug(f"Tags: {tags}")

            fields = utils.normalize_fields(fields)

            measurement = "weatherflow_evt_strike"

            collector_data_with_meta = {
                "data_type": "single",  # or "batch" for batch processing
                "measurement": measurement,
                "tags": tags,
                "fields": fields,
                "timestamp": timestamp,
                # Include other necessary data or metadata
            }

            # Publish the data using the event manager
            await self.event_manager.publish(
                "influxdb_storage_event", collector_data_with_meta
            )

            logger_WebSocketHandler.debug(
                f"Published {measurement} data to event manager for device {device_id}."
            )

            # Setting attirbutes for the delta timestamp decorator

            # Loop through tags and set them as attributes
            for key, value in tags.items():
                setattr(self, f"current_{key}", value)

            # Update the current state
            self.current_timestamp = timestamp

        else:
            # Log a warning if the data is not in the expected format
            logger_WebSocketHandler.warning(
                f"Invalid evt_strike data format: {full_data}"
            )

    @utils.calculate_timestamp_delta("handle_rapid_wind")
    async def handle_rapid_wind(self, full_data):
        logger_WebSocketHandler.debug(f"Received rapid_wind full data: {full_data}")

        # Extract the nested 'data' dictionary
        data = full_data.get("data", {})
        device_id = data.get("device_id")
        ob_data = data.get("ob", [])

        if len(ob_data) >= 3:
            timestamp, wind_speed, wind_direction = ob_data[:3]

            fields = {
                "timestamp": timestamp,
                "wind_speed": wind_speed,
                "wind_direction": wind_direction,
                # Add other relevant fields as needed
            }

            # Extract station information
            station_info = full_data.get("station_info", {})
            logger_WebSocketHandler.debug(f"Station info: {station_info}")

            # Construct the tags
            tags = {
                "collector_type": self.collector_type,
                "station_name": station_info.get("station_name"),
                "station_latitude": station_info.get("station_latitude"),
                "station_longitude": station_info.get("station_longitude"),
                "station_elevation": station_info.get("station_elevation"),
                "station_time_zone": station_info.get("station_time_zone"),
            }

            # Extract device information
            device_info = full_data.get("device_info", {})
            logger_WebSocketHandler.debug(f"Device info: {device_info}")

            # Add device information as tags, if available
            for key in [
                "device_id",
                "device_name",
                "device_type",
                "serial_number",
            ]:
                if key in device_info and device_info[key] is not None:
                    tags[key] = device_info[key]

            logger_WebSocketHandler.debug(f"Tags: {tags}")

            fields = utils.normalize_fields(fields)

            measurement = "weatherflow_rapid_wind"

            collector_data_with_meta = {
                "data_type": "single",  # or "batch" for batch processing
                "measurement": measurement,
                "tags": tags,
                "fields": fields,
                "timestamp": timestamp,
                # Include other necessary data or metadata
            }

            # Publish the data using the event manager
            await self.event_manager.publish(
                "influxdb_storage_event", collector_data_with_meta
            )

            logger_WebSocketHandler.debug(
                f"Published {measurement} data to event manager for device {device_id}."
            )

            # Setting attirbutes for the delta timestamp decorator

            # Loop through tags and set them as attributes
            for key, value in tags.items():
                setattr(self, f"current_{key}", value)

            # Update the current state
            self.current_timestamp = timestamp

        else:
            # Log a warning if the data is not in the expected format
            logger_WebSocketHandler.warning(
                f"Invalid rapid_wind data format: {full_data}"
            )

    @utils.calculate_timestamp_delta("handle_obs_st")
    async def handle_obs_st(self, full_data):
        logger_WebSocketHandler.debug("Handling obs_st full data")

        # Extract the nested 'data' dictionary
        data = full_data.get("data", {})
        device_id = data.get("device_id")
        if not device_id:
            logger_WebSocketHandler.warning("Device ID missing in handle_obs_st data")
            return

        obs_data = data.get("obs", [])
        if obs_data:
            obs = obs_data[0]
            # Map fields directly without checking each index
            fields = {
                field: obs[idx] if field != "timestamp" else obs[idx]
                for idx, field in enumerate(
                    [
                        "timestamp",
                        "wind_lull",
                        "wind_avg",
                        "wind_gust",
                        "wind_direction",
                        "wind_sample_interval",
                        "station_pressure",
                        "air_temperature",
                        "relative_humidity",
                        "illuminance",
                        "uv",
                        "solar_radiation",
                        "rain_accumulated",
                        "precipitation_type",
                        "lightning_strike_avg_distance",
                        "lightning_strike_count",
                        "battery",
                        "report_interval",
                        "local_daily_rain_accumulation",
                        "rain_accumulated_final",
                        "local_daily_rain_accumulation_final",
                        "precipitation_analysis_type",
                    ]
                )
                if idx < len(obs)
            }

            # Normalize the fields
            fields = utils.normalize_fields(fields)

            # Process summary and trend data
            summary = data.get("summary", {})
            trend_mapping = {"falling": -1, "steady": 0, "rising": 1, "unknown": None}
            fields["pressure_trend"] = trend_mapping.get(
                summary.get("pressure_trend"), None
            )
            for key in summary:
                if key != "pressure_trend" and key != "raining_minutes":
                    fields[key] = summary[key]

            # Extract elevation and calculate additional metrics
            elevation = full_data.get("station_info", {}).get("station_elevation")
            weather_data = {
                key: fields[key]
                for key in [
                    "air_temperature",
                    "relative_humidity",
                    "station_pressure",
                    "wind_avg",
                ]
                if key in fields
            }
            weather_data["elevation"] = elevation
            additional_metrics = CalculateWeatherMetrics.calculate_weather_metrics(
                weather_data
            )
            fields.update(additional_metrics)

            # Extract station information
            station_info = full_data.get("station_info", {})
            logger_WebSocketHandler.debug(f"Station info: {station_info}")

            # Construct the tags
            tags = {
                "collector_type": self.collector_type,
                "source": data.get("source"),
                "type": data.get("type"),
                "station_name": station_info.get("station_name"),
                "station_latitude": station_info.get("station_latitude"),
                "station_longitude": station_info.get("station_longitude"),
                "station_elevation": station_info.get("station_elevation"),
                "station_time_zone": station_info.get("station_time_zone"),
            }

            # Extract device information
            device_info = full_data.get("device_info", {})
            logger_WebSocketHandler.debug(f"Device info: {device_info}")

            # Add device information as tags, if available
            for key in [
                "device_id",
                "device_name",
                "device_type",
                "serial_number",
            ]:
                if key in device_info and device_info[key] is not None:
                    tags[key] = device_info[key]

            logger_WebSocketHandler.debug(f"Tags: {tags}")

            measurement = "weatherflow_obs"

            collector_data_with_meta = {
                "data_type": "single",  # or "batch" for batch processing
                "measurement": measurement,
                "tags": tags,
                "fields": fields,
                "timestamp": fields["timestamp"],
                # Include other necessary data or metadata
            }

            # Publish the data using the event manager
            await self.event_manager.publish(
                "influxdb_storage_event", collector_data_with_meta
            )

            logger_WebSocketHandler.debug(
                f"Published {measurement} data to event manager for device {device_id}."
            )

            # Setting attirbutes for the delta timestamp decorator

            # Loop through tags and set them as attributes
            for key, value in tags.items():
                setattr(self, f"current_{key}", value)

            # Update the current state
            self.current_timestamp = fields["timestamp"]

        else:
            logger_WebSocketHandler.warning(
                "Invalid or incomplete obs_st data received"
            )

    @utils.calculate_timestamp_delta("handle_obs_air")
    async def handle_obs_air(self, full_data):
        logger_WebSocketHandler.debug("Handling obs_air full data")

        # Extract the nested 'data' dictionary
        data = full_data.get("data", {})
        device_id = data.get("device_id")
        if not device_id:
            logger_WebSocketHandler.warning("Device ID missing in obs_air data")
            return

        obs_data = data.get("obs", [])
        if obs_data:
            obs = obs_data[0]

            # Map fields directly without checking each index
            fields = {
                field: obs[idx] if field != "timestamp" else obs[idx]
                for idx, field in enumerate(
                    [
                        "timestamp",
                        "station_pressure",
                        "air_temperature",
                        "relative_humidity",
                        "lightning_strike_count",
                        "lightning_strike_avg_distance",
                        "battery",
                        "report_interval",
                    ]
                )
                if idx < len(obs)
            }

            # Normalize the fields
            fields = utils.normalize_fields(fields)

            # Extract elevation and other metrics from the full data
            elevation = full_data.get("station_info", {}).get("station_elevation")
            weather_data = {
                "air_temperature": fields.get("air_temperature"),
                "relative_humidity": fields.get("relative_humidity"),
                "station_pressure": fields.get("station_pressure"),
                "elevation": elevation,
            }

            # Calculate additional weather metrics
            additional_metrics = CalculateWeatherMetrics.calculate_weather_metrics(
                weather_data
            )
            fields.update(additional_metrics)

            # Extract station information
            station_info = full_data.get("station_info", {})
            logger_WebSocketHandler.debug(f"Station info: {station_info}")

            # Construct the tags
            tags = {
                "collector_type": self.collector_type,
                "source": data.get("source"),
                "type": data.get("type"),
                "station_name": station_info.get("station_name"),
                "station_latitude": station_info.get("station_latitude"),
                "station_longitude": station_info.get("station_longitude"),
                "station_elevation": station_info.get("station_elevation"),
                "station_time_zone": station_info.get("station_time_zone"),
            }

            # Extract device information
            device_info = full_data.get("device_info", {})
            logger_WebSocketHandler.debug(f"Device info: {device_info}")

            # Add device information as tags, if available
            for key in [
                "device_id",
                "device_name",
                "device_type",
                "serial_number",
            ]:
                if key in device_info and device_info[key] is not None:
                    tags[key] = device_info[key]

            logger_WebSocketHandler.debug(f"Tags: {tags}")

            measurement = "weatherflow_obs"

            collector_data_with_meta = {
                "data_type": "single",  # or "batch" for batch processing
                "measurement": measurement,
                "tags": tags,
                "fields": fields,
                "timestamp": fields["timestamp"],
                # Include other necessary data or metadata
            }

            # Publish the data using the event manager
            await self.event_manager.publish(
                "influxdb_storage_event", collector_data_with_meta
            )

            # Setting attirbutes for the delta timestamp decorator

            # Loop through tags and set them as attributes
            for key, value in tags.items():
                setattr(self, f"current_{key}", value)

            # Update the current state
            self.current_timestamp = fields["timestamp"]

            logger_WebSocketHandler.debug(
                f"Published {measurement} data to event manager for device {device_id}."
            )

        else:
            logger_WebSocketHandler.warning(
                "Invalid or incomplete obs_air data received"
            )

    @utils.calculate_timestamp_delta("handle_obs_sky")
    async def handle_obs_sky(self, full_data):
        logger_WebSocketHandler.debug("Handling obs_sky full data")

        # Extract the nested 'data' dictionary
        data = full_data.get("data", {})
        device_id = data.get("device_id")
        if not device_id:
            logger_WebSocketHandler.warning("Device ID missing in obs_sky data")
            return

        obs_data = data.get("obs", [])
        if obs_data and len(obs_data) > 0:
            obs = obs_data[0]

            # Map fields directly without checking each index
            fields = {
                field: obs[idx] if field != "timestamp" else obs[idx]
                for idx, field in enumerate(
                    [
                        "timestamp",
                        "illuminance",
                        "uv",
                        "rain_accumulated",
                        "wind_lull",
                        "wind_avg",
                        "wind_gust",
                        "wind_direction",
                        "battery",
                        "report_interval",
                        "solar_radiation",
                        "local_daily_rain_accumulation",
                        "precipitation_type",
                        "wind_sample_interval",
                        "rain_accumulated_final",
                        "local_daily_rain_accumulation_final",
                        "precipitation_analysis_type",
                    ]
                )
                if idx < len(obs)
            }

            # Normalize the fields
            fields = utils.normalize_fields(fields)

            # Extract station information
            station_info = full_data.get("station_info", {})
            logger_WebSocketHandler.debug(f"Station info: {station_info}")

            # Construct the tags
            tags = {
                "collector_type": self.collector_type,
                "source": data.get("source"),
                "type": data.get("type"),
                "station_name": station_info.get("station_name"),
                "station_latitude": station_info.get("station_latitude"),
                "station_longitude": station_info.get("station_longitude"),
                "station_elevation": station_info.get("station_elevation"),
                "station_time_zone": station_info.get("station_time_zone"),
            }

            # Extract device information
            device_info = full_data.get("device_info", {})
            logger_WebSocketHandler.debug(f"Device info: {device_info}")

            # Add device information as tags, if available
            for key in [
                "device_id",
                "device_name",
                "device_type",
                "serial_number",
            ]:
                if key in device_info and device_info[key] is not None:
                    tags[key] = device_info[key]

            logger_WebSocketHandler.debug(f"Tags: {tags}")

            measurement = "weatherflow_obs"

            collector_data_with_meta = {
                "data_type": "single",  # or "batch" for batch processing
                "measurement": measurement,
                "tags": tags,
                "fields": fields,
                "timestamp": fields["timestamp"],
                # Include other necessary data or metadata
            }

            # Publish the data using the event manager
            await self.event_manager.publish(
                "influxdb_storage_event", collector_data_with_meta
            )

            logger_WebSocketHandler.debug(
                f"Published {measurement} data to event manager for device {device_id}."
            )

            # Setting attirbutes for the delta timestamp decorator

            # Loop through tags and set them as attributes
            for key, value in tags.items():
                setattr(self, f"current_{key}", value)

            # Update the current state
            self.current_timestamp = fields["timestamp"]

        else:
            logger_WebSocketHandler.warning(
                "Invalid or incomplete obs_sky data received"
            )

    @utils.calculate_timestamp_delta("handle_geo_strike")
    async def handle_geo_strike(self, full_data):
        logger_WebSocketHandler.debug("Handling geo_strike full data")

        # Extract the nested 'data' dictionary
        data = full_data.get("data", {})
        device_id = data.get("device_id")
        if not device_id:
            logger_WebSocketHandler.warning("Device ID missing in geo_strike data")
            return

        # Extract and process data
        time = data.get("time")
        lat = data.get("lat")
        lon = data.get("lon")
        mag = data.get("mag")
        strike_type = data.get("strike_type")

        fields = {
            "time": time,
            "latitude": lat,
            "longitude": lon,
            "magnitude": mag,
            "strike_type": strike_type,
            # Add other relevant fields as needed
        }

        # Extract station information
        station_info = full_data.get("station_info", {})
        logger_WebSocketHandler.debug(f"Station info: {station_info}")

        # Construct the tags
        tags = {
            "collector_type": self.collector_type,
            "station_name": station_info.get("station_name"),
            "station_latitude": station_info.get("station_latitude"),
            "station_longitude": station_info.get("station_longitude"),
            "station_elevation": station_info.get("station_elevation"),
            "station_time_zone": station_info.get("station_time_zone"),
        }

        # Extract device information
        device_info = full_data.get("device_info", {})
        logger_WebSocketHandler.debug(f"Device info: {device_info}")

        # Add device information as tags, if available
        for key in [
            "device_id",
            "device_name",
            "device_type",
            "serial_number",
        ]:
            if key in device_info and device_info[key] is not None:
                tags[key] = device_info[key]

        logger_WebSocketHandler.debug(f"Tags: {tags}")

        fields = utils.normalize_fields(fields)

        measurement = "weatherflow_geo_strike"

        collector_data_with_meta = {
            "data_type": "single",  # or "batch" for batch processing
            "measurement": measurement,
            "tags": tags,
            "fields": fields,
            "timestamp": fields["timestamp"],
            # Include other necessary data or metadata
        }

        # Publish the data using the event manager
        await self.event_manager.publish(
            "influxdb_storage_event", collector_data_with_meta
        )

        # Setting attirbutes for the delta timestamp decorator

        # Loop through tags and set them as attributes
        for key, value in tags.items():
            setattr(self, f"current_{key}", value)

        # Update the current state
        self.current_timestamp = fields["timestamp"]

        logger_WebSocketHandler.debug(
            f"Published {measurement} data to event manager for device {device_id}."
        )
