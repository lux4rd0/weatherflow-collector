import aiohttp
import asyncio
import logging
from datetime import datetime, timedelta
import config
import utils.utils as utils
import json
import time

import logger

logger_RestImportClient = logger.get_module_logger(__name__ + ".RestImportCollector")


class RestImportCollector:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        self.api_key = config.WEATHERFLOW_COLLECTOR_API_TOKEN
        self.base_url = config.WEATHERFLOW_API_REST_IMPORT_URL
        self.stats_url = config.WEATHERFLOW_API_REST_STATS_URL
        self.module_name = "collector_rest_import"
        self.collector_type = "collector_rest_import"

    async def fetch_daily_observations(self, station_id, specific_date):
        try:
            # Convert the specific date to epoch time for start and end of the day
            start_epoch = int(datetime.strptime(specific_date, "%Y-%m-%d").timestamp())
            end_epoch = start_epoch + 86400 - 1  # End of the day in epoch time

            # Construct the API URL for daily observations
            endpoint = f"/stn/{station_id}"
            query_parameters = f"?time_start={start_epoch}&time_end={end_epoch}&bucket=1&units_temp=c&units_wind=mps&units_pressure=mb&units_precip=mm&units_distance=km"
            api_key_parameter = f"&api_key={self.api_key}"
            url_daily_observations = (
                f"{self.base_url}{endpoint}{query_parameters}{api_key_parameter}"
            )

            logger_RestImportClient.debug(
                f"Fetching daily observations for station ID {station_id} and date {specific_date} from URL: {url_daily_observations}"
            )

            response_data = await utils.fetch_data_from_url(
                url_daily_observations, self.collector_type, self.event_manager
            )
            if response_data:
                json_data = json.dumps(
                    response_data
                )  # Convert dictionary to JSON string
                data_with_metadata = {
                    "metadata": {
                        "collector_type": self.collector_type,
                        "station_id": station_id,
                    },
                    "data": json.loads(json_data),
                }
                await self.event_manager.publish(
                    "collector_data_event",
                    data_with_metadata,
                    publisher="RestImportCollector.fetch_daily_observations",
                )
                logger_RestImportClient.info(
                    f"Published daily observations for station ID {station_id} and date {specific_date} to event manager"
                )
                return json_data  # Added to return the fetched JSON data
            else:
                logger_RestImportClient.warning(
                    f"No daily observation data received for station ID {station_id} and date {specific_date}"
                )
                return None

        except Exception as e:
            logger_RestImportClient.error(f"Error fetching daily observations: {e}")
            return None
        finally:

            pass
            # Add a delay between requests
            # delay_duration_ms = config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_IMPORT_FETCH_OBSERVATIONS_DELAY_MS
            # logger_RestImportClient.debug(f"Sleeping for {delay_duration_ms} milliseconds before next request...")
            # start_sleep_time = time.monotonic()  # Record the start time of the sleep
            # await asyncio.sleep(delay_duration_ms / 1000)  # Convert milliseconds to seconds for asyncio.sleep
            # end_sleep_time = time.monotonic()  # Record the end time of the sleep
            # sleep_duration = end_sleep_time - start_sleep_time
            # logger_RestImportClient.debug(f"Finished sleeping. Slept for {sleep_duration:.2f} seconds.")

    async def fetch_date_range(self, station_id):
        try:
            url = f"{self.stats_url}/station/{station_id}?api_key={self.api_key}"
            logger_RestImportClient.debug(
                f"Fetching statistics for station ID {station_id} from URL: {url}"
            )

            response_data = await utils.fetch_data_from_url(
                url, "collector_rest_import", self.event_manager
            )
            if response_data:
                json_data_stats = json.dumps(response_data)
                parsed_data_stats = json.loads(json_data_stats)
                start_date = datetime.strptime(
                    parsed_data_stats.get("first_ob_day_local"), "%Y-%m-%d"
                )
                end_date = datetime.strptime(
                    parsed_data_stats.get("last_ob_day_local"), "%Y-%m-%d"
                )
                return start_date, end_date
            else:
                logger_RestImportClient.warning(
                    f"No statistics data received for station ID {station_id}"
                )
                return None, None
        except Exception as e:
            logger_RestImportClient.error(f"Error fetching date range: {e}")
            return None, None

    async def process_stations(self, station_metadata):
        try:
            num_workers = (
                config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_IMPORT_FETCH_WORKERS
            )
            semaphore = asyncio.Semaphore(num_workers)
            tasks = []

            for station_id, station_info in station_metadata.items():
                if station_info.get("enabled", False):
                    first_date, last_date = await self.fetch_date_range(station_id)

                    if first_date and last_date:
                        current_date = first_date
                        end_date = last_date

                        while current_date <= end_date:
                            formatted_date = current_date.strftime("%Y-%m-%d")
                            task = asyncio.create_task(
                                self.fetch_daily_observations_with_semaphore(
                                    semaphore, station_id, formatted_date
                                )
                            )
                            tasks.append(task)
                            current_date += timedelta(days=1)

            if tasks:
                await asyncio.gather(*tasks)
            else:
                logger_RestImportClient.warning("No tasks created for processing.")

        except Exception as e:
            logger_RestImportClient.error(f"Error processing stations: {e}")

    async def fetch_daily_observations_with_semaphore(
        self, semaphore, station_id, specific_date
    ):
        async with semaphore:
            await self.fetch_daily_observations(station_id, specific_date)

    async def run_once(self):
        try:
            logger_RestImportClient.info(
                "Starting RestImportCollector for a single run."
            )
            start_time = datetime.now()
            await self.process_stations(utils.StationMetadataSingleton().get_metadata())
            elapsed_time = datetime.now() - start_time

            logger_RestImportClient.info(
                f"Execution of data retrieval and processing took {elapsed_time.total_seconds():.2f} seconds."
            )
        except Exception as e:
            logger_RestImportClient.error(f"Error in run_once: {e}")
