# logger.py

"""
Logging Configuration Module

This module provides a centralized configuration for logging across the application.
It defines a custom logging formatter that adds color coding to log messages based
on their severity levels and includes timestamps for better traceability. The module
also sets up both console and file logging handlers to direct log output appropriately.

Key Features:
- CustomFormatter: A custom logging formatter class that adds color coding,
  timestamps, module, and method names to log messages.
- configure_logging: A function to configure the root logger with custom settings,
  including setting the log level, adding a console handler with the custom formatter,
  and setting up a file handler for logging to a file with a daily rotation.

The color coding in the log messages enhances readability and helps in quickly
identifying the severity of log messages. The module ensures that all parts of the
application use a consistent logging format and level.

Usage:
The module is used to configure the logging at the start of the application. It sets
up handlers for both console and file outputs, applying the custom formatter to both.
The file handler writes logs to a file with the current date in its filename, allowing
for easier log management and review.

Dependencies:
- datetime: Used for timestamp formatting and generating log file names.
- os: Used for creating the log directory if it does not exist.
- config: Configuration module containing settings like log levels and log directory path.

Author: Dave Schmid
Created: 2023-12-17
"""
import config
from datetime import datetime

import inspect
import logging
import os

# Custom Formatter to add colors, time, module, and method to log levels
class CustomFormatter(logging.Formatter):
    LOG_LEVEL_COLORS = {
        "DEBUG": "\x1b[36;1m",  # Cyan
        "INFO": "\x1b[32;1m",  # Green
        "WARNING": "\x1b[33;1m",  # Yellow
        "ERROR": "\x1b[31;1m",  # Red
        "CRITICAL": "\x1b[35;1m",  # Magenta
    }

    # Color codes
    COLOR_CODES = {
        "grey": "\x1b[38;21m",
        "yellow": "\x1b[33;21m",
        "red": "\x1b[31;21m",
        "bold_red": "\x1b[31;1m",
        "green": "\x1b[32;21m",
        "blue": "\x1b[34;21m",
        "magenta": "\x1b[35;21m",
        "cyan": "\x1b[36;21m",
        "reset": "\x1b[0m",
        "black": "\x1b[30m",
        "light_black": "\x1b[30;1m",
        "light_red": "\x1b[31;1m",
        "light_green": "\x1b[32;1m",
        "light_yellow": "\x1b[33;1m",
        "light_blue": "\x1b[34;1m",
        "light_magenta": "\x1b[35;1m",
        "light_cyan": "\x1b[36;1m",
        "white": "\x1b[37m",
        "light_white": "\x1b[37;1m",
        "dark_gray": "\x1b[90m",
        "dark_red": "\x1b[91m",
        "dark_green": "\x1b[92m",
        "dark_yellow": "\x1b[93m",
        "dark_blue": "\x1b[94m",
        "dark_magenta": "\x1b[95m",
        "dark_cyan": "\x1b[96m",
        "bright_white": "\x1b[97m",
    }

    # Module to color mapping
    MODULE_TO_COLOR = {
        "asyncio": "dark_cyan",
        "assist_logger.CodeAnalyzer": "yellow",
        "collector": "dark_blue",
        "collector.rest_export.RestExportCollector": "dark_blue",
        "collector.rest_forecasts.RestForcecastsCollector": "dark_blue",
        "collector.rest_import.RestImportCollector": "dark_blue",
        "collector.rest_observations_device": "dark_blue",
        "collector.rest_observations_device.RESTObservationsDeviceCollector": "dark_blue",
        "collector.rest_observations_station.RESTObservationsStationCollector": "dark_blue",
        "collector.rest_stats": "dark_blue",
        "collector.rest_stats.RestStatsCollector": "dark_blue",
        "collector.udp.UDPCollector": "dark_blue",
        "collector.udp.UDPProtocol": "dark_blue",
        "collector.websocket.WebsocketCollector": "dark_blue",
        "event_manager": "cyan",
        "event_manager.EventManager": "cyan",
        "handlers": "magenta",
        "handlers.handler.Handler": "dark_green",
        "handlers.rest_forecasts.BaseDataHandler": "dark_green",
        "handlers.rest_forecasts.RESTForecastsHandler": "dark_green",
        "handlers.rest_import.BaseDataHandler": "dark_green",
        "handlers.rest_import.RESTImportHandler": "dark_green",
        "handlers.rest_observations_device.BaseDataHandler": "dark_green",
        "handlers.rest_observations_device.RESTObservationsDeviceHandler": "dark_green",
        "handlers.rest_observations_station.BaseDataHandler": "dark_green",
        "handlers.rest_observations_station.RESTObservationsStationHandler": "dark_green",
        "handlers.rest_stats.BaseDataHandler": "dark_green",
        "handlers.rest_stats.RESTStatsHandler": "dark_green",
        "handlers.system_metrics.SystemMetricsHandler": "dark_green",
        "handlers.udp.BaseDataHandler": "dark_green",
        "handlers.udp.UDPHandler": "dark_green",
        "handlers.websocket.BaseDataHandler": "dark_green",
        "handlers.websocket.WebSocketHandler": "dark_green",
        "logger": "cyan",
        "logger.CustomFormatter": "cyan",
        "processor": "dark_cyan",
        "processor.collector_data.CollectorDataProcessor": "dark_cyan",
        "processor.export.ExportProcessor": "dark_cyan",
        "provider": "blue",
        "provider.websocket_server.WebSocketServerProvider": "blue",
        "station_metadata_manager": "magenta",
        "storage": "dark_magenta",
        "storage.file.FileStorage": "dark_magenta",
        "storage.influxdb.InfluxDBStorage": "dark_magenta",
        "utils": "light_cyan",
        "utils.calculate_weather_metrics.CalculateWeatherMetrics": "light_cyan",
        "utils.utils.SingletonMeta": "light_cyan",
        "utils.utils.StationMetadataSingleton": "light_cyan",
        "websockets": "light_cyan",
        "__main__": "dark_green",
    }

    def __init__(self, use_color=True):
        super().__init__()
        self.use_color = use_color

    def get_color_for_module(self, module_name):
        # Split the module name into parts
        parts = module_name.split(".")

        # Iterate from the most specific to the least specific part
        for i in range(len(parts), 0, -1):
            # Join the parts to form the current name to check
            name_to_check = ".".join(parts[:i])
            if name_to_check in self.MODULE_TO_COLOR:
                # Found a match, return the corresponding color
                return self.COLOR_CODES[self.MODULE_TO_COLOR[name_to_check]]

        # Default color if no match is found
        return self.COLOR_CODES["grey"]

    def format(self, record):
        # Extract the module and class names from the record
        name_parts = record.name.split(".")
        if len(name_parts) > 1:
            module_name = ".".join(name_parts[:-1])  # Module name
            class_name = name_parts[-1]  # Class name
        else:
            module_name = name_parts[0]
            class_name = ""

        # Apply color to module name if colors are enabled
        if self.use_color:
            # Use the modified get_color_for_module to find the correct color
            module_color = self.get_color_for_module(module_name)
            colored_module = f"{module_color}{module_name}{self.COLOR_CODES['reset']}"

            # Assign color to log level name
            log_level_color = self.LOG_LEVEL_COLORS.get(
                record.levelname, self.COLOR_CODES["reset"]
            )
            colored_levelname = (
                f"{log_level_color}{record.levelname}{self.COLOR_CODES['reset']}"
            )
        else:
            colored_module = module_name
            colored_levelname = record.levelname

        # Bold the method name if colors are enabled
        bold_funcName = (
            f"\x1b[1m{record.funcName}\x1b[0m" if self.use_color else record.funcName
        )

        # Construct log format string using the original format
        log_fmt = f"%(asctime)s - {colored_module} - {class_name} - {bold_funcName} - {colored_levelname} - %(message)s"

        # Apply format
        formatter = logging.Formatter(log_fmt, "%Y-%m-%d %H:%M:%S")
        return formatter.format(record)


