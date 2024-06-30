# collector_rest_observations_device.py

import asyncio
from datetime import datetime, timedelta
import time

import config
import utils.utils as utils
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
        request_processing_start = time.time()
        processing_duration = 0

        try:
            url = f"{self.base_url}/device/{device_id}?api_key={self.api_key}"
            logger_RESTObservationsDeviceCollector.debug(
                f"Fetching data for device ID {device_id}"
            )

            json_data = await utils.fetch_data_from_url(
                url, self.collector_type, self.event_manager
            )

            if not json_data:
                logger_RESTObservationsDeviceCollector.warning(
                    f"No data received for device ID {device_id}"
                )
                return

            # Check if the response contains the expected data
            if json_data.get("obs") is None or json_data.get("device_id") is None:
                logger_RESTObservationsDeviceCollector.warning(
                    f"Incomplete data received for device ID {device_id}: {json_data}"
                )
                return

            logger_RESTObservationsDeviceCollector.debug(
                f"Received valid JSON data for device ID {device_id}"
            )

            data_with_metadata = {
                "metadata": {
                    "collector_type": self.collector_type,
                    "device_id": device_id,
                },
                "data": json_data,
            }

            await self.event_manager.publish(
                "collector_data_event",
                data_with_metadata,
                publisher=f"{self.__class__.__name__}.handle_latest_device_observation",
            )
            logger_RESTObservationsDeviceCollector.debug(
                f"Published data for device ID {device_id}"
            )

            self.request_count += 1

        except Exception as e:
            self.error_count += 1
            logger_RESTObservationsDeviceCollector.error(
                f"Error processing device ID {device_id}: {e}"
            )

        finally:
            processing_duration = time.time() - request_processing_start

            logger_RESTObservationsDeviceCollector.debug(
                f"Metrics: messages={self.request_count}, errors={self.error_count}, duration={processing_duration:.2f}s"
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
        try:
            station_metadata = utils.StationMetadataSingleton().get_metadata()
            tasks = []

            for station_id, station_info in station_metadata.items():
                if station_info.get("enabled", False):
                    devices = station_info.get("devices", [])
                    for device in devices:
                        if (
                            device.get("enabled", False)
                            and device.get("device_type") != "HB"
                        ):
                            device_id = device.get("device_id")
                            if device_id:
                                task = asyncio.create_task(
                                    self.handle_latest_device_observation(device_id)
                                )
                                tasks.append(task)

            await asyncio.gather(*tasks)
        except Exception as e:
            logger_RESTObservationsDeviceCollector.error(
                f"Error in retrieve_and_save_data: {e}"
            )

    async def run_forever(self):
        logger_RESTObservationsDeviceCollector.info(
            "Starting RESTObservationsDeviceCollector in run_forever mode."
        )
        try:
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
                next_start_time_formatted = next_start_time.strftime(
                    "%Y-%m-%d %H:%M:%S"
                )

                logger_RESTObservationsDeviceCollector.info(
                    f"Sleeping for {sleep_time:.2f} seconds. Next cycle will start at approximately {next_start_time_formatted}."
                )

                await asyncio.sleep(sleep_time)
        except asyncio.CancelledError:
            logger_RESTObservationsDeviceCollector.info(
                "RESTObservationsDeviceCollector received cancellation signal."
            )
        except Exception as e:
            logger_RESTObservationsDeviceCollector.error(
                f"Unexpected error in run_forever: {e}"
            )
        finally:
            logger_RESTObservationsDeviceCollector.info(
                "RESTObservationsDeviceCollector shutting down."
            )
