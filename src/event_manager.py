# event_manager.py

"""
EventManager Module for WeatherFlow Collector

This module provides the core functionality for event management in the WeatherFlow Collector system. 
It facilitates the subscription and notification of various clients (such as data handlers and clients) 
to specific event types, especially for handling meteorological data from different sources.

Key Features:
- Manages subscriptions for different event types, allowing various clients to receive specific data updates.
- Supports asynchronous data publishing to handle real-time data efficiently.
- Offers flexibility in handling both synchronous and asynchronous collector update methods.

Usage:
The EventManager is used to manage data flow within the WeatherFlow Collector system. Clients subscribe 
to the EventManager, specifying the types of events they are interested in. When data is published to an 
event type, all subscribed clients are notified and can process the data as required.

Dependencies:
- asyncio: For managing asynchronous operations and tasks.
- inspect: To introspect collector methods and determine if they are asynchronous.
- threading: For running asynchronous tasks in a separate thread when needed.
- logger: Custom logging for tracking events and errors.

Components:
- EventManager: Central class responsible for managing event subscriptions and data publication.

Methods:
- subscribe: Allows clients to subscribe to specific event types.
- publish: Asynchronously publishes data to all subscribers of a given event type.
- run_async_method: A utility method to run asynchronous methods, handling different loop scenarios.

Author: [Your Name or Team's Name]
Last Update: [Last Update Date]

Note:
EventManager is a crucial component of the WeatherFlow Collector, ensuring smooth and efficient data flow 
across various parts of the system. Its implementation can be adapted for other systems requiring similar 
event-driven architectures.
"""


import asyncio
import inspect
import threading
import logger
import time

import utils.utils as utils
import config

logger_EventManager = logger.get_module_logger(__name__ + ".EventManager")


class EventManager:
    def __init__(self):
        self.subscribers = {}
        self.loop = asyncio.get_event_loop()
        self.shutdown_flag = False
        self.max_retries = config.WEATHERFLOW_COLLECTOR_EVENT_MANAGER_MAX_RETRIES
        self.retry_delay = config.WEATHERFLOW_COLLECTOR_EVENT_MANAGER_RETRY_DELAY
        # self.metrics_lock = asyncio.Lock()  # Lock for thread-safe metric updates
        self.is_metric_event_processing = (
            False  # Flag to indicate metric event processing
        )

        self.error_count = 0  # Counter for errors
        self.event_count = 0  # Counter for errors
        self.module_name = "event_manager"

    def subscribe(self, event_type, collector):
        """Subscribe a collector to a specific type of event."""
        if not hasattr(collector, "update") or not callable(
            getattr(collector, "update")
        ):
            logger_EventManager.error(
                f"collector {collector.__class__.__name__} does not have a callable 'update' method."
            )
            return

        if collector not in self.subscribers.setdefault(event_type, []):
            self.subscribers[event_type].append(collector)
            collector_info = f"{collector.__class__.__name__}"
            logger_EventManager.info(
                f"collector {collector_info} subscribed to event type: {event_type}"
            )

    async def publish(self, event_type, data, publisher=None):
        """Asynchronously publish data to all collectors subscribed to the event type."""
        logger_EventManager.debug(
            f"Received event type: {event_type}, data: {data}, publisher: {publisher}"
        )

        if self.shutdown_flag:
            logger_EventManager.warning(
                "EventManager is shutting down. No more events are published."
            )
            return

        if event_type == "system_metrics_event":
            if self.is_metric_event_processing:
                return  # Avoid recursion if already processing a metric event
            self.is_metric_event_processing = True

        start_time = time.time()  # Record start time for duration calculation

        for collector in self.subscribers.get(event_type, []):
            collector_info = f"{collector.__class__.__name__}"
            retries = 0
            while retries < self.max_retries:
                try:
                    if inspect.iscoroutinefunction(collector.update):
                        await collector.update(data)
                    else:
                        collector.update(data)
                    logger_EventManager.debug(
                        f"Published data to {collector_info} for event {event_type} (Published by: {publisher})"
                    )
                    break  # Successful update, exit retry loop
                except Exception as e:
                    logger_EventManager.error(
                        f"Error updating collector {collector_info} for {event_type}: {e}"
                    )
                    self.error_count += 1
                    retries += 1
                    if retries < self.max_retries:
                        logger_EventManager.warning(
                            f"Retrying update for collector {collector_info}, attempt {retries}/{self.max_retries}."
                        )
                        await asyncio.sleep(self.retry_delay)

        duration = time.time() - start_time  # Calculate event duration
        self.event_count += 1  # Increment event count for rate calculation

        if event_type == "system_metrics_event":
            self.is_metric_event_processing = False

        if event_type != "system_metrics_event":
            # Debugging: Output details before publishing metrics
            logger_EventManager.debug(
                f"Publishing metrics: metric_name='publish_event', module_name={self.module_name}, rate={self.event_count}, errors={self.error_count}, duration={duration}"
            )

            try:
                await utils.async_publish_metrics(
                    self,
                    metric_name="publish_event",
                    module_name=self.module_name,
                    rate=self.event_count,
                    errors=self.error_count,
                    duration=duration,
                )
            except Exception as e:
                logger_EventManager.error(f"Failed to publish metrics: {e}")

    def run_async_method(self, coro):
        """Helper function to run an asynchronous coroutine."""
        if self.loop.is_running():
            asyncio.create_task(coro)
        else:
            # Start a new event loop for the coroutine
            new_loop = asyncio.new_event_loop()
            t = threading.Thread(target=new_loop.run_until_complete, args=(coro,))
            t.start()
            t.join()
            new_loop.close()

    def shutdown(self):
        """Shut down the EventManager gracefully."""
        self.shutdown_flag = True
        logger_EventManager.info("EventManager is shutting down.")

        # Perform any cleanup if necessary
        # ...

        # Close the event loop if it's not closed
        if not self.loop.is_closed():
            self.loop.close()
            logger_EventManager.info("Event loop closed.")
