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
- RESTObservationsStationHandler: Manages observational data from REST APIs.
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


logger_RESTObservationsDeviceHandler = logger.get_module_logger(
    __name__ + ".RESTObservationsDeviceHandler"
)


class RESTObservationsDeviceHandler(BaseDataHandler):
    def __init__(self, event_manager):

        self.collector_type = "collector_rest"  # Directly set the collector type
        self.event_manager = event_manager

    @utils.calculate_timestamp_delta("process_data")
    async def process_data(self, full_data):
        logger_RESTObservationsDeviceHandler.debug(
            "Processing full_data in RESTObservationsDeviceHandler"
        )

        # Log the incoming full_data for debugging
        logger_RESTObservationsDeviceHandler.debug(f"Incoming full_data: {full_data}")

        # Extract and log the 'metadata', 'data', and 'station_info'
        metadata = full_data.get("metadata", {})
        data = full_data.get("data", {})
        station_info = full_data.get("station_info", {})
        device_info = full_data.get("device_info", {})

        source = data.get("source")

        summary = data.get("summary", {})

        obs_data = full_data.get("data", {}).get("obs", [[]])[0]

        logger_RESTObservationsDeviceHandler.debug(f"Extracted 'obs' data: {obs_data}")

        logger_RESTObservationsDeviceHandler.debug(f"Metadata: {metadata}")
        logger_RESTObservationsDeviceHandler.debug(f"Data: {data}")
        logger_RESTObservationsDeviceHandler.debug(f"Station info: {station_info}")
        logger_RESTObservationsDeviceHandler.debug(f"Device info: {device_info}")

        fields = {}
        if obs_data:
            # Map each element in obs_data to corresponding field
            fields = {
                field: obs_data[idx]
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
                if idx < len(obs_data)
            }
            logger_RESTObservationsDeviceHandler.debug(f"Mapped 'obs' fields: {fields}")
        else:
            # Log when obs_data is empty or not present
            logger_RESTObservationsDeviceHandler.debug(
                "No 'obs' data to map in full_data"
            )

        # Merge summary fields from the 'data' with fields
        summary = full_data.get("data", {}).get("summary", {})
        fields.update(summary)
        logger_RESTObservationsDeviceHandler.debug(f"Merged 'summary' fields: {fields}")

        # Normalize fields
        fields = utils.normalize_fields(fields)

        # Log the normalized fields for debugging
        logger_RESTObservationsDeviceHandler.debug(f"Normalized fields: {fields}")

        # Additional processing: pressure trend mapping, weather metrics, etc.
        trend_mapping = {"falling": -1, "steady": 0, "rising": 1}
        fields["pressure_trend"] = trend_mapping.get(
            fields.get("pressure_trend", "steady"), 0
        )

        # Extract weather data for additional calculations
        weather_data_keys = [
            "air_temperature",
            "relative_humidity",
            "station_pressure",
            "wind_avg",
        ]
        weather_data = {k: fields[k] for k in weather_data_keys if k in fields}
        weather_data["elevation"] = station_info.get("station_elevation", 0)

        additional_metrics = CalculateWeatherMetrics.calculate_weather_metrics(
            weather_data
        )
        fields.update(additional_metrics)

        # Create tags using 'metadata' and 'station_info'
        tags = {
            "collector_type": self.collector_type,
            "source": source,
            "station_id": metadata.get("station_id", "unknown"),
        }

        # Add station information as tags, if available
        for key in [
            "station_id",
            "station_name",
            "station_latitude",
            "station_longitude",
            "station_elevation",
            "station_time_zone",
        ]:
            if key in station_info and station_info[key] is not None:
                tags[key] = station_info[key]

        # Add device information as tags, if available
        for key in [
            "device_id",
            "device_name",
            "device_type",
            "serial_number",
        ]:
            if key in device_info and device_info[key] is not None:
                tags[key] = device_info[key]

        # Log the tags for debugging
        logger_RESTObservationsDeviceHandler.debug(f"Tags: {tags}")

        # Save transformed data to InfluxDB
        measurement = "weatherflow_obs"
        timestamp = fields.get("timestamp", None)

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
            "influxdb_storage_event", collector_data_with_meta
        )

        # Loop through tags and set them as attributes
        for key, value in tags.items():
            setattr(self, f"current_{key}", value)

        # Update the current state
        self.current_timestamp = timestamp

        logger_RESTObservationsDeviceHandler.debug(
            f"Published weatherflow_obs data to event manager"
        )
