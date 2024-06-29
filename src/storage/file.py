# file_client.py

"""
FileStorage Module for WeatherFlow Collector

This module is responsible for writing received meteorological data to files. It is part of the WeatherFlow Collector 
system, which gathers data from various sources like UDP, WebSocket, and REST clients. The FileStorage specifically 
handles the storage of this data in a structured and accessible file format.

Key Features:
- Writes data to JSON files, ensuring persistence of received meteorological information.
- Organizes files based on collector type and date, facilitating easy data retrieval and management.
- Capable of handling data from different sources, including UDP, WebSocket, and REST clients.

Usage:
The FileStorage is initialized with an event manager and an output directory. It subscribes to data events, 
processing each incoming packet and writing it to a JSON file in the appropriate directory.

Dependencies:
- json: For parsing and writing data in JSON format.
- os: For file and directory operations.
- datetime: To generate timestamps for file naming.
- logger: Custom logging for tracking events and errors.

Components:
- EventManager: Interface for receiving data events.
- FileStorage: Core class responsible for file operations.

Methods:
- update: Handles incoming data and delegates file writing tasks.
- construct_filename_suffix: Generates a unique suffix for file names based on data characteristics.
- write_to_file: Writes the provided data to a JSON file in the designated directory.

Author: [Your Name or Team's Name]
Last Update: [Last Update Date]

Note:
The design of FileStorage is tailored to the WeatherFlow Collector system's structure. It can be adapted 
or extended for broader applications or different data formats as needed.
"""


import json
import os
from datetime import datetime
import logger
import time
import asyncio


import utils.utils as utils
import config

logger_FileStorage = logger.get_module_logger(__name__ + ".FileStorage")


