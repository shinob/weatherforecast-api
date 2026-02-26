# WeatherForecast API Client - Ruby

Ruby用のWeatherForecast APIクライアントライブラリです。

## 📦 インストール

このライブラリは標準ライブラリのみを使用しているため、追加のインストールは不要です。

### 必要なRubyバージョン

- Ruby 2.5以上

## 🚀 基本的な使い方

```ruby
require_relative 'weather_forecast_client'

# クライアントを初期化
client = WeatherForecastClient.new('your_api_token')

# 東京の24時間予報を取得
forecast = client.get_forecast(35.6762, 139.6503, 24)

# 位置情報
puts "緯度: #{forecast.latitude}"
puts "経度: #{forecast.longitude}"
puts "予報時間数: #{forecast.length}"

# 最初の時間の詳細
first = forecast.at(0)
puts "#{first.datetime}: #{first.temperature}°C"
puts "天気: #{first.weather_icon}"
puts "風: #{first.wind_speed}m/s #{first.wind_direction_compass}"
```

## 📚 API リファレンス

### WeatherForecastClient

#### 初期化

```ruby
client = WeatherForecastClient.new(api_token)
```

**パラメータ:**
- `api_token` (String): あなたのAPIトークン

#### get_forecast(latitude, longitude, hours = 24)

天気予報を取得します。

```ruby
forecast = client.get_forecast(35.6762, 139.6503, 24)
```

**パラメータ:**
- `latitude` (Float): 緯度
- `longitude` (Float): 経度
- `hours` (Integer, optional): 予報時間数（デフォルト: 24、最大: 172）

**戻り値:** `Forecast` オブジェクト

**例外:**
- `WeatherAPIError`: APIリクエストが失敗した場合

### Forecast

予報データを管理するクラス。

#### プロパティ

```ruby
forecast.latitude        # Float: 緯度
forecast.longitude       # Float: 経度
forecast.grib2file_time  # String: 予報基準時刻
forecast.data            # Array<ForecastItem>: 予報データ配列
```

#### メソッド

##### at(hour)

指定した時間の予報を取得。

```ruby
item = forecast.at(3)  # 3時間後の予報
```

**戻り値:** `ForecastItem` または `nil`

##### temperature_at(hour)

指定した時間の気温を取得。

```ruby
temp = forecast.temperature_at(3)  # 3時間後の気温
```

**戻り値:** `Float` または `nil`

##### precipitation_at(hour)

指定した時間の降水量を取得。

```ruby
rain = forecast.precipitation_at(3)  # 3時間後の降水量
```

**戻り値:** `Float` または `nil`

##### all

すべての予報データを配列で取得。

```ruby
all_forecasts = forecast.all
```

**戻り値:** `Array<ForecastItem>`

##### length

予報時間数を取得。

```ruby
hours = forecast.length
```

**戻り値:** `Integer`

##### each(&block)

各予報データをイテレート。

```ruby
forecast.each do |item|
  puts "#{item.datetime}: #{item.temperature}°C"
end
```

### ForecastItem

個別の予報データ。

#### プロパティ

```ruby
item.datetime         # String: 予報日時 (例: "2026-02-25 17:00:00")
item.temperature      # Float: 気温 (°C)
item.precipitation    # Float: 降水量 (mm)
item.wind_speed       # Float: 風速 (m/s)
item.wind_direction   # Float: 風向 (度)
item.humidity         # Float: 湿度 (%)
item.cloud_cover      # Float: 雲量 (%)
item.pressure         # Float: 気圧 (hPa)
```

#### メソッド

##### wind_direction_compass

風向を16方位で取得。

```ruby
direction = item.wind_direction_compass  # 例: "NE" (北東)
```

**戻り値:** `String`

##### weather_icon

天気状態をアイコン絵文字で取得。

```ruby
icon = item.weather_icon  # 例: "☀️" (晴れ)
```

**戻り値:** `String`

判定ロジック:
- 🌧️ 降水量 > 1.0mm
- 🌦️ 降水量 > 0.1mm
- ☁️ 雲量 > 70%
- ⛅ 雲量 > 30%
- ☀️ その他

##### to_h

すべてのデータをハッシュで取得。

```ruby
hash = item.to_h
# => {
#   datetime: "2026-02-25 17:00:00",
#   temperature: 9.13,
#   precipitation: 0.594,
#   wind_speed: 3.42,
#   wind_direction: 45,
#   wind_direction_compass: "NE",
#   humidity: 88.2,
#   cloud_cover: 100.0,
#   pressure: 1008.8,
#   weather_icon: "🌧️"
# }
```

