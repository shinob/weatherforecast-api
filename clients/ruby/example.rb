#!/usr/bin/env ruby
require_relative 'weather_forecast_client'

# 使用例
api_token = 'api_sample'  # あなたのAPIトークンに置き換えてください

# クライアントを初期化
client = WeatherForecastClient.new(api_token)

begin
  # 東京の天気予報を取得（24時間分）
  puts "東京の24時間天気予報を取得中..."
  forecast = client.get_forecast(35.6762, 139.6503, 24)

  puts "\n📍 位置: #{forecast.latitude}, #{forecast.longitude}"
  puts "📅 基準時刻: #{forecast.grib2file_time}"
  puts "⏱️  予報時間数: #{forecast.length}時間\n\n"

  # 最初の3時間の詳細を表示
  puts "【最初の3時間の詳細】"
  forecast.data.take(3).each_with_index do |item, i|
    puts "\n--- #{i}時間後 (#{item.datetime}) ---"
    puts "#{item.weather_icon} 天気アイコン"
    puts "🌡️  気温: #{item.temperature.round(1)}°C"
    puts "💧 降水量: #{item.precipitation.round(1)}mm"
    puts "💨 風速: #{item.wind_speed.round(1)}m/s (#{item.wind_direction_compass})"
    puts "💦 湿度: #{item.humidity.round(0)}%"
    puts "☁️  雲量: #{item.cloud_cover.round(0)}%"
    puts "🎚️  気圧: #{item.pressure.round(1)}hPa"
  end

  # 24時間の気温推移を表示
  puts "\n\n【24時間の気温推移】"
  forecast.each_with_index do |item, i|
    temp = item.temperature.round(1)
    bar = '█' * (temp.to_i / 2)
    puts "#{i.to_s.rjust(2)}時間後: #{temp.to_s.rjust(5)}°C #{bar}"
  end

  # 特定の時間の気温を取得
  puts "\n\n【簡単なアクセス方法】"
  puts "3時間後の気温: #{forecast.temperature_at(3).round(1)}°C"
  puts "6時間後の降水量: #{forecast.precipitation_at(6).round(1)}mm"

rescue WeatherAPIError => e
  puts "❌ エラー: #{e.message}"
end
