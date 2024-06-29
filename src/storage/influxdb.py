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
- WSDataHandler: Handles WebSocket stream data.
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

from influxdb_client import InfluxDBClient, Point, WriteOptions, DeleteService
from influxdb_client.client.influxdb_client_async import InfluxDBClientAsync


# from influxdb_client.client.write_api import ASYNCHRONOUS


# Import necessary libraries for InfluxDB communication and others

import time
import pytz
from datetime import datetime, timedelta
import json
import inspect
import os
import asyncio
import traceback


import logger
import utils.utils as utils


logger_InfluxDBStorage = logger.get_module_logger(__name__ + ".InfluxDBStorage")


class InfluxDBStorage:
    def __init__(self, event_manager, url, token, org, bucket):

        self.event_manager = event_manager

        # Configure write options using values from config.py
        write_options = WriteOptions(
            batch_size=config.WEATHERFLOW_COLLECTOR_STORAGE_INFLUXDB_BATCH_SIZE,
            flush_interval=config.WEATHERFLOW_COLLECTOR_STORAGE_INFLUXDB_FLUSH_INTERVAL,
            jitter_interval=config.WEATHERFLOW_COLLECTOR_STORAGE_INFLUXDB_JITTER_INTERVAL,
            retry_interval=config.WEATHERFLOW_COLLECTOR_STORAGE_INFLUXDB_RETRY_INTERVAL,
            max_retry_time=config.WEATHERFLOW_COLLECTOR_STORAGE_INFLUXDB_MAX_RETRY_TIME,
            max_retries=config.WEATHERFLOW_COLLECTOR_STORAGE_INFLUXDB_MAX_RETRIES,
            max_retry_delay=config.WEATHERFLOW_COLLECTOR_STORAGE_INFLUXDB_MAX_RETRY_DELAY,
            max_close_wait=config.WEATHERFLOW_COLLECTOR_STORAGE_INFLUXDB_MAX_CLOSE_WAIT,
        )

        self.client = InfluxDBClientAsync(
            url=url, token=token, org=org, enable_gzip=True
        )

        # self.write_api = self.write_api(write_options)

        self.write_api = self.client.write_api()
        self.bucket = bucket

        # Debug data dictionary

        self.last_dump_time = time.time()
        self.data_structure = {}  # Data structure for relationships and callers

        self.metrics_by_client_type = {}

        self.module_name = "influxdb_handler"
        self.collector_type = "influxdb_handler"

        self.tasks_by_client_type = {}  # Dictionary to store tasks by collector type

        self.tasks = []

    async def save_batch_data(self, batch):
        """
        Saves a batch of data points to InfluxDB in chunks based on a specified batch size.

        Parameters:
        - batch (list): A list of tuples, each containing:
            - measurement (str)
            - tags (dict)
            - fields (dict)
            - timestamp (int/float/str) (optional)
        """
        logger_InfluxDBStorage.debug(
            f"Received a batch of {len(batch)} data points to save to InfluxDB."
        )

        batch_size = config.WEATHERFLOW_COLLECTOR_STORAGE_INFLUXDB_BATCH_SIZE
        for i in range(0, len(batch), batch_size):
            chunk = batch[i : i + batch_size]
            await self.write_chunk_to_influxdb(chunk)

    async def write_chunk_to_influxdb(self, chunk):
        """
        Writes a chunk of data points to InfluxDB, including a secondary data point
        for primary sources.

        Parameters:
        - chunk (list): A list of tuples, each containing:
            - measurement (str)
            - tags (dict)
            - fields (dict)
            - timestamp (int/float/str) (optional)
        """
        start_time = time.time()
        points = []

        try:
            for measurement, tags, fields, timestamp in chunk:
                # Check if tags and fields are in the correct format
                if not isinstance(tags, dict) or not isinstance(fields, dict):
                    logger_InfluxDBStorage.error(
                        f"Invalid data format. Measurement: {measurement}, Tags: {tags}, Fields: {fields}, Timestamp: {timestamp}"
                    )
                    continue  # Skip this iteration

                # Normalize fields before writing to the database
                fields = utils.normalize_fields(fields)

                # If timestamp is not provided, use current time
                if timestamp is None:
                    timestamp = int(time.time())

                # Sort tags for consistency
                sorted_tags = dict(sorted(tags.items()))

                # Create the primary data point
                point = Point(measurement)
                for tag, value in sorted_tags.items():
                    point.tag(tag, value)
                for field, value in fields.items():
                    point.field(field, value)
                point.time(timestamp, write_precision="s")

                # Add the primary data point to the points list
                points.append(point)

                # Check for primary data source and create a secondary point if necessary
                if (
                    sorted_tags.get("collector_type")
                    == config.WEATHERFLOW_COLLECTOR_PRIMARY_SOURCE
                ):
                    # Modify the collector_type for the secondary data point
                    tags_copy = dict(sorted_tags)
                    tags_copy["collector_type"] = "primary"

                    # Create the secondary data point
                    secondary_point = Point(measurement)
                    for tag, value in tags_copy.items():
                        secondary_point.tag(tag, value)
                    for field, value in fields.items():
                        secondary_point.field(field, value)
                    secondary_point.time(timestamp, write_precision="s")

                    # Add the secondary data point to the points list
                    points.append(secondary_point)

            # Write all points in the chunk to InfluxDB
            if points:
                await asyncio.wait_for(
                    self.write_api.write(
                        bucket=self.bucket, record=points, write_precision="s"
                    ),
                    timeout=30,  # Specify timeout duration in seconds
                )

            end_time = time.time()
            logger_InfluxDBStorage.debug(
                f"Chunk of {len(chunk)} data points successfully written to InfluxDB in {end_time - start_time:.2f} seconds"
            )

        except Exception as e:
            tb = traceback.format_exc()
            logger_InfluxDBStorage.error(
                f"Error writing chunk to InfluxDB: {e}\nTraceback:\n{tb}"
            )

    async def save_data(self, measurement, tags, fields, timestamp=None):
        # Perform data structure tracking only if enabled in config
        if config.WEATHERFLOW_COLLECTOR_ENABLE_INFLUXDB_DATA_STRUCTURE_TRACKING:
            current_time = time.time()
            # Check if 2 minutes have passed since the last dump
            if (
                current_time - self.last_dump_time
                > config.WEATHERFLOW_COLLECTOR_ENABLE_INFLUXDB_DATA_STRUCTURE_TRACKING_EXPORT_INTERVAL
            ):
                self.dump_data_structure()
                self.last_dump_time = current_time  # Reset the last dump time

            caller_info = self.get_caller_info()

            # Update the data structure with new data, types, and caller
            if measurement not in self.data_structure:
                self.data_structure[measurement] = {
                    "tags": {},
                    "fields": {},
                    "callers": set(),
                }
            self.data_structure[measurement]["callers"].add(caller_info)

            for tag, value in tags.items():
                if tag not in self.data_structure[measurement]["tags"]:
                    self.data_structure[measurement]["tags"][tag] = {
                        "type": type(value).__name__,
                        "callers": set(),
                    }
                self.data_structure[measurement]["tags"][tag]["callers"].add(
                    caller_info
                )

            for field, value in fields.items():
                if field not in self.data_structure[measurement]["fields"]:
                    self.data_structure[measurement]["fields"][field] = {
                        "type": type(value).__name__,
                        "callers": set(),
                    }
                self.data_structure[measurement]["fields"][field]["callers"].add(
                    caller_info
                )

        try:
            logger_InfluxDBStorage.debug(
                f"Received data for measurement '{measurement}':"
            )
            logger_InfluxDBStorage.debug(f"Tags: {tags}")
            logger_InfluxDBStorage.debug(f"Fields: {fields}")

            # Normalize fields before writing to the database
            fields = utils.normalize_fields(fields)
            # logger_InfluxDBStorage.debug(f"Normalized Fields: {fields}")

            if timestamp is None:
                timestamp = int(time.time())  # Current time in epoch seconds
                logger_InfluxDBStorage.debug(
                    "Timestamp not provided, using current time"
                )

            # Sort tags for consistency
            sorted_tags = dict(sorted(tags.items()))

            # Creating the primary data point
            point = Point(measurement)
            for tag, value in sorted_tags.items():
                point.tag(tag, value)
            for field, value in fields.items():
                point.field(field, value)
            point.time(timestamp, write_precision="s")

            await self.write_api.write(
                bucket=self.bucket, record=point, write_precision="s"
            )
            logger_InfluxDBStorage.debug("Data point written to InfluxDB")

            # Check for primary data source and send a second copy if matched
            primary_source_flag = config.WEATHERFLOW_COLLECTOR_PRIMARY_SOURCE
            if sorted_tags.get("collector_type") == primary_source_flag:
                logger_InfluxDBStorage.debug(
                    f"Collector type matches primary source ({primary_source_flag}), creating secondary data point."
                )

                # Create a copy of tags and modify the collector_type for the secondary data point
                tags_copy = dict(sorted_tags)
                tags_copy["collector_type"] = "primary"

                # Create and write the secondary data point
                secondary_point = Point(measurement)
                for tag, value in tags_copy.items():
                    secondary_point.tag(tag, value)
                for field, value in fields.items():
                    secondary_point.field(field, value)
                secondary_point.time(timestamp, write_precision="s")

                await self.write_api.write(
                    bucket=self.bucket, record=secondary_point, write_precision="s"
                )
                logger_InfluxDBStorage.debug(
                    "Secondary data point for primary source written to InfluxDB"
                )

        except Exception as e:
            tb = traceback.format_exc()  # This gets the full traceback
            logger_InfluxDBStorage.error(
                f"Error writing to InfluxDB: {e}\nTraceback:\n{tb}"
            )

    async def handle_delete(self, delete_instructions):
        # Extract delete instructions
        measurement = delete_instructions.get("measurement", "default_measurement")
        start_time = delete_instructions.get("start_time")
        end_time = delete_instructions.get("end_time")
        tags = delete_instructions.get("tags", {})

        # Construct the predicate for deletion
        tag_conditions = [f'{key}="{value}"' for key, value in tags.items()]
        tag_predicate = " AND ".join(tag_conditions)
        predicate = f'_measurement="{measurement}"'
        if tag_predicate:
            predicate += f" AND {tag_predicate}"

        # Perform deletion using the existing InfluxDB client
        # delete_api = self.client.delete_api()
        # await delete_api.delete(start_time, end_time, predicate, self.bucket)

        # Log the deletion
        # logger_InfluxDBStorage.debug(f"Deleted data from {measurement} for the period {start_time} to {end_time} with tags {tags}")

    def close(self):
        self.client.close()

    def get_caller_info(self):
        # Get the stack frame of the caller
        stack = inspect.stack()
        # Look for the caller's frame, skipping frames in this file
        for frame_info in stack[2:]:
            if frame_info.filename != __file__:
                # If the caller is a method of a class, get the class name
                if "self" in frame_info.frame.f_locals:
                    caller_class = frame_info.frame.f_locals["self"].__class__.__name__
                    return f"{caller_class}.{frame_info.function}"
                else:
                    return frame_info.function
        return "Unknown"

    async def update(self, data):
        request_processing_start = time.time()

        # Extract metadata and collector type
        metadata = data.get("metadata", {})
        collector_type = metadata.get("collector_type")
        metric_name = f"update_{collector_type}"

        logger_InfluxDBStorage.debug(
            f"Received data for collector type: {collector_type}"
        )

        tasks = []

        # Check for delete instructions
        if "delete_instructions" in data:
            logger_InfluxDBStorage.debug("Received delete_instructions")
            delete_instructions = data["delete_instructions"]
            tasks.append(self.handle_delete(delete_instructions))

        # Determine the data type and process accordingly
        data_type = data.get("data_type", "single")
        if data_type == "batch":
            tasks.append(self.save_batch_data(data.get("batch_data", [])))
        else:
            measurement = data.get("measurement")
            tags = data.get("tags", {})
            fields = data.get("fields", {})
            timestamp = data.get("timestamp")
            tasks.append(self.save_data(measurement, tags, fields, timestamp))

        # Debug: Log the number of tasks about to be run concurrently
        logger_InfluxDBStorage.debug(f"Running {len(tasks)} tasks concurrently.")

        # Run all tasks concurrently
        await asyncio.gather(*tasks)

        # Metrics and task management
        if collector_type not in self.metrics_by_client_type:
            self.metrics_by_client_type[collector_type] = {
                "request_count": 0,
                "error_count": 0,
                "active_tasks": 0,
            }
        self.metrics_by_client_type[collector_type]["request_count"] += 1

        processing_duration = time.time() - request_processing_start
        logger_InfluxDBStorage.debug(
            f"Publishing metrics for {collector_type}: "
            f"message_count={self.metrics_by_client_type[collector_type]['request_count']}, "
            f"errors={self.metrics_by_client_type[collector_type]['error_count']}, "
            f"duration={processing_duration}"
        )
        await utils.async_publish_metrics(
            self.event_manager,
            metric_name=metric_name,
            module_name=self.module_name,
            rate=self.metrics_by_client_type[collector_type]["request_count"],
            errors=self.metrics_by_client_type[collector_type]["error_count"],
            duration=processing_duration,
        )

    def task_done_callback(self, task):
        collector_type = getattr(task, "collector_type", "Unknown")

        if collector_type in self.tasks_by_client_type:
            try:
                self.tasks_by_client_type[collector_type].remove(task)
                self.metrics_by_client_type[collector_type]["active_tasks"] = max(
                    0, self.metrics_by_client_type[collector_type]["active_tasks"] - 1
                )
                logger_InfluxDBStorage.debug(
                    f"Active tasks for {collector_type}: {self.metrics_by_client_type[collector_type]['active_tasks']}"
                )
            except ValueError:
                pass  # Task was already removed or not found

    async def close(self):
        # Wait for all scheduled tasks to complete before closing
        if self.tasks:
            await asyncio.wait(self.tasks)
        self.client.close()

    def dump_data_structure(self):
        # Only perform dumping if data structure tracking is enabled
        if config.WEATHERFLOW_COLLECTOR_ENABLE_INFLUXDB_DATA_STRUCTURE_TRACKING:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            directory = (
                config.WEATHERFLOW_COLLECTOR_ENABLE_INFLUXDB_DATA_STRUCTURE_TRACKING_SAVE_DIR
            )
            filename = f"{directory}/influxdb_relationships_{timestamp}.json"

            # Check if directory exists, if not, create it
            if not os.path.exists(directory):
                os.makedirs(directory)

            # Convert sets to lists for JSON serialization
            serializable_data_structure = {}
            for measurement, data in self.data_structure.items():
                serializable_data_structure[measurement] = {
                    "tags": {
                        tag: {
                            "type": details["type"],
                            "callers": list(details["callers"]),
                        }
                        for tag, details in data["tags"].items()
                    },
                    "fields": {
                        field: {
                            "type": details["type"],
                            "callers": list(details["callers"]),
                        }
                        for field, details in data["fields"].items()
                    },
                    "callers": list(data["callers"]),
                }

            with open(filename, "w") as file:
                json.dump(serializable_data_structure, file, indent=4)
            logger_InfluxDBStorage.debug(f"Data structure dumped to file: {filename}")

    def reset_tracking(self):
        self.data_structure.clear()

    def get_caller_info(self):
        # Inspect the call stack
        stack = inspect.stack()

        # Iterate over the stack to find the external caller
        for frame_info in stack:
            # Skip internal methods of InfluxDBStorage
            if frame_info.frame.f_locals.get("self", None).__class__ == InfluxDBStorage:
                continue

            # Check if the frame is from this file (same module)
            if frame_info.filename == __file__:
                # Skip 'publish' method or any known intermediaries
                if frame_info.function not in [
                    "publish",
                    "save_data",
                    "get_caller_info",
                ]:
                    # Extract class and method name if it's a class method
                    if "self" in frame_info.frame.f_locals:
                        caller_class = frame_info.frame.f_locals[
                            "self"
                        ].__class__.__name__
                        return f"{caller_class}.{frame_info.function}"
                    else:  # For standalone functions
                        return frame_info.function
        return "Unknown Caller"
