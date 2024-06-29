# utils.py

"""
Utilities Module for WeatherFlow Data Processing

This module provides utility functions for handling and processing weather data from
WeatherFlow weather stations. It includes functions for retrieving station configurations
based on serial numbers and device IDs, calculating various weather metrics, and generating
maps of enabled statuses for stations, devices, and hubs.

Key Features:
- Retrieval of station configurations using serial numbers and device IDs.
- Calculation of Vapor Pressure Deficit (VPD), Dew Point, Heat Index, and Wind Chill.
- Generation of enabled status maps for efficient data processing.

Usage:
The functions in this module are designed to be used throughout the WeatherFlow data
processing system. They assist in fetching the right configuration for a given device
and in performing essential weather-related calculations necessary for accurate data
analysis and presentation.

Dependencies:
- math: Required for performing mathematical calculations.

Functions:
- get_station_config_by_serial_number: Retrieves station configuration based on device's serial number.
- get_hub_config_by_serial_number: Retrieves station configuration based on hub's serial number.
- generate_enabled_status_map: Generates a map of enabled statuses for stations, devices, and hubs.
- get_station_config_by_device_id: Retrieves station configuration based on device ID.
- calculate_vpd: Calculates Vapor Pressure Deficit.
- calculate_dew_point: Calculates the dew point temperature.
- calculate_heat_index: Calculates the heat index in Celsius.
- calculate_wind_chill: Calculates the wind chill factor in Celsius.

Author: Dave Schmid
Created: 2023-12-17
"""


import math


import aiohttp
import asyncio


from logger import get_module_logger

import time
from functools import wraps


import logging  # Add this import
from datetime import datetime

import logger
import config

logger_Utils = logger.get_module_logger(__name__ + ".Utils")


metrics_data = {}


