# WeatherForecast API Client Libraries

WeatherForecast APIを**Ruby**、**Python**、**PHP**から簡単に利用できるクライアントライブラリです。

## 📚 対応言語

- **Ruby** - シンプルで読みやすいAPI
- **Python** - 型ヒント対応、dataclassベース
- **PHP** - Iterator/Countable実装

## 🌟 特徴

すべてのライブラリで統一された以下のインターフェースを提供：

- ✅ シンプルで直感的なAPI
- ✅ 型安全な設計
- ✅ エラーハンドリング
- ✅ 天気アイコン自動判定
- ✅ 風向の方位変換
- ✅ イテレータサポート

## 📦 インストール

### Ruby

```bash
cd clients/ruby
# 依存パッケージは標準ライブラリのみ
```

### Python

```bash
cd clients/python
pip install -r requirements.txt
```

### PHP

```bash
cd clients/php
# 依存パッケージなし（PHP 7.4以上、cURL拡張が必要）
```

## 🚀 クイックスタート

### Ruby

```ruby
require_relative 'weather_forecast_client'

client = WeatherForecastClient.new('your_api_token')
forecast = client.get_forecast(35.6762, 139.6503, 24)

# 最初の時間の気温を取得
puts forecast.temperature_at(0)

# すべての予報をループ
forecast.each do |item|
  puts "#{item.datetime}: #{item.temperature}°C #{item.weather_icon}"
end
```

### Python

```python
from weather_forecast_client import WeatherForecastClient

client = WeatherForecastClient('your_api_token')
forecast = client.get_forecast(35.6762, 139.6503, 24)

# 最初の時間の気温を取得
print(forecast.temperature_at(0))

# すべての予報をループ
for item in forecast:
    print(f"{item.datetime}: {item.temperature}°C {item.weather_icon()}")
```

### PHP

```php
require_once 'WeatherForecastClient.php';

$client = new WeatherForecastClient('your_api_token');
$forecast = $client->getForecast(35.6762, 139.6503, 24);

// 最初の時間の気温を取得
echo $forecast->temperatureAt(0);

// すべての予報をループ
foreach ($forecast as $item) {
    echo "{$item->datetime}: {$item->temperature}°C {$item->getWeatherIcon()}\n";
}
```

## 📖 使用例

各言語のディレクトリに詳細な使用例があります：

- **Ruby**: `clients/ruby/example.rb`
- **Python**: `clients/python/example.py`
- **PHP**: `clients/php/example.php`

### 実行方法

```bash
# Ruby
ruby clients/ruby/example.rb

# Python
python3 clients/python/example.py

# PHP
php clients/php/example.php
```

## 🔧 API仕様

### クライアント初期化

| 言語 | 構文 |
|------|------|
| Ruby | `WeatherForecastClient.new(api_token)` |
| Python | `WeatherForecastClient(api_token)` |
| PHP | `new WeatherForecastClient($apiToken)` |

### 天気予報取得

```
get_forecast(latitude, longitude, hours=24)
getForecast(latitude, longitude, hours=24)
```

**パラメータ:**
- `latitude` (float): 緯度
- `longitude` (float): 経度
- `hours` (int, optional): 予報時間数（デフォルト: 24、最大: 172）

**戻り値:** `Forecast` オブジェクト

### Forecastオブジェクト

#### プロパティ

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `latitude` | float | 緯度 |
| `longitude` | float | 経度 |
| `grib2file_time` | string | 予報基準時刻 |
| `data` | array | ForecastItemの配列 |

#### メソッド

| メソッド | 説明 |
|---------|------|
| `at(hour)` | 指定時間の予報を取得 |
| `temperature_at(hour)` | 指定時間の気温を取得 |
| `precipitation_at(hour)` | 指定時間の降水量を取得 |
| `all()` | すべての予報を配列で取得 |
| `length` / `count()` | 予報時間数を取得 |

### ForecastItemオブジェクト

#### プロパティ

| プロパティ | 型 | 単位 | 説明 |
|-----------|-----|------|------|
| `datetime` | string | - | 予報日時 |
| `temperature` | float | °C | 気温 |
| `precipitation` | float | mm | 降水量 |
| `wind_speed` | float | m/s | 風速 |
| `wind_direction` | float | 度 | 風向（角度） |
| `humidity` | float | % | 湿度 |
| `cloud_cover` | float | % | 雲量 |
| `pressure` | float | hPa | 気圧 |

