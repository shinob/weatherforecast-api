"""
WeatherForecast API Client for Python

Usage:
    from weather_forecast_client import WeatherForecastClient

    client = WeatherForecastClient('your_api_token')
    forecast = client.get_forecast(35.6762, 139.6503)
    print(forecast.temperature_at(0))
"""

import requests
from typing import List, Optional, Dict, Any
from dataclasses import dataclass


class WeatherAPIError(Exception):
    """Custom exception for API errors"""
    pass


@dataclass
class ForecastItem:
    """Individual forecast item"""

    datetime: str
    temperature: float      # Temperature (°C)
    precipitation: float    # Precipitation (mm)
    wind_speed: float      # Wind speed (m/s)
    wind_direction: float  # Wind direction (degrees)
    humidity: float        # Relative humidity (%)
    cloud_cover: float     # Total cloud cover (%)
    pressure: float        # Pressure (hPa)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ForecastItem':
        """Create ForecastItem from API data dictionary"""
        return cls(
            datetime=data['datetime'],
            temperature=data['TMP'],
            precipitation=data['APCP'],
            wind_speed=data['WSPD'],
            wind_direction=data['WDIR'],
            humidity=data['RH'],
            cloud_cover=data['TCDC'],
            pressure=data['PRES']
        )

    def wind_direction_compass(self) -> str:
        """Get wind direction as compass direction

        Returns:
            str: Compass direction (e.g., "N", "NE", "E")
        """
        directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                     'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW']
        index = int(round(self.wind_direction / 22.5) % 16)
        return directions[index]

    def weather_icon(self) -> str:
        """Get weather condition icon

        Returns:
            str: Weather icon emoji
        """
        if self.precipitation > 1.0:
            return '🌧️'  # Rain
        elif self.precipitation > 0.1:
            return '🌦️'  # Light rain
        elif self.cloud_cover > 70:
            return '☁️'  # Cloudy
        elif self.cloud_cover > 30:
            return '⛅'  # Partly cloudy
        else:
            return '☀️'  # Sunny

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary

        Returns:
            dict: Item data as dictionary
        """
        return {
            'datetime': self.datetime,
            'temperature': self.temperature,
            'precipitation': self.precipitation,
            'wind_speed': self.wind_speed,
            'wind_direction': self.wind_direction,
            'wind_direction_compass': self.wind_direction_compass(),
            'humidity': self.humidity,
            'cloud_cover': self.cloud_cover,
            'pressure': self.pressure,
            'weather_icon': self.weather_icon()
        }


class Forecast:
    """Forecast data object"""

    def __init__(self, result: Dict[str, Any], hours: int = 24):
        """Initialize Forecast object

        Args:
            result: API result data
            hours: Number of hours to include
        """
        lat, lng = result['latlng'].split(',')
        self.latitude = float(lat)
        self.longitude = float(lng)
        self.grib2file_time = result['grib2file_time']
        self.data: List[ForecastItem] = [
            ForecastItem.from_dict(item)
            for item in result['forecast'][:hours]
        ]

    def at(self, hour: int) -> Optional[ForecastItem]:
        """Get forecast item at specific hour

        Args:
            hour: Hour index (0-based)

        Returns:
            ForecastItem or None if out of range
        """
        if 0 <= hour < len(self.data):
            return self.data[hour]
        return None

    def temperature_at(self, hour: int) -> Optional[float]:
        """Get temperature at specific hour

        Args:
            hour: Hour index (0-based)

        Returns:
            Temperature in Celsius or None
        """
        item = self.at(hour)
        return item.temperature if item else None

    def precipitation_at(self, hour: int) -> Optional[float]:
        """Get precipitation at specific hour

        Args:
            hour: Hour index (0-based)

        Returns:
            Precipitation in mm or None
        """
        item = self.at(hour)
        return item.precipitation if item else None

    def all(self) -> List[ForecastItem]:
        """Get all forecast items

        Returns:
            List of all forecast items
        """
        return self.data

    def __len__(self) -> int:
        """Get number of forecast hours"""
        return len(self.data)

    def __iter__(self):
        """Iterate over all forecast items"""
        return iter(self.data)

    def __getitem__(self, index: int) -> ForecastItem:
        """Get forecast item by index"""
        return self.data[index]


class WeatherForecastClient:
    """WeatherForecast API Client"""

    API_BASE_URL = 'https://weather.ittools.biz/api/forecast/GSM'

    def __init__(self, api_token: str):
        """Initialize the client with an API token

        Args:
            api_token: Your weather API token
        """
        self.api_token = api_token

    def get_forecast(self, latitude: float, longitude: float, hours: int = 24) -> Forecast:
        """Get weather forecast for a specific location

        Args:
            latitude: Latitude of the location
            longitude: Longitude of the location
            hours: Number of hours to forecast (default: 24, max: 172)

        Returns:
            Forecast object containing weather data

        Raises:
            WeatherAPIError: If the API request fails
        """
        url = f"{self.API_BASE_URL}/{self.api_token}/{latitude},{longitude}"

        try:
            response = requests.get(url, timeout=30)
            response.raise_for_status()

            data = response.json()

            if 'error' in data:
                raise WeatherAPIError(data['error'])

            if data.get('code') != 200:
                raise WeatherAPIError(f"API Error: Code {data.get('code')}")

            return Forecast(data['result'], hours)

        except requests.exceptions.RequestException as e:
            raise WeatherAPIError(f"Request failed: {str(e)}")
        except (KeyError, ValueError) as e:
            raise WeatherAPIError(f"Failed to parse response: {str(e)}")