class FileStorage:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        self.output_directory = config.WEATHERFLOW_COLLECTOR_API_DATA_SAVE_DIR
        self.current_date = None
        self.file_path = None
        self.request_count = 0  # Counter for processed requests
        self.error_count = 0  # Counter for errors
        self.module_name = "file_client"

        # Ensure the base output directory exists
        os.makedirs(self.output_directory, exist_ok=True)

    async def update(self, full_data):
        request_processing_start = time.time()  # Start time for processing

        try:
            # Debugging: log the received full_data
            # logger_FileStorage.debug(f"Received full_data: {full_data}")

            metadata = full_data.get("metadata", {})
            collector_type = metadata.get(
                "collector_type", "unknown"
            )  # Default to "unknown"
            filename_suffix = self.construct_filename_suffix(full_data, collector_type)
            await self.write_to_file(full_data, collector_type, filename_suffix)

            # Increment request count
            self.request_count += 1

            # Calculate processing duration and publish metrics
            processing_duration = time.time() - request_processing_start

            logger_FileStorage.debug(
                f"Publishing metrics: request_count={self.request_count}, errors={self.error_count}, duration={processing_duration}"
            )

            await utils.async_publish_metrics(
                self.event_manager,
                metric_name="update",
                module_name=self.module_name,
                rate=self.request_count,
                errors=self.error_count,
                duration=processing_duration,
            )

        except Exception as e:
            self.error_count += 1  # Increment error count
            logger_FileStorage.error(f"Error processing data: {e}")

            # Publish error metrics
            processing_duration = time.time() - request_processing_start

            logger_FileStorage.debug(
                f"Publishing metrics: request_count={self.request_count}, errors={self.error_count}, duration={processing_duration}"
            )

            await utils.async_publish_metrics(
                self.event_manager,
                metric_name="update",
                module_name=self.module_name,
                rate=self.request_count,
                errors=self.error_count,
                duration=processing_duration,
            )

    def construct_filename_suffix(self, full_data, collector_type):
        """Construct a suffix for the filename based on collector type and data."""
        date_str = datetime.now().strftime("%Y%m%d")
        metadata = full_data.get("metadata", {})  # Correctly access metadata here

        if collector_type == "collector_udp" or collector_type == "collector_websocket":
            data_content = full_data.get("data", {})
            data_type = data_content.get("type", "unknown")
            if collector_type == "collector_websocket":
                serial_number = data_content.get("serial_number", "unknown")
                return f"data_{serial_number}_{data_type}_{date_str}"
            return f"data_{data_type}_{date_str}"

        elif collector_type == "collector_rest_observations_device":
            # Handle 'collector_rest_observations_device' differently by using 'device_id'
            device_id = metadata.get("device_id", "unknown")
            return f"data_{device_id}_{date_str}"

        elif collector_type in [
            "collector_rest_observations_station",
            "collector_rest_forecasts",
            "collector_rest_stats",
            "collector_rest_import",
        ]:
            station_id = metadata.get("station_id", "unknown")
            return f"data_{station_id}_{date_str}"

        else:  # Default case for unknown collector types
            return f"data_unknown_{date_str}"

    async def write_to_file(self, full_data, collector_type, filename_suffix):

        if (
            collector_type == "collector_rest_forecasts"
            and not config.WEATHERFLOW_COLLECTOR_STORAGE_FILE_COLLECTOR_REST_FORECASTS_ENABLED
        ):
            logger_FileStorage.debug(
                "Writing for 'collector_rest_forecasts' is disabled."
            )
            return
        elif (
            collector_type == "collector_rest_import"
            and not config.WEATHERFLOW_COLLECTOR_STORAGE_FILE_COLLECTOR_REST_IMPORT_ENABLED
        ):
            logger_FileStorage.debug("Writing for 'collector_rest_import' is disabled.")
            return
        elif (
            collector_type == "collector_rest_export"
            and not config.WEATHERFLOW_COLLECTOR_STORAGE_FILE_COLLECTOR_REST_EXPORT_ENABLED
        ):
            logger_FileStorage.debug("Writing for 'collector_rest_export' is disabled.")
            return
        elif (
            collector_type == "collector_rest_observations_device"
            and not config.WEATHERFLOW_COLLECTOR_STORAGE_FILE_COLLECTOR_REST_OBSERVATIONS_DEVICE_ENABLED
        ):
            logger_FileStorage.debug(
                "Writing for 'collector_rest_observations_device' is disabled."
            )
            return
        elif (
            collector_type == "collector_rest_observations_station"
            and not config.WEATHERFLOW_COLLECTOR_STORAGE_FILE_COLLECTOR_REST_OBSERVATIONS_STATION_ENABLED
        ):
            logger_FileStorage.debug(
                "Writing for 'collector_rest_observations_station' is disabled."
            )
            return
        elif (
            collector_type == "collector_rest_stationconfig"
            and not config.WEATHERFLOW_COLLECTOR_STORAGE_FILE_COLLECTOR_REST_STATIONCONFIG_ENABLED
        ):
            logger_FileStorage.debug(
                "Writing for 'collector_rest_stationconfig' is disabled."
            )
            return
        elif (
            collector_type == "collector_udp"
            and not config.WEATHERFLOW_COLLECTOR_STORAGE_FILE_COLLECTOR_UDP_ENABLED
        ):
            logger_FileStorage.debug("Writing for 'collector_udp' is disabled.")
            return
        elif (
            collector_type == "collector_websocket"
            and not config.WEATHERFLOW_COLLECTOR_STORAGE_FILE_COLLECTOR_WEBSOCKET_ENABLED
        ):
            logger_FileStorage.debug("Writing for 'collector_websocket' is disabled.")
            return
        elif (
            collector_type == "collector_rest_stats"
            and not config.WEATHERFLOW_COLLECTOR_STORAGE_FILE_COLLECTOR_REST_STATS_ENABLED
        ):
            logger_FileStorage.debug("Writing for 'collector_rest_stats' is disabled.")
            return

        client_output_directory = os.path.join(self.output_directory, collector_type)
        os.makedirs(client_output_directory, exist_ok=True)

        # Extract only the "data" part from the full_data
        data_to_write = full_data.get("data", {})

        self.file_path = os.path.join(
            client_output_directory, filename_suffix + ".json"
        )
        try:
            with open(self.file_path, "a") as file:
                json.dump(data_to_write, file)
                file.write("\n")
            logger_FileStorage.debug(f"Data appended to file: {self.file_path}")
        except Exception as e:
            logger_FileStorage.error(f"Error writing data to file: {e}")
