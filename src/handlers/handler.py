# handler.py

import config
import time
import os
import asyncio

import logger
import utils.utils as utils

from .rest_forecasts import RESTForecastsHandler
from .rest_import import RESTImportHandler
from .rest_observations_device import RESTObservationsDeviceHandler
from .rest_observations_station import RESTObservationsStationHandler
from .rest_stats import RESTStatsHandler
from .websocket import WebSocketHandler
from .udp import UDPHandler

logger_Handler = logger.get_module_logger(__name__ + ".Handler")


class Handler:
    def __init__(self, event_manager):

        self.event_manager = event_manager
        self.handlers = {
            "collector_udp": UDPHandler(event_manager),
            "collector_rest_observations_device": RESTObservationsDeviceHandler(
                event_manager
            ),
            "collector_rest_observations_station": RESTObservationsStationHandler(
                event_manager
            ),
            "collector_rest_forecasts": RESTForecastsHandler(event_manager),
            "collector_websocket": WebSocketHandler(event_manager),
            "collector_rest_stats": RESTStatsHandler(event_manager),
            "collector_rest_import": RESTImportHandler(event_manager),
        }

        self.module_name = "handler"
        self.collector_type = "handler"

        self.tasks_by_collector_type = {}
        self.metrics_by_collector_type = {}

    async def update(self, full_data):
        request_processing_start = time.time()

        metadata = full_data.get("metadata", {})
        collector_type = metadata.get("collector_type")
        metric_name = (
            f"update_{collector_type}"  # Define metric_name based on collector_type
        )

        logger_Handler.debug(f"Received full_data for collector type: {collector_type}")

        handler = self.handlers.get(collector_type)
        if handler:
            # Directly creating an asyncio task for the async handler method
            task = asyncio.create_task(handler.process_data(full_data))
            task.collector_type = collector_type  # Assign collector_type to the task for later identification

            if collector_type not in self.tasks_by_collector_type:
                self.tasks_by_collector_type[collector_type] = []

            self.tasks_by_collector_type[collector_type].append(task)
            task.add_done_callback(self.task_done_callback)

            if collector_type not in self.metrics_by_collector_type:
                self.metrics_by_collector_type[collector_type] = {
                    "request_count": 0,
                    "error_count": 0,
                    "active_tasks": 0,
                }
            self.metrics_by_collector_type[collector_type]["request_count"] += 1
            self.metrics_by_collector_type[collector_type]["active_tasks"] += 1

            logger_Handler.debug(
                f"Active tasks for {collector_type}: {self.metrics_by_collector_type[collector_type]['active_tasks']}"
            )
        else:
            logger_Handler.error(
                f"No handler found for collector type: {collector_type}"
            )

        processing_duration = time.time() - request_processing_start
        logger_Handler.debug(
            f"Publishing metrics for {collector_type}: "
            f"message_count={self.metrics_by_collector_type[collector_type]['request_count']}, "
            f"errors={self.metrics_by_collector_type[collector_type]['error_count']}, "
            f"duration={processing_duration}"
        )
        await utils.async_publish_metrics(
            self.event_manager,
            metric_name=metric_name,
            module_name=self.module_name,
            rate=self.metrics_by_collector_type[collector_type]["request_count"],
            errors=self.metrics_by_collector_type[collector_type]["error_count"],
            active_tasks=self.metrics_by_collector_type[collector_type]["active_tasks"],
            duration=processing_duration,
        )

    def task_done_callback(self, task):
        collector_type = getattr(task, "collector_type", "Unknown")

        if task.exception():
            logger_Handler.error(
                f"Task for {collector_type} raised an exception: {task.exception()}"
            )

        if collector_type in self.tasks_by_collector_type:
            try:
                self.tasks_by_collector_type[collector_type].remove(task)
                self.metrics_by_collector_type[collector_type]["active_tasks"] = max(
                    0,
                    self.metrics_by_collector_type[collector_type]["active_tasks"] - 1,
                )
                logger_Handler.debug(
                    f"Active tasks for {collector_type}: {self.metrics_by_collector_type[collector_type]['active_tasks']}"
                )
            except ValueError:
                pass  # Task was already removed or not found

    async def close(self):
        # Close method updated to correctly handle remaining tasks
        for tasks in self.tasks_by_collector_type.values():
            if tasks:
                await asyncio.wait(tasks)
