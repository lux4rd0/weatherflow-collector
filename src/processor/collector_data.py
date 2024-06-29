# client_data_processor.py

"""
CollectorDataProcessor Module for WeatherFlow Collector

This module provides functionalities for processing and enriching incoming data from 
various clients within the WeatherFlow Collector system. It acts as a mediator to 
transform raw collector data, enrich it with additional metadata, and normalize it 
for further processing or storage.

Key Features:
- Processes and enriches data from different data sources such as UDP and WebSocket clients.
- Integrates with the EventManager to subscribe to collector data events and publish processed data events.
- Utilizes utility functions from the utils module to enrich data with station-specific metadata.
- Ensures data consistency and structure before forwarding to storage or other clients.

Usage:
The CollectorDataProcessor is an integral part of the data pipeline, transforming incoming data 
from various sources into a structured and enriched format. It subscribes to raw data events, 
processes the data, and then publishes it for other components like data storage handlers or 
real-time data streaming services.

Dependencies:
- asyncio: For managing asynchronous operations.
- inspect, threading: For handling Python's asynchronous and threading paradigms.
- copy: For creating deep copies of data structures.
- utils: Utility functions for data transformation and enrichment.
- logger: Custom logging for tracking operations and errors.

Methods:
- update: An asynchronous method that is triggered when new collector data is available.
- transform_and_enrich_data: Transforms and enriches collector data with additional metadata.

Author: [Your Name or Team's Name]
Last Update: [Last Update Date]

Note:
CollectorDataProcessor plays a pivotal role in ensuring data integrity and enrichment in the 
WeatherFlow Collector system. It provides a customizable and extendable framework for 
processing diverse data from meteorological sensors.
"""


import json
from datetime import datetime


import asyncio
import inspect
import threading
import copy

import utils.utils as utils
import logger

logger_CollectorDataProcessor = logger.get_module_logger(__name__ + ".CollectorDataProcessor")


class CollectorDataProcessor:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        # Subscribe to collector data event
        self.event_manager.subscribe("collector_data_event", self)

    async def update(self, client_data):
        try:
            # Create a deep copy of the collector data for processing
            client_data_copy = copy.deepcopy(client_data)

            # Process the copied data
            processed_data = self.transform_and_enrich_data(client_data_copy)

            # Determine the type of collector and publish accordingly
            collector_type = client_data_copy.get("metadata", {}).get("collector_type", "")
            if collector_type == "rest_export_client":
                # Publish processed data for rest_export_client
                await self.event_manager.publish(
                    "processed_export_event", processed_data, publisher="CollectorDataProcessor.update"
                )
            else:
                # Publish processed data for other collector types
                await self.event_manager.publish("processed_data_event", processed_data, publisher="CollectorDataProcessor.update")
        except Exception as e:
            logger_CollectorDataProcessor.error(f"Error processing data: {e}")

    def transform_and_enrich_data(self, client_data):
        """Transform and enrich collector data before it's sent to clients."""

        found_station_id = None  # Initialize the variable

        try:
            # Retrieve the station metadata from the Singleton
            station_metadata = utils.StationMetadataSingleton().get_metadata()
            logger_CollectorDataProcessor.debug(f"station_metadata: {station_metadata}")

            # Assume client_data is already a dictionary
            structured_data = client_data

            # logger_CollectorDataProcessor.debug(f"client_data coming in: {client_data}")

            # Fetch specific station configuration and enrich data
            serial_number = structured_data.get("data", {}).get("serial_number")
            device_id = structured_data.get("data", {}).get("device_id")
            hub_sn = structured_data.get("data", {}).get("hub_sn")

            # Check for station_id in both data and metadata
            station_id_data = structured_data.get("data", {}).get("station_id")
            station_id_meta = structured_data.get("metadata", {}).get("station_id")
            station_id = station_id_data or station_id_meta

            logger_CollectorDataProcessor.debug(f"Serial Number: {serial_number}")
            logger_CollectorDataProcessor.debug(f"Device ID: {device_id}")
            logger_CollectorDataProcessor.debug(f"Station ID: {station_id}")
            logger_CollectorDataProcessor.debug(f"Hub SN: {hub_sn}")

            current_station_info = None
            current_device_info = None

            if serial_number:
                (
                    current_station_info,
                    current_device_info,
                ) = utils.get_station_and_device_config_by_serial_number(serial_number)
                logger_CollectorDataProcessor.debug(
                    f"Current station info: {current_station_info}"
                )
                if current_station_info:
                    found_station_id = current_station_info.get("station_id")
                    logger_CollectorDataProcessor.debug(
                        f"Found station ID: {found_station_id}"
                    )

            elif device_id:
                (
                    current_station_info,
                    current_device_info,
                ) = utils.get_station_and_device_config_by_device_id(device_id)

                # Find the station_id by searching through the station_metadata
                found_station_id = None
                for station_id, station_info in station_metadata.items():
                    for device in station_info.get("devices", []):
                        if device["device_id"] == device_id:
                            found_station_id = station_id
                            break
                    if found_station_id is not None:
                        break

            elif station_id:  # Use the found station_id
                current_station_info = utils.get_station_config_by_station_id(
                    station_id
                )
            elif hub_sn:
                current_station_info = utils.get_station_config_by_hub_sn(hub_sn)

            final_station_id = (
                station_id if station_id is not None else found_station_id
            )

            if current_station_info:
                # Add enhanced meta information as a new section in the 'data' dictionary
                structured_data["station_info"] = {
                    "station_name": current_station_info.get("name"),
                    "station_id": final_station_id,
                    "station_latitude": current_station_info.get("latitude"),
                    "station_longitude": current_station_info.get("longitude"),
                    "station_elevation": current_station_info.get("elevation"),
                    "station_time_zone": current_station_info.get("time_zone"),
                }

            if current_device_info:
                structured_data["device_info"] = {
                    "device_id": current_device_info.get("device_id"),
                    "device_type": current_device_info.get("device_type"),
                    "device_name": current_device_info.get("device_name"),
                    "serial_number": current_device_info.get("serial_number"),
                    # Add other device-specific fields if necessary
                }

            # logger_CollectorDataProcessor.debug(
            #    f"structured_data after: {structured_data}"
            # )

            # Normalize the fields
            normalized_fields = utils.normalize_fields(structured_data)

            # logger_CollectorDataProcessor.debug(
            #    f"normalized_fields after: {normalized_fields}"
            # )

            logger_CollectorDataProcessor.debug(
                "Data transformed and enriched successfully"
            )
            return normalized_fields
        except Exception as e:
            logger_CollectorDataProcessor.error(
                f"Error transforming or enriching data: {e}"
            )
            return None
