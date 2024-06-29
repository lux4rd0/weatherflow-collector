# station_metadata_manager.py

"""
WeatherFlow Collector Station Metadata Manager

This module is part of the WeatherFlow Collector system, responsible for managing station metadata.
It handles fetching, processing, and updating station and device configurations from the WeatherFlow API,
and manages a local configuration file for enabled/disabled stations and devices.

Key Features:
- Fetches station metadata from the WeatherFlow API.
- Processes and stores metadata for individual stations and their devices.
- Reads from and writes to a local configuration file to persist settings.
- Handles changes in API tokens and updates configuration accordingly.
- Supports backup creation for configuration files.

Usage:
This module is designed to work within the WeatherFlow Collector system. It's initialized with API tokens and URLs,
and it interacts with the WeatherFlow API to fetch and manage station metadata.

Dependencies:
- requests: For making HTTP requests to the WeatherFlow API.
- configparser: For managing local configuration files.
- json, os, logging: For general utility functions.

Classes:
- StationMetadataManager: Manages interactions with the WeatherFlow API and local configurations.

Methods:
- fetch_station_metadata(): Fetches metadata from the WeatherFlow API.
- process_metadata(metadata): Processes the fetched metadata.
- read_config_file(): Reads from the local configuration file.
- create_config_file(): Creates a new configuration file with default settings.
- update_config_file(): Updates the configuration file with fetched metadata.
- initialize_config(): Initializes the configuration setup.
- run(): Starts the metadata management process.
- get_station_metadata(): Returns the complete station configuration metadata.
- check_token_change(): Checks if the API token has changed.
- backup_config_file(): Creates a backup of the current configuration file.

Author: [Your Name or Team's Name]
Last Update: [Last Update Date]

Note:
The StationMetadataManager is an integral part of the WeatherFlow Collector system and is not intended for standalone use.
It works in conjunction with other components of the system to manage weather station data effectively.
"""

import config

# from api_data_saver import APIDataSaver
from datetime import datetime

# from data_storage import DataStorage

from logger import configure_logging
import utils.utils as utils

import configparser
import json
import logging
import os
import requests
import time

import logger

logger_StationMetadataManager = logger.get_module_logger(
    __name__ + ".StationMetadataManager"
)

# station_metadata = {}