#### メソッド

| メソッド | 戻り値 | 説明 |
|---------|--------|------|
| `wind_direction_compass()` | string | 風向を方位で取得 (例: "N", "NE") |
| `weather_icon()` | string | 天気アイコン絵文字 |
| `to_h()` / `to_dict()` / `toArray()` | hash/dict/array | 辞書形式に変換 |

## 🌤️ 天気アイコン判定ロジック

すべてのライブラリで統一された判定ロジック：

- 🌧️ 雨: 降水量 > 1.0mm
- 🌦️ 小雨: 降水量 > 0.1mm
- ☁️ 曇り: 雲量 > 70%
- ⛅ 晴れ時々曇り: 雲量 > 30%
- ☀️ 晴れ: その他

## 🧭 風向変換

16方位に対応：

```
N (北), NNE (北北東), NE (北東), ENE (東北東),
E (東), ESE (東南東), SE (南東), SSE (南南東),
S (南), SSW (南南西), SW (南西), WSW (西南西),
W (西), WNW (西北西), NW (北西), NNW (北北西)
```

## ⚠️ エラーハンドリング

すべてのライブラリでカスタム例外を提供：

| 言語 | 例外クラス |
|------|-----------|
| Ruby | `WeatherAPIError` |
| Python | `WeatherAPIError` |
| PHP | `WeatherAPIException` |

### エラーハンドリング例

**Ruby:**
```ruby
begin
  forecast = client.get_forecast(35.6762, 139.6503)
rescue WeatherAPIError => e
  puts "エラー: #{e.message}"
end
```

**Python:**
```python
try:
    forecast = client.get_forecast(35.6762, 139.6503)
except WeatherAPIError as e:
    print(f"エラー: {e}")
```

**PHP:**
```php
try {
    $forecast = $client->getForecast(35.6762, 139.6503);
} catch (WeatherAPIException $e) {
    echo "エラー: " . $e->getMessage();
}
```

## 📍 APIエンドポイント

```
https://weather.ittools.biz/api/forecast/GSM/{token}/{lat},{lng}
```

## 💡 使用例集

### 1. 特定時間の気温取得

```ruby
# Ruby
temp = forecast.temperature_at(3)  # 3時間後の気温
```

```python
# Python
temp = forecast.temperature_at(3)  # 3時間後の気温
```

```php
// PHP
$temp = $forecast->temperatureAt(3);  // 3時間後の気温
```

### 2. 最高・最低気温の計算

```ruby
# Ruby
temps = forecast.data.map(&:temperature)
max_temp = temps.max
min_temp = temps.min
```

```python
# Python
temps = [item.temperature for item in forecast]
max_temp = max(temps)
min_temp = min(temps)
```

```php
// PHP
$temps = array_map(fn($item) => $item->temperature, $forecast->all());
$maxTemp = max($temps);
$minTemp = min($temps);
```

### 3. 雨が降る時間帯の検索

```ruby
# Ruby
rainy_hours = forecast.data.select { |item| item.precipitation > 0.1 }
```

```python
# Python
rainy_hours = [item for item in forecast if item.precipitation > 0.1]
```

```php
// PHP
$rainyHours = array_filter($forecast->all(), fn($item) => $item->precipitation > 0.1);
```

### 4. 平均気温の計算

```ruby
# Ruby
avg = forecast.data.sum(&:temperature) / forecast.length
```

```python
# Python
avg = sum(item.temperature for item in forecast) / len(forecast)
```

```php
// PHP
$total = array_sum(array_map(fn($item) => $item->temperature, $forecast->all()));
$avg = $total / count($forecast);
```

## 🔍 デバッグ

各言語でレスポンス全体を確認する方法：

```ruby
# Ruby
require 'pp'
pp forecast.data.first.to_h
```

```python
# Python
import pprint
pprint.pprint(forecast[0].to_dict())
```

```php
// PHP
print_r($forecast->at(0)->toArray());
```

## 📝 ライセンス

MIT License

## 🙏 謝辞

- [ITtools Weather Service](https://weather.ittools.biz/) - 気象予報データAPI

## 📞 サポート

問題が発生した場合は、各言語のサンプルコード（example.*）を参照してください。
