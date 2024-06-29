from datetime import datetime, timedelta
import pytz
from influxdb_client import InfluxDBClient, DeleteService

# Configuration variables
WEATHERFLOW_COLLECTOR_INFLUXDB_BUCKET = "weatherflow2"
WEATHERFLOW_COLLECTOR_INFLUXDB_ORG = "Tyle"
WEATHERFLOW_COLLECTOR_INFLUXDB_TOKEN = "TbVVRF66YnSSe8Ix_whNBsqZJN0r8fbq5It7RLJvONX0ZyMBCu7NjvlAuDmGlj0UWgpMiLopWbIMEvs27dSoBA=="
WEATHERFLOW_COLLECTOR_INFLUXDB_URL = "http://build01.tylephony.com:8086"

# Calculate current time and 10 days later in RFC3339
now = datetime.now(pytz.utc)
ten_days_later = now + timedelta(days=10)
start_time = now.isoformat()
end_time = ten_days_later.isoformat()

# Connect to InfluxDB using hardcoded configuration variables
client = InfluxDBClient(
    url=WEATHERFLOW_COLLECTOR_INFLUXDB_URL,
    token=WEATHERFLOW_COLLECTOR_INFLUXDB_TOKEN,
    org=WEATHERFLOW_COLLECTOR_INFLUXDB_ORG,
)

# Deletion parameters
bucket = WEATHERFLOW_COLLECTOR_INFLUXDB_BUCKET
org = WEATHERFLOW_COLLECTOR_INFLUXDB_ORG
measurement_name = "weatherflow_forecast_spray"  # Replace with your measurement name

# Predicate to delete all data from a specific measurement
predicate = f'_measurement="{measurement_name}"'

# Perform deletion
delete_api = client.delete_api()
delete_api.delete(start_time, end_time, predicate, bucket, org)

# Close the connection
client.close()