class StationMetadataManager:
    def __init__(self):

        self.api_token = config.WEATHERFLOW_COLLECTOR_API_TOKEN
        self.api_url = (
            f"{config.WEATHERFLOW_API_REST_STATIONS_URL}?token={self.api_token}"
        )
        self.config_file = config.WEATHERFLOW_COLLECTOR_CONFIG_FILE
        self.station_metadata = {}
        self.enabled_flag = {}
        # self.data_saver = APIDataSaver(self)
        # self.storage = storage
        # global station_metadata

    # @utils.measure_execution_time("fetch_station_metadata")
    def fetch_station_metadata(self):
        params = {"token": self.api_token}
        try:
            response = requests.get(self.api_url, params=params, timeout=10)
            response.raise_for_status()  # This will raise an HTTPError if the HTTP request returned an unsuccessful status code

            # Debug log for the retrieved data
            logger_StationMetadataManager.debug(f"Data retrieved: {response.text}")

            if response.headers.get("Content-Type") == "application/json":
                return response.json()
            else:
                logger_StationMetadataManager.error(
                    "Unexpected content type in response"
                )
                return None

        except requests.exceptions.Timeout:
            logger_StationMetadataManager.error(
                "Timeout occurred while fetching metadata from WeatherFlow API"
            )
        except requests.exceptions.ConnectionError:
            logger_StationMetadataManager.error(
                "Connection error occurred while fetching metadata from WeatherFlow API"
            )
        except requests.exceptions.HTTPError as e:
            logger_StationMetadataManager.error(
                f"HTTP error occurred while fetching metadata: {e}"
            )
        except requests.exceptions.RequestException as e:
            logger_StationMetadataManager.error(
                f"Error fetching metadata from WeatherFlow API: {e}"
            )

        return None

    # @utils.measure_execution_time("process_metadata")
    def process_metadata(self, metadata):
        logger_StationMetadataManager.debug("Starting to process station metadata")

        for station in metadata.get("stations", []):
            station_id = station.get("station_id")
            logger_StationMetadataManager.debug(
                f"Processing metadata for station ID: {station_id}"
            )

            # Initialize a list to store all devices for this station
            devices_info = []

            for device in station.get("devices", []):
                device_info = {
                    "device_id": device.get("device_id"),
                    "device_type": device.get("device_type") or "Unknown",
                    "serial_number": device.get("serial_number") or "Unknown",
                    "device_name": device.get("device_meta", {}).get("name", "Unknown"),
                    "agl": device.get("device_meta", {}).get("agl", 0.0),
                    "environment": device.get("device_meta", {}).get(
                        "environment", "Unknown"
                    ),
                    "firmware_revision": device.get("firmware_revision") or "Unknown",
                    "hardware_revision": device.get("hardware_revision") or "Unknown",
                    "enabled": True,  # Set default enabled flag to True
                }

                logger_StationMetadataManager.debug(
                    f"Processed device details: {device_info} for station ID: {station_id}"
                )
                devices_info.append(device_info)

            # Compiling station metadata
            self.station_metadata[station_id] = {
                "name": station.get("name", "Unknown"),
                "station_id": station_id,
                "station_name": station.get("name", "Unknown"),
                "latitude": station.get("latitude", 0.0),
                "longitude": station.get("longitude", 0.0),
                "elevation": station.get("station_meta", {}).get("elevation", 0.0),
                "time_zone": station.get("timezone", "Unknown"),
                "enabled": True,  # Set default enabled flag to True
                "devices": devices_info,
            }

            logger_StationMetadataManager.debug(
                f"Station Metadata for ID {station_id}: {self.station_metadata[station_id]}"
            )

        logger_StationMetadataManager.debug("Finished processing all station metadata")

    # @utils.measure_execution_time("read_config_file")
    def read_config_file(self):
        config_parser = configparser.ConfigParser()

        if os.path.exists(self.config_file):
            config_parser.read(self.config_file)
            logger_StationMetadataManager.info("Configuration file read successfully.")

            for section in config_parser.sections():
                if section.isdigit():  # Station section
                    station_id = int(section)
                    enabled = config_parser.getboolean(
                        section, "enabled", fallback=False
                    )

                    # Update the enabled flag for the station
                    if station_id in self.station_metadata:
                        self.station_metadata[station_id]["enabled"] = enabled

                elif section.startswith("Device_"):  # Device section
                    _, device_id_str, station_id_str = section.split("_")
                    device_id = int(device_id_str)
                    station_id = int(station_id_str)

                    # Update the enabled flag for the device
                    if station_id in self.station_metadata:
                        for device in self.station_metadata[station_id]["devices"]:
                            if device["device_id"] == device_id:
                                device["enabled"] = config_parser.getboolean(
                                    section, "enabled", fallback=False
                                )

        else:
            logger_StationMetadataManager.info(
                "Configuration file does not exist. Creating a new one."
            )
            self.create_config_file()

    # @utils.measure_execution_time("create_config_file")
    def create_config_file(self):
        config_parser = configparser.ConfigParser()

        # Ensure the directory for the config file exists
        os.makedirs(os.path.dirname(self.config_file), exist_ok=True)

        # Add a general section to store the API token
        config_parser.add_section("General")
        config_parser.set(
            "General", "api_token", str(self.api_token)
        )  # Ensure it's a string

        # Iterate through station metadata to add sections for stations and devices
        for station_id, station_info in self.station_metadata.items():
            station_section = str(station_id)
            config_parser.add_section(station_section)

            # Set default values for the station
            config_parser.set(
                station_section, "enabled", str(station_info["enabled"])
            )  # Ensure it's a string
            config_parser.set(
                station_section, "name", station_info.get("name", "Unknown")
            )

            # Add sections for each device in the station
            for device in station_info.get("devices", []):
                device_section = f'Device_{device["device_id"]}_{station_id}'
                config_parser.add_section(device_section)

                # Set default values for the device
                config_parser.set(
                    device_section, "enabled", str(device["enabled"])
                )  # Ensure it's a string
                config_parser.set(
                    device_section, "device_id", str(device.get("device_id", "Unknown"))
                )  # Ensure it's a string
                config_parser.set(
                    device_section, "device_type", device.get("device_type", "Unknown")
                )
                config_parser.set(
                    device_section,
                    "serial_number",
                    device.get("serial_number", "Unknown"),
                )
                config_parser.set(
                    device_section, "name", device.get("device_name", "Unknown")
                )

        # Write the configuration to the file
        try:
            with open(self.config_file, "w") as configfile:
                config_parser.write(configfile)
                logger_StationMetadataManager.info(
                    "Configuration file created with default settings."
                )
        except Exception as e:
            logger_StationMetadataManager.error(
                f"Error writing configuration file: {e}"
            )

    # @utils.measure_execution_time("update_config_file")
    def update_config_file(self):
        config_parser = configparser.ConfigParser()
        if os.path.exists(self.config_file):
            config_parser.read(self.config_file)

        # Logic for updating station and device sections without altering 'enabled' flags
        for station_id, station_info in self.station_metadata.items():
            station_section = str(station_id)
            if station_section not in config_parser:
                config_parser.add_section(station_section)

            # Only update name for stations, do not touch 'enabled' flag
            config_parser.set(
                station_section, "name", station_info.get("name", "Unknown")
            )

            for device in station_info.get("devices", []):
                device_section = f"Device_{device['device_id']}_{station_id}"
                if device_section not in config_parser:
                    config_parser.add_section(device_section)

                # Only update device details, do not touch 'enabled' flag
                config_parser.set(
                    device_section, "device_id", str(device.get("device_id", ""))
                )  # Ensure it's a string
                config_parser.set(
                    device_section, "device_type", device.get("device_type", "Unknown")
                )
                config_parser.set(
                    device_section,
                    "serial_number",
                    device.get("serial_number", "Unknown"),
                )
                config_parser.set(
                    device_section, "name", device.get("device_name", "Unknown")
                )

        with open(self.config_file, "w") as configfile:
            config_parser.write(configfile)
            logger_StationMetadataManager.info(
                "Configuration file updated with details for stations and devices (excluding 'enabled' flags)."
            )

    # @utils.measure_execution_time("initialize_config")
    def initialize_config(self):
        # Method to set up and read the configuration file
        self.read_config_file()

    # @utils.measure_execution_time("run")
    def run(self):
        logger_StationMetadataManager.info("Starting WeatherFlow station configuration")
        try:
            data = self.fetch_station_metadata()
            if data:
                self.process_metadata(data)
                self.initialize_config()
                self.update_config_file()
                for station_id, info in self.station_metadata.items():
                    station_name = info.get("name", "Unknown")
                    enabled = info.get("enabled", "Unknown")

                    # Apply color, bold, and flashing based on the enabled flag
                    if enabled is True:
                        # Bold Green for True
                        enabled_status = f"\033[1;32m{enabled}\033[0m"
                    elif enabled is False:
                        # Bold Red and Flashing for False
                        enabled_status = f"\033[1;31;5m{enabled}\033[0m"
                    else:
                        # No color or effect if status is unknown
                        enabled_status = str(enabled)

                    logger_StationMetadataManager.info(
                        f"Station \033[1m{station_id}\033[0m - \033[1m{station_name}\033[0m: Enabled flag - {enabled_status}"
                    )

                logger_StationMetadataManager.info(
                    "WeatherFlow station configuration updated successfully"
                )

                # Load metadata into the Singleton
                metadata_singleton = utils.StationMetadataSingleton()
                metadata_singleton.load_metadata(self.station_metadata)

        except Exception as e:
            logger_StationMetadataManager.error(f"An error occurred: {e}")

    # @utils.measure_execution_time("get_station_metadata")
    def get_station_metadata(self):
        # Returns the complete station configuration metadata
        return self.station_metadata

    # @utils.measure_execution_time("check_token_change")
    def check_token_change(self):
        config_parser = configparser.ConfigParser()
        if os.path.exists(self.config_file):
            config_parser.read(self.config_file)

            # Check if the token key has changed
            last_token = config_parser.get("General", "api_token", fallback=None)
            if last_token != self.api_token:
                logger_StationMetadataManager.info(
                    "API token has changed. Creating backup of the current configuration."
                )
                self.backup_config_file()
                return True
        return False

    # @utils.measure_execution_time("backup_config_file")
    def backup_config_file(self):
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        backup_filename = f"{self.config_file}_{timestamp}.bak"
        os.rename(self.config_file, backup_filename)
        logger_StationMetadataManager.info(f"Backup created: {backup_filename}")

    # @utils.measure_execution_time("initialize_config")
    def initialize_config(self):
        token_changed = self.check_token_change()

        if token_changed or not os.path.exists(self.config_file):
            self.create_config_file()
        else:
            self.read_config_file()
