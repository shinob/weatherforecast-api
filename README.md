# WeatherForecast API

日本の気象予報データを取得するためのクライアントライブラリとWebアプリケーション例のコレクションです。

## 📚 プロジェクト構成

```
weatherforecast-api/
├── clients/           # クライアントライブラリ（Ruby, Python, PHP, VBA）
│   ├── ruby/         # Rubyクライアント
│   ├── python/       # Pythonクライアント
│   ├── php/          # PHPクライアント
│   └── vba/          # Excel VBAクライアント
├── mcp/              # MCPサーバー（Claude Code連携）
│   ├── server.py     # MCPサーバーメイン実装
│   ├── city_coordinates.py  # 日本の主要都市座標データ
│   └── README.md     # MCPサーバードキュメント
└── examples/         # Webアプリケーション例
    ├── index.html    # 地図で見る天気予報アプリ
    ├── app.js        # JavaScriptアプリケーション
    ├── config.js     # 設定ファイル
    └── server-proxy.py  # CORS対応プロキシサーバー
```

## 🌟 特徴

### クライアントライブラリ

Ruby、Python、PHP、VBAの4言語で**統一されたインターフェース**を提供：

- ✅ シンプルで直感的なAPI設計
- ✅ 型安全な実装
- ✅ 天気アイコン自動判定（☀️🌦️🌧️☁️⛅）
- ✅ 風向の16方位変換
- ✅ エラーハンドリング
- ✅ イテレータ/列挙サポート
- ✅ 24〜172時間の予報取得

### MCPサーバー（NEW! 🎉）

- 🤖 **Claude Code連携**: Claude CodeからMCPプロトコルで直接利用可能
- 🗾 **70以上の都市対応**: 都道府県庁所在地・主要都市・観光地
- 📊 **柔軟な出力**: テキスト形式またはJSON形式で取得
- ⏰ **最大172時間予報**: 長期予報に対応
- 🔍 **都市検索機能**: 部分一致検索で都市を簡単に発見

### Webアプリケーション例

- 📍 地図上の任意の地点をクリックして天気予報を取得
- 🌤️ 1時間ごとの詳細な気象情報（24時間分）
- 📊 気温・降水量・風速のグラフ表示
- 🎨 レスポンシブデザイン（PC/タブレット/スマートフォン対応）

## 🚀 クイックスタート

### MCPサーバー（Claude Code）

```bash
# 依存パッケージをインストール
cd mcp
pip install -r requirements.txt

# Claude Codeの設定ファイルに追加
# ~/.config/claude-code/claude_desktop_config.json

{
  "mcpServers": {
    "weather-forecast": {
      "command": "python3",
      "args": ["/path/to/weatherforecast-api/mcp/server.py"],
      "env": {"WEATHER_API_TOKEN": "api_sample"}
    }
  }
}

# Claude Codeで使用
# ユーザー: 東京の天気を教えて
# Claude: [自動的に天気予報を取得]
```

詳細: [mcp/README.md](mcp/README.md) | [mcp/QUICKSTART.md](mcp/QUICKSTART.md)

### クライアントライブラリ

#### Ruby

```ruby
require_relative 'clients/ruby/weather_forecast_client'

client = WeatherForecastClient.new('your_api_token')
forecast = client.get_forecast(35.6762, 139.6503, 24)

# 最初の時間の気温
puts forecast.temperature_at(0)

# すべての予報をループ
forecast.each do |item|
  puts "#{item.datetime}: #{item.temperature}°C #{item.weather_icon}"
end
```

#### Python

```python
from clients.python.weather_forecast_client import WeatherForecastClient

client = WeatherForecastClient('your_api_token')
forecast = client.get_forecast(35.6762, 139.6503, 24)

# 最初の時間の気温
print(forecast.temperature_at(0))

# すべての予報をループ
for item in forecast:
    print(f"{item.datetime}: {item.temperature}°C {item.weather_icon()}")
```

#### PHP

```php
require_once 'clients/php/WeatherForecastClient.php';

$client = new WeatherForecastClient('your_api_token');
$forecast = $client->getForecast(35.6762, 139.6503, 24);

// 最初の時間の気温
echo $forecast->temperatureAt(0);

// すべての予報をループ
foreach ($forecast as $item) {
    echo "{$item->datetime}: {$item->temperature}°C {$item->getWeatherIcon()}\n";
}
```

