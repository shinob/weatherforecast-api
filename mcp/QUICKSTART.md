# クイックスタートガイド

このガイドでは、Weather Forecast MCPサーバーをClaude Codeで使用するまでの手順を説明します。

## 前提条件

- Python 3.8以上がインストールされていること
- Claude Codeがインストールされていること
- インターネット接続があること

## 5分で始める

### ステップ1: 依存パッケージのインストール

```bash
cd /path/to/weatherforecast-api/mcp
pip install -r requirements.txt
```

以下のパッケージがインストールされます：
- `mcp` - MCP SDK
- `requests` - HTTP通信ライブラリ

### ステップ2: APIトークンの設定（オプション）

本番用のAPIトークンがある場合は環境変数に設定します：

```bash
export WEATHER_API_TOKEN="your_api_token_here"
```

**注意**: 設定しない場合は `api_sample` トークンが使用されます（サンプルデータのみ取得可能）。

### ステップ3: Claude Codeの設定

Claude Codeの設定ファイルを編集します。

#### macOS/Linux

```bash
# 設定ファイルのパスを確認
echo ~/.config/claude-code/claude_desktop_config.json

# ファイルを編集
nano ~/.config/claude-code/claude_desktop_config.json
```

以下の内容を追加または編集：

```json
{
  "mcpServers": {
    "weather-forecast": {
      "command": "python3",
      "args": [
        "/absolute/path/to/weatherforecast-api/mcp/server.py"
      ],
      "env": {
        "WEATHER_API_TOKEN": "api_sample"
      }
    }
  }
}
```

**重要**: `args` のパスは、実際のserver.pyの絶対パスに変更してください。

パスを確認するには：
```bash
cd /path/to/weatherforecast-api/mcp
pwd
# 出力例: /home/username/weatherforecast-api/mcp
# この場合、パスは /home/username/weatherforecast-api/mcp/server.py
```

#### Windows

```cmd
# 設定ファイルのパスを確認
echo %APPDATA%\claude-code\claude_desktop_config.json

# ファイルをメモ帳で編集
notepad %APPDATA%\claude-code\claude_desktop_config.json
```

以下の内容を追加：

```json
{
  "mcpServers": {
    "weather-forecast": {
      "command": "python",
      "args": [
        "C:\\Users\\YourName\\weatherforecast-api\\mcp\\server.py"
      ],
      "env": {
        "WEATHER_API_TOKEN": "api_sample"
      }
    }
  }
}
```

### ステップ4: Claude Codeを再起動

設定を反映させるため、Claude Codeを完全に終了してから再起動します。

### ステップ5: 動作確認

Claude Codeを起動し、以下のメッセージを送信してテストします：

```
東京の天気を教えて
```

または

```
利用可能な都市を教えて
```

MCPサーバーが正しく設定されていれば、Claude Codeが自動的にツールを使用して天気予報を取得します。

## よくある使い方

### 特定の都市の天気予報

```
札幌の24時間天気予報を教えて
```

```
大阪の48時間予報をJSON形式で
```

### 複数都市の比較

```
東京と大阪の気温を比較して
```

### 観光地の天気

```
富士山の天気はどう？
```

```
箱根と軽井沢の天気を比較して
```

### 緯度経度指定

```
緯度35.0、経度135.0の天気を教えて
```

## トラブルシューティング

### MCPサーバーが認識されない

1. Claude Codeを完全に終了して再起動
2. 設定ファイルのJSONフォーマットが正しいか確認
3. server.pyのパスが正しいか確認（相対パスではなく絶対パス）

### "Tool not found" エラー

設定ファイルのパスや、Python実行ファイルの名前を確認してください：

```bash
# Pythonのパスを確認
which python3  # macOS/Linux
where python   # Windows
```

### APIエラー

1. インターネット接続を確認
2. APIトークンが正しいか確認
3. ログファイルを確認：
   ```bash
   tail -f ~/.weather-mcp.log
   ```

### 依存パッケージのエラー

```bash
pip install --upgrade -r mcp/requirements.txt
```

## 次のステップ

- [詳細なドキュメント](README.md) を読む
- [対応都市一覧](README.md#対応都市) を確認
- [カスタマイズ方法](README.md#開発カスタマイズ) を学ぶ

---

**Happy Forecasting! 🌤️**
