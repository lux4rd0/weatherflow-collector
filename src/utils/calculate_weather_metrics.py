# calcuate_weather_metrics.py

"""
CalculateWeatherMetrics Module for Advanced Weather Data Processing

This module offers a comprehensive suite of static methods under the CalculateWeatherMetrics class, 
designed to compute a range of weather-related metrics. These metrics include vapor pressure deficit (VPD), 
dew point, heat index, absolute humidity, visibility index, sea level pressure, wind chill, Beaufort scale rating, 
and frost point, tailored to provide detailed insights from meteorological data.

Key Features:
- Calculates essential weather metrics from basic meteorological data inputs like temperature, 
  relative humidity, station pressure, and wind speed.
- Implements both standard and advanced methods for calculating weather phenomena, 
  using formulas like the Magnus-Tetens approximation and Buck's Improved Formula.
- Designed to assist in detailed climate analysis, agricultural planning, meteorological research, 
  and environmental monitoring.

Usage:
This module is intended to be imported and utilized in contexts where weather data is analyzed. 
It can process individual data points or batches of weather data, returning calculated metrics 
that offer deeper insights into current and forecasted weather conditions.

Dependencies:
- math: Required for executing mathematical operations and formulae.
- logging: For logging purposes, especially useful in debugging and operational monitoring.

Example:
To use this module, simply import it and call the appropriate static methods with your weather data. 
For instance, `CalculateWeatherMetrics.calculate_vpd(temperature, humidity)` will provide the vapor pressure deficit.

Classes:
- CalculateWeatherMetrics: Contains all static methods for weather metric calculations.

Methods:
- calculate_weather_metrics: Orchestrates the calculation of various metrics based on input data.
- calculate_vpd, calculate_vpd_buck, calculate_dew_point, etc.: Individual methods for specific weather calculations.

Author: [Your Name]
Created: [Creation Date]
"""

import math
import logging
from datetime import datetime

# from data_storage import DataStorage
from logger import get_module_logger
import utils.utils as utils