#### VBA (Excel)

```vba
' WeatherForecastClient.bas をインポート
Initialize "your_api_token"

Dim forecast As Object
Set forecast = GetForecast(35.6762, 139.6503, 24)

' 最初の時間の気温
Debug.Print GetTemperatureAt(forecast, 0)

' すべての予報をループ
Dim i As Integer
For i = 0 To GetCount(forecast) - 1
    Dim item As Object
    Set item = GetAt(forecast, i)
    Debug.Print item("DateTime") & ": " & item("Temperature") & "°C " & item("WeatherIcon")
Next i
```

### Webアプリケーション

```bash
# プロキシサーバーを起動（CORS問題の解決）
cd examples
python3 server-proxy.py 8000

# ブラウザでアクセス
# http://localhost:8000
```

## 📖 ドキュメント

### MCPサーバー

- **メインドキュメント**: [mcp/README.md](mcp/README.md)
- **クイックスタート**: [mcp/QUICKSTART.md](mcp/QUICKSTART.md)

### クライアントライブラリ

詳細なドキュメントは各ディレクトリを参照してください：

- **総合ガイド**: [clients/README.md](clients/README.md)
- **Ruby**: [clients/ruby/README.md](clients/ruby/README.md)
- **Python**: [clients/python/README.md](clients/python/README.md)
- **PHP**: [clients/php/README.md](clients/php/README.md)
- **VBA**: [clients/vba/README.md](clients/vba/README.md)

### Webアプリケーション

- **メインドキュメント**: [examples/README.md](examples/README.md)
- **クイックスタート**: [examples/QUICKSTART.md](examples/QUICKSTART.md)

## 🔧 APIエンドポイント

```
https://weather.ittools.biz/api/forecast/GSM/{token}/{lat},{lng}
```

### パラメータ

- `{token}`: APIトークン
- `{lat}`: 緯度（小数点形式）
- `{lng}`: 経度（小数点形式）

### レスポンス

```json
{
  "code": 200,
  "result": {
    "latlng": "35.6762,139.6503",
    "grib2file_time": "20260226000000",
    "forecast": [
      {
        "datetime": "2026-02-26 09:00:00",
        "TMP": 12.5,
        "APCP": 0.0,
        "WSPD": 2.3,
        "WDIR": 45,
        "RH": 65.0,
        "TCDC": 30.0,
        "PRES": 1013.2
      }
      // ... 最大172時間分
    ]
  }
}
```

### 気象データ項目

| 項目 | 単位 | 説明 |
|------|------|------|
| TMP | °C | 気温 |
| APCP | mm | 1時間あたりの降水量 |
| WSPD | m/s | 風速 |
| WDIR | 度 | 風向 |
| RH | % | 相対湿度 |
| TCDC | % | 全雲量 |
| PRES | hPa | 気圧 |

## 📦 インストール

### Ruby

```bash
cd clients/ruby
# 標準ライブラリのみ使用、追加インストール不要
ruby example.rb
```

### Python

```bash
cd clients/python
pip install -r requirements.txt
python3 example.py
```

### PHP

```bash
cd clients/php
# PHP 7.4以上、cURL拡張が必要
php example.php
```

### VBA

1. Excelを開き、`Alt + F11`でVBAエディタを起動
2. `WeatherForecastClient.bas`をインポート
3. 参照設定で以下を有効化：
   - Microsoft Scripting Runtime
   - Microsoft WinHTTP Services
4. サンプルコード(`Example.bas`)を実行

## 💡 使用例

### 1. 特定時間の気温取得

すべての言語で統一されたインターフェース：

```ruby
# Ruby
temp = forecast.temperature_at(3)
```

```python
# Python
temp = forecast.temperature_at(3)
```

```php
// PHP
$temp = $forecast->temperatureAt(3);
```

### 2. 最高・最低気温の計算

```ruby
# Ruby
temps = forecast.data.map(&:temperature)
puts "最高: #{temps.max}°C, 最低: #{temps.min}°C"
```

```python
# Python
temps = [item.temperature for item in forecast]
print(f"最高: {max(temps)}°C, 最低: {min(temps)}°C")
```

