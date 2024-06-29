# collector_udp.py

"""
WeatherFlow Collector UDP Client

This module is part of the WeatherFlow Collector system, designed to listen for UDP broadcasts
from WeatherFlow weather stations. It captures and processes weather data transmitted over the local network.

Key Features:
- Listens for UDP broadcasts on a specified port.
- Decodes received data from JSON format and adds relevant metadata.
- Integrates with an event manager to publish data for further processing.
- Operates asynchronously with the main event loop.

Usage:
This module is instantiated with an event manager and an asyncio event loop. It can be started to listen
for UDP data and stopped as needed. It's designed to run as a daemon thread in the background of the WeatherFlow
Collector system.

Dependencies:
- socket: For UDP communication.
- threading: To run the UDP listening server in a separate thread.
- json: For decoding the received data.
- asyncio: For asynchronous operations.

Classes:
- UDPCollector: Manages the UDP data reception and processing.

Methods:
- _create_socket(): Creates and configures the UDP socket.
- start_listening(): Starts the UDP listening server in a daemon thread.
- collect_data(): Continuously collects data from the UDP socket.
- decode_data_and_add_metadata(data): Decodes and adds metadata to the received data.
- stop(): Stops the UDP listening server.

Author: [Your Name or Team's Name]
Last Update: [Last Update Date]

Note:
The UDPCollector is a component of the WeatherFlow Collector system and is not intended for standalone use.
It is tailored to receive and process data specifically from WeatherFlow weather stations.
"""

import asyncio
import json
import time
import socket

import config
import utils.utils as utils
import logger


UDPProtocol = logger.get_module_logger(__name__ + ".UDPProtocol")


class UDPProtocol(asyncio.DatagramProtocol):
    def __init__(self, collector):
        self.collector = collector

    def datagram_received(self, data, addr):
        try:
            asyncio.create_task(self.collector.handle_data(data, addr))
        except Exception as e:
            logger_UDPCollector.error(f"Error in datagram_received: {e}")


logger_UDPCollector = logger.get_module_logger(__name__ + ".UDPCollector")


class UDPCollector:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        self.listen_address = config.WEATHERFLOW_COLLECTOR_UDP_LISTEN_ADDRESS
        self.port = config.WEATHERFLOW_COLLECTOR_UDP_COLLECTOR_PORT
        self.max_retries = config.WEATHERFLOW_COLLECTOR_UDP_COLLECTOR_MAX_RETRIES
        self.retry_delay = config.WEATHERFLOW_COLLECTOR_UDP_COLLECTOR_RETRY_DELAY
        self.buffer_size = config.WEATHERFLOW_COLLECTOR_UDP_BUFFER_SIZE

        self.collector_type = "collector_udp"
        self.module_name = "collector_udp"
        self.packet_count = 0  # Counter for processed packets
        self.error_count = 0  # Counter for errors

        self.socket = None
        self.running = True

    async def _init_socket(self):
        retry_count = 0
        while retry_count < self.max_retries:
            logger_UDPCollector.debug(
                f"Attempting to bind to port {self.port}, attempt {retry_count + 1}"
            )
            try:
                # Create an asyncio Datagram Endpoint
                loop = asyncio.get_running_loop()
                listen = loop.create_datagram_endpoint(
                    lambda: UDPProtocol(self),
                    local_addr=(self.listen_address, self.port),
                    reuse_port=True,  # Enable port reuse
                )
                self.transport, _ = await listen
                logger_UDPCollector.info(
                    f"Listening for UDP traffic on port {self.port}"
                )
                break  # Exit the loop on successful socket creation
            except OSError as e:
                if e.errno == socket.errno.EADDRINUSE:
                    # Handle the case where the port is already in use
                    logger_UDPCollector.warning(
                        f"Port {self.port} in use. Retrying in {self.retry_delay} seconds."
                    )
                    await asyncio.sleep(self.retry_delay)
                    retry_count += 1
                else:
                    # Log and raise other OSError exceptions
                    logger_UDPCollector.error(f"Error binding socket: {e}")
                    raise e

        if retry_count == self.max_retries:
            # Log an error if the socket fails to bind after the maximum number of retries
            logger_UDPCollector.error(
                f"Failed to bind to port {self.port} after {self.max_retries} retries."
            )
            raise RuntimeError(f"Failed to bind to port {self.port}")

    async def start_listening(self):
        await self._init_socket()

    async def handle_data(self, data, addr):
        logger_UDPCollector.debug(f"Handling data received from {addr}")
        packet_processing_start = time.time()
        packet_size = len(data)  # Size of the current packet

        try:
            # Increment the packet count for each successfully received packet
            self.packet_count += 1
            logger_UDPCollector.debug(f"Received {packet_size} bytes from {addr}")

            # Decode the data and add metadata
            collector_data_with_metadata = self.decode_data_and_add_metadata(data)
            if collector_data_with_metadata is not None:
                # Publish the data using the event manager
                await self.event_manager.publish(
                    "collector_data_event",
                    collector_data_with_metadata,
                    publisher="UDPCollector.handle_data",
                )

                # Calculate and log the duration of data processing
                processing_duration = time.time() - packet_processing_start
                await utils.async_publish_metrics(
                    self.event_manager,
                    metric_name="handle_data",
                    module_name=self.module_name,
                    rate=self.packet_count,
                    errors=self.error_count,
                    duration=processing_duration,
                    bytes=packet_size,
                )
            else:
                logger_UDPCollector.warning(
                    f"Data from {addr} could not be decoded or lacked metadata."
                )

        except Exception as e:
            # Increment the error count and log the exception
            self.error_count += 1
            logger_UDPCollector.error(f"Error handling data from {addr}: {e}")
            # Asynchronously publish metrics about the error
            await utils.async_publish_metrics(
                self.event_manager,
                metric_name="handle_data",
                module_name=self.module_name,
                rate=self.packet_count,
                errors=self.error_count,
                duration=0,  # Duration is 0 since an error occurred
                bytes=packet_size,
            )

    def decode_data_and_add_metadata(self, data):
        logger_UDPCollector.debug("Starting to decode data.")
        try:
            # Decode the data from bytes to a string
            decoded_data = data.decode("utf-8")
            # Convert the JSON string to a Python dictionary
            json_data = json.loads(decoded_data)
            data_with_metadata = {
                "metadata": {
                    "collector_type": self.collector_type,
                },
                "data": json_data,
            }

            logger_UDPCollector.debug("Data decoded and metadata added successfully.")
            return data_with_metadata

        except json.JSONDecodeError as e:
            logger_UDPCollector.error(f"JSON decoding error: {e}")
        except UnicodeDecodeError as e:
            logger_UDPCollector.error(f"Unicode decoding error: {e}")
        except Exception as e:
            logger_UDPCollector.error(f"Unexpected error in decoding data: {e}")

        # Return None or an empty dict if an error occurs
        return None

    async def stop(self):
        logger_UDPCollector.info("Stopping UDPCollector")
        if self.transport:
            self.transport.close()
            logger_UDPCollector.info("UDP transport closed")
