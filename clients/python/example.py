#!/usr/bin/env python3
"""
使用例: WeatherForecast API Client for Python
"""

from weather_forecast_client import WeatherForecastClient, WeatherAPIError


def main():
    # 使用例
    api_token = 'api_sample'  # あなたのAPIトークンに置き換えてください

    # クライアントを初期化
    client = WeatherForecastClient(api_token)

    try:
        # 東京の天気予報を取得（24時間分）
        print("東京の24時間天気予報を取得中...")
        forecast = client.get_forecast(35.6762, 139.6503, 24)

        print(f"\n📍 位置: {forecast.latitude}, {forecast.longitude}")
        print(f"📅 基準時刻: {forecast.grib2file_time}")
        print(f"⏱️  予報時間数: {len(forecast)}時間\n")

        # 最初の3時間の詳細を表示
        print("【最初の3時間の詳細】")
        for i, item in enumerate(forecast.data[:3]):
            print(f"\n--- {i}時間後 ({item.datetime}) ---")
            print(f"{item.weather_icon()} 天気アイコン")
            print(f"🌡️  気温: {item.temperature:.1f}°C")
            print(f"💧 降水量: {item.precipitation:.1f}mm")
            print(f"💨 風速: {item.wind_speed:.1f}m/s ({item.wind_direction_compass()})")
            print(f"💦 湿度: {item.humidity:.0f}%")
            print(f"☁️  雲量: {item.cloud_cover:.0f}%")
            print(f"🎚️  気圧: {item.pressure:.1f}hPa")

        # 24時間の気温推移を表示
        print("\n\n【24時間の気温推移】")
        for i, item in enumerate(forecast):
            temp = item.temperature
            bar = '█' * int(temp / 2)
            print(f"{i:2d}時間後: {temp:5.1f}°C {bar}")

        # 特定の時間の気温を取得
        print("\n\n【簡単なアクセス方法】")
        print(f"3時間後の気温: {forecast.temperature_at(3):.1f}°C")
        print(f"6時間後の降水量: {forecast.precipitation_at(6):.1f}mm")

        # インデックスアクセス
        print(f"\n【インデックスアクセス】")
        print(f"最初の予報: {forecast[0].datetime} - {forecast[0].temperature:.1f}°C")

        # イテレーション
        print(f"\n【平均気温計算】")
        avg_temp = sum(item.temperature for item in forecast) / len(forecast)
        print(f"24時間平均気温: {avg_temp:.1f}°C")

    except WeatherAPIError as e:
        print(f"❌ エラー: {e}")


if __name__ == '__main__':
    main()
