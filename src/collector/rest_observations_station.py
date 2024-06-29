"""
collector_rest_observations_station.py

This module defines the RESTObservationsStationCollector class, which handles API requests to the WeatherFlow Smart Weather API. 
It retrieves the latest observations for weather stations and publishes the data for further processing and analysis.

Key Features:
- Retrieves weather data from the WeatherFlow API.
- Processes and extracts relevant fields from the observation data.
- Organizes data with tags for better categorization.
- Publishes the processed data to an event manager.

Usage:
Initialize the RESTObservationsStationCollector class with an event manager instance and a station configuration. 
It periodically fetches the latest weather observations based on the provided configuration and publishes this data.

Dependencies:
- requests, json, logging, etc. for handling API requests and data processing.
- utils: Utility module containing functions for weather calculations and configurations.
- config: Configuration module containing API keys and other settings.

Classes:
- RESTObservationsStationCollector: Handles API requests, data processing, and publishing.

Author: Dave Schmid
Created: 2023-12-17
"""

import aiohttp
import asyncio
import logging
from datetime import datetime, timedelta
import time


import config
import utils.utils as utils


#from utils.calculate_weather_metrics import CalculateWeatherMetrics

import logger

logger_RESTObservationsStationCollector = logger.get_module_logger(
    __name__ + ".RESTObservationsStationCollector"
)


class RESTObservationsStationCollector:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        self.api_key = config.WEATHERFLOW_COLLECTOR_API_TOKEN
        self.base_url = config.WEATHERFLOW_API_REST_OBSERVATIONS_URL
        self.request_count = 0  # Counter for processed requests
        self.error_count = 0  # Counter for errors
        self.module_name = "collector_rest_observations_station"
        self.collector_type = "collector_rest_observations_station"

    async def handle_latest_station_observation(self, station_id):
        request_processing_start = time.time()  # Start time for processing

        try:
            url = f"{self.base_url}/station/{station_id}?api_key={self.api_key}"
            logger_RESTObservationsStationCollector.debug(
                f"Fetching data for station ID {station_id} from URL: {url}"
            )

            json_data = await utils.fetch_data_from_url(
                url, self.collector_type, self.event_manager
            )

            if json_data:
                logger_RESTObservationsStationCollector.debug(
                    f"Received JSON data for station ID {station_id}: {json_data}"
                )
                if "obs" in json_data and len(json_data["obs"]) > 0:
                    obs_data = json_data["obs"][0]
                    logger_RESTObservationsStationCollector.debug(
                        f"Fetched observation data: {obs_data}"
                    )

                    # Wrap the data with metadata
                    data_with_metadata = {
                        "metadata": {
                            "collector_type": self.collector_type,
                            "station_id": station_id,
                        },
                        "data": obs_data,
                    }

                    await self.event_manager.publish(
                        "collector_data_event", data_with_metadata, publisher="RESTObservationsStationCollector.handle_latest_station_observation"
                    )
                    logger_RESTObservationsStationCollector.debug(
                        f"Published data to event manager for station ID {station_id}"
                    )
                else:
                    logger_RESTObservationsStationCollector.warning(
                        f"No observation data available in response for station ID {station_id}"
                    )

            else:
                logger_RESTObservationsStationCollector.warning(
                    f"No data received for station ID {station_id} from URL: {url}"
                )

            # Increment request count
            self.request_count += 1

            # Calculate processing duration and publish metrics
            processing_duration = time.time() - request_processing_start

            logger_RESTObservationsStationCollector.debug(
                f"Publishing metrics: request_count={self.request_count}, errors={self.error_count}, duration={processing_duration}"
            )

            await utils.async_publish_metrics(
                self.event_manager,
                metric_name="handle_latest_station_observation",
                module_name=self.module_name,
                rate=self.request_count,
                errors=self.error_count,
                duration=processing_duration,
            )

        except Exception as e:
            self.error_count += 1  # Increment error count
            logger_RESTObservationsStationCollector.error(f"Error in retrieving data: {e}")

            # Publish error metrics
            processing_duration = time.time() - request_processing_start

            logger_RESTObservationsStationCollector.debug(
                f"Publishing metrics: request_count={self.request_count}, errors={self.error_count}, duration={processing_duration}"
            )

            await utils.async_publish_metrics(
                self.event_manager,
                metric_name="handle_latest_station_observation",
                module_name=self.module_name,
                rate=self.request_count,
                errors=self.error_count,
                duration=processing_duration,
            )

    async def retrieve_and_save_data(self):
        station_metadata = utils.StationMetadataSingleton().get_metadata()
        tasks = []
        for station_id, station_info in station_metadata.items():
            if station_info.get("enabled", False):
                task = asyncio.create_task(
                    self.handle_latest_station_observation(station_id)
                )
                tasks.append(task)
        await asyncio.gather(*tasks)

    async def run_forever(self):
        logger_RESTObservationsStationCollector.info(
            "Starting RESTObservationsStationCollector in run_forever mode."
        )
        while True:
            start_time = asyncio.get_event_loop().time()
            await self.retrieve_and_save_data()
            elapsed_time = asyncio.get_event_loop().time() - start_time

            # Logging the execution time
            logger_RESTObservationsStationCollector.debug(
                f"Execution of data retrieval and processing took {elapsed_time:.2f} seconds."
            )

            # Calculating and logging the sleep time
            sleep_time = max(
                config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_OBSERVATIONS_INTERVAL - elapsed_time, 0
            )
            next_start_time = datetime.now() + timedelta(seconds=sleep_time)
            next_start_time_formatted = next_start_time.strftime("%Y-%m-%d %H:%M:%S")

            logger_RESTObservationsStationCollector.debug(
                f"Sleeping for {sleep_time:.2f} seconds. Next cycle will start at approximately {next_start_time_formatted}."
            )

            await asyncio.sleep(sleep_time)
