# Weather Forecast MCP Server

日本の天気予報を取得するためのMCP（Model Context Protocol）サーバーです。Claude CodeなどのMCPクライアントから利用できます。

## 特徴

- 🌤️ **詳細な気象情報**: 気温、降水量、風速、風向、湿度、雲量、気圧
- 🗾 **70以上の都市対応**: 都道府県庁所在地、主要都市、観光地
- 📊 **柔軟な出力形式**: テキスト形式またはJSON形式
- ⏰ **最大172時間予報**: 1〜172時間の予報を取得可能
- 🌍 **座標指定対応**: 緯度経度を直接指定して予報取得

## インストール

### 1. 依存パッケージのインストール

```bash
cd mcp
pip install -r requirements.txt
```

### 2. 環境変数の設定

APIトークンを環境変数に設定します：

```bash
export WEATHER_API_TOKEN="your_api_token_here"
```

永続的に設定する場合は、`.bashrc` または `.zshrc` に追加：

```bash
echo 'export WEATHER_API_TOKEN="your_api_token_here"' >> ~/.bashrc
source ~/.bashrc
```

**注意**: APIトークンが設定されていない場合、デフォルトで `api_sample` が使用されます（サンプルデータのみ）。

## Claude Codeでの設定

Claude CodeにMCPサーバーを追加する方法は2つあります。

### 方法1: CLIコマンドで追加（推奨）

プロジェクトディレクトリで以下のコマンドを実行：

```bash
cd /path/to/weatherforecast-api
claude mcp add --transport stdio weather-forecast -- python3 ${PWD}/mcp/server.py
```

環境変数を設定する場合：

```bash
export WEATHER_API_TOKEN="your_api_token_here"
claude mcp add --transport stdio weather-forecast -- python3 ${PWD}/mcp/server.py
```

### 方法2: 設定ファイルを手動で編集

#### ユーザースコープ（全プロジェクトで使用）

`~/.claude.json` を作成または編集：

```json
{
  "mcpServers": {
    "weather-forecast": {
      "command": "python3",
      "args": [
        "/absolute/path/to/weatherforecast-api/mcp/server.py"
      ],
      "env": {
        "WEATHER_API_TOKEN": "your_api_token_here"
      }
    }
  }
}
```

**重要**: `args` のパスを実際のサーバーファイルの絶対パスに変更してください。例: `/home/username/weatherforecast-api/mcp/server.py`

#### プロジェクトスコープ（このプロジェクトのみ）

プロジェクトルートに `.mcp.json` を作成：

```json
{
  "mcpServers": {
    "weather-forecast": {
      "command": "python3",
      "args": [
        "/absolute/path/to/weatherforecast-api/mcp/server.py"
      ],
      "env": {
        "WEATHER_API_TOKEN": "${WEATHER_API_TOKEN:-api_sample}"
      }
    }
  }
}
```

**重要**: `args` のパスは絶対パスで指定してください。

**プロジェクトスコープの利点**:
- チームメンバーと設定を共有できる（バージョン管理に含める）
- 環境変数のデフォルト値を設定可能（`${VAR:-default}` 構文）

#### Windowsの場合

ユーザースコープ（`~/.claude.json`）:

```json
{
  "mcpServers": {
    "weather-forecast": {
      "command": "python",
      "args": [
        "C:\\Users\\YourName\\weatherforecast-api\\mcp\\server.py"
      ],
      "env": {
        "WEATHER_API_TOKEN": "your_api_token_here"
      }
    }
  }
}
```

## 提供ツール

### 1. get_weather_forecast

緯度経度を指定して天気予報を取得します。

**パラメータ**:
- `latitude` (必須): 緯度 (-90 〜 90)
- `longitude` (必須): 経度 (-180 〜 180)
- `hours` (オプション): 予報時間数 (デフォルト: 24、最大: 172)
- `format` (オプション): 出力形式 ('text' または 'json'、デフォルト: 'text')

**例**:
```json
{
  "latitude": 35.6762,
  "longitude": 139.6503,
  "hours": 24,
  "format": "text"
}
```

### 2. get_weather_by_city

都市名から天気予報を取得します。

**パラメータ**:
- `city` (必須): 都市名（例: "東京", "大阪", "Tokyo"）
- `hours` (オプション): 予報時間数 (デフォルト: 24、最大: 172)
- `format` (オプション): 出力形式 ('text' または 'json'、デフォルト: 'text')

**例**:
```json
{
  "city": "東京",
  "hours": 48,
  "format": "text"
}
```

### 3. list_available_cities

利用可能な都市の一覧を取得します。

**パラメータ**: なし

### 4. search_cities

都市名を部分一致で検索します。

**パラメータ**:
- `query` (必須): 検索クエリ

**例**:
```json
{
  "query": "京"
}
```
→ "東京", "京都" などが返されます

## 対応都市

### 主要都市
東京、大阪、名古屋、札幌、福岡、横浜、京都、神戸、仙台、広島

### 都道府県庁所在地
青森、盛岡、秋田、山形、福島、水戸、宇都宮、前橋、さいたま、千葉、新潟、富山、金沢、福井、甲府、長野、岐阜、静岡、津、大津、奈良、和歌山、鳥取、松江、岡山、山口、徳島、高松、松山、高知、佐賀、長崎、熊本、大分、宮崎、鹿児島、那覇

### 主要観光地
函館、小樽、旭川、釧路、帯広、富士山、箱根、日光、軽井沢、金沢兼六園、高山、伊勢、宮島、倉敷、尾道、別府、阿蘇、屋久島、石垣島、宮古島

**詳細**: `city_coordinates.py` を参照

## Claude Codeでの使用例

Claude Codeを起動し、以下のように質問します：

