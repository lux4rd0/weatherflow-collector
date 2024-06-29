# rest_forecasts.py

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


logger_RESTForecastsHandler = logger.get_module_logger(
    __name__ + ".RESTForecastsHandler"
)


class RESTForecastsHandler(BaseDataHandler):
    def __init__(self, event_manager):

        self.collector_type = "collector_forecast"  # Directly set the collector type
        self.event_manager = event_manager

    async def process_data(self, full_data):
        logger_RESTForecastsHandler.debug("Starting to process forecast data")

        if (
            full_data
            and "metadata" in full_data
            and "station_id" in full_data["metadata"]
        ):
            station_id = full_data["metadata"]["station_id"]

            # Process data with the extracted station_id
            await self.handle_current_conditions(full_data)
            await self.handle_forecast_daily(full_data)
            await self.handle_forecast_hourly(full_data)

            logger_RESTForecastsHandler.debug(
                f"Forecast data processed and saved for station {station_id}"
            )
        else:
            logger_RESTForecastsHandler.warning("No valid data received for processing")

    async def handle_current_conditions(self, full_data):
        metadata = full_data.get("metadata", {})
        station_id = metadata.get("station_id")
        station_info = full_data.get("station_info", {})
        data = full_data.get("data", {})

        if not station_id:
            logger_RESTForecastsHandler.warning("No station ID found in metadata")
            return

        current_conditions = data.get("current_conditions", {})

        # Rename the "time" field to "timestamp" if it exists
        if "time" in current_conditions:
            current_conditions["timestamp"] = current_conditions.pop("time")

        logger_RESTForecastsHandler.debug(f"current_conditions: {current_conditions}")

        fields = {field: value for field, value in current_conditions.items()}

        # Extract weather data for additional calculations
        weather_data_keys = [
            "air_temperature",
            "relative_humidity",
            "station_pressure",
            "wind_avg",
        ]
        weather_data = {k: fields.get(k) for k in weather_data_keys if k in fields}
        weather_data["elevation"] = station_info.get("station_elevation", 0)

        additional_metrics = CalculateWeatherMetrics.calculate_weather_metrics(
            weather_data
        )
        fields.update(additional_metrics)

        # Normalize the fields
        fields = utils.normalize_fields(fields)

        # Log the normalized fields for debugging
        logger_RESTForecastsHandler.debug(f"Normalized fields: {fields}")

        # Create tags using 'metadata' and 'station_info'
        tags = {
            "collector_type": self.collector_type,
            "station_id": station_id,
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

        # Log the tags for debugging
        logger_RESTForecastsHandler.debug(f"Tags: {tags}")

        # Save transformed data to InfluxDB
        measurement = "weatherflow_forecast_current"
        timestamp = fields.get("timestamp", None)

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

        logger_RESTForecastsHandler.debug(
            f"Published weatherflow_obs data to event manager"
        )

    async def handle_forecast_daily(self, full_data):
        metadata = full_data.get("metadata", {})
        station_id = metadata.get("station_id")
        station_info = full_data.get("station_info", {})
        data = full_data.get("data", {})

        if not station_id:
            logger_RESTForecastsHandler.warning("No station ID found in metadata")
            return

        daily_forecasts = data.get("forecast", {}).get("daily", [])
        data_batch = []  # List to accumulate data points for batch processing

        for index, daily in enumerate(daily_forecasts):
            fields = {
                "day_relative": index,
                "air_temp_high": daily.get("air_temp_high"),
                "air_temp_low": daily.get("air_temp_low"),
                "day_num": daily.get("day_num"),
                "day_start_local": daily.get("day_start_local"),
                "month_num": daily.get("month_num"),
                "precip_probability": daily.get("precip_probability"),
                "sunrise": daily.get("sunrise"),
                "sunset": daily.get("sunset"),
                "conditions": daily.get("conditions"),
                "icon": daily.get("icon"),
                "precip_icon": daily.get("precip_icon"),
                "precip_type": daily.get("precip_type"),
            }

            logger_RESTForecastsHandler.debug(f"fields: {fields}")

            # Create "day_end_local" and add 86399 seconds to "day_start_local"
            day_start_local = daily.get("day_start_local")
            day_end_local = (
                day_start_local + 86399 if day_start_local is not None else None
            )
            fields["day_end_local"] = day_end_local

            # Calculating additional metrics for high and low temperatures
            high_temp = fields.get("air_temp_high")
            low_temp = fields.get("air_temp_low")
            relative_humidity = (
                50  # Assuming average relative humidity for calculations
            )

            # Process for high and low temperatures
            for temp_type in ["high_temp", "low_temp"]:
                temperature = daily.get(f"air_temp_{temp_type}")
                if temperature is not None:
                    weather_data = {
                        "air_temperature": temperature,
                        "relative_humidity": relative_humidity,
                    }

                    additional_metrics = (
                        CalculateWeatherMetrics.calculate_weather_metrics(weather_data)
                    )
                    for key, value in additional_metrics.items():
                        fields[f"{key}_{temp_type}"] = value

            tags = {"collector_type": self.collector_type}
            for key in [
                "station_name",
                "station_latitude",
                "station_longitude",
                "station_elevation",
                "station_time_zone",
            ]:
                if key in station_info:
                    tags[key] = station_info[key]

            # Prepare data point for batch
            measurement = "weatherflow_forecast_daily"
            daily_data_point = (measurement, tags, fields, day_end_local)
            data_batch.append(daily_data_point)

            # If it's the first index, prepare data point for current forecast
            if index == 0:
                # For the current forecast, we let InfluxDB provide a current timestamp
                # by setting the previously used `day_end_local` to None.
                current_measurement = "weatherflow_forecast_current"
                current_data_point = (current_measurement, tags, fields, None)
                data_batch.append(current_data_point)

                logger_RESTForecastsHandler.debug(
                    f"Added daily forecast details to forecast_current: {current_data_point}"
                )

        # Send all accumulated data points in a single batch
        if data_batch:
            await self.event_manager.publish(
                "influxdb_storage_event",
                {"data_type": "batch", "batch_data": data_batch},
            )

            logger_RESTForecastsHandler.debug(
                "Published daily forecast batch data to event manager"
            )

    async def handle_forecast_hourly(self, full_data):
        metadata = full_data.get("metadata", {})
        station_id = metadata.get("station_id")
        station_info = full_data.get("station_info", {})
        data = full_data.get("data", {})

        if not station_id:
            logger_RESTForecastsHandler.warning("No station ID found in metadata")
            return

        elevation = station_info.get("elevation", None)
        station_time_zone = station_info.get("time_zone", "UTC")

        # Adjust current time to station's time zone
        tz = pytz.timezone(station_time_zone)
        current_time = datetime.now(tz)

        hourly_forecasts = data.get("forecast", {}).get("hourly", [])

        data_batch = []  # List to accumulate data points for batch processing

        for index, hourly in enumerate(hourly_forecasts):
            fields = {field: value for field, value in hourly.items()}

            # Convert sea level pressure to station pressure if elevation is available
            sea_level_pressure = hourly.get("sea_level_pressure")
            if sea_level_pressure is not None and elevation is not None:
                station_pressure = (
                    CalculateWeatherMetrics.calculate_station_pressure_from_sea_level(
                        float(sea_level_pressure), elevation
                    )
                )
                fields["calculated_station_pressure"] = station_pressure

            timestamp = hourly.get("time")

            # Calculate the "days out" for this forecast
            if timestamp is not None:
                forecast_time = datetime.fromtimestamp(timestamp, tz)
                days_out = (forecast_time - current_time).days
            else:
                days_out = None

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

            # Normalize the observation fields
            fields = utils.normalize_fields(fields)

            # Log the normalized fields for debugging
            logger_RESTForecastsHandler.debug(f"Normalized fields: {fields}")

            # Initial tags setup
            tags = {
                "collector_type": self.collector_type,
                "number_of_days_out": days_out,
                "local_day": int(fields.get("local_day", 0))
                if fields.get("local_day") is not None
                else 0,
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

            # Prepare data for batch
            measurement = "weatherflow_forecast_hourly"
            fields = utils.normalize_fields(fields)
            data_point = (measurement, tags, fields, timestamp)
            data_batch.append(data_point)

            if index == 0:
                current_measurement = "weatherflow_forecast_current"
                current_data_point = (current_measurement, tags, fields, timestamp)
                data_batch.append(current_data_point)

            if days_out != 0:
                tags_with_days_out_zero = tags.copy()
                tags_with_days_out_zero["number_of_days_out"] = 0
                zero_day_data_point = (
                    measurement,
                    tags_with_days_out_zero,
                    fields,
                    timestamp,
                )
                data_batch.append(zero_day_data_point)

        # Send all accumulated data points in a single batch
        if data_batch:
            batch_data = {"data_type": "batch", "batch_data": data_batch}
            await self.event_manager.publish("influxdb_storage_event", batch_data)
