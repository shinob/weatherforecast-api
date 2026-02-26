<?php
/**
 * WeatherForecast API Client for PHP
 *
 * Usage:
 *   require_once 'WeatherForecastClient.php';
 *
 *   $client = new WeatherForecastClient('your_api_token');
 *   $forecast = $client->getForecast(35.6762, 139.6503);
 *   echo $forecast->temperatureAt(0);
 */

/**
 * Custom exception for API errors
 */
class WeatherAPIException extends Exception {}

/**
 * Individual forecast item
 */
class ForecastItem {
    public $datetime;
    public $temperature;      // Temperature (°C)
    public $precipitation;    // Precipitation (mm)
    public $windSpeed;       // Wind speed (m/s)
    public $windDirection;   // Wind direction (degrees)
    public $humidity;        // Relative humidity (%)
    public $cloudCover;      // Total cloud cover (%)
    public $pressure;        // Pressure (hPa)

    /**
     * Create ForecastItem from API data
     *
     * @param array $data API data
     */
    public function __construct(array $data) {
        $this->datetime = $data['datetime'];
        $this->temperature = $data['TMP'];
        $this->precipitation = $data['APCP'];
        $this->windSpeed = $data['WSPD'];
        $this->windDirection = $data['WDIR'];
        $this->humidity = $data['RH'];
        $this->cloudCover = $data['TCDC'];
        $this->pressure = $data['PRES'];
    }

    /**
     * Get wind direction as compass direction
     *
     * @return string Compass direction (e.g., "N", "NE", "E")
     */
    public function getWindDirectionCompass(): string {
        $directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
        $index = (int)round($this->windDirection / 22.5) % 16;
        return $directions[$index];
    }

    /**
     * Get weather condition icon
     *
     * @return string Weather icon emoji
     */
    public function getWeatherIcon(): string {
        if ($this->precipitation > 1.0) {
            return '🌧️';  // Rain
        } elseif ($this->precipitation > 0.1) {
            return '🌦️';  // Light rain
        } elseif ($this->cloudCover > 70) {
            return '☁️';  // Cloudy
        } elseif ($this->cloudCover > 30) {
            return '⛅';  // Partly cloudy
        } else {
            return '☀️';  // Sunny
        }
    }

    /**
     * Convert to array
     *
     * @return array Item data as array
     */
    public function toArray(): array {
        return [
            'datetime' => $this->datetime,
            'temperature' => $this->temperature,
            'precipitation' => $this->precipitation,
            'wind_speed' => $this->windSpeed,
            'wind_direction' => $this->windDirection,
            'wind_direction_compass' => $this->getWindDirectionCompass(),
            'humidity' => $this->humidity,
            'cloud_cover' => $this->cloudCover,
            'pressure' => $this->pressure,
            'weather_icon' => $this->getWeatherIcon()
        ];
    }
}

/**
 * Forecast data object
 */
class Forecast implements Iterator, Countable {
    public $latitude;
    public $longitude;
    public $grib2fileTime;
    public $data;
    private $position = 0;

    /**
     * Initialize Forecast object
     *
     * @param array $result API result data
     * @param int $hours Number of hours to include
     */
    public function __construct(array $result, int $hours = 24) {
        list($lat, $lng) = explode(',', $result['latlng']);
        $this->latitude = (float)$lat;
        $this->longitude = (float)$lng;
        $this->grib2fileTime = $result['grib2file_time'];

        $this->data = array_map(
            function($item) { return new ForecastItem($item); },
            array_slice($result['forecast'], 0, $hours)
        );
    }

    /**
     * Get forecast item at specific hour
     *
     * @param int $hour Hour index (0-based)
     * @return ForecastItem|null Forecast item or null if out of range
     */
    public function at(int $hour): ?ForecastItem {
        return $this->data[$hour] ?? null;
    }

    /**
     * Get temperature at specific hour
     *
     * @param int $hour Hour index (0-based)
     * @return float|null Temperature in Celsius
     */
    public function temperatureAt(int $hour): ?float {
        $item = $this->at($hour);
        return $item ? $item->temperature : null;
    }

    /**
     * Get precipitation at specific hour
     *
     * @param int $hour Hour index (0-based)
     * @return float|null Precipitation in mm
     */
    public function precipitationAt(int $hour): ?float {
        $item = $this->at($hour);
        return $item ? $item->precipitation : null;
    }

    /**
     * Get all forecast items
     *
     * @return array All forecast items
     */
    public function all(): array {
        return $this->data;
    }

    // Iterator interface methods
    public function rewind(): void {
        $this->position = 0;
    }

    public function current(): ForecastItem {
        return $this->data[$this->position];
    }

    public function key(): int {
        return $this->position;
    }

    public function next(): void {
        ++$this->position;
    }

    public function valid(): bool {
        return isset($this->data[$this->position]);
    }

    // Countable interface
    public function count(): int {
        return count($this->data);
    }
}

/**
 * WeatherForecast API Client
 */
class WeatherForecastClient {
    const API_BASE_URL = 'https://weather.ittools.biz/api/forecast/GSM';

    private $apiToken;

    /**
     * Initialize the client with an API token
     *
     * @param string $apiToken Your weather API token
     */
    public function __construct(string $apiToken) {
        $this->apiToken = $apiToken;
    }

    /**
     * Get weather forecast for a specific location
     *
     * @param float $latitude Latitude of the location
     * @param float $longitude Longitude of the location
     * @param int $hours Number of hours to forecast (default: 24, max: 172)
     * @return Forecast Forecast object containing weather data
     * @throws WeatherAPIException if the API request fails
     */
    public function getForecast(float $latitude, float $longitude, int $hours = 24): Forecast {
        $url = self::API_BASE_URL . "/{$this->apiToken}/{$latitude},{$longitude}";

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 30,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_SSL_VERIFYPEER => true
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($response === false) {
            throw new WeatherAPIException("Request failed: {$curlError}");
        }

        if ($httpCode !== 200) {
            throw new WeatherAPIException("HTTP Error: {$httpCode}");
        }

        $data = json_decode($response, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new WeatherAPIException("Failed to parse JSON response: " . json_last_error_msg());
        }

        if (isset($data['error'])) {
            throw new WeatherAPIException($data['error']);
        }

        if (!isset($data['code']) || $data['code'] !== 200) {
            $code = $data['code'] ?? 'unknown';
            throw new WeatherAPIException("API Error: Code {$code}");
        }

        return new Forecast($data['result'], $hours);
    }
}