```
ユーザー: 東京の今日の天気を教えて

Claude: [get_weather_by_city ツールを自動使用]

# 東京の天気予報
📍 位置: 緯度 35.6762, 経度 139.6503
📅 データ生成時刻: 20260226000000
⏰ 予報時間数: 24時間

## 概要
🌡️ 最高気温: 15.2°C
🌡️ 最低気温: 8.3°C
💧 総降水量: 2.5mm
🌧️ 降水時間: 3時間

## 24時間予報

2026-02-26 09:00:00 ⛅ 気温:12.5°C 降水:0.0mm 風速:2.3m/s(北東) 湿度:65% 雲量:30% 気圧:1013.2hPa
...
```

```
ユーザー: 札幌と福岡の気温を比較して

Claude: [2つの都市の予報を取得して比較]
```

```
ユーザー: 緯度35.0, 経度135.0の48時間予報をJSON形式で

Claude: [get_weather_forecast ツールをJSON形式で使用]
```

## 出力形式

### テキスト形式 (デフォルト)

```
# 東京の天気予報
📍 位置: 緯度 35.6762, 経度 139.6503
📅 データ生成時刻: 20260226000000
⏰ 予報時間数: 24時間

## 概要
🌡️ 最高気温: 15.2°C
🌡️ 最低気温: 8.3°C
💧 総降水量: 2.5mm
🌧️ 降水時間: 3時間

## 24時間予報

2026-02-26 09:00:00 ⛅ 気温:12.5°C 降水:0.0mm ...
```

### JSON形式

```json
{
  "location": {
    "latitude": 35.6762,
    "longitude": 139.6503,
    "city": "東京"
  },
  "data_time": "20260226000000",
  "forecast": [
    {
      "datetime": "2026-02-26 09:00:00",
      "temperature": 12.5,
      "precipitation": 0.0,
      "wind_speed": 2.3,
      "wind_direction": 45,
      "wind_compass": "北東",
      "humidity": 65.0,
      "cloud_cover": 30.0,
      "pressure": 1013.2,
      "weather_icon": "⛅"
    }
  ],
  "summary": {
    "max_temp": 15.2,
    "min_temp": 8.3,
    "total_precipitation": 2.5,
    "rainy_hours": 3,
    "forecast_hours": 24
  }
}
```

## 気象データ項目

| 項目 | 説明 | 単位 |
|------|------|------|
| temperature | 気温 | °C |
| precipitation | 1時間降水量 | mm |
| wind_speed | 風速 | m/s |
| wind_direction | 風向（角度） | 度 |
| wind_compass | 風向（方位） | 16方位 |
| humidity | 相対湿度 | % |
| cloud_cover | 全雲量 | % |
| pressure | 気圧 | hPa |
| weather_icon | 天気アイコン | ☀️🌦️🌧️☁️⛅ |

## 天気アイコンの判定ロジック

| アイコン | 条件 |
|---------|------|
| 🌧️ 雨 | 降水量 > 1.0mm |
| 🌦️ 小雨 | 降水量 > 0.1mm |
| ☁️ 曇り | 雲量 > 70% |
| ⛅ 晴れ時々曇り | 雲量 > 30% |
| ☀️ 晴れ | その他 |

## ログファイル

サーバーのログは以下に出力されます：

```
~/.weather-mcp.log
```

デバッグやトラブルシューティング時に確認してください。

## トラブルシューティング

### MCPサーバーが起動しない

1. Python 3のインストールを確認：
   ```bash
   python3 --version
   ```

2. 依存パッケージのインストールを確認：
   ```bash
   pip install -r mcp/requirements.txt
   ```

3. server.pyのパスが正しいか確認

### APIエラーが発生する

1. 環境変数 `WEATHER_API_TOKEN` が設定されているか確認：
   ```bash
   echo $WEATHER_API_TOKEN
   ```

2. APIトークンが有効か確認

3. インターネット接続を確認

### 都市が見つからない

1. `list_available_cities` ツールで利用可能な都市を確認

2. `search_cities` ツールで部分一致検索

3. 都市名のスペルミスを確認（例: "おおさか" → "大阪"）

### 設定ファイルの確認

登録されているMCPサーバーを確認：

```bash
claude mcp list
```

設定ファイルの場所を確認：

```bash
# ユーザースコープ
cat ~/.claude.json

# プロジェクトスコープ
cat .mcp.json
```

### ログを確認する

```bash
tail -f ~/.weather-mcp.log
```

## 開発・カスタマイズ

### 都市を追加する

`city_coordinates.py` の `CITY_COORDINATES` 辞書に追加：

```python
CITY_COORDINATES = {
    # ...
    "新しい都市": (緯度, 経度),
}
```

### 出力形式をカスタマイズする

`server.py` の `format_forecast_summary()` または `format_forecast_json()` 関数を編集します。

## テスト

MCPサーバーを直接テストする場合：

```bash
cd mcp
python3 server.py
```

標準入力からMCPプロトコルのJSONメッセージを送信してテストできます。

## API仕様

このMCPサーバーは以下のAPIを使用しています：

```
https://weather.ittools.biz/api/forecast/GSM/{token}/{lat},{lng}
```

詳細は [親ディレクトリのREADME](../README.md) を参照してください。

## ライセンス

MIT License

## 関連ドキュメント

- [WeatherForecast API クライアントライブラリ](../clients/README.md)
- [Webアプリケーション](../examples/README.md)
- [MCP (Model Context Protocol)](https://modelcontextprotocol.io/)

## サポート

問題が発生した場合：

1. ログファイル (`~/.weather-mcp.log`) を確認
2. 環境変数とAPIトークンを確認
3. Claude Codeの設定ファイルのパスを確認
4. Issueを作成してサポートを依頼

---

**Happy Weather Forecasting! 🌤️**
