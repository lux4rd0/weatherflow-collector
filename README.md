
## About The Project

<center><img src="https://labs.lux4rd0.com/wp-content/uploads/2021/05/weatherflow_collector_header.png"></center>

**weatherflow-collector** is a set of scripts deployed with Docker that provide multiple ways of collecting data from the [WeatherFlow Tempest](https://weatherflow.com/tempest-weather-system/) weather system. Once deployed, a collection of Grafana dashboards help get you started visualizing that data with Grafana dashboards. This collector is part of my [WeatherFlow Dashboards AIO](https://github.com/lux4rd0/weatherflow-dashboards-aio) (All In One) project. Having access to just the collector may benefit you if you already have familiarity with InfluxDB and Grafana and want to import these dashboards yourself.

A live [set of dashboards](https://labs.lux4rd0.com/weatherflow-collector/) using this collector are available for you to try out.


## Getting Started

The project builds a pre-configured Docker container that takes different configurations based on how you want to collect and where you want to store the data.

## Prerequisites

- [Docker](https://docs.docker.com/install)
- [Docker Compose](https://docs.docker.com/compose/install)
- [InfluxDB 1.8](https://docs.influxdata.com/influxdb/v1.8/) or [Grafana Loki 2.2](https://grafana.com/oss/loki/)

## Notice

Like all projects - weatherflow-collector is always in a flux state based on trying out new things and seeing what works and what doesn't work. It started as a fun exercise to visualize "what's possible," and I'm experimenting with different collectors and backends. Please expect breaking changes along the way.

## Deploying the WeatherFlow Collector

Use the following [Docker container](https://hub.docker.com/r/lux4rd0/weatherflow-collector):

    lux4rd0/weatherflow-collector:2.8.2
    lux4rd0/weatherflow-collector:latest
    
Correct environmental variables need to be set for the container to function. The following script may be used:

    generate_docker-compose.sh

To use it, provide the following details about your InfluxDB and your WeatherFlow token as environmental variables.

    WEATHERFLOW_COLLECTOR_IMPORT_DAYS #optional
    WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
    WEATHERFLOW_COLLECTOR_INFLUXDB_URL
    WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
    WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL #optional
    WEATHERFLOW_COLLECTOR_THREADS
    WEATHERFLOW_COLLECTOR_TOKEN

An example would be:

    WEATHERFLOW_COLLECTOR_IMPORT_DAYS="365" \
    WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD="4L851Jtjaasdset7AJoFasdoFYR3di5Zniew28" \
    WEATHERFLOW_COLLECTOR_INFLUXDB_URL="http://influxdb01.com:8086/write?db=weatherflow" \
    WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME="influxdb" \
    WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL="http://loki:3100/loki/api/v1/push" \
    WEATHERFLOW_COLLECTOR_THREADS="4" \
    WEATHERFLOW_COLLECTOR_TOKEN="a22afsa7-0dcc-4918-9f9a-923dfd339f41c" \
    bash ./generate_docker-compose.sh

The following files will be generated for you:

#### docker-compose.yml

Running `docker-compose up -d' will spin up several containers for each of the types of data available to you. (Listed below) If you have more than one hub on your account - please edit the docker-compose.yml file to only have your hub local to your network. If you have more than one device, those will also be added and can remain.

#### Optional:
#### remote-import-<<station_name>>.sh

This script will spin up a docker container to import all of the observed metrics in the WeatherFlow cloud. Having an import function may be helpful if you're starting with this WeatherFlow Collector or if you've reset your InfluxDB database. It essentially loads in over your local UDP data. If you have more than one device, a separate import file will be generated for each.

## Environmental flags:

```WEATHERFLOW_COLLECTOR_BACKEND_TYPE```

- influxdb (supports local-udp, remote-rest (forecasts), and remote-socket (observations)
- loki (supports local-udp and remote-socket (observations)

```WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE```

- [remote-socket](https://weatherflow.github.io/Tempest/api/ws.html)
- [local-udp](https://weatherflow.github.io/Tempest/api/udp.html)
- [remote-rest](https://weatherflow.github.io/Tempest/api/swagger/#/observations/)
- [remote-forecast](https://weatherflow.github.io/Tempest/api/swagger/#/forecast/)
- remote-import

```WEATHERFLOW_COLLECTOR_DEBUG```

- true
- false

```WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD```

The password for your InfluxDB

```WEATHERFLOW_COLLECTOR_INFLUXDB_URL```

The URL connection string for your InfluxDB. For example: http://influxdb:8086/write?db=weatherflow

```WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME```

The username of your InfluxDB

```WEATHERFLOW_COLLECTOR_DEVICE_ID```

The Device ID of your Tempest

```WEATHERFLOW_COLLECTOR_STATION_ID```

The Station ID of your Tempest

```WEATHERFLOW_COLLECTOR_TOKEN```

The WeatherFlow Personal Access Token.

```WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL```

The URL connection string for your Grafana Loki endpoint. For example: http://loki:3100/loki/api/v1/push

```WEATHERFLOW_COLLECTOR_REMOTE_FORECAST_INTERVAL```

Number in seconds that you want to pull the forecast data. (Defaults to 60 seconds)

```WEATHERFLOW_COLLECTOR_REMOTE_REST_INTERVAL```

Number in seconds that you want to pull observability data. (Defaults to 60 seconds)

#### *Note - If a change is made to the location details of your WeatherFlow device (such as station name, public name, longitude, latitude, etc.) - please rerun the generate_docker-compose.sh script or manually update the environmental variables to match.*

## Obtaining Your Tempest Authentication Token

 You can obtain this by signing in to the Tempest Web App at tempestwx.com, then go to Settings -> Data Authorizations -> Create Token.

## Collector Details

#### remote-socket

This setting grabs all of the metrics from your Tempest and all of the [derived metrics](https://weatherflow.github.io/Tempest/api/derived-metric-formulas.html), accomplished with WeatherFlow backend AI systems. The metrics don't have the same metrics resolution as the local-udp collector but supports lightning suppression and sea level pressure adjustments. It also provides for additional events such as online and offline status. This setting works with both Grafana Loki and InfluxDB 1.8.

#### remote-rest

This setting is similiar to the remote-socket for obtaining Weatherflow observations but only pulls data once a minute from a REST call. A few additional metrics are available on this collector such as sea level pressure. Still working out which metrics make sense and the right kind of polling mechanism to put in place - so I'm trying out both!

#### local-udp

This setting provides a listener on UDP port 50222 for messages coming from your Tempest hub. It provides all of the raw observation details and details on the Hub and Tempest, such as RSSI Wifi details, uptime, sensor details, and device battery voltage. The observation metrics have a slightly higher resolution of data than what the REST/Socket API calls provide. However, it does not give any of the [derived metrics](https://weatherflow.github.io/Tempest/api/derived-metric-formulas.html) available with the REST/Socket API calls. This setting works with both Grafana Loki and InfluxDB 1.8.

#### remote-forecast

This setting populates the WeatherFlow Forecast dashboards. It makes a Web services call to pull the daily and hourly forecasts for your location and stores them in InfluxDB. It runs the forecasting process on startup and every 60 minutes after the start of the container. This setting works only works with InfluxDB 1.8.

#### remote-import

This setting populates the WeatherFlow local-udp metrics from the WeatherFlow Cloud. 

## Grafana Dashboards

Collecting data is only half the fun. Now it's time to provision some Grafana Dashboards to visualize all of our great WeatherFlow data. You'll find a [folder of dashboards](https://github.com/lux4rd0/weatherflow-collector/tree/main/dashboards) with collectors and backends split out.

### Alerts

<center><img src="./images/weatherflow_collector-alerts.jpg"></center>

Coming soon - a set of Grafana alerts to let you know of deviations in expected collector performance or weather metrics change.

### Current Conditions

<center><img src="./images/weatherflow_collector-current_conditions.jpg"></center>

This dashboard provides a comprehensive overview of your station location, combining all "at-a-glance" metrics from your WeatherFlow device. The current conditions dashboard is divided up into:

- **Temperature & Wind**: observed, feels like, forecast high and low, the chance of precipitation, humidity, sea level pressure, UV, wind speed, and direction.)

- **Sunrise & Sunset and Sky Conditions**

- **Temperature & Brightness**: Heat index, wind chill, dry bulb, wet bulb, dew point, station pressure, brightness, solar radiation, and air density.

- **Rain & Lightning**: Rain accumulation (today and yesterday), rain duration (today and yesterday), lightning last detected, last distance, and the number of lightning detections during the previous 3 hours.

### Device Details

<center><img src="./images/weatherflow_collector-device_details.jpg"></center>

This dashboard provides the current status for both the Tempest and your WeatherFlow hub, such as Uptime, Radio Status, RSSI, Reboot Count, I2C Bus Count Error, Radio Version, Network ID, Firmware Version, and Voltage.

RSSI and Battery Voltage over time defaulted to the last seven days are shown at the top of the dashboard, while current device details are shown below.

Sensor Status measurements are shown with a number related to each per minute collection from the device. Either "Sensors OK" is down or any failures, which sensor had the error. Note that if you have the Lightning Disturber enabled, you may see a high number of failures as electromagnetic interference is being suppressed.

### Forecast

<center><img src="./images/weatherflow_collector-forecast.jpg"></center>

Provides both a daily and hourly forecast in table format with charts below them. The default time range includes the current day plus the next nine upcoming days. The interval drop-down at the top defaults to 12 hours to provide for highs and lows forecasts. Clicking on any of the dates in the "Forecast - Daily" table will refresh the Forecast hourly table to that day's hourly forecasts. This can also be done from the top "Forecast Day" drop-down menu.

### Forecast Vs. Observed

<center><img src="./images/weatherflow_collector-forecast_vs_observed.jpg"></center>

As forecast data is collected, this dashboard may be used to compare what was forecasted (by how many days out) versus the observed metric from your WeatherFlow device. Temperature, Humidity, Wind, and UV measurements are covered here. By default, "All" available forecast days are overlayed over the observed metric. You can choose different "Days Out" from the top drop-down menu to compare individual forecasts.

### Historical (local-udp)

<center><img src="./images/weatherflow_collector-historical_local-udp.jpg"></center>

Provides a place to view weather details over longer periods of time. It defaults to 30 days with a 12-hour interval to show highs and lows for each of the Air Temperature, Humidity, Station Pressure, Solar, and Wind metrics. Precipitation Accumulation is displayed for any days that precipitation is detected.

### Historical (remote)

<center><img src="./images/weatherflow_collector-historical_remote.jpg"></center>

Provides a place to view weather details over longer periods of time. It defaults to 30 days with a 12-hour interval to show highs and lows for each of the Air Temperature, Humidity, Station Pressure, Solar, and Wind metrics. Includes [derived metrics](https://weatherflow.github.io/Tempest/api/derived-metric-formulas.html)  as well such as Feels Like, Heat Index, Wind Chill, Dry Bulb, Wet Bulb, and Dew Point. Precipitation Accumulation is displayed for any days that precipitation is detected.

### Overview

<center><img src="./images/weatherflow_collector-overview.jpg"></center>

Overview is the default landing page for the WeatherFlow Collector AIO. It provides an overview of current weather metrics and live updates for Wind and direction. From here, you can choose other dashboards from the top right-hand dashboard panel or the top left-hand side drop-downs under "WeatherFlow Collector Dashboards".

### Rain and Lightning

<center><img src="./images/weatherflow_collector-rain_and_lightning.jpg"></center>

A historical view (defaulted to seven days) shows both the precipitation rate alongside the daily accumulation. As you zoom into the specific precipitation events, change the Interval drop-down to smaller increments (up to 1-minute collections) for finer rates.

For Lightning, Strikes and Distance show on a heatmap visualization. Time is across the x-axis while the number of detected lightning strikes is bucketed by color (dark blue to yellow). The Y-axis shows the bucketed distances (up to 40 miles away). Hover over each of the squares to see a histogram of each strike/distance count.

<center><img src="./images/weatherflow_collector-rain_and_lightning_histogram.jpg"></center>

### System Stats

<center><img src="./images/weatherflow_collector-system_stats.jpg"></center>

Provides for two different system metrics to understand the health of your weatherflow-collector. At the top shows which container is running and each of the times that it last started. A default Docker health check is enabled for each container that requires some data to be received and persisted every 60 seconds, or the container is marked unhealthy. This check happens every 5 seconds and will restart the container after three failed checks.

The second section shows how long it's taking to receive and persist forecasts and observations.

 - Forecast Build Duration - Daily - between 1 and 2 seconds
 Forecast Build Duration - Hourly - between 30 and 45 seconds (note - if this takes longer than 60 seconds, the Docker Health Check will currently recycle the container. A future update will change this to take a longer build duration into account. For now - set the "WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED" environmental variable to "false".
 - Rest Observations - between 1 and 2 seconds

### Today So Far (local-udp)

<center><img src="./images/weatherflow_collector-today_so_far_local-udp.jpg"></center>

The dashboard provides for Temperature, Relative Humidity, Station Pressure, Accumulated Rain, Solar Radiation, Illuminance, UV, Lightning Strike, and Wind Speed from midnight to the current time. These reflect the direct measurements from the local-udp collector (or imported from WeatherFlow).

### Today So Far (remote)

<center><img src="./images/weatherflow_collector-today_so_far_remote.jpg"></center>

This dashboard provides for the Temperature (Air, Feels Like, Heat Index, Wind Chill, Dry Bulb, Wet Bulb, and Dew Point), Relative Humidity, Air Density, Station Pressure (with Trending), Accumulated Rain, Solar Radiation, Illuminance, UV, Lightning Strike, and Wind Speed from midnight to the current time. These reflect the WeatherFlow measurements from data sent to WeatherFlow and include [derived metrics](https://weatherflow.github.io/Tempest/api/derived-metric-formulas.html) in the response.

## Multiple Devices

The data collector supports mulitple devices and the dashboards have been designed to accomidate such.

### Time Zone Variable

A TZ variable is required when running the docker-compose.yml file. (It's populated automatically from the generate_docker-compose.sh scripts) 

TZ is specific to each of the device locations and is required as part of the InluxDB query to identify day breaks and other 12/24 hour interval groups. For dashboards with multiple devices in different time zones, you may need to switch the time zones from the top drop-down to correctly group midnight/noon periods.

## Roadmap

See the open issues for a list of proposed features (and known issues).

## Contact

Dave Schmid - [@lux4rd0](https://twitter.com/lux4rd0) - dave@pulpfree.org
Project Link: https://github.com/lux4rd0/weatherflow-collector

## Acknowledgements

- Grafana Labs - https://grafana.com/
- Grafana - https://grafana.com/oss/grafana/
- Grafana Dashboard Community - https://grafana.com/grafana/dashboards
