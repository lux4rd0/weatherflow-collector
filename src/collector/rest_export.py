# collector_rest_export.py


import aiohttp
import asyncio
import logging
from datetime import datetime, timedelta
import config
import utils.utils as utils
import json
from zoneinfo import ZoneInfo

import time

import logger

logger_RestExportCollector = logger.get_module_logger(__name__ + ".RestExportCollector")


class RestExportCollector:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        self.api_key = config.WEATHERFLOW_COLLECTOR_API_TOKEN
        self.base_url = config.WEATHERFLOW_API_REST_IMPORT_URL
        self.stats_url = (
            config.WEATHERFLOW_API_REST_STATS_URL
        )  # URL for fetching statistics
        self.module_name = "collector_rest_export"
        self.collector_type = "collector_rest_export"

    async def make_api_request(self, url):
        try:
            logger_RestExportCollector.debug(f"Making API request to {url}")
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    url, headers={"accept": "application/json"}, timeout=10
                ) as response:
                    if response.status == 200:
                        logger_RestExportCollector.debug("API request successful")
                        return await response.text()
                    else:
                        logger_RestExportCollector.warning(
                            f"API request failed: Status code {response.status}, Response: {await response.text()}"
                        )
                        return None
        except aiohttp.ClientError as e:
            logger_RestExportCollector.error(f"API request exception: {e}")
            return None

    async def fetch_data(self, url):
        logger_RestExportCollector.debug(f"Fetching data from URL: {url}")
        return await self.make_api_request(url)

    async def fetch_daily_observations(
        self, station_id, specific_date, semaphore, date_range, station_metadata
    ):
        async with semaphore:  # Using semaphore to control concurrency

            # Retrieve station time_zone from metadata
            station_time_zone = station_metadata[station_id].get("time_zone")
            if not station_time_zone:
                logger_RestExportCollector.error(
                    f"Time zone information missing for station ID {station_id}"
                )
                return

            # Get the OS time_zone
            os_time_zone = datetime.now().astimezone().tzinfo

            # Log both time_zones
            logger_RestExportCollector.debug(
                f"OS Time zone: {os_time_zone}, Station Time zone: {station_time_zone}"
            )

            # Convert the specific date to time zone-aware datetime objects using ZoneInfo
            time_zone = ZoneInfo(station_time_zone)
            start_date = datetime.strptime(specific_date, "%Y-%m-%d").replace(
                tzinfo=time_zone
            )
            end_date = start_date + timedelta(days=1, seconds=-1)

            # Convert time zone-aware datetime objects to epoch time
            start_epoch = int(start_date.timestamp())
            end_epoch = int(end_date.timestamp())

            # Construct the API URL for daily observations
            endpoint = f"/stn/{station_id}"
            query_parameters = (
                f"?time_start={start_epoch}&time_end={end_epoch}"
                "&bucket=1&units_temp=c&units_wind=mps&units_pressure=mb"
                "&units_precip=mm&units_distance=km"
            )
            api_key_parameter = f"&api_key={self.api_key}"
            url_daily_observations = (
                f"{self.base_url}{endpoint}{query_parameters}{api_key_parameter}"
            )

            logger_RestExportCollector.debug(
                f"Fetching daily observations for station ID {station_id} and date {specific_date} from URL: {url_daily_observations}"
            )

            json_data = await self.fetch_data(url_daily_observations)
            if json_data:
                data = json.loads(json_data)

                if "obs" in data and len(data["obs"]) > 0:
                    data_with_metadata = {
                        "metadata": {
                            "collector_type": self.collector_type,
                            "station_id": station_id,
                            "date": specific_date,
                            "date_range": date_range,
                            "status": "success",
                        },
                        "data": data,
                    }
                    await self.event_manager.publish(
                        "collector_data_event",
                        data_with_metadata,
                        publisher="RestExportCollector.fetch_daily_observations",
                    )
                    logger_RestExportCollector.info(
                        f"Published daily observations for station ID {station_id} and date {specific_date} to event manager"
                    )
                else:
                    await self.event_manager.publish(
                        "collector_data_event",
                        {
                            "metadata": {
                                "collector_type": self.collector_type,
                                "station_id": station_id,
                                "date": specific_date,
                                "date_range": date_range,
                                "status": "failure",
                                "reason": "Data validation failed: 'obs' array is empty or missing.",
                            }
                        },
                        publisher="RestExportCollector.fetch_daily_observations",
                    )
                    logger_RestExportCollector.warning(
                        f"Data validation failed for station ID {station_id} and date {specific_date}."
                    )
            else:
                await self.event_manager.publish(
                    "collector_data_event",
                    {
                        "metadata": {
                            "collector_type": self.collector_type,
                            "station_id": station_id,
                            "date": specific_date,
                            "date_range": date_range,
                            "status": "failure",
                            "reason": "No data received or API call failed.",
                        }
                    },
                    publisher="RestExportCollector.fetch_daily_observations",
                )
                logger_RestExportCollector.warning(
                    f"No daily observation data received for station ID {station_id} and date {specific_date}."
                )

    async def fetch_date_range(self, station_id):
        # Construct the URL to fetch statistics for the station
        url = f"{self.stats_url}/station/{station_id}?api_key={self.api_key}"
        logger_RestExportCollector.debug(
            f"Fetching statistics for station ID {station_id} from URL: {url}"
        )

        json_data_stats = await self.fetch_data(url)
        if json_data_stats:
            parsed_data_stats = json.loads(json_data_stats)
            start_date = datetime.strptime(
                parsed_data_stats.get("first_ob_day_local"), "%Y-%m-%d"
            )
            end_date = datetime.strptime(
                parsed_data_stats.get("last_ob_day_local"), "%Y-%m-%d"
            )
            return start_date, end_date
        else:
            logger_RestExportCollector.warning(
                f"No statistics data received for station ID {station_id}"
            )
            return None, None

    async def process_stations(self, station_metadata):
        semaphore = asyncio.Semaphore(
            config.WEATHERFLOW_COLLECTOR_REST_EXPORT_FETCH_OBSERVATIONS_WORKERS
        )

        for station_id, station_info in station_metadata.items():
            if station_info.get("enabled", False):
                first_date, last_date = await self.fetch_date_range(station_id)

                if first_date and last_date:
                    date_range = {
                        "start": first_date.strftime("%Y-%m-%d"),
                        "end": last_date.strftime("%Y-%m-%d"),
                    }

                    tasks = []  # Initialize a list to collect tasks
                    current_date = first_date

                    while current_date <= last_date:
                        task = self.fetch_daily_observations(
                            station_id,
                            current_date.strftime("%Y-%m-%d"),
                            semaphore,
                            date_range,
                            station_metadata,  # Pass station_info to the method
                        )
                        tasks.append(task)
                        current_date += timedelta(days=1)

                    # Await all tasks concurrently
                    await asyncio.gather(*tasks)
                else:
                    logger_RestExportCollector.warning(
                        f"No valid date range available for station ID {station_id}"
                    )

    async def run_once(self):
        logger_RestExportCollector.info(
            "Starting RestExportCollector for a single run."
        )
        start_time = datetime.now()
        await self.process_stations(utils.StationMetadataSingleton().get_metadata())
        elapsed_time = datetime.now() - start_time

        logger_RestExportCollector.info(
            f"Execution of data retrieval and processing took {elapsed_time.total_seconds():.2f} seconds."
        )
