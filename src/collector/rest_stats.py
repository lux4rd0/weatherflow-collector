# collector_rest_stats.py

import asyncio
import logging
from datetime import datetime, timedelta
import time

import config
import utils.utils as utils

import logger

logger_RestStatsCollector = logger.get_module_logger(__name__ + ".RestStatsCollector")


class RestStatsCollector:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        self.api_key = config.WEATHERFLOW_COLLECTOR_API_TOKEN
        self.base_url = config.WEATHERFLOW_API_REST_STATS_URL
        self.collector_type = "collector_rest_stats"
        self.request_count = 0  # Counter for processed requests
        self.error_count = 0  # Counter for errors
        self.module_name = "collector_rest_stats"

    async def fetch_stats(self, station_id):
        request_processing_start = time.time()  # Start time for processing

        try:
            url = f"{self.base_url}/station/{station_id}?api_key={self.api_key}"
            logger_RestStatsCollector.debug(
                f"Fetching data for station ID {station_id} from URL: {url}"
            )

            json_data = await utils.fetch_data_from_url(
                url, self.collector_type, self.event_manager
            )

            if json_data:
                logger_RestStatsCollector.debug(
                    f"Received JSON data for station ID {station_id}"
                )

                # Wrap the data with metadata
                data_with_metadata = {
                    "metadata": {
                        "collector_type": self.collector_type,
                        "station_id": station_id,
                    },
                    "data": json_data,
                }

                # logger_RestStatsCollector.debug(
                #    f"Data with metadata to be published: {data_with_metadata}"
                # )
                await self.event_manager.publish(
                    "collector_data_event",
                    data_with_metadata,
                    publisher="RestStatsCollector.fetch_stats",
                )
                logger_RestStatsCollector.debug(
                    f"Published data to event manager for station ID {station_id}"
                )
            else:
                logger_RestStatsCollector.warning(
                    f"No data received for station ID {station_id} from URL: {url}"
                )

            # Increment request count
            self.request_count += 1

            # Calculate processing duration and publish metrics
            processing_duration = time.time() - request_processing_start

            logger_RestStatsCollector.debug(
                f"Publishing metrics: request_count={self.request_count}, errors={self.error_count}, duration={processing_duration}"
            )

            await utils.async_publish_metrics(
                self.event_manager,
                metric_name="fetch_stats",
                module_name=self.module_name,
                rate=self.request_count,
                errors=self.error_count,
                duration=processing_duration,
            )

        except Exception as e:
            self.error_count += 1  # Increment error count
            logger_RestStatsCollector.error(f"Error in retrieving data: {e}")

            # Publish error metrics
            processing_duration = time.time() - request_processing_start

            logger_RestStatsCollector.debug(
                f"Publishing metrics: request_count={self.request_count}, errors={self.error_count}, duration={processing_duration}"
            )

            await utils.async_publish_metrics(
                self.event_manager,
                metric_name="fetch_stats",
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
                task = asyncio.create_task(self.fetch_stats(station_id))
                tasks.append(task)
        await asyncio.gather(*tasks)

    def calculate_sleep_time(self):
        now = datetime.now()
        next_midnight = datetime(now.year, now.month, now.day) + timedelta(days=1)
        sleep_time_seconds = (next_midnight - now).total_seconds()
        return sleep_time_seconds, next_midnight

    async def on_external_notification(self, station_id):
        # This method will be triggered by an external notification, like a config file update
        await self.fetch_stats(station_id)

    async def run_forever(self):
        logger_RestStatsCollector.info(
            "Starting RestStatsCollector in run_forever mode."
        )
        while True:
            # Run once at startup
            await self.retrieve_and_save_data()

            # Calculating the time until next midnight and the next start time
            sleep_time_seconds, next_start_time = self.calculate_sleep_time()
            sleep_hours = sleep_time_seconds // 3600
            sleep_minutes = (sleep_time_seconds % 3600) // 60

            logger_RestStatsCollector.info(
                f"Sleeping for approximately {int(sleep_hours)} hours and {int(sleep_minutes)} minutes. "
                f"Next cycle will start at approximately {next_start_time.strftime('%Y-%m-%d %H:%M:%S')}."
            )

            await asyncio.sleep(sleep_time_seconds)
