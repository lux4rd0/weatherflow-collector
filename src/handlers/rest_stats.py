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


import time
from pytz import timezone
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


logger_RESTStatsHandler = logger.get_module_logger(__name__ + ".RESTStatsHandler")


class RESTStatsHandler:
    FIELD_MAPPING = {
        "pressure": 1,
        "pressure_high": 2,
        "pressure_low": 3,
        "temperature": 4,
        "temperature_high": 5,
        "temperature_low": 6,
        "humidity": 7,
        "humidity_high": 8,
        "humidity_low": 9,
        "lux": 10,
        "lux_high": 11,
        "lux_low": 12,
        "uv": 13,
        "uv_high": 14,
        "uv_low": 15,
        "solar_radiation": 16,
        "solar_radiation_high": 17,
        "solar_radiation_low": 18,
        "wind_average": 19,
        "wind_gust": 20,
        "wind_lull": 21,
        "wind_direction": 22,
        "wind_interval": 23,
        "strike_count": 24,
        "strike_average_distance": 25,
        "record_count": 26,
        "battery": 27,
        "local_precipitation_accumulation_today": 28,
        "local_precipitation_accumulation_final": 29,
        "local_precipitation_minutes_today": 30,
        "local_precipitation_minutes_final": 31,
        "precipitation_type": 32,
        "precipitation_analysis_type": 33,
    }

    def __init__(self, event_manager):

        self.collector_type = "collector_stats"  # Directly set the collector type
        self.event_manager = event_manager

    async def process_data(self, full_data):
        metadata = full_data.get("metadata", {})
        station_info = full_data.get("station_info", {})
        data = full_data.get("data", {})

        if not metadata.get("station_id"):
            logger_RESTStatsHandler.warning("No station ID found in metadata")
            return

        batch_data = []
        for category in ["stats_day", "stats_week", "stats_month", "stats_year"]:
            category_data = data.get(category, [])
            processed_category_data = await self.process_category(
                category_data, category, metadata, station_info
            )
            for data_point in processed_category_data:
                # Convert dictionary data_point to tuple format
                measurement = data_point["measurement"]
                tags = data_point["tags"]
                fields = data_point["fields"]
                timestamp = data_point["time"]

                # Log the type of data_point components
                logger_RESTStatsHandler.debug(
                    f"Measurement: {measurement}, Tags: {tags}, Fields: {fields}, Timestamp: {timestamp}"
                )

                # Append tuple to batch_data
                batch_data.append((measurement, tags, fields, timestamp))

        # Publish all accumulated data points in a single batch
        if batch_data:
            await self.event_manager.publish(
                "influxdb_storage_event",
                {"data_type": "batch", "batch_data": batch_data},
            )
            logger_RESTStatsHandler.debug("Published stats batch data to event manager")

    async def process_category(
        self, category_data, category_name, metadata, station_info
    ):
        processed_data = []

        # Mapping for category names
        category_name_mapping = {
            "stats_day": "Daily",
            "stats_week": "Weekly",
            "stats_month": "Monthly",
            "stats_year": "Yearly",
            "stats_alltime": "Overall",
        }

        station_time_zone = station_info.get(
            "time_zone", "UTC"
        )  # Default to UTC if not provided
        tz = timezone(station_time_zone)

        for entry in category_data:
            if len(entry) == 0:
                continue

            date_str = entry[0]
            date = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=tz)

            # Adjust the timestamp to the last minute of the period, respecting the timezone
            if category_name == "stats_day":
                timestamp = datetime(
                    date.year, date.month, date.day, 23, 59, 59, tzinfo=tz
                )
            elif category_name == "stats_year":
                timestamp = datetime(date.year, 12, 31, 23, 59, 59, tzinfo=tz)
            # Add other conditions as needed
            else:
                timestamp = date  # Use the provided date

            # Convert timestamp to UTC if necessary
            timestamp_utc = timestamp.astimezone(pytz.utc)

            epoch_timestamp = int(timestamp_utc.timestamp())

            # Mapping data to fields
            fields = {}
            for field_name, index in self.FIELD_MAPPING.items():
                if index < len(entry):
                    value = entry[index]
                    if value is not None:
                        fields[field_name] = value
                    else:
                        if (
                            not config.WEATHERFLOW_COLLECTOR_HANDLER_REST_STATS_SUPPRESS_WARNINGS_ENABLED
                        ):
                            logger_RESTStatsHandler.warning(
                                f"Field '{field_name}' is None in {category_name} for station {metadata.get('station_id')}"
                            )
                else:
                    if (
                        not config.WEATHERFLOW_COLLECTOR_HANDLER_REST_STATS_SUPPRESS_WARNINGS_ENABLED
                    ):
                        logger_RESTStatsHandler.warning(
                            f"Index {index} out of range for field '{field_name}' in {category_name} for station {metadata.get('station_id')}"
                        )

            elevation = station_info.get("elevation", None)

            # Calculating additional metrics
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
            fields = utils.normalize_fields(fields)

            spelled_out_category = category_name_mapping.get(category_name, "Unknown")

            # Initial tags setup
            tags = {
                "collector_type": self.collector_type,
                "station_id": metadata.get("station_id", "unknown"),
                "time_period": spelled_out_category,  # Adding the time period as a tag
            }

            # Add additional tags from station_info
            for key in [
                "station_name",
                "station_latitude",
                "station_longitude",
                "station_elevation",
                "station_time_zone",
            ]:
                if key in station_info and station_info[key] is not None:
                    tags[key] = station_info[key]

            # Prepare data point for InfluxDB
            data_point = {
                "measurement": "weatherflow_stats",
                "tags": tags,
                "fields": fields,
                "time": epoch_timestamp,
            }

            processed_data.append(data_point)

        return processed_data
