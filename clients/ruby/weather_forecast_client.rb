require 'net/http'
require 'json'
require 'uri'

# WeatherForecast API Client for Ruby
#
# Usage:
#   client = WeatherForecastClient.new('your_api_token')
#   forecast = client.get_forecast(35.6762, 139.6503)
#   puts forecast.temperature_at(0)
#
class WeatherForecastClient
  API_BASE_URL = 'https://weather.ittools.biz/api/forecast/GSM'

  attr_reader :api_token

  # Initialize the client with an API token
  #
  # @param api_token [String] Your weather API token
  def initialize(api_token)
    @api_token = api_token
  end

  # Get weather forecast for a specific location
  #
  # @param latitude [Float] Latitude of the location
  # @param longitude [Float] Longitude of the location
  # @param hours [Integer] Number of hours to forecast (default: 24, max: 172)
  # @return [Forecast] Forecast object containing weather data
  # @raise [WeatherAPIError] if the API request fails
  def get_forecast(latitude, longitude, hours = 24)
    url = URI("#{API_BASE_URL}/#{@api_token}/#{latitude},#{longitude}")

    begin
      response = Net::HTTP.get_response(url)

      unless response.is_a?(Net::HTTPSuccess)
        raise WeatherAPIError, "HTTP Error: #{response.code} #{response.message}"
      end

      data = JSON.parse(response.body)

      if data['error']
        raise WeatherAPIError, data['error']
      end

      unless data['code'] == 200
        raise WeatherAPIError, "API Error: Code #{data['code']}"
      end

      Forecast.new(data['result'], hours)
    rescue JSON::ParserError => e
      raise WeatherAPIError, "Failed to parse JSON response: #{e.message}"
    rescue StandardError => e
      raise WeatherAPIError, "Request failed: #{e.message}"
    end
  end
end

# Forecast data object
class Forecast
  attr_reader :latitude, :longitude, :grib2file_time, :data

  # @param result [Hash] API result data
  # @param hours [Integer] Number of hours to include
  def initialize(result, hours = 24)
    @latitude, @longitude = result['latlng'].split(',').map(&:to_f)
    @grib2file_time = result['grib2file_time']
    @data = result['forecast'].take(hours).map { |item| ForecastItem.new(item) }
  end

  # Get forecast item at specific hour
  #
  # @param hour [Integer] Hour index (0-based)
  # @return [ForecastItem, nil] Forecast item or nil if out of range
  def at(hour)
    @data[hour]
  end

  # Get temperature at specific hour
  #
  # @param hour [Integer] Hour index (0-based)
  # @return [Float, nil] Temperature in Celsius
  def temperature_at(hour)
    item = at(hour)
    item ? item.temperature : nil
  end

  # Get precipitation at specific hour
  #
  # @param hour [Integer] Hour index (0-based)
  # @return [Float, nil] Precipitation in mm
  def precipitation_at(hour)
    item = at(hour)
    item ? item.precipitation : nil
  end

  # Get all forecast items
  #
  # @return [Array<ForecastItem>] All forecast items
  def all
    @data
  end

  # Get number of forecast hours
  #
  # @return [Integer] Number of hours
  def length
    @data.length
  end

  # Iterate over all forecast items
  #
  # @yield [ForecastItem] Each forecast item
  def each(&block)
    @data.each(&block)
  end
end

# Individual forecast item
class ForecastItem
  attr_reader :datetime, :temperature, :precipitation, :wind_speed, :wind_direction,
              :humidity, :cloud_cover, :pressure

  # @param data [Hash] Forecast item data
  def initialize(data)
    @datetime = data['datetime']
    @temperature = data['TMP']          # Temperature (°C)
    @precipitation = data['APCP']        # Precipitation (mm)
    @wind_speed = data['WSPD']          # Wind speed (m/s)
    @wind_direction = data['WDIR']      # Wind direction (degrees)
    @humidity = data['RH']              # Relative humidity (%)
    @cloud_cover = data['TCDC']         # Total cloud cover (%)
    @pressure = data['PRES']            # Pressure (hPa)
  end

  # Get wind direction as compass direction
  #
  # @return [String] Compass direction (e.g., "N", "NE", "E")
  def wind_direction_compass
    directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                  'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW']
    index = ((@wind_direction / 22.5).round % 16)
    directions[index]
  end

  # Get weather condition icon
  #
  # @return [String] Weather icon emoji
  def weather_icon
    if @precipitation > 1.0
      '🌧️'  # Rain
    elsif @precipitation > 0.1
      '🌦️'  # Light rain
    elsif @cloud_cover > 70
      '☁️'  # Cloudy
    elsif @cloud_cover > 30
      '⛅'  # Partly cloudy
    else
      '☀️'  # Sunny
    end
  end

  # Convert to hash
  #
  # @return [Hash] Item data as hash
  def to_h
    {
      datetime: @datetime,
      temperature: @temperature,
      precipitation: @precipitation,
      wind_speed: @wind_speed,
      wind_direction: @wind_direction,
      wind_direction_compass: wind_direction_compass,
      humidity: @humidity,
      cloud_cover: @cloud_cover,
      pressure: @pressure,
      weather_icon: weather_icon
    }
  end
end

# Custom exception for API errors
class WeatherAPIError < StandardError; end
