# collector_websocket.py

"""
WeatherFlow Collector WebSocket Client

This module is part of the WeatherFlow Collector system and is responsible for managing WebSocket
connections to receive real-time weather data. It handles the establishment of the WebSocket 
connection, authentication, message reception, and forwarding the data to the appropriate 
event manager for further processing.

Key Features:
- Automatic WebSocket connection management with reconnection logic.
- Authentication handling with WeatherFlow API token.
- Real-time data reception and forwarding to an event manager.
- Subscription management for specific WeatherFlow devices.

Usage:
This WebSocket collector is designed to be used within the WeatherFlow Collector system. It requires
a valid API token and a configured WebSocket URL to establish a connection with the WeatherFlow 
WebSocket server.

Dependencies:
- websockets: For handling WebSocket connections.
- asyncio: For asynchronous programming.
- json: For JSON parsing and formatting.
- config: Custom module for configuration settings.
- logger: Custom module for logging.
- utils: Utilties.

Classes:
- WebsocketCollector: Manages WebSocket connections and data handling.

Methods:
- establish_connection(): Establishes and maintains a WebSocket connection.
- authenticate(): Sends an authentication message to the WebSocket server.
- receive_and_forward_messages(): Listens for messages and forwards them to an event manager.
- handle_connection_opened(): Handles actions when a connection is opened.
- subscribe_to_device(device_id): Subscribes to a specific device's data.
- close_connection(): Closes the WebSocket connection.
- start(): Initiates the WebSocket collector and starts data reception.
- update(data): Updates the collector with new configuration data.

Author: [Your Name or Team's Name]
Last Update: [Last Update Date]

Note:
The WebSocket collector is an integral part of the WeatherFlow Collector system and is not intended 
for standalone use. It should be used in conjunction with other components of the system.
"""


import json
import asyncio
import websockets


import config
import logger
import random
import time
import datetime


import utils.utils as utils  # Assuming utils contains necessary methods

logger_WebsocketCollector = logger.get_module_logger(__name__ + ".WebsocketCollector")


logger_websockets = logger.get_module_logger("websockets")


