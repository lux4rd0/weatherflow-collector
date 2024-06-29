import asyncio
import json
import os
from datetime import datetime, timedelta
import calendar
import pandas as pd
import time

import config
import utils.utils as utils
from utils.calculate_weather_metrics import CalculateWeatherMetrics
import logger

logger_ExportProcessor = logger.get_module_logger(__name__ + ".ExportProcessor")


class ExportProcessor:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        self.output_directory = config.WEATHERFLOW_COLLECTOR_EXPORT_CLIENT_EXPORT_FOLDER
        self.start_date = None
        self.end_date = None
        self.accumulated_data = {}
        self.failed_dates = {}  # Dictionary to track failed dates by segment
        self.task_semaphore = asyncio.Semaphore(
            config.WEATHERFLOW_COLLECTOR_EXPORT_CLIENT_EXPORT_TASKS
        )

        # Ensure the base output directory exists
        os.makedirs(self.output_directory, exist_ok=True)

        self.collector_type = "remote-export"
        self.field_mapping = {
            "timestamp": "timestamp",
            "report_interval": "report_interval",  # No direct equivalent, kept as is
            "wind_lull": "wind_lull",
            "wind_avg": "wind_avg",
            "wind_gust": "wind_gust",
            "wind_dir": "wind_direction",
            "station_pressure": "station_pressure",
            "sea_level_pressure": "sea_level_pressure",  # No direct equivalent, kept as is
            "air_temp": "air_temperature",
            "rh": "relative_humidity",
            "illuminance": "illuminance",
            "uv": "uv",
            "solar_radiation": "solar_radiation",
            "precip_accumulation": "rain_accumulated",
            "local_day_precip_accumulation": "local_daily_rain_accumulation",
            "precip_type": "precipitation_type",
            "strike_count": "lightning_strike_count",
            "strike_distance": "lightning_strike_avg_distance",
            "nc_precip_accumulation": "nc_precip_accumulation",  # No direct equivalent, kept as is
            "nc_local_day_precip_accumulation": "nc_local_day_precip_accumulation",  # No direct equivalent, kept as is
        }

    async def update_date_range(self, metadata):
        date_range = metadata.get("date_range", {})
        metadata_start_date_str = date_range.get("start")
        metadata_end_date_str = date_range.get("end")

        if metadata_start_date_str:
            metadata_start_date = datetime.strptime(
                metadata_start_date_str, "%Y-%m-%d"
            ).date()
            if self.start_date is None or metadata_start_date < self.start_date:
                self.start_date = metadata_start_date

        if metadata_end_date_str:
            metadata_end_date = datetime.strptime(
                metadata_end_date_str, "%Y-%m-%d"
            ).date()
            if self.end_date is None or metadata_end_date > self.end_date:
                self.end_date = metadata_end_date

        logger_ExportProcessor.debug(
            f"Updated date range: Start - {self.start_date}, End - {self.end_date}"
        )

    async def process_data(self, full_data):
        start_time = time.time()  # Start the timer

        logger_ExportProcessor.debug("Processing data in process_data method.")
        metadata = full_data.get("metadata", {})
        station_id = metadata.get("station_id", "unknown")

        station_info = full_data.get("station_info", {})
        logger_ExportProcessor.debug(f"station_info: {station_info}")
        await self.update_date_range(metadata)

        data = full_data.get("data", {})
        ob_fields = data.get("ob_fields", [])
        observations = data.get("obs", [])

        tasks = []
        for observation in observations:
            # Acquire a semaphore slot before creating a new task
            await self.task_semaphore.acquire()
            task = asyncio.create_task(
                self.process_observation(observation, ob_fields, metadata, station_info)
            )
            task.add_done_callback(lambda t: self.task_semaphore.release())
            tasks.append(task)

        # Wait for all tasks to complete
        await asyncio.gather(*tasks)

        # Create a static list of keys to avoid modifying the dictionary during iteration
        segment_keys = list(self.accumulated_data.keys())
        for segment_key in list(self.accumulated_data.get(station_id, {}).keys()):
            if await self.is_segment_complete(station_id, segment_key):
                await self.export_data_for_segment(
                    station_id, segment_key, metadata, station_info
                )

        end_time = time.time()  # End the timer
        processing_duration = end_time - start_time
        logger_ExportProcessor.debug(
            f"Processing completed in {processing_duration} seconds."
        )

    async def process_observation(self, observation, ob_fields, metadata, station_info):
        fields = {
            self.field_mapping.get(k, k): v for k, v in zip(ob_fields, observation)
        }
        fields = utils.normalize_fields(fields)
        additional_metrics = CalculateWeatherMetrics.calculate_weather_metrics(fields)
        fields.update(additional_metrics)

        observation_date_str = self.extract_date(fields)
        await self.store_observation_by_date(fields, observation_date_str, station_info)

    def extract_date(self, observation):
        timestamp = observation.get("timestamp")
        return datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d")

    async def is_segment_complete(self, station_id, segment_key):
        try:
            year, month = map(int, segment_key.split("-"))
            start_of_month = datetime(year, month, 1).date()
            end_of_month = datetime(
                year, month, calendar.monthrange(year, month)[1]
            ).date()
        except ValueError:
            # Handle case when segment_key is just a year
            year = int(segment_key)
            start_of_month = datetime(year, 1, 1).date()
            end_of_month = datetime(year, 12, 31).date()

        # Adjust the start and end dates of the segment based on the overall date range
        start_of_segment = (
            max(start_of_month, self.start_date) if self.start_date else start_of_month
        )
        end_of_segment = (
            min(end_of_month, self.end_date) if self.end_date else end_of_month
        )

        # Generate expected dates for the segment
        expected_dates = {
            start_of_segment + timedelta(days=i)
            for i in range((end_of_segment - start_of_segment).days + 1)
        }
        expected_dates_str = {date.strftime("%Y-%m-%d") for date in expected_dates}

        received_dates = {
            self.extract_date(obs)
            for obs in self.accumulated_data.get(station_id, {}).get(segment_key, [])
        }
        failed_dates_for_segment = self.failed_dates.get(station_id, {}).get(
            segment_key, set()
        )

        all_dates_accounted_for = expected_dates_str.issubset(
            received_dates.union(failed_dates_for_segment)
        )
        return all_dates_accounted_for

    async def store_observation_by_date(
        self, fields, observation_date_str, station_info
    ):
        station_id = station_info.get("station_id", "unknown")
        date_obj = datetime.strptime(observation_date_str, "%Y-%m-%d")
        segment_key = (
            date_obj.strftime("%Y-%m")
            if config.WEATHERFLOW_COLLECTOR_PROCESSOR_EXPORT_BUCKET == "month"
            else date_obj.strftime("%Y")
        )

        if station_id not in self.accumulated_data:
            self.accumulated_data[station_id] = {}
        if segment_key not in self.accumulated_data[station_id]:
            self.accumulated_data[station_id][segment_key] = []

        self.accumulated_data[station_id][segment_key].append(fields)

    async def export_data_for_segment(
        self, station_id, segment_key, metadata, station_info
    ):
        logger_ExportProcessor.debug(f"station_info: {station_info}")
        if segment_key in self.accumulated_data[station_id]:
            segment_data = self.accumulated_data[station_id][segment_key]
            df = pd.DataFrame(segment_data)
            await self.export_dataframe(
                df, station_id, segment_key, metadata, station_info
            )
            del self.accumulated_data[station_id][segment_key]
        else:
            logger_ExportProcessor.warning(f"No data found for segment: {segment_key}")

    async def export_dataframe(
        self, df, station_id, segment_key, metadata, station_info
    ):
        logger_ExportProcessor.debug(f"station_info: {station_info}")
        logger_ExportProcessor.debug(
            f"Preparing to export dataframe for segment: {segment_key}"
        )

        # Directly access the station_name from station_info
        station_name = station_info.get("station_name", "unknown").replace(" ", "_")

        station_dir = os.path.join(self.output_directory, station_name)
        if not os.path.exists(station_dir):
            os.makedirs(station_dir)

        file_name = f"data_{station_name}_{segment_key}"
        file_extension = (
            "csv"
            if config.WEATHERFLOW_COLLECTOR_PROCESSOR_EXPORT_TYPE.lower() == "csv"
            else "xlsx"
        )
        full_filename = os.path.join(station_dir, f"{file_name}.{file_extension}")

        if config.WEATHERFLOW_COLLECTOR_PROCESSOR_EXPORT_TYPE.lower() == "csv":
            df.to_csv(full_filename, index=False, float_format="%.6f")
        else:
            df.to_excel(full_filename, index=False)

        logger_ExportProcessor.info(f"Saved data to {full_filename}")

    def handle_failure(self, metadata):
        """Handle a failure event by marking the date as failed."""
        station_id = metadata.get("station_id", "unknown")
        failed_date_str = metadata.get("date", "")

        failed_date_obj = datetime.strptime(failed_date_str, "%Y-%m-%d")
        segment_key = (
            failed_date_obj.strftime("%Y-%m")
            if config.WEATHERFLOW_COLLECTOR_PROCESSOR_EXPORT_BUCKET == "month"
            else failed_date_obj.strftime("%Y")
        )

        # Add the failed date to the set of failed dates
        self.failed_dates.setdefault(station_id, {}).setdefault(segment_key, set()).add(
            failed_date_str
        )
        logger_ExportProcessor.warning(
            f"Marked {failed_date_str} as failed for station {station_id}, segment {segment_key}."
        )

    async def update(self, event_data):
        logger_ExportProcessor.debug("Received new event data for export.")
        metadata = event_data.get("metadata", {})
        status = metadata.get("status")

        logger_ExportProcessor.debug(f"metadata: {metadata}")

        if status == "failure":
            # Handle the failure event
            self.handle_failure(metadata)
        else:
            # Process the data for successful events or if the status is not specified
            await self.process_data(event_data)