**戻り値:** `Hash`

## 💡 使用例

### 例1: 基本的な情報表示

```ruby
require_relative 'weather_forecast_client'

client = WeatherForecastClient.new('api_sample')
forecast = client.get_forecast(35.6762, 139.6503)

forecast.each_with_index do |item, i|
  puts "#{i}時間後: #{item.temperature}°C #{item.weather_icon}"
end
```

### 例2: 最高気温・最低気温の取得

```ruby
temps = forecast.data.map(&:temperature)
max_temp = temps.max
min_temp = temps.min

puts "最高気温: #{max_temp.round(1)}°C"
puts "最低気温: #{min_temp.round(1)}°C"
```

### 例3: 雨が降る時間帯を検索

```ruby
rainy_hours = forecast.data.select { |item| item.precipitation > 0.1 }

if rainy_hours.empty?
  puts "今後24時間は雨が降らない予報です"
else
  puts "雨が降る時間帯:"
  rainy_hours.each do |item|
    puts "  #{item.datetime}: #{item.precipitation}mm"
  end
end
```

### 例4: 平均気温の計算

```ruby
avg_temp = forecast.data.sum(&:temperature) / forecast.length
puts "平均気温: #{avg_temp.round(1)}°C"
```

### 例5: 風の強い時間帯を検索

```ruby
windy_hours = forecast.data.select { |item| item.wind_speed > 5.0 }

unless windy_hours.empty?
  puts "風の強い時間帯 (5m/s以上):"
  windy_hours.each do |item|
    puts "  #{item.datetime}: #{item.wind_speed}m/s #{item.wind_direction_compass}"
  end
end
```

### 例6: エラーハンドリング

```ruby
begin
  client = WeatherForecastClient.new('your_api_token')
  forecast = client.get_forecast(35.6762, 139.6503)

  puts "予報取得成功！"
  puts "気温: #{forecast.temperature_at(0)}°C"

rescue WeatherAPIError => e
  puts "エラーが発生しました: #{e.message}"

  case e.message
  when /HTTP Error: 401/
    puts "APIトークンが無効です"
  when /HTTP Error: 404/
    puts "指定された位置の予報が見つかりません"
  when /Failed to fetch/
    puts "ネットワークエラーです。接続を確認してください"
  else
    puts "予期しないエラーです"
  end
end
```

## 🎯 実践的な例

### 天気予報レポートの生成

```ruby
require_relative 'weather_forecast_client'

def generate_weather_report(lat, lng, api_token)
  client = WeatherForecastClient.new(api_token)
  forecast = client.get_forecast(lat, lng, 24)

  puts "=" * 50
  puts "天気予報レポート"
  puts "=" * 50
  puts "位置: #{forecast.latitude}, #{forecast.longitude}"
  puts "基準時刻: #{forecast.grib2file_time}"
  puts ""

  # 概要統計
  temps = forecast.data.map(&:temperature)
  rains = forecast.data.map(&:precipitation)

  puts "【24時間の概要】"
  puts "最高気温: #{temps.max.round(1)}°C"
  puts "最低気温: #{temps.min.round(1)}°C"
  puts "平均気温: #{(temps.sum / temps.size).round(1)}°C"
  puts "総降水量: #{rains.sum.round(1)}mm"
  puts ""

  # 時間帯別の情報
  puts "【時間帯別予報】"
  [0, 6, 12, 18].each do |hour|
    item = forecast.at(hour)
    next unless item

    puts "\n#{hour}時間後 (#{item.datetime}):"
    puts "  #{item.weather_icon} #{item.temperature.round(1)}°C"
    puts "  降水: #{item.precipitation.round(1)}mm"
    puts "  風: #{item.wind_speed.round(1)}m/s (#{item.wind_direction_compass})"
  end

rescue WeatherAPIError => e
  puts "エラー: #{e.message}"
end

# 使用例
generate_weather_report(35.6762, 139.6503, 'api_sample')
```

## 🔧 トラブルシューティング

### Q: `LoadError` が発生する

```ruby
# 相対パスが正しいか確認
require_relative 'weather_forecast_client'

# または絶対パス
require '/path/to/weather_forecast_client'
```

### Q: APIトークンエラー

```ruby
# 正しいトークンを使用しているか確認
client = WeatherForecastClient.new('your_actual_token_here')
```

### Q: タイムアウトエラー

ネットワークが遅い場合、標準ライブラリのタイムアウトを調整できます（デフォルトは60秒）。

## 📞 サポート

詳細な使用例は `example.rb` を参照してください。

```bash
ruby example.rb
```