class WebsocketCollector:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        self.logger = logger_WebsocketCollector
        self.websocket_url = config.WEATHERFLOW_API_WEBSOCKET_URL
        self.api_token = config.WEATHERFLOW_COLLECTOR_API_TOKEN
        self.websocket = None
        self.last_message_time = time.time()
        self.timeout_duration = (
            config.WEATHERFLOW_COLLECTOR_HEALTHCHECK_WEBSOCKETCOLLECTOR_TIMEOUT_SOCKET
        )

        logger_WebsocketCollector.info("WebsocketCollector initialized.")
        self.message_count = 0  # Counter for processed messages
        self.error_count = 0  # Counter for errors
        self.module_name = "collector_websocket"
        self.collector_type = "collector_websocket"

    async def establish_connection(self):
        retry_delay = config.WEATHERFLOW_COLLECTOR_COLLECTOR_WEBSOCKET_RETRY_DELAY
        max_delay = config.WEATHERFLOW_COLLECTOR_COLLECTOR_WEBSOCKET_MAX_DELAY
        max_retries = config.WEATHERFLOW_COLLECTOR_COLLECTOR_WEBSOCKET_MAX_RETRIES
        retry_count = 0

        while retry_count < max_retries:
            try:
                self.websocket = await websockets.connect(self.websocket_url)
                await self.authenticate()
                logger_WebsocketCollector.info("WebSocket connection established.")
                break
            except Exception as e:
                retry_count += 1
                logger_WebsocketCollector.error(
                    f"Failed to establish WebSocket connection: {e}"
                )

                if retry_count < max_retries:
                    next_retry_time = datetime.datetime.now() + datetime.timedelta(
                        seconds=retry_delay
                    )
                    logger_WebsocketCollector.warning(
                        f"Retrying in {retry_delay} seconds at {next_retry_time.strftime('%Y-%m-%d %H:%M:%S')}... "
                        f"(Attempt {retry_count} of {max_retries})"
                    )
                    await asyncio.sleep(retry_delay)
                    retry_delay = min(max_delay, retry_delay * 2)  # Exponential backoff
                else:
                    logger_WebsocketCollector.error(
                        f"Maximum retry attempts ({max_retries}) reached. WebSocket connection not established."
                    )
                    break

    async def authenticate(self):
        auth_message = json.dumps({"type": "listen_start", "token": self.api_token})
        await self.websocket.send(auth_message)
        logger_WebsocketCollector.info(
            "Sent authentication message to WebSocket server."
        )

    async def receive_and_forward_messages(self):
        """
        Continuously receives and processes messages from the WebSocket connection.

        This method performs the following tasks:
        - Listens for messages from the WebSocket.
        - Parses each message and determines its type.
        - Handles specific message types with custom logic:
          - "connection_opened": Calls a method to handle the opening of the connection.
          - "ack": Logs the receipt of an acknowledgment message.
          - Messages containing a "status" field: Treated as initial connection responses and logged, but not forwarded.
        - Forwards all other messages to the event manager for further processing.

        The method filters out "connection_opened", "ack", and initial "status" messages because:
        - "connection_opened" messages are internal indicators of a successful connection establishment.
        - "ack" messages are acknowledgments from the server, usually in response to specific commands sent by the client.
        - Messages with a "status" field typically convey the status of the connection or responses to certain commands,
          and do not carry the data intended for processing by the event manager.

        All other messages are expected to contain data relevant to the application and are therefore forwarded.
        """
        while True:
            try:
                # Wait for a message to be received
                message = await self.websocket.recv()
                self.last_message_time = (
                    time.time()
                )  # Update the last received message time

                # Start the timer after receiving the message
                message_processing_start = time.time()

                try:
                    json_data = json.loads(message)
                except json.JSONDecodeError as json_err:
                    logger_WebsocketCollector.error(f"JSON parsing error: {json_err}")
                    continue  # Skip this message and continue with the next

                message_size = len(message)  # Capture the size of the message
                self.message_count += 1  # Increment message count

                # Log and filter out "connection_opened", "ack", and "status" messages
                message_type = json_data.get("type")
                if message_type == "connection_opened":
                    await self.handle_connection_opened()
                    logger_WebsocketCollector.info(
                        f"Handled connection opened: {message}"
                    )

                elif message_type == "ack":
                    logger_WebsocketCollector.debug(
                        f"Received and acknowledged 'ack' message: {message}"
                    )

                elif "status" in json_data:
                    logger_WebsocketCollector.debug(
                        f"Received initial 'status' message: {message}"
                    )

                else:
                    # Forward other messages to the event manager
                    data_with_metadata = {
                        "metadata": {"collector_type": self.collector_type},
                        "data": json_data,
                    }
                    await self.event_manager.publish(
                        "collector_data_event",
                        data_with_metadata,
                        publisher="WebsocketCollector.receive_and_forward_messages",
                    )

            except websockets.ConnectionClosed:
                logger_WebsocketCollector.warning(
                    "WebSocket connection closed, attempting to reconnect."
                )
                await self.establish_connection()
                self.error_count += 1  # Increment error count for connection closure

            except Exception as e:
                self.error_count += 1
                logger_WebsocketCollector.error(f"Error in receiving messages: {e}")
                # Detailed error logging
                logger_WebsocketCollector.debug(
                    f"Exception details: {e.__class__.__name__}: {str(e)}"
                )

            finally:
                # Calculate processing duration and publish metrics in all scenarios
                processing_duration = time.time() - message_processing_start

                logger_WebsocketCollector.debug(
                    f"Publishing metrics: message_count={self.message_count}, errors={self.error_count}, duration={processing_duration}, bytes={message_size if 'message_size' in locals() else 0}"
                )

                await utils.async_publish_metrics(
                    self.event_manager,
                    metric_name="receive_and_forward_messages",
                    module_name=self.module_name,
                    rate=self.message_count,
                    errors=self.error_count,
                    duration=processing_duration,
                    bytes=message_size if "message_size" in locals() else 0,
                )

    async def handle_connection_opened(self):
        station_metadata = utils.StationMetadataSingleton().get_metadata()
        for station_id, station_info in station_metadata.items():
            if station_info.get("enabled", False):
                for device in station_info.get("devices", []):
                    if (
                        device.get("enabled", False)
                        and device.get("device_type") != "HB"
                    ):
                        await self.subscribe_to_device(device.get("device_id"))

    async def subscribe_to_device(self, device_id):
        subscription_id = random.randint(1, 1000000)
        listen_start_message = {
            "type": "listen_start",
            "device_id": device_id,
            "id": subscription_id,
        }
        await self.websocket.send(json.dumps(listen_start_message))
        logger_WebsocketCollector.info(
            f"Subscribed start to device: {device_id} with ID: {subscription_id}"
        )

        listen_rapid_start_message = {
            "type": "listen_rapid_start",
            "device_id": device_id,
            "id": subscription_id,
        }
        await self.websocket.send(json.dumps(listen_rapid_start_message))
        logger_WebsocketCollector.info(
            f"Subscribed rapid_start to device: {device_id} with ID: {subscription_id}"
        )

    async def close_connection(self):
        if self.websocket:
            try:
                # Send any final messages if needed (e.g., 'disconnect' message)
                # await self.websocket.send(json.dumps({"type": "disconnect"}))
                await self.websocket.close()
                logger_WebsocketCollector.info(
                    "WebSocket connection closed gracefully."
                )
            except Exception as e:
                logger_WebsocketCollector.error(
                    f"Error closing WebSocket connection: {e}"
                )
                # Additional logging for debugging
                logger_WebsocketCollector.debug(
                    f"Exception details: {e.__class__.__name__}: {str(e)}"
                )

    async def start(self):
        await self.establish_connection()
        asyncio.create_task(self.monitor_connection())  # Start the background task
        await self.receive_and_forward_messages()

    async def monitor_connection(self):
        """
        Monitors the connection to check if messages are being received.
        If no messages are received within the timeout duration, the connection is restarted.
        """
        while True:
            current_time = time.time()
            elapsed_time = current_time - self.last_message_time

            if elapsed_time < 60:
                elapsed_time_str = f"{elapsed_time:.2f} seconds"
            else:
                minutes = int(elapsed_time // 60)
                seconds = elapsed_time % 60
                elapsed_time_str = f"{minutes} minutes and {seconds:.2f} seconds"

            logger_WebsocketCollector.debug(
                f"Performing connection check. Last message received {elapsed_time_str} ago."
            )

            if elapsed_time > self.timeout_duration:
                last_event_time = time.strftime(
                    "%Y-%m-%d %H:%M:%S", time.localtime(self.last_message_time)
                )
                timeout_duration_str = (
                    f"{self.timeout_duration} seconds"
                    if self.timeout_duration < 60
                    else f"{self.timeout_duration // 60} minutes"
                )
                logger_WebsocketCollector.warning(
                    f"No data received within timeout duration of {timeout_duration_str}. Last event received at {last_event_time}. Restarting connection."
                )
                await self.close_connection()
                await self.establish_connection()

            await asyncio.sleep(self.timeout_duration)

    def update(self, data):
        logger_WebsocketCollector.debug("Updating WebsocketCollector with new data")