def get_log_level_for_module(module_name, log_levels, default_level="DEBUG"):
    parts = module_name.split(".")
    for i in range(len(parts), 0, -1):
        name_to_check = ".".join(parts[:i])
        if name_to_check in log_levels:
            return log_levels[name_to_check]
    return default_level


def configure_logging():
    # Configure root logger
    logger = logging.getLogger()
    if logger.hasHandlers():
        logger.handlers.clear()  # Clear existing handlers
    logger.setLevel(logging.DEBUG)  # Capture everything, handlers will filter

    # Console logging configuration
    console_enabled = config.WEATHERFLOW_COLLECTOR_LOGGER_CONSOLE_ENABLED
    if console_enabled:
        console_formatter = CustomFormatter(
            use_color=config.WEATHERFLOW_COLLECTOR_LOGGER_CONSOLE_USE_COLOR_ENABLED
        )
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(console_formatter)
        console_handler.setLevel(logging.DEBUG)
        logger.addHandler(console_handler)

    # File logging configuration
    file_enabled = config.WEATHERFLOW_COLLECTOR_LOGGER_FILE_ENABLED
    if file_enabled:
        file_formatter = CustomFormatter(
            use_color=config.WEATHERFLOW_COLLECTOR_LOGGER_FILE_USE_COLOR_ENABLED
        )
        log_directory = config.WEATHERFLOW_COLLECTOR_LOG_DIRECTORY
        os.makedirs(log_directory, exist_ok=True)
        log_file_name = f"application_{datetime.now().strftime('%Y-%m-%d')}.log"
        log_file_path = os.path.join(log_directory, log_file_name)
        file_handler = logging.FileHandler(log_file_path)
        file_handler.setFormatter(file_formatter)
        file_handler.setLevel(logging.DEBUG)
        logger.addHandler(file_handler)


