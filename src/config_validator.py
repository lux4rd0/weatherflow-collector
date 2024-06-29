# config_validator.py

import config
import logger

logger_ConfigValidator = logger.get_module_logger()


def obfuscate_token(token):
    if token and len(token) > 10:
        return token[:5] + "..." + token[-5:]
    return token


def validate_api_config():
    if not config.WEATHERFLOW_COLLECTOR_API_TOKEN:
        logger_ConfigValidator.error("WeatherFlow API token is not set.")
        return False
    else:
        obscured_token = obfuscate_token(config.WEATHERFLOW_COLLECTOR_API_TOKEN)
        logger_ConfigValidator.info(
            f"WeatherFlow API token is set (partially shown): {obscured_token}"
        )
    return True


def validate_influxdb_config():
    missing_config = []
    if not config.WEATHERFLOW_COLLECTOR_INFLUXDB_URL:
        missing_config.append("WEATHERFLOW_COLLECTOR_INFLUXDB_URL")
    else:
        logger_ConfigValidator.info(
            f"InfluxDB URL is set to: {config.WEATHERFLOW_COLLECTOR_INFLUXDB_URL}"
        )

    if not config.WEATHERFLOW_COLLECTOR_INFLUXDB_TOKEN:
        missing_config.append("WEATHERFLOW_COLLECTOR_INFLUXDB_TOKEN")
    else:
        obscured_token = obfuscate_token(config.WEATHERFLOW_COLLECTOR_INFLUXDB_TOKEN)
        logger_ConfigValidator.info(
            f"InfluxDB Token is set (partially shown): {obscured_token}"
        )

    if not config.WEATHERFLOW_COLLECTOR_INFLUXDB_ORG:
        missing_config.append("WEATHERFLOW_COLLECTOR_INFLUXDB_ORG")
    else:
        logger_ConfigValidator.info(
            f"InfluxDB Organization is set to: {config.WEATHERFLOW_COLLECTOR_INFLUXDB_ORG}"
        )

    if not config.WEATHERFLOW_COLLECTOR_INFLUXDB_BUCKET:
        missing_config.append("WEATHERFLOW_COLLECTOR_INFLUXDB_BUCKET")
    else:
        logger_ConfigValidator.info(
            f"InfluxDB Bucket is set to: {config.WEATHERFLOW_COLLECTOR_INFLUXDB_BUCKET}"
        )

    if missing_config:
        logger_ConfigValidator.error(
            f"Missing InfluxDB configuration(s): {', '.join(missing_config)}."
        )
        return False

    return True


def validate_module_enablement():
    logger_ConfigValidator.info("Module Enablement Status:")

    # Function to log the status of each module
    def log_module_status(setting_name, is_enabled):
        status = "Enabled" if is_enabled else "Disabled"
        logger_ConfigValidator.info(f"{setting_name} module is {status}")

    # Log the status for each module
    log_module_status(
        "Collector Export", config.WEATHERFLOW_COLLECTOR_COLLECTOR_EXPORT_ENABLED
    )
    log_module_status("Storage File", config.WEATHERFLOW_COLLECTOR_STORAGE_FILE_ENABLED)
    log_module_status(
        "Storage InfluxDB", config.WEATHERFLOW_COLLECTOR_STORAGE_INFLUXDB_ENABLED
    )
    log_module_status(
        "Collector REST Export",
        config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_EXPORT_ENABLED,
    )
    log_module_status(
        "Collector REST Forecasts",
        config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_FORECASTS_ENABLED,
    )
    log_module_status(
        "Collector REST Import",
        config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_IMPORT_ENABLED,
    )
    log_module_status(
        "Collector REST Observations Device",
        config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_OBSERVATIONS_DEVICE_ENABLED,
    )
    log_module_status(
        "Collector REST Observations Station",
        config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_OBSERVATIONS_STATION_ENABLED,
    )
    log_module_status(
        "Collector REST Stats",
        config.WEATHERFLOW_COLLECTOR_COLLECTOR_REST_STATS_ENABLED,
    )
    log_module_status(
        "System Metrics", config.WEATHERFLOW_COLLECTOR_SYSTEM_METRICS_ENABLED
    )
    log_module_status(
        "Collector UDP", config.WEATHERFLOW_COLLECTOR_COLLECTOR_UDP_ENABLED
    )
    log_module_status(
        "Collector WebSocket", config.WEATHERFLOW_COLLECTOR_COLLECTOR_WEBSOCKET_ENABLED
    )
    log_module_status(
        "Provider WebSocket Server",
        config.WEATHERFLOW_COLLECTOR_PROVIDER_WEBSOCKET_SERVER_ENABLED,
    )
    log_module_status("Handler", config.WEATHERFLOW_COLLECTOR_HANDLER_ENABLED)

    return True


def validate_all():
    return (
        validate_api_config()
        and validate_module_enablement()
        and validate_influxdb_config()
    )
