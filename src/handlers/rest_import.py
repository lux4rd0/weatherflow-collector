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
- pytz: For time_zone calculations.
- calculate_weather_metrics: Custom module for computing additional weather metrics.

Classes:
- BaseDataHandler: An abstract class providing a blueprint for all data handlers.
- UDPDataHandler: Processes data from UDP broadcasts.
- WebSocketHandler: Handles WebSocket stream data.
- RESTObservationsStationHandler: Manages observational data from REST APIs.
- RESTForecastsHandler: Handles forecast data from REST APIs.
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


logger_RESTImportHandler = logger.get_module_logger(__name__ + ".RESTImportHandler")


class RESTImportHandler(BaseDataHandler):
    def __init__(self, event_manager):

        self.collector_type = "collector_import"  # Directly set the collector type
        self.event_manager = event_manager

        self.batch_size = config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_IMPORT_BATCH_SIZE

        self.field_mapping = {
            "timestamp": "timestamp",
            "report_interval": "report_interval",  # No direct equivalent, kept as is
            "wind_lull": "wind_lull",
            "wind_avg": "wind_avg",
            "wind_gust": "wind_gust",
            "wind_dir": "wind_direction",
            "station_pressure": "station_pressure",
            "sea_level_pressure": "sea_level_pressure",  # No direct equivalent, kept as is
            "air_temp": "air_temperature",
            "rh": "relative_humidity",
            "illuminance": "illuminance",
            "uv": "uv",
            "solar_radiation": "solar_radiation",
            "precip_accumulation": "rain_accumulated",
            "local_day_precip_accumulation": "local_daily_rain_accumulation",
            "precip_type": "precipitation_type",
            "strike_count": "lightning_strike_count",
            "strike_distance": "lightning_strike_avg_distance",
            "nc_precip_accumulation": "nc_precip_accumulation",  # No direct equivalent, kept as is
            "nc_local_day_precip_accumulation": "nc_local_day_precip_accumulation",  # No direct equivalent, kept as is
        }

    async def process_data(self, full_data):
        # Extracting metadata, station_info, and data from full_data
        metadata = full_data.get("metadata", {})
        station_info = full_data.get("station_info", {})
        station_id = metadata.get("station_id")
        data = full_data.get("data", {})

        # logger_RESTImportHandler.debug(f"Metadata: {metadata}")
        # logger_RESTImportHandler.debug(f"Data: {data}")

        batch = []
        for observation in data.get("obs", []):
            # Mapping fields and calculating additional metrics
            fields = {
                self.field_mapping.get(k, k): v
                for k, v in zip(data.get("ob_fields", []), observation)
            }
            fields = utils.normalize_fields(fields)

            elevation = station_info.get("elevation", None)
            weather_data = {
                "air_temperature": fields.get("air_temperature"),
                "relative_humidity": fields.get("relative_humidity"),
                "station_pressure": fields.get("station_pressure"),
                "wind_avg": fields.get("wind_avg"),
                "elevation": elevation,
            }
            additional_metrics = CalculateWeatherMetrics.calculate_weather_metrics(
                weather_data
            )
            fields.update(additional_metrics)

            tags = {
                "collector_type": self.collector_type,
                "station_id": metadata.get("station_id", "unknown"),
            }
            for key in [
                "station_name",
                "station_latitude",
                "station_longitude",
                "station_elevation",
                "station_time_zone",
            ]:
                if key in station_info and station_info[key] is not None:
                    tags[key] = station_info[key]

            timestamp = fields.get("timestamp", None)
            measurement = "weatherflow_obs"

            # Appending data to batch
            batch.append((measurement, tags, fields, timestamp))

            if len(batch) >= self.batch_size:
                await self.event_manager.publish(
                    "influxdb_storage_event",
                    {"data_type": "batch", "batch_data": batch},
                )
                batch = []

        if batch:
            await self.event_manager.publish(
                "influxdb_storage_event", {"data_type": "batch", "batch_data": batch}
            )

        logger_RESTImportHandler.debug("Data processed by RESTImportHandler")