def get_module_logger(name=None):
    if name is None:
        frame = inspect.stack()[1]
        module = inspect.getmodule(frame[0])
        name = module.__name__ if module is not None else "__main__"

    module_logger = logging.getLogger(name)
    module_logger.propagate = False

    # Add console handler based on config
    if config.WEATHERFLOW_COLLECTOR_LOGGER_CONSOLE_ENABLED:
        console_handler_exists = any(
            isinstance(handler, logging.StreamHandler)
            for handler in module_logger.handlers
        )
        if not console_handler_exists:
            console_level_name = get_log_level_for_module(
                name, config.WEATHERFLOW_COLLECTOR_CONSOLE_LOG_LEVELS, "INFO"
            )
            console_handler = logging.StreamHandler()
            console_handler.setFormatter(
                CustomFormatter(
                    use_color=config.WEATHERFLOW_COLLECTOR_LOGGER_CONSOLE_USE_COLOR_ENABLED
                )
            )
            console_handler.setLevel(getattr(logging, console_level_name))
            module_logger.addHandler(console_handler)

    # Add file handler based on config
    if config.WEATHERFLOW_COLLECTOR_LOGGER_FILE_ENABLED:
        file_handler_exists = any(
            isinstance(handler, logging.FileHandler)
            for handler in module_logger.handlers
        )
        if not file_handler_exists:
            file_level_name = get_log_level_for_module(
                name, config.WEATHERFLOW_COLLECTOR_FILE_LOG_LEVELS, "DEBUG"
            )
            log_directory = config.WEATHERFLOW_COLLECTOR_LOG_DIRECTORY
            os.makedirs(log_directory, exist_ok=True)
            log_file_name = f"{name}.log"
            log_file_path = os.path.join(log_directory, log_file_name)
            file_handler = logging.FileHandler(log_file_path)
            file_handler.setFormatter(
                CustomFormatter(
                    use_color=config.WEATHERFLOW_COLLECTOR_LOGGER_FILE_USE_COLOR_ENABLED
                )
            )
            file_handler.setLevel(getattr(logging, file_level_name))
            module_logger.addHandler(file_handler)

    return module_logger


# Call configure_logging to set up the logging environment
configure_logging()