class CalculateWeatherMetrics:
    @staticmethod
    def calculate_weather_metrics(data):

        elevation = data.get("elevation")
        temperature = data.get("air_temperature")
        relative_humidity = data.get("relative_humidity")
        station_pressure = data.get("station_pressure")
        wind_speed_mps = data.get("wind_avg")

        calculated_metrics = {}

        if temperature is not None and relative_humidity is not None:
            if station_pressure is not None:
                vpd_buck = CalculateWeatherMetrics.calculate_vpd_buck(
                    temperature, relative_humidity, station_pressure
                )
                if vpd_buck is not None:
                    calculated_metrics["calculated_vpd_buck"] = vpd_buck

            vpd = CalculateWeatherMetrics.calculate_vpd(temperature, relative_humidity)
            if vpd is not None:
                calculated_metrics["calculated_vpd"] = vpd

            dew_point = CalculateWeatherMetrics.calculate_dew_point(
                temperature, relative_humidity
            )
            if dew_point is not None:
                calculated_metrics["calculated_dew_point"] = dew_point

            dew_point_buck = CalculateWeatherMetrics.calculate_dew_point_buck(
                temperature, relative_humidity
            )
            if dew_point_buck is not None:
                calculated_metrics["calculated_dew_point_buck"] = dew_point_buck

            heat_index = CalculateWeatherMetrics.calculate_heat_index(
                temperature, relative_humidity
            )
            if heat_index is not None:
                calculated_metrics["calculated_heat_index"] = heat_index

            absolute_humidity = CalculateWeatherMetrics.calculate_absolute_humidity(
                temperature, relative_humidity
            )
            if absolute_humidity is not None:
                calculated_metrics["calculated_absolute_humidity"] = absolute_humidity

            visibility_index = CalculateWeatherMetrics.calculate_visibility_index(
                temperature, relative_humidity
            )
            if visibility_index is not None:
                calculated_metrics["calculated_visibility_index"] = visibility_index

        if (
            station_pressure is not None
            and temperature is not None
            and elevation is not None
        ):
            sea_level_pressure = CalculateWeatherMetrics.calculate_sea_level_pressure(
                station_pressure, elevation, temperature
            )
            if sea_level_pressure is not None:
                calculated_metrics["calculated_sea_level_pressure"] = sea_level_pressure

        if temperature is not None and wind_speed_mps is not None:
            wind_chill = CalculateWeatherMetrics.calculate_wind_chill(
                temperature, wind_speed_mps
            )
            if wind_chill is not None:
                calculated_metrics["calculated_wind_chill"] = wind_chill

        if wind_speed_mps is not None:
            beaufort_scale_rating = (
                CalculateWeatherMetrics.calculate_beaufort_scale_rating(wind_speed_mps)
            )
            if beaufort_scale_rating is not None:
                calculated_metrics[
                    "calculated_beaufort_scale_rating"
                ] = beaufort_scale_rating

        if temperature is not None and relative_humidity is not None:
            frost_point = CalculateWeatherMetrics.calculate_frost_point(
                temperature, relative_humidity
            )
            if frost_point is not None:
                calculated_metrics["calculated_frost_point"] = frost_point

        if all(
            metric is not None
            for metric in [
                temperature,
                dew_point,
                relative_humidity,
                wind_speed_mps,
                vpd,
                absolute_humidity,
                wind_chill,
                #sea_level_pressure,
                frost_point,
            ]
        ):
            frost_risk = CalculateWeatherMetrics.calculate_frost_risk(
                temperature,
                dew_point,
                relative_humidity,
                wind_speed_mps,
                vpd,
                absolute_humidity,
                wind_chill,
                #sea_level_pressure,
                frost_point,
            )

            if frost_risk is not None:
                calculated_metrics["calculated_frost_risk"] = frost_risk

        return calculated_metrics

    @staticmethod
    def calculate_vpd(temperature, relative_humidity):
        if temperature is None or relative_humidity is None:
            return None
        a = 17.27
        b = 237.7
        es = 6.112 * math.exp((a * temperature) / (temperature + b))
        ea = (relative_humidity / 100.0) * es
        vpd = es - ea
        return vpd

    @staticmethod
    def calculate_vpd_buck(temperature, relative_humidity, pressure):
        if temperature is None or relative_humidity is None or pressure is None:
            return None
        a = 6.1121
        b = 17.368
        c = 238.88
        pressure_kpa = pressure / 10
        es = a * math.exp((b * temperature) / (temperature + c))
        es_corrected = es * (pressure_kpa / 101.325)
        ea = (relative_humidity / 100.0) * es_corrected
        vpd = es_corrected - ea
        return vpd

    @staticmethod
    def calculate_dew_point(temperature, relative_humidity):
        if temperature is None or relative_humidity is None:
            return None

        if relative_humidity < 0 or relative_humidity > 100:
            return None
        a = 17.27
        b = 237.7
        try:
            alpha = ((a * temperature) / (b + temperature)) + math.log(
                relative_humidity / 100.0
            )
            dew_point = (b * alpha) / (a - alpha)
            return dew_point
        except (ValueError, ZeroDivisionError):
            return None

    @staticmethod
    def calculate_dew_point_buck(temperature, relative_humidity):
        if temperature is None or relative_humidity is None:
            return None

        if relative_humidity < 0 or relative_humidity > 100:
            return None
        a = 6.1121
        b = 18.678
        c = 257.14  # degrees Celsius
        d = 234.5  # degrees Celsius
        try:
            gamma = math.log(relative_humidity / 100.0) + (b - temperature / d) * (
                temperature / (c + temperature)
            )
            dew_point = c * gamma / (b - gamma)
            return dew_point
        except (ValueError, ZeroDivisionError):
            return None

    @staticmethod
    def calculate_heat_index(temperature, relative_humidity):
        if temperature is None or relative_humidity is None:
            return None
        temperature_fahrenheit = (temperature * 9 / 5) + 32
        if temperature_fahrenheit >= 80 and relative_humidity >= 40:
            c1 = -42.379
            c2 = 2.04901523
            c3 = 10.14333127
            c4 = -0.22475541
            c5 = -6.83783e-03
            c6 = -5.481717e-02
            c7 = 1.22874e-03
            c8 = 8.5282e-04
            c9 = -1.99e-06
            heat_index_fahrenheit = (
                c1
                + (c2 * temperature_fahrenheit)
                + (c3 * relative_humidity)
                + (c4 * temperature_fahrenheit * relative_humidity)
                + (c5 * temperature_fahrenheit**2)
                + (c6 * relative_humidity**2)
                + (c7 * temperature_fahrenheit**2 * relative_humidity)
                + (c8 * temperature_fahrenheit * relative_humidity**2)
                + (c9 * temperature_fahrenheit**2 * relative_humidity**2)
            )
            heat_index_celsius = (heat_index_fahrenheit - 32) * 5 / 9
            return heat_index_celsius
        return temperature

    @staticmethod
    def calculate_absolute_humidity(temperature, relative_humidity):
        if temperature is None or relative_humidity is None:
            return None

        es = CalculateWeatherMetrics.calculate_saturation_vapor_pressure_goff_gratch(
            temperature
        )
        ea = (relative_humidity / 100.0) * es
        ea_pa = ea * 100
        R = 8.314  # J/(mol·K)
        Mw = 0.01801528  # kg/mol
        temperature_kelvin = temperature + 273.15
        absolute_humidity = (ea_pa * Mw) / (R * temperature_kelvin) * 1000
        return absolute_humidity

    @staticmethod
    def calculate_visibility_index(temperature, relative_humidity):
        if temperature is None or relative_humidity is None:
            return None

        dew_point = CalculateWeatherMetrics.calculate_dew_point_buck(
            temperature, relative_humidity
        )
        if dew_point is not None:

            dew_point_difference = temperature - dew_point
            return dew_point_difference

    @staticmethod
    def calculate_sea_level_pressure(station_pressure, altitude, temperature):
        if station_pressure is None or altitude is None or temperature is None:
            return None

        temperature_kelvin = temperature + 273.15
        sea_level_pressure = station_pressure * (
            1 + ((0.0065 * altitude) / temperature_kelvin)
        ) ** (9.80665 / (287.05 * 0.0065))
        return sea_level_pressure

    @staticmethod
    def calculate_wind_chill(temperature, wind_speed_mps):
        if temperature is None or wind_speed_mps is None:
            return None
        if temperature <= 10 and wind_speed_mps >= 0.5:
            wind_speed_kmh = wind_speed_mps * 3.6
            wind_chill = (
                13.12
                + (0.6215 * temperature)
                - (11.37 * (wind_speed_kmh**0.16))
                + (0.3965 * temperature * (wind_speed_kmh**0.16))
            )
            return wind_chill
        else:
            return temperature

    @staticmethod
    def calculate_beaufort_scale_rating(wind_speed_mps):
        if wind_speed_mps is None:
            return None
        if wind_speed_mps < 0.5:
            return 0
        elif wind_speed_mps < 1.5:
            return 1
        elif wind_speed_mps < 3.4:
            return 2
        elif wind_speed_mps < 5.5:
            return 3
        elif wind_speed_mps < 8.0:
            return 4
        elif wind_speed_mps < 10.8:
            return 5
        elif wind_speed_mps < 13.9:
            return 6
        elif wind_speed_mps < 17.2:
            return 7
        elif wind_speed_mps < 20.8:
            return 8
        elif wind_speed_mps < 24.5:
            return 9
        elif wind_speed_mps < 28.5:
            return 10
        elif wind_speed_mps < 32.7:
            return 11
        else:
            return 12

    @staticmethod
    def calculate_frost_point(temperature, relative_humidity):
        if temperature is None or relative_humidity is None:
            return None
        if relative_humidity < 0 or relative_humidity > 100 or temperature >= 0:
            return None
        a = 17.27
        b = 237.7
        try:
            alpha = ((a * temperature) / (b + temperature)) + math.log(
                relative_humidity / 100.0
            )
            frost_point = (b * alpha) / (a - alpha)
            return frost_point
        except (ValueError, ZeroDivisionError):
            return None

    @staticmethod
    def calculate_saturation_vapor_pressure_goff_gratch(temperature):
        if temperature is None:
            return None

        T = temperature + 273.15
        log_es = (
            -7.90298 * ((373.16 / T) - 1)
            + 5.02808 * math.log10(373.16 / T)
            - 1.3816e-7 * (10 ** (11.344 * (1 - T / 373.16)) - 1)
            + 8.1328e-3 * (10 ** (-3.49149 * (373.16 / T - 1)))
            + math.log10(1013.246)
        )
        saturation_vapor_pressure = 10**log_es
        return saturation_vapor_pressure

    @staticmethod
    def calculate_station_pressure_from_sea_level(sea_level_pressure, elevation):
        if sea_level_pressure is None or elevation is None:
            return None
        """
        Calculates the station pressure from the sea level pressure and elevation.

        Args:
            sea_level_pressure (float): Sea level pressure in hPa (hectopascals).
            elevation (float): Elevation in meters above sea level.

        Returns:
            float: Station pressure in hPa.
        """

        # Convert temperature to Kelvin for the standard atmosphere
        standard_temperature_kelvin = (
            288.15  # Standard temperature at sea level in Kelvin
        )

        # Calculate station pressure using the hypsometric formula
        station_pressure = sea_level_pressure / (
            1 + ((0.0065 * elevation) / standard_temperature_kelvin)
        ) ** (9.80665 / (287.05 * 0.0065))

        return station_pressure

    @staticmethod
    def calculate_frost_risk(
        temperature,
        dew_point,
        relative_humidity,
        wind_speed_mps,
        vpd,
        absolute_humidity,
        wind_chill,
        #sea_level_pressure,
        frost_point,
    ):
        """
        Calculates the risk of frost based on a comprehensive range of weather parameters.

        Args:
            temperature (float): Air temperature in degrees Celsius.
            dew_point (float): Dew point in degrees Celsius.
            relative_humidity (float): Relative humidity in percentage.
            wind_speed_mps (float): Wind speed in meters per second.
            vpd (float): Vapor pressure deficit.
            absolute_humidity (float): Absolute humidity.
            wind_chill (float): Wind chill temperature in degrees Celsius.
            sea_level_pressure (float): Sea level pressure in hPa.
            frost_point (float): Frost point in degrees Celsius.

        Returns:
            int: Frost risk as a percentage.
        """

        # Define weights for each parameter upfront
        temp_weight = 1.5
        dew_point_weight = 1.2
        rh_weight = 1.0
        wind_speed_weight = 1.0
        vpd_weight = 0.5
        absolute_humidity_weight = 0.5
        wind_chill_weight = 1.0
        #sea_level_pressure_weight = 0.3
        frost_point_weight = 1.5

        if any(
            param is None
            for param in [
                temperature,
                dew_point,
                relative_humidity,
                wind_speed_mps,
                vpd,
                absolute_humidity,
                wind_chill,
                #sea_level_pressure,
                frost_point,
            ]
        ):
            return None

        frost_risk = 0

        # Apply weights in calculations
        frost_risk += max(0, (0 - temperature) * temp_weight)
        frost_risk += max(0, (0 - dew_point) * dew_point_weight)
        frost_risk += max(0, (relative_humidity - 90) * rh_weight)
        frost_risk += max(0, (3 - wind_speed_mps) * wind_speed_weight)
        frost_risk += max(0, (0.5 - vpd) * vpd_weight)
        frost_risk += max(0, (3 - absolute_humidity) * absolute_humidity_weight)
        frost_risk += max(0, (0 - wind_chill) * wind_chill_weight)
        #frost_risk += max(0, (1020 - sea_level_pressure) * sea_level_pressure_weight)
        frost_risk += max(0, (0 - frost_point) * frost_point_weight)

        # Cap the risk at 100%
        frost_risk = min(frost_risk, 100)

        return round(frost_risk)