```php
// PHP
$temps = array_map(fn($item) => $item->temperature, $forecast->all());
printf("最高: %.1f°C, 最低: %.1f°C\n", max($temps), min($temps));
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

## 🌤️ 天気アイコン判定

すべてのライブラリで統一されたロジック：

| アイコン | 条件 |
|---------|------|
| 🌧️ 雨 | 降水量 > 1.0mm |
| 🌦️ 小雨 | 降水量 > 0.1mm |
| ☁️ 曇り | 雲量 > 70% |
| ⛅ 晴れ時々曇り | 雲量 > 30% |
| ☀️ 晴れ | その他 |

## 🧭 風向変換

16方位に対応：

```
N (北), NNE (北北東), NE (北東), ENE (東北東),
E (東), ESE (東南東), SE (南東), SSE (南南東),
S (南), SSW (南南西), SW (南西), WSW (西南西),
W (西), WNW (西北西), NW (北西), NNW (北北西)
```

## ⚠️ エラーハンドリング

すべての言語でカスタム例外を提供：

```ruby
# Ruby
begin
  forecast = client.get_forecast(35.6762, 139.6503)
rescue WeatherAPIError => e
  puts "エラー: #{e.message}"
end
```

```python
# Python
try:
    forecast = client.get_forecast(35.6762, 139.6503)
except WeatherAPIError as e:
    print(f"エラー: {e}")
```

```php
// PHP
try {
    $forecast = $client->getForecast(35.6762, 139.6503);
} catch (WeatherAPIException $e) {
    echo "エラー: " . $e->getMessage();
}
```

## 🔒 セキュリティ

### APIトークンの保護

APIトークンを環境変数または設定ファイルから読み込むことを推奨します：

```ruby
# Ruby
api_token = ENV['WEATHER_API_TOKEN']
client = WeatherForecastClient.new(api_token)
```

```python
# Python
import os
api_token = os.getenv('WEATHER_API_TOKEN')
client = WeatherForecastClient(api_token)
```

```php
// PHP
$apiToken = getenv('WEATHER_API_TOKEN');
$client = new WeatherForecastClient($apiToken);
```

```vba
' VBA
' ワークシートのセルから読み込む
Dim apiToken As String
apiToken = ThisWorkbook.Worksheets("Config").Range("A1").Value
Initialize apiToken
```

## 🛠️ トラブルシューティング

### CORS エラー（Webアプリケーション）

天気予報APIは直接ブラウザからアクセスできません。必ずプロキシサーバーを使用してください：

```bash
cd examples
python3 server-proxy.py 8000
```

### APIトークンエラー

有効なAPIトークンを設定してください。サンプルトークン `'api_sample'` は開発・テスト用です。

### タイムアウトエラー

ネットワークが遅い場合、各ライブラリのタイムアウト設定を調整できます（デフォルト: 30秒）。

## 📊 技術スタック

### クライアントライブラリ

- **Ruby**: 標準ライブラリ（Net::HTTP, JSON）
- **Python**: requests, dataclasses, type hints
- **PHP**: cURL, Iterator/Countable interfaces
- **VBA**: WinHTTP, Scripting.Dictionary, ScriptControl

### Webアプリケーション

- **フロントエンド**: HTML5, CSS3, JavaScript (ES6+)
- **地図**: Leaflet.js + OpenStreetMap
- **グラフ**: Chart.js
- **バックエンド**: Python (プロキシサーバー)

## 🤝 貢献

プルリクエストを歓迎します！以下のことを確認してください：

- すべての言語で統一されたインターフェースを維持
- ドキュメントの更新
- サンプルコードの動作確認

## 📝 ライセンス

MIT License

## 🙏 謝辞

- [ITtools Weather Service](https://weather.ittools.biz/) - 気象予報データAPI
- [Leaflet](https://leafletjs.com/) - 地図ライブラリ
- [Chart.js](https://www.chartjs.org/) - グラフライブラリ
- [OpenStreetMap](https://www.openstreetmap.org/) - 地図データ

## 📞 サポート

- **クライアントライブラリ**: 各言語の `README.md` と `example.*` ファイルを参照
- **Webアプリケーション**: `examples/QUICKSTART.md` を参照
- **API仕様**: このREADMEの「APIエンドポイント」セクションを参照

---

**Happy Coding! 🚀**
