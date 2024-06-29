import asyncio
import websockets
import json
import urllib.parse
import time
import sys

import config
import utils.utils as utils
import logger

logger_WebSocketServerProvider = logger.get_module_logger(
    __name__ + ".WebSocketServerProvider"
)


class WebSocketServerProvider:
    def __init__(self, event_manager):
        self.event_manager = event_manager
        self.host = config.WEATHERFLOW_COLLECTOR_PROVIDER_WEBSOCKET_SERVER_HOST
        self.port = config.WEATHERFLOW_COLLECTOR_PROVIDER_WEBSOCKET_SERVER_PORT
        self.station_metadata = utils.StationMetadataSingleton().get_metadata()
        self.clients = set()
        self.default_clients = set()  # Initialize default_clients
        self.initialize_stations()  # Call this method to initialize enabled stations
        self.module_name = "websocket_server"
        self.collector_type = "websocket_server"
        self.metrics_by_client_type = {}

    def get_station_info_by_name(self, station_name):
        """Search the station_metadata for a station with the given name."""
        for station_id, info in self.station_metadata.items():
            if info.get("name") == station_name and info.get("enabled", False):
                return info
        return None

    def get_device_id_from_serial(self, serial_number):
        # Implement logic to retrieve device ID from serial number
        # Placeholder implementation
        for station_info in self.station_metadata.values():
            for device in station_info.get("devices", []):
                if device.get("serial_number") == serial_number:
                    return device.get("device_id")
        return None

    def initialize_stations(self):
        self.enabled_stations = {}
        for station_id, station_info in self.station_metadata.items():
            if station_info.get("enabled", False):
                self.enabled_stations[station_info["name"]] = {
                    device["device_type"]: device.get("enabled", False)
                    for device in station_info.get("devices", [])
                    if device.get("device_type") != "HB"
                }

    async def register(self, websocket, path):
        total_connections = len(self.clients) + len(self.default_clients)
        if (
            total_connections
            >= config.WEATHERFLOW_COLLECTOR_PROVIDER_WEBSOCKET_SERVER_MAX_CONNECTIONS
        ):
            logger_WebSocketServerProvider.warning(
                "Maximum connection limit reached. Closing new connection."
            )
            await websocket.close(code=1001, reason="Connection limit reached")
            return

        logger_WebSocketServerProvider.debug(
            f"Attempting to register client with path: {path}"
        )
        path_parts = path.strip("/").split("/")
        if len(path_parts) < 2:
            self.default_clients.add(websocket)
            logger_WebSocketServerProvider.info(
                f"Client {websocket.remote_address} added to default group due to insufficient path info."
            )
            return

        collector_type, device_id_str = path_parts[0], path_parts[1]
        try:
            device_id = int(device_id_str)
        except ValueError:
            self.default_clients.add(websocket)
            logger_WebSocketServerProvider.info(f"Invalid device ID in path: {path}")
            return

        # Check if any enabled station has this device and if it's enabled
        for station_info in self.station_metadata.values():
            if station_info.get("enabled", False):  # Check if the station is enabled
                for device in station_info.get("devices", []):
                    if device.get("device_id") == device_id and device.get(
                        "enabled", False
                    ):
                        # Register the client if both station and device are enabled
                        self.clients.add((websocket, collector_type, device_id))
                        logger_WebSocketServerProvider.info(
                            f"Client {websocket.remote_address} registered for device ID '{device_id}' with collector type '{collector_type}'."
                        )
                        return

        # Add to default clients if device or station is not enabled or found
        self.default_clients.add(websocket)
        logger_WebSocketServerProvider.info(
            f"Client {websocket.remote_address} added to default group due to disabled or unknown device/station."
        )

    async def unregister(self, websocket):
        client = next((c for c in self.clients if c[0] == websocket), None)
        if client:
            self.clients.remove(client)
            logger_WebSocketServerProvider.info(
                f"Client {client[2]} disconnected from {client[1]}."
            )
        elif websocket in self.default_clients:
            self.default_clients.remove(websocket)
            logger_WebSocketServerProvider.info(
                f"Client disconnected from default group."
            )
        else:
            logger_WebSocketServerProvider.warning(
                "Unregister called for unknown client."
            )

    async def websocket_handler(self, websocket, path):
        try:
            await self.register(websocket, path)
            async for message in websocket:
                logger_WebSocketServerProvider.info(
                    f"Received message from client: {message}"
                )
        except websockets.exceptions.ConnectionClosedError as e:
            logger_WebSocketServerProvider.error(
                f"WebSocket connection closed unexpectedly: {e}"
            )
        except Exception as e:
            logger_WebSocketServerProvider.error(f"Error in websocket_handler: {e}")
        finally:
            await self.unregister(websocket)

    def update(self, full_data):
        collector_type = full_data.get("metadata", {}).get("collector_type")

        if collector_type == "collector_udp":
            self.handle_udp_collector_data(full_data)

        if collector_type == "collector_websocket":
            self.handle_websocker_collector_data(full_data)

    def handle_udp_collector_data(self, full_data):
        logger_WebSocketServerProvider.debug(
            f"UDP collector data received: {full_data}"
        )
        data_type = full_data.get("data", {}).get("type")

        if data_type == "rapid_wind":
            formatted_data = self.format_rapid_wind_data(full_data)
            # Assuming a method to map from serial number to device ID
            serial_number = full_data.get("data", {}).get("serial_number")
            device_id = (
                self.get_device_id_from_serial(serial_number) if serial_number else None
            )

            if device_id is not None:
                asyncio.create_task(
                    self.broadcast(formatted_data, "collector_udp", device_id)
                )
            else:
                logger_WebSocketServerProvider.debug(
                    "Device ID is unknown or not applicable for UDP collector data"
                )

    def handle_websocker_collector_data(self, full_data):
        logger_WebSocketServerProvider.debug(
            f"WebSocket collector data received: {full_data}"
        )
        data_type = full_data.get("data", {}).get("type")

        if data_type == "rapid_wind":
            formatted_data = self.format_rapid_wind_data(full_data)
            device_id = full_data.get("data", {}).get("device_id")
            if device_id is not None:
                asyncio.create_task(
                    self.broadcast(formatted_data, "collector_websocket", device_id)
                )
            else:
                logger_WebSocketServerProvider.debug(
                    "Device ID is unknown in WebSocket collector data"
                )

    def format_rapid_wind_data(self, full_data):
        observation = full_data.get("data", {}).get("ob", [])
        if observation and len(observation) == 3:
            timestamp, wind_speed, wind_direction = observation
        else:
            logger_WebSocketServerProvider.error(
                "Invalid or incomplete observation data received"
            )
            return None

        client_type_map = {
            "collector_udp": "collector_udp",
            "collector_websocket": "collector_websocket",
        }
        source = client_type_map.get(
            full_data.get("metadata", {}).get("collector_type"), "unknown-source"
        )

        station_info = full_data.get("station_info", {})
        structured_data = {
            "rapid_wind": {
                source: {
                    station_info.get("station_name", "unknown"): {
                        "station_name": station_info.get("station_name"),
                        "timestamp": timestamp,
                        "wind_speed": wind_speed,
                        "wind_direction": wind_direction,
                        "latitude": station_info.get("station_latitude"),
                        "longitude": station_info.get("station_longitude"),
                    }
                }
            }
        }

        return json.dumps(structured_data)

    async def broadcast(self, message, collector_type, device_id=None):
        broadcast_start_time = time.time()

        # Initialize metrics for the collector_type if not already present
        if collector_type not in self.metrics_by_client_type:
            self.metrics_by_client_type[collector_type] = {
                "message_count": 0,
                "error_count": 0,
                "client_count": 0,
            }

        try:
            logger_WebSocketServerProvider.debug(
                f"Preparing to broadcast message to {collector_type} clients with device ID '{device_id}'"
            )

            # Determine the clients to notify based on collector_type and device_id
            clients_to_notify = []
            for client in self.clients:
                if client[1] == collector_type and (
                    device_id is None or client[2] == device_id
                ):
                    clients_to_notify.append(client[0])

            logger_WebSocketServerProvider.debug(
                f"Clients to notify ({'by device ID' if device_id is not None else collector_type}): {clients_to_notify}"
            )

            # Update the client count metric
            self.metrics_by_client_type[collector_type]["client_count"] = len(
                clients_to_notify
            )

            # Calculate the size of the message for metrics
            message_json = json.dumps(message) if isinstance(message, dict) else message
            message_bytes = len(message_json.encode("utf-8"))

            # Broadcast the message to the identified clients
            if clients_to_notify:
                await asyncio.wait(
                    [
                        asyncio.create_task(client.send(message_json))
                        for client in clients_to_notify
                    ]
                )
                logger_WebSocketServerProvider.debug(
                    f"Broadcasted message to {collector_type} clients at device ID '{device_id}'"
                )

                # Increment message count for the specific collector_type
                self.metrics_by_client_type[collector_type]["message_count"] += 1

            else:
                logger_WebSocketServerProvider.debug(
                    "No clients to broadcast to for this message"
                )

        except Exception as e:
            logger_WebSocketServerProvider.error(f"Error during message broadcast: {e}")
            self.metrics_by_client_type[collector_type]["error_count"] += 1

        finally:
            broadcast_duration = time.time() - broadcast_start_time

            logger_WebSocketServerProvider.debug(
                f"Broadcast completed in {broadcast_duration:.2f} seconds for collector_type '{collector_type}'"
            )

            # Log and publish metrics including client count and message bytes
            logger_WebSocketServerProvider.debug(
                f"Publishing metrics for {collector_type}: "
                f"message_count={self.metrics_by_client_type[collector_type]['message_count']}, "
                f"errors={self.metrics_by_client_type[collector_type]['error_count']}, "
                f"duration={broadcast_duration}, "
                f"client_count={self.metrics_by_client_type[collector_type]['client_count']}, "
                f"bytes_transmitted={message_bytes}"
            )

            await utils.async_publish_metrics(
                self.event_manager,
                metric_name=f"broadcast_{collector_type}",
                module_name=self.module_name,
                rate=self.metrics_by_client_type[collector_type]["message_count"],
                errors=self.metrics_by_client_type[collector_type]["error_count"],
                duration=broadcast_duration,
                client_count=self.metrics_by_client_type[collector_type][
                    "client_count"
                ],
                bytes=message_bytes,  # Transmit the size of the current message
            )

    async def start_server(self):
        try:
            # Start the WebSocket server
            server = await websockets.serve(
                self.websocket_handler,
                self.host,
                self.port,
                ping_interval=config.WEATHERFLOW_COLLECTOR_PROVIDER_WEBSOCKET_SERVER_PING_INTERVAL,
                ping_timeout=config.WEATHERFLOW_COLLECTOR_PROVIDER_WEBSOCKET_SERVER_PING_TIMEOUT,
            )
            logger_WebSocketServerProvider.info(
                f"WebSocket Server started on ws://{self.host}:{self.port}/"
            )

            # Run the cleanup task along with the server
            await asyncio.gather(server.wait_closed(), self.cleanup_connections())

        except OSError as os_error:
            logger_WebSocketServerProvider.error(
                f"OS error occurred while starting WebSocket server: {os_error}"
            )
            # Handle the OS error appropriately, e.g., raise or log and continue

        except websockets.WebSocketException as ws_error:
            logger_WebSocketServerProvider.error(
                f"WebSocket error occurred while starting WebSocket server: {ws_error}"
            )
            # Handle the WebSocket error appropriately, e.g., raise or log and continue

        except Exception as e:
            logger_WebSocketServerProvider.error(
                f"Unexpected error occurred while starting WebSocket server: {e}"
            )
            # Handle the unexpected error appropriately, e.g., raise or log and continue

    async def cleanup_connections(self):
        while True:
            try:
                await asyncio.sleep(
                    config.WEATHERFLOW_COLLECTOR_PROVIDER_WEBSOCKET_SERVER_CLEANUP_CONNECTIONS_INTERVAL
                )
                for client in list(self.clients):
                    if client[0].closed:
                        self.clients.remove(client)
                        logger_WebSocketServerProvider.info(
                            f"Removed closed connection from active clients."
                        )

                for client in list(self.default_clients):
                    if client.closed:
                        self.default_clients.remove(client)
                        logger_WebSocketServerProvider.info(
                            f"Removed closed connection from default clients."
                        )
            except Exception as e:
                logger_WebSocketServerProvider.error(
                    f"Error during connection cleanup: {e}"
                )