class SingletonMeta(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super(SingletonMeta, cls).__call__(*args, **kwargs)
        return cls._instances[cls]


class StationMetadataSingleton(metaclass=SingletonMeta):
    def __init__(self):
        self.station_metadata = {}

    def load_metadata(self, data):
        self.station_metadata = data

    def get_metadata(self):
        return self.station_metadata


def get_station_config_by_serial_number(serial_number):
    """
    Retrieves the station configuration based on a device's serial number.

    Args:
        serial_number (str): The serial number of the device.

    Returns:
        dict: The configuration of the station if found, otherwise None.
    """
    # Get the singleton instance and access its metadata
    metadata_singleton = StationMetadataSingleton()
    station_metadata = metadata_singleton.get_metadata()

    logger_Utils.debug(
        f"get_station_config_by_serial_number: data coming in {serial_number}"
    )

    for station_id, config in station_metadata.items():
        for device in config.get("devices", []):
            if device.get("serial_number") == serial_number:
                # Keep the station's configuration at the top level and nest the device config
                station_info = config.copy()  # Create a copy of the station config
                station_info["device_config"] = device  # Nest the device config
                if "devices" in station_info:
                    del station_info[
                        "devices"
                    ]  # Optionally remove the 'devices' list to avoid redundancy
                return station_info
    return None


def get_hub_config_by_serial_number(hub_sn):
    """
    Retrieves the station configuration based on a hub serial number.

    Args:
        hub_sn (str): The serial number of the hub.

    Returns:
        dict: The configuration of the station associated with the hub, if found; otherwise None.
    """
    # Get the singleton instance and access its metadata
    metadata_singleton = StationMetadataSingleton()
    station_metadata = metadata_singleton.get_metadata()

    logger_Utils.debug(f"get_hub_config_by_serial_number: data coming in {hub_sn}")

    for station_id, config in station_metadata.items():
        if "devices" in config:
            for device in config["devices"]:
                if device.get("serial_number") == hub_sn:
                    return config
    return None


def get_station_config_by_station_id(station_id):
    """
    Retrieves the station configuration based on a station ID.

    Args:
        station_id (int): The ID of the station.

    Returns:
        dict: The configuration of the station if found, otherwise None.
    """
    # Get the singleton instance and access its metadata
    metadata_singleton = StationMetadataSingleton()
    station_metadata = metadata_singleton.get_metadata()

    logger_Utils.debug(f"get_station_config_by_station_id: data coming in {station_id}")

    return station_metadata.get(station_id)


def get_station_config_by_device_id(device_id):
    """
    Retrieves the station configuration based on a device ID.

    Args:
        device_id (int): The device ID of the station.

    Returns:
        dict: The configuration of the station if found, otherwise None.
    """
    # Get the singleton instance and access its metadata
    metadata_singleton = StationMetadataSingleton()
    station_metadata = metadata_singleton.get_metadata()

    for station_id, config in station_metadata.items():
        for device in config.get("devices", []):
            if device.get("device_id") == device_id:
                return config
    return None


def get_station_config_by_hub_sn(hub_sn):
    """
    Retrieves the station configuration based on a hub's serial number.

    Args:
        hub_sn (str): The serial number of the hub.

    Returns:
        dict: The configuration of the station associated with the hub, if found; otherwise None.
    """
    # Get the singleton instance and access its metadata
    metadata_singleton = StationMetadataSingleton()
    station_metadata = metadata_singleton.get_metadata()

    for station_id, config in station_metadata.items():
        for device in config.get("devices", []):
            if device.get("serial_number") == hub_sn:
                return config
    return None


def get_station_and_device_config_by_serial_number(serial_number):
    """
    Retrieves the station and specific device configuration based on a device's serial number.

    Args:
        serial_number (str): The serial number of the device.

    Returns:
        tuple:
            - dict: The configuration of the station if found, otherwise None.
            - dict: The specific device configuration if found, otherwise None.
    """
    metadata_singleton = StationMetadataSingleton()
    station_metadata = metadata_singleton.get_metadata()

    for station_id, station_config in station_metadata.items():
        for device in station_config.get("devices", []):
            if device.get("serial_number") == serial_number:
                return station_config, device
    return None, None


def get_station_and_device_config_by_device_id(device_id):
    """
    Retrieves the station and specific device configuration based on a device ID.

    Args:
        device_id (int): The device ID of the station.

    Returns:
        tuple:
            - dict: The configuration of the station if found, otherwise None.
            - dict: The specific device configuration if found, otherwise None.
    """
    metadata_singleton = StationMetadataSingleton()
    station_metadata = metadata_singleton.get_metadata()

    for station_id, station_config in station_metadata.items():
        for device in station_config.get("devices", []):
            if device.get("device_id") == device_id:
                return station_config, device
    return None, None


def generate_enabled_status_map(station_config):
    """
    Generate a map of enabled statuses for all stations, devices, and hubs.

    Args:
        station_config (dict): A dictionary of station configurations.

    Returns:
        dict: A map with serial numbers as keys and enabled statuses as values.
    """
    enabled_status_map = {}
    for station_id, config in station_config.items():
        station_enabled = config.get("enabled", False)
        enabled_status_map[station_id] = station_enabled

        if "devices" in config:
            for device in config["devices"]:
                device_serial = device["serial_number"]
                device_enabled = station_enabled and device.get("enabled", False)
                enabled_status_map[device_serial] = {
                    "enabled": device_enabled,
                    "station_id": station_id,  # Include the station_id here
                }
    return enabled_status_map


def calculate_timestamp_delta(method_name):
    def decorator(func):
        @wraps(func)
        async def wrapper(self, *args, **kwargs):
            is_coroutine = asyncio.iscoroutinefunction(func)

            # Execute the original function (API call)
            result = (
                await func(self, *args, **kwargs)
                if is_coroutine
                else func(self, *args, **kwargs)
            )

            # Post execution logic
            api_end_timestamp = time.time()
            delta_timestamp = api_end_timestamp - getattr(
                self, "current_timestamp", api_end_timestamp
            )

            system_fields = {"timestamp_delta": delta_timestamp}
            system_tags = {
                "collector_type": getattr(self, "current_collector_type", "unknown"),
                "class": self.__class__.__name__,
                "module": self.__class__.__module__,
                "method": method_name,
            }

            # Process all 'current_' attributes
            current_attrs = {
                attr[len("current_") :]
                for attr in dir(self)
                if attr.startswith("current_") and attr != "current_timestamp"
            }
            system_tags.update(
                {
                    tag: getattr(self, "current_" + tag)
                    for tag in current_attrs
                    if getattr(self, "current_" + tag, None) is not None
                }
            )

            collector_data_with_meta = {
                "data_type": "single",
                "measurement": "weatherflow_system_metrics",
                "tags": system_tags,
                "fields": system_fields,
                "timestamp": int(time.time()),
            }

            event_manager = getattr(self, "event_manager", None)
            if event_manager:
                await event_manager.publish(
                    "influxdb_storage_event", collector_data_with_meta
                )
                logger_Utils.debug("Event published")

            logger_Utils.debug(
                f"calculate_timestamp_delta from {self.__class__.__module__}-{method_name}: Details: {collector_data_with_meta}"
            )

            return result

        return wrapper

    return decorator


def measure_execution_time(method_name):
    def decorator(func):
        @wraps(func)
        def wrapper(self, *args, **kwargs):
            logger = logging.getLogger("utils")

            # Start the timer
            start_time = time.time()

            # Execute the function
            result = func(self, *args, **kwargs)

            # Stop the timer
            end_time = time.time()
            execution_time = end_time - start_time

            class_name = self.__class__.__name__
            module_name = self.__class__.__module__

            # Retrieve attributes from thread-local storage or instance attributes
            local_attrs = getattr(self, "local", None)
            station_id = (
                getattr(local_attrs, "current_station_id", None)
                if local_attrs
                else getattr(self, "current_station_id", None)
            )
            device_id = (
                getattr(local_attrs, "current_device_id", None)
                if local_attrs
                else getattr(self, "current_device_id", None)
            )
            serial_number = (
                getattr(local_attrs, "current_serial_number", None)
                if local_attrs
                else getattr(self, "current_serial_number", None)
            )

            logger_Utils.debug(
                f"Station ID in decorator from {module_name}-{method_name}: {station_id}, "
                f"Device ID in decorator: {device_id}, "
                f"Serial Number in decorator: {serial_number}"
            )

            # Determine the scope of the operation
            if station_id:
                scope = "station"
            elif device_id or serial_number:
                scope = "device"
            else:
                scope = "global"

            logger_Utils.debug(f"scope {scope}")

            tags = {
                "class": class_name,
                "module": module_name,
                "method": method_name,
                "scope": scope,  # Add the scope tag
            }
            fields = {"execution_time": execution_time}

            logger_Utils.debug(
                f"Execution time for {module_name}.{class_name}.{method_name}: {execution_time} seconds - station_id={station_id}, device_id={device_id}, serial_number={serial_number}"
            )

            # Determine parameters for save_data based on available identifiers
            save_data_kwargs = {"tags": tags, "fields": fields}
            if device_id is not None:
                save_data_kwargs["device_id"] = device_id
            if serial_number is not None:
                save_data_kwargs["serial_number"] = serial_number
            if station_id is not None:
                save_data_kwargs["station_id"] = station_id

            # Write to InfluxDB
            self.storage.save_data("weatherflow_system_data", **save_data_kwargs)

            # Optionally clear the attributes from thread-local storage
            if hasattr(self, "local"):
                if hasattr(self.local, "current_station_id"):
                    delattr(self.local, "current_station_id")
                if hasattr(self.local, "current_device_id"):
                    delattr(self.local, "current_device_id")
                if hasattr(self.local, "current_serial_number"):
                    delattr(self.local, "current_serial_number")

            # Optionally clear the instance attributes
            if hasattr(self, "current_station_id"):
                delattr(self, "current_station_id")
            if hasattr(self, "current_device_id"):
                delattr(self, "current_device_id")
            if hasattr(self, "current_serial_number"):
                delattr(self, "current_serial_number")

            return result

        return wrapper

    return decorator


def get_utils_logger():
    logger = logging.getLogger("utils")
    logger.setLevel(logging.INFO)  # Set your desired logging level

    # Configure your logger further if needed (handlers, formatters, etc.)
    # Example:
    # handler = logging.StreamHandler()
    # formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    # handler.setFormatter(formatter)
    # logger.addHandler(handler)

    return logger


def normalize_fields(fields):
    """
    Normalize fields based on predefined data types.
    """

    # Define the normalization map within the function
    normalization_map = {
        "air_temperature": float,
        "daily_precip_sum": float,
        "firmware_revision": int,
        "illuminance": int,
        "lightning_strike_avg_distance": float,
        "lightning_strike_count": int,
        "local_daily_rain_accumulation": float,
        "local_daily_rain_accumulation": float,
        "local_daily_rain_accumulation_final": float,
        "local_precipitation_accumulation_final": float,
        "local_precipitation_accumulation_today": float,
        "precip": float,
        "precip_accum_local_day": float,
        "precip_accum_local_yesterday": float,
        "precipitation_analysis_type": int,
        "precipitation_type": int,
        "rain_accumulated": float,
        "rain_accumulated_final": float,
        "relative_humidity": float,
        "report_interval": int,
        "solar_radiation": int,
        "station_pressure": float,
        "timestamp": int,
        "uv": float,
        "wind_avg": float,
        "wind_direction": int,
        "wind_gust": float,
        "wind_lull": float,
        "wind_sample_interval": int,
    }

    normalized_fields = {}
    for field, value in fields.items():
        expected_type = normalization_map.get(field)

        if field == "firmware_revision" and isinstance(value, str):
            try:
                value = int(value.strip())
            except ValueError:
                value = None  # or provide a default value

        # Print the original value of each field
        # logger.debug(f"DEBUG: Original {field}: {value}")

        try:
            if expected_type is str:
                # Convert to string if not already
                normalized_fields[field] = str(value)
            elif expected_type is float:
                # Convert to float if not None
                normalized_fields[field] = float(value) if value is not None else None
            elif expected_type is int:
                # Convert to integer if not None, but only if the value is numeric
                normalized_fields[field] = (
                    int(str(value))
                    if value is not None and str(value).isdigit()
                    else None
                )

            else:
                normalized_fields[field] = value
        except (ValueError, TypeError):
            # Handle or log error
            normalized_fields[field] = None  # or a default value

    return normalized_fields


async def fetch_data_from_url(url, collector_type, event_manager):
    global metrics_data

    # Initialize metrics for this collector type if not already done
    if collector_type not in metrics_data:
        metrics_data[collector_type] = {
            "requests": 0,
            "errors": 0,
            "duration": 0,
            "bytes": 0,
        }

    attempt = 0
    while attempt < config.WEATHERFLOW_COLLECTOR_UTILS_HTTP_FETCH_RETRIES:
        try:
            timeout = aiohttp.ClientTimeout(
                total=config.WEATHERFLOW_COLLECTOR_UTILS_HTTP_FETCH_TIMEOUT
            )
            start_time = time.perf_counter()

            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.get(url) as response:
                    duration = time.perf_counter() - start_time

                    if response.status == 200:
                        payload = await response.read()
                        bytes_transferred = len(payload)
                        json_data = await response.json()

                        metrics_data[collector_type]["requests"] += 1
                        metrics_data[collector_type]["duration"] += duration
                        metrics_data[collector_type]["bytes"] += bytes_transferred

                        logger_Utils.debug(f"Data successfully fetched from URL: {url}")
                        logger_Utils.debug(
                            f"Request duration: {duration:.2f} seconds, Payload size: {bytes_transferred} bytes"
                        )

                        # Publish the metrics after a successful request
                        logger_Utils.debug(
                            f"Metrics for {collector_type}: {metrics_data[collector_type]}"
                        )
                        await async_publish_metrics(
                            event_manager=event_manager,
                            metric_name="fetch_data_from_url",
                            module_name=collector_type,
                            rate=metrics_data[collector_type]["requests"],
                            errors=metrics_data[collector_type]["errors"],
                            duration=metrics_data[collector_type]["duration"],
                            bytes=metrics_data[collector_type]["bytes"],
                        )

                        # Reset duration and bytes for the next call
                        metrics_data[collector_type]["duration"] = 0
                        metrics_data[collector_type]["bytes"] = 0

                        return json_data
                    else:
                        metrics_data[collector_type]["errors"] += 1
                        logger_Utils.error(
                            f"Error {response.status} fetching data from URL: {url}"
                        )
        except aiohttp.ClientConnectionError as e:
            metrics_data[collector_type]["errors"] += 1
            logger_Utils.warning(f"Connection error when fetching data from {url}: {e}")
        except aiohttp.ClientError as e:
            metrics_data[collector_type]["errors"] += 1
            logger_Utils.error(f"Client error when fetching data from {url}: {e}")
            break  # Stop retrying for collector errors
        except asyncio.TimeoutError as e:
            metrics_data[collector_type]["errors"] += 1
            logger_Utils.warning(f"Timeout error when fetching data from {url}: {e}")
        except Exception as e:
            metrics_data[collector_type]["errors"] += 1
            logger_Utils.error(f"Unexpected error when fetching data from {url}: {e}")
            break  # Stop retrying for unexpected errors

        attempt += 1
        if attempt < config.WEATHERFLOW_COLLECTOR_UTILS_HTTP_FETCH_RETRIES:
            await asyncio.sleep(
                config.WEATHERFLOW_COLLECTOR_UTILS_HTTP_FETCH_RETRY_WAIT
            )

    # Publish the metrics after all attempts, even if all attempts fail
    logger_Utils.debug(f"Metrics for {collector_type}: {metrics_data[collector_type]}")
    await async_publish_metrics(
        metric_name="fetch_data_from_url",
        module_name=collector_type,
        rate=metrics_data[collector_type]["requests"],
        errors=metrics_data[collector_type]["errors"],
        duration=metrics_data[collector_type]["duration"],
        bytes=metrics_data[collector_type]["bytes"],
    )

    # Reset duration and bytes for the next call
    metrics_data[collector_type]["duration"] = 0
    metrics_data[collector_type]["bytes"] = 0

    return None


def publish_metrics(
    event_manager, loop, metric_name, module_name, rate, errors, duration
):
    """
    Publish metrics using the event manager.

    :param event_manager: The event manager instance to publish metrics.
    :param loop: The asyncio event loop.
    :param metric_name: Name of the metric event.
    :param module_name: Name of the module.
    :param rate: Rate of packets or events.
    :param errors: Number of errors encountered.
    :param duration: Processing duration in seconds.
    """
    try:
        metrics_payload = {
            "metric_name": metric_name,
            "module_name": module_name,
            "rate": rate,
            "errors": errors,
            "duration": duration,
        }
        asyncio.run_coroutine_threadsafe(
            event_manager.publish(
                "system_metrics_event", metrics_payload, publisher="publish_metrics"
            ),
            loop,
        )
    except Exception as e:
        logger_Utils.error(f"Failed to publish metrics: {e}")


async def async_publish_metrics(
    event_manager, metric_name, module_name, rate, errors, duration, **optional_metrics
):
    """
    Asynchronously publish metrics using the event manager.

    :param event_manager: The event manager instance to publish metrics.
    :param metric_name: Name of the metric event.
    :param module_name: Name of the module.
    :param rate: Rate of packets or events.
    :param errors: Number of errors encountered.
    :param duration: Processing duration in seconds.
    :param optional_metrics: Optional additional metrics such as bytes and client_count.
    """
    # Check if the EventManager is already processing a metric event
    if event_manager.is_metric_event_processing:
        return  # Avoid triggering another metric event

    try:
        metrics_payload = {
            "metric_name": metric_name,
            "module_name": module_name,
            "rate": rate,
            "errors": errors,
            "duration": duration,
            **{k: v for k, v in optional_metrics.items() if v is not None},
        }

        # Debugging: Output details before publishing metrics
        logger_Utils.debug(f"Publishing metrics: {metrics_payload}")

        await event_manager.publish(
            "system_metrics_event",
            metrics_payload,
            publisher="Utils.async_publish_metrics",
        )
    except Exception as e:
        logger_Utils.error(f"Failed to publish metrics: {e}")
