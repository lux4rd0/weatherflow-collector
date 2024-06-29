import time
import logger

logger_SystemMetricsHandler = logger.get_module_logger(__name__)


class SystemMetricsHandler:
    def __init__(self, event_manager):
        self.event_manager = event_manager

    async def update(self, metrics_data):
        """
        Coroutine to handle the update from the event manager.
        """
        logger_SystemMetricsHandler.debug("Processing metrics data update.")
        try:
            # Prepare the message for the InfluxDBStorage handler
            influxdb_message = self.process_metrics(metrics_data)
            if influxdb_message:
                # Publish the prepared message to the event manager
                await self.event_manager.publish(
                    "influxdb_storage_event",
                    influxdb_message,
                    publisher="SystemMetricsHandler.update",
                )
        except Exception as e:
            logger_SystemMetricsHandler.error(f"Error processing metrics data: {e}")

    def process_metrics(self, metrics_data):
        """
        Prepare the metrics data message for InfluxDB storage.
        """
        required_fields = ["rate", "errors", "duration", "metric_name", "module_name"]
        if not all(field in metrics_data for field in required_fields):
            logger_SystemMetricsHandler.error("Missing required fields in metrics data")
            return None  # Skip processing if required fields are missing

        # Prepare the data for the InfluxDBStorage message
        measurement = "weatherflow_system_metrics"
        fields = {
            "rate": metrics_data.get("rate"),
            "errors": metrics_data.get("errors"),
            "duration": metrics_data.get("duration"),
            **{
                k: v
                for k, v in metrics_data.items()
                if k in ["bytes", "client_count", "active_tasks"] and v is not None
            },
        }
        tags = {
            "metric_name": metrics_data.get("metric_name"),
            "module_name": metrics_data.get("module_name"),
        }
        timestamp = int(time.time())  # Current time in epoch seconds

        # Construct the message for the InfluxDBStorage handler
        influxdb_message = {
            "data_type": "single",
            "measurement": measurement,
            "tags": tags,
            "fields": fields,
            "timestamp": timestamp,
        }

        return influxdb_message

    def close(self):
        """
        Close any resources, if necessary.
        """
        # Perform any necessary cleanup
        logger_SystemMetricsHandler.info("SystemMetricsHandler cleanup completed")
