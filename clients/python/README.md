# WeatherForecast API Client - Python

Python用のWeatherForecast APIクライアントライブラリです。型ヒント対応、dataclassベースの設計。

## 📦 インストール

```bash
pip install -r requirements.txt
```

### 必要なPythonバージョン

- Python 3.7以上

### 依存パッケージ

- requests >= 2.31.0

## 🚀 基本的な使い方

```python
from weather_forecast_client import WeatherForecastClient

# クライアントを初期化
client = WeatherForecastClient('your_api_token')

# 東京の24時間予報を取得
forecast = client.get_forecast(35.6762, 139.6503, 24)

# 位置情報
print(f"緯度: {forecast.latitude}")
print(f"経度: {forecast.longitude}")
print(f"予報時間数: {len(forecast)}")

# 最初の時間の詳細
first = forecast[0]
print(f"{first.datetime}: {first.temperature}°C")
print(f"天気: {first.weather_icon()}")
print(f"風: {first.wind_speed}m/s {first.wind_direction_compass()}")
```

## 📚 API リファレンス

### WeatherForecastClient

#### 初期化

```python
client = WeatherForecastClient(api_token: str)
```

**パラメータ:**
- `api_token` (str): あなたのAPIトークン

#### get_forecast(latitude, longitude, hours=24)

天気予報を取得します。

```python
forecast = client.get_forecast(35.6762, 139.6503, 24)
```

**パラメータ:**
- `latitude` (float): 緯度
- `longitude` (float): 経度
- `hours` (int, optional): 予報時間数（デフォルト: 24、最大: 172）

**戻り値:** `Forecast` オブジェクト

**例外:**
- `WeatherAPIError`: APIリクエストが失敗した場合

### Forecast

予報データを管理するクラス。

#### プロパティ

```python
forecast.latitude: float        # 緯度
forecast.longitude: float       # 経度
forecast.grib2file_time: str   # 予報基準時刻
forecast.data: List[ForecastItem]  # 予報データリスト
```

#### メソッド

##### at(hour: int) -> Optional[ForecastItem]

指定した時間の予報を取得。

```python
item = forecast.at(3)  # 3時間後の予報
```

**戻り値:** `ForecastItem` または `None`

##### temperature_at(hour: int) -> Optional[float]

指定した時間の気温を取得。

```python
temp = forecast.temperature_at(3)  # 3時間後の気温
```

**戻り値:** `float` または `None`

##### precipitation_at(hour: int) -> Optional[float]

指定した時間の降水量を取得。

```python
rain = forecast.precipitation_at(3)  # 3時間後の降水量
```

**戻り値:** `float` または `None`

##### all() -> List[ForecastItem]

すべての予報データをリストで取得。

```python
all_forecasts = forecast.all()
```

**戻り値:** `List[ForecastItem]`

##### __len__() -> int

予報時間数を取得（`len()`関数で使用）。

```python
hours = len(forecast)
```

**戻り値:** `int`

##### __iter__() / __getitem__()

イテレータおよびインデックスアクセスをサポート。

```python
# イテレータ
for item in forecast:
    print(item.temperature)

# インデックスアクセス
first = forecast[0]
last = forecast[-1]
```

### ForecastItem

個別の予報データ（dataclass）。

#### プロパティ

```python
item.datetime: str         # 予報日時 (例: "2026-02-25 17:00:00")
item.temperature: float    # 気温 (°C)
item.precipitation: float  # 降水量 (mm)
item.wind_speed: float     # 風速 (m/s)
item.wind_direction: float # 風向 (度)
item.humidity: float       # 湿度 (%)
item.cloud_cover: float    # 雲量 (%)
item.pressure: float       # 気圧 (hPa)
```

#### メソッド

##### wind_direction_compass() -> str

風向を16方位で取得。

```python
direction = item.wind_direction_compass()  # 例: "NE" (北東)
```

**戻り値:** `str`

##### weather_icon() -> str

天気状態をアイコン絵文字で取得。

```python
icon = item.weather_icon()  # 例: "☀️" (晴れ)
```

**戻り値:** `str`

判定ロジック:
- 🌧️ 降水量 > 1.0mm
- 🌦️ 降水量 > 0.1mm
- ☁️ 雲量 > 70%
- ⛅ 雲量 > 30%
- ☀️ その他

##### to_dict() -> Dict[str, Any]

すべてのデータを辞書で取得。

```python
data = item.to_dict()
# => {
#   'datetime': "2026-02-25 17:00:00",
#   'temperature': 9.13,
#   'precipitation': 0.594,
#   'wind_speed': 3.42,
#   'wind_direction': 45,
#   'wind_direction_compass': "NE",
#   'humidity': 88.2,
#   'cloud_cover': 100.0,
#   'pressure': 1008.8,
#   'weather_icon': "🌧️"
# }
```

**戻り値:** `Dict[str, Any]`

## 💡 使用例

### 例1: 基本的な情報表示

```python
from weather_forecast_client import WeatherForecastClient

client = WeatherForecastClient('api_sample')
forecast = client.get_forecast(35.6762, 139.6503)

for i, item in enumerate(forecast):
    print(f"{i}時間後: {item.temperature}°C {item.weather_icon()}")
```

### 例2: 最高気温・最低気温の取得

```python
temps = [item.temperature for item in forecast]
max_temp = max(temps)
min_temp = min(temps)

print(f"最高気温: {max_temp:.1f}°C")
print(f"最低気温: {min_temp:.1f}°C")
```

### 例3: 雨が降る時間帯を検索

```python
rainy_hours = [item for item in forecast if item.precipitation > 0.1]

if not rainy_hours:
    print("今後24時間は雨が降らない予報です")
else:
    print("雨が降る時間帯:")
    for item in rainy_hours:
        print(f"  {item.datetime}: {item.precipitation}mm")
```

