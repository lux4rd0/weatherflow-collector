# collector_rest_observations_device.py


import aiohttp
import asyncio
import logging
from datetime import datetime, timedelta
import config
import utils.utils as utils
import time


#from utils.calculate_weather_metrics import CalculateWeatherMetrics

import logger

logger_RESTObservationsDeviceCollector = logger.get_module_logger(
    __name__ + ".RESTObservationsDeviceCollector"
)


class RESTObservationsDeviceCollector:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        self.api_key = config.WEATHERFLOW_COLLECTOR_API_TOKEN
        self.base_url = config.WEATHERFLOW_API_REST_OBSERVATIONS_URL
        self.request_count = 0  # Counter for processed requests
        self.error_count = 0  # Counter for errors
        self.module_name = "collector_rest_observations_device"
        self.collector_type = "collector_rest_observations_device"

    async def handle_latest_device_observation(self, device_id):
        request_processing_start = time.time()  # Start time for processing

        try:
            url = f"{self.base_url}/device/{device_id}?api_key={self.api_key}"
            logger_RESTObservationsDeviceCollector.debug(
                f"Fetching data for device ID {device_id} from URL: {url}"
            )

            json_data = await utils.fetch_data_from_url(
                url, self.collector_type, self.event_manager
            )

            if json_data:
                logger_RESTObservationsDeviceCollector.debug(
                    f"Received JSON data for device ID {device_id}: {json_data}"
                )

                # Wrap the entire JSON response with metadata
                data_with_metadata = {
                    "metadata": {
                        "collector_type": self.collector_type,
                        "device_id": device_id,
                    },
                    "data": json_data,  # Assigning the entire JSON response to 'data'
                }

                await self.event_manager.publish(
                    "collector_data_event",
                    data_with_metadata,
                    publisher="RESTObservationsDeviceCollector.handle_latest_device_observation",
                )
                logger_RESTObservationsDeviceCollector.debug(
                    f"Published data to event manager for device ID {device_id}"
                )
            else:
                logger_RESTObservationsDeviceCollector.warning(
                    f"No data received for device ID {device_id} from URL: {url}"
                )

            # Increment request count
            self.request_count += 1

            # Calculate processing duration and publish metrics
            processing_duration = time.time() - request_processing_start

            logger_RESTObservationsDeviceCollector.debug(
                f"Publishing metrics: message_count={self.request_count}, errors={self.error_count}, duration={processing_duration}"
            )

            await utils.async_publish_metrics(
                self.event_manager,
                metric_name="handle_latest_device_observation",
                module_name=self.module_name,
                rate=self.request_count,
                errors=self.error_count,
                duration=processing_duration,
            )

        except Exception as e:
            self.error_count += 1  # Increment error count
            logger_RESTObservationsDeviceCollector.error(
                f"Error in retrieving data: {e}"
            )

            # Publish error metrics
            processing_duration = time.time() - request_processing_start

            logger_RESTObservationsDeviceCollector.debug(
                f"Publishing metrics: message_count={self.request_count}, errors={self.error_count}, duration={processing_duration}"
            )

            await utils.async_publish_metrics(
                self.event_manager,
                metric_name="handle_latest_device_observation",
                module_name=self.module_name,
                rate=self.request_count,
                errors=self.error_count,
                duration=processing_duration,
            )

    async def retrieve_and_save_data(self):
        station_metadata = utils.StationMetadataSingleton().get_metadata()
        tasks = []

        for station_id, station_info in station_metadata.items():
            # Check if the station is enabled
            if station_info.get("enabled", False):
                devices = station_info.get("devices", [])
                for device in devices:
                    # Check if the device is enabled and its type is not 'HB'
                    if (
                        device.get("enabled", False)
                        and device.get("device_type") != "HB"
                    ):
                        device_id = device["device_id"]
                        task = asyncio.create_task(
                            self.handle_latest_device_observation(device_id)
                        )
                        tasks.append(task)

        await asyncio.gather(*tasks)

    async def run_forever(self):
        logger_RESTObservationsDeviceCollector.info(
            "Starting RESTObservationsDeviceCollector in run_forever mode."
        )
        while True:
            start_time = asyncio.get_event_loop().time()
            await self.retrieve_and_save_data()
            elapsed_time = asyncio.get_event_loop().time() - start_time

            logger_RESTObservationsDeviceCollector.info(
                f"Execution of data retrieval and processing took {elapsed_time:.2f} seconds."
            )

            sleep_time = max(
                config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_OBSERVATIONS_INTERVAL
                - elapsed_time,
                0,
            )
            next_start_time = datetime.now() + timedelta(seconds=sleep_time)
            next_start_time_formatted = next_start_time.strftime("%Y-%m-%d %H:%M:%S")

            logger_RESTObservationsDeviceCollector.info(
                f"Sleeping for {sleep_time:.2f} seconds. Next cycle will start at approximately {next_start_time_formatted}."
            )

            await asyncio.sleep(sleep_time)
