# collector_rest_forecasts.py

"""
WeatherFlow Collector REST Forecasts Client

This module is part of the WeatherFlow Collector system and is responsible for retrieving weather forecasts
from WeatherFlow's REST API. It periodically fetches forecast data for enabled weather stations and publishes 
the data with relevant metadata for further processing.

Key Features:
- Asynchronous fetching of forecast data from WeatherFlow's REST API.
- Configurable interval for data retrieval.
- Integration with an event manager to publish the fetched data.
- Addition of metadata to the fetched data for identification and processing.

Usage:
The RestForcecastsCollector is instantiated with an event manager. It can be started in a continuous run mode,
where it periodically fetches and publishes forecast data.

Dependencies:
- aiohttp: For asynchronous HTTP requests.
- asyncio: For managing asynchronous tasks and scheduling.
- config: Configuration module for API keys and URLs.
- utils: Utility module for common functionalities.
- calculate_weather_metrics: Module for calculating weather-related metrics.
- logger: Custom logging module.

Classes:
- RestForcecastsCollector: Manages the fetching and processing of forecast data.

Methods:
- make_get_request(url, station_id): Asynchronously makes a GET request to the provided URL.
- fetch_forecasts(station_id): Fetches forecasts for a given station ID.
- retrieve_and_save_data(): Retrieves forecasts for all enabled stations and saves the data.
- run_forever(): Runs the collector in a continuous loop with a configurable interval.

Author: [Your Name or Team's Name]
Last Update: [Last Update Date]

Note:
The RestForcecastsCollector is specifically designed for integration with the WeatherFlow Collector system.
It is tailored to interact with WeatherFlow's REST API and is not intended for standalone use.
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

logger_CollectorRestForcecasts = logger.get_module_logger(
    __name__ + ".RestForcecastsCollector"
)


class RestForcecastsCollector:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        self.api_key = config.WEATHERFLOW_COLLECTOR_API_TOKEN
        self.base_url = config.WEATHERFLOW_API_REST_FORECASTS_URL
        self.request_count = 0  # Counter for processed requests
        self.error_count = 0  # Counter for errors
        self.module_name = "collector_rest_forecasts"
        self.collector_type = "collector_rest_forecasts"

    async def fetch_forecasts(self, station_id):
        request_processing_start = time.time()  # Start time for processing

        try:
            url = f"{self.base_url}?station_id={station_id}&token={self.api_key}"
            logger_CollectorRestForcecasts.debug(
                f"Fetching data for station ID {station_id} from URL: {url}"
            )

            json_data = await utils.fetch_data_from_url(
                url, self.collector_type, self.event_manager
            )

            if json_data:
                logger_CollectorRestForcecasts.debug(
                    f"Received JSON data for station ID {station_id}"
                )

                data_with_metadata = {
                    "metadata": {
                        "collector_type": self.collector_type,
                        "station_id": station_id,
                    },
                    "data": json_data,
                }

                await self.event_manager.publish(
                    "collector_data_event",
                    data_with_metadata,
                    publisher="RestForcecastsCollector.fetch_forecasts",
                )
                logger_CollectorRestForcecasts.debug(
                    f"Published data to event manager for station ID {station_id}"
                )
            else:
                logger_CollectorRestForcecasts.warning(
                    f"No data received for station ID {station_id} from URL: {url}"
                )

            # Increment request count
            self.request_count += 1

            # Calculate processing duration and publish metrics
            processing_duration = time.time() - request_processing_start

            logger_CollectorRestForcecasts.debug(
                f"Publishing metrics: request_count={self.request_count}, errors={self.error_count}, duration={processing_duration}"
            )

            await utils.async_publish_metrics(
                self.event_manager,
                metric_name="fetch_forecasts",
                module_name=self.module_name,
                rate=self.request_count,
                errors=self.error_count,
                duration=processing_duration,
            )

        except Exception as e:
            self.error_count += 1  # Increment error count
            logger_CollectorRestForcecasts.error(f"Error in retrieving data: {e}")

            # Publish error metrics
            processing_duration = time.time() - request_processing_start

            logger_CollectorRestForcecasts.debug(
                f"Publishing metrics: request_count={self.request_count}, errors={self.error_count}, duration={processing_duration}"
            )

            await utils.async_publish_metrics(
                self.event_manager,
                metric_name="fetch_forecasts",
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
                task = asyncio.create_task(self.fetch_forecasts(station_id))
                tasks.append(task)
        await asyncio.gather(*tasks)

    async def run_forever(self):
        logger_CollectorRestForcecasts.info(
            "Starting RestForcecastsCollector in run_forever mode."
        )
        while True:
            start_time = asyncio.get_event_loop().time()
            await self.retrieve_and_save_data()
            elapsed_time = asyncio.get_event_loop().time() - start_time

            # Logging the execution time
            logger_CollectorRestForcecasts.info(
                f"Execution of data retrieval and processing took {elapsed_time:.2f} seconds."
            )

            # Calculating and logging the sleep time
            sleep_time = max(
                config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_FORECASTS_FETCH_INTERVAL
                - elapsed_time,
                0,
            )
            next_start_time = datetime.now() + timedelta(seconds=sleep_time)
            next_start_time_formatted = next_start_time.strftime("%Y-%m-%d %H:%M:%S")

            logger_CollectorRestForcecasts.info(
                f"Sleeping for {sleep_time:.2f} seconds. Next cycle will start at approximately {next_start_time_formatted}."
            )

            await asyncio.sleep(sleep_time)
