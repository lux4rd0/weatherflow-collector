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
    def process_data(self):
        raise NotImplementedError("This method should be implemented by subclasses.")


logger_RESTObservationsStationHandler = logger.get_module_logger(
    __name__ + ".RESTObservationsStationHandler"
)


class RESTObservationsStationHandler(BaseDataHandler):
    def __init__(self, event_manager):

        self.collector_type = "collector_rest"  # Directly set the collector type
        self.event_manager = event_manager

    @utils.calculate_timestamp_delta("process_data")
    async def process_data(self, full_data):
        logger_RESTObservationsStationHandler.debug(
            "Processing full_data in RESTObservationsStationHandler"
        )

        # Log the incoming full_data for debugging
        logger_RESTObservationsStationHandler.debug(f"Incoming full_data: {full_data}")

        # Extract and log the 'metadata', 'data', and 'station_info'
        metadata = full_data.get("metadata", {})
        data = full_data.get("data", {})
        station_info = full_data.get("station_info", {})
        station_id = metadata.get("station_id")

        logger_RESTObservationsStationHandler.debug(f"Metadata: {metadata}")
        logger_RESTObservationsStationHandler.debug(f"Data: {data}")
        logger_RESTObservationsStationHandler.debug(f"Station info: {station_info}")

        # Normalize the observation fields
        fields = utils.normalize_fields(data)

        # Log the normalized fields for debugging
        logger_RESTObservationsStationHandler.debug(f"Normalized fields: {fields}")

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
            "station_id": metadata.get("station_id", "unknown"),
        }

        # Add station information as tags, if available
        for key in [
            "station_name",
            "station_latitude",
            "station_longitude",
            "station_elevation",
            "station_time_zone",
        ]:
            if key in station_info and station_info[key] is not None:
                tags[key] = station_info[key]

        # Log the tags for debugging
        logger_RESTObservationsStationHandler.debug(f"Tags: {tags}")

        # Save transformed data to InfluxDB
        measurement = "weatherflow_obs"
        timestamp = fields.get("timestamp", None)

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
            "influxdb_storage_event", collector_data_with_meta
        )

        # Loop through tags and set them as attributes
        for key, value in tags.items():
            setattr(self, f"current_{key}", value)

        # Update the current state
        self.current_timestamp = timestamp

        logger_RESTObservationsStationHandler.debug(
            f"Published weatherflow_obs data to event manager for device {station_id}"
        )