### 例4: 平均気温の計算

```python
avg_temp = sum(item.temperature for item in forecast) / len(forecast)
print(f"平均気温: {avg_temp:.1f}°C")
```

### 例5: 風の強い時間帯を検索

```python
windy_hours = [item for item in forecast if item.wind_speed > 5.0]

if windy_hours:
    print("風の強い時間帯 (5m/s以上):")
    for item in windy_hours:
        print(f"  {item.datetime}: {item.wind_speed}m/s {item.wind_direction_compass()}")
```

### 例6: エラーハンドリング

```python
from weather_forecast_client import WeatherForecastClient, WeatherAPIError

try:
    client = WeatherForecastClient('your_api_token')
    forecast = client.get_forecast(35.6762, 139.6503)

    print("予報取得成功！")
    print(f"気温: {forecast.temperature_at(0)}°C")

except WeatherAPIError as e:
    print(f"エラーが発生しました: {e}")

    error_msg = str(e)
    if "401" in error_msg:
        print("APIトークンが無効です")
    elif "404" in error_msg:
        print("指定された位置の予報が見つかりません")
    elif "Request failed" in error_msg:
        print("ネットワークエラーです。接続を確認してください")
    else:
        print("予期しないエラーです")
```

## 🎯 実践的な例

### 天気予報レポートの生成

```python
from weather_forecast_client import WeatherForecastClient, WeatherAPIError

def generate_weather_report(lat: float, lng: float, api_token: str):
    """天気予報レポートを生成"""
    try:
        client = WeatherForecastClient(api_token)
        forecast = client.get_forecast(lat, lng, 24)

        print("=" * 50)
        print("天気予報レポート")
        print("=" * 50)
        print(f"位置: {forecast.latitude}, {forecast.longitude}")
        print(f"基準時刻: {forecast.grib2file_time}")
        print()

        # 概要統計
        temps = [item.temperature for item in forecast]
        rains = [item.precipitation for item in forecast]

        print("【24時間の概要】")
        print(f"最高気温: {max(temps):.1f}°C")
        print(f"最低気温: {min(temps):.1f}°C")
        print(f"平均気温: {sum(temps) / len(temps):.1f}°C")
        print(f"総降水量: {sum(rains):.1f}mm")
        print()

        # 時間帯別の情報
        print("【時間帯別予報】")
        for hour in [0, 6, 12, 18]:
            item = forecast.at(hour)
            if item:
                print(f"\n{hour}時間後 ({item.datetime}):")
                print(f"  {item.weather_icon()} {item.temperature:.1f}°C")
                print(f"  降水: {item.precipitation:.1f}mm")
                print(f"  風: {item.wind_speed:.1f}m/s ({item.wind_direction_compass()})")

    except WeatherAPIError as e:
        print(f"エラー: {e}")

# 使用例
if __name__ == '__main__':
    generate_weather_report(35.6762, 139.6503, 'api_sample')
```

### Pandasと組み合わせた分析

```python
import pandas as pd
from weather_forecast_client import WeatherForecastClient

client = WeatherForecastClient('api_sample')
forecast = client.get_forecast(35.6762, 139.6503, 24)

# DataFrameに変換
df = pd.DataFrame([item.to_dict() for item in forecast])

# 統計情報
print(df[['temperature', 'precipitation', 'wind_speed']].describe())

# 気温の推移をプロット（matplotlibが必要）
import matplotlib.pyplot as plt

plt.figure(figsize=(12, 4))
plt.plot(df.index, df['temperature'])
plt.title('Temperature Forecast')
plt.xlabel('Hours')
plt.ylabel('Temperature (°C)')
plt.grid(True)
plt.show()
```

### 型ヒントを活用したコード

```python
from typing import List, Tuple
from weather_forecast_client import (
    WeatherForecastClient,
    Forecast,
    ForecastItem,
    WeatherAPIError
)

def get_hourly_summary(forecast: Forecast, hour: int) -> Tuple[float, float, str]:
    """指定時間の気温、降水量、天気アイコンを取得"""
    item = forecast.at(hour)
    if item:
        return item.temperature, item.precipitation, item.weather_icon()
    return 0.0, 0.0, "❓"

def filter_by_temperature(
    forecast: Forecast,
    min_temp: float,
    max_temp: float
) -> List[ForecastItem]:
    """気温範囲でフィルタリング"""
    return [
        item for item in forecast
        if min_temp <= item.temperature <= max_temp
    ]

# 使用例
client: WeatherForecastClient = WeatherForecastClient('api_sample')
forecast: Forecast = client.get_forecast(35.6762, 139.6503)

# 型チェックが効く
temp, rain, icon = get_hourly_summary(forecast, 3)
print(f"3時間後: {temp}°C, {rain}mm, {icon}")

# フィルタリング
warm_hours = filter_by_temperature(forecast, 15.0, 25.0)
print(f"15-25°Cの時間帯: {len(warm_hours)}時間")
```

## 🔧 トラブルシューティング

### Q: `ModuleNotFoundError: No module named 'requests'`

```bash
pip install requests
# または
pip install -r requirements.txt
```

### Q: APIトークンエラー

```python
# 正しいトークンを使用しているか確認
client = WeatherForecastClient('your_actual_token_here')
```

### Q: タイムアウトエラー

デフォルトのタイムアウトは30秒です。ネットワークが遅い場合、ライブラリを編集して調整できます。

### Q: 型ヒントエラー（Python 3.7-3.8）

Python 3.7-3.8では、一部の型ヒントで `from __future__ import annotations` が必要な場合があります。

## 📞 サポート

詳細な使用例は `example.py` を参照してください。

```bash
python3 example.py
```
