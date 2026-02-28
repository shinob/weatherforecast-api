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

MCPサーバーをClaude Codeに追加します。

#### 方法A: CLIコマンドで追加（推奨・最速）

```bash
cd /path/to/weatherforecast-api
claude mcp add --transport stdio weather-forecast -- python3 ${PWD}/mcp/server.py
```

この方法なら設定は自動的に完了します！

#### 方法B: 設定ファイルを手動で編集

**ユーザースコープ（全プロジェクトで使用）**

```bash
# 設定ファイルを編集
nano ~/.claude.json
```

以下の内容を追加：

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

**プロジェクトスコープ（このプロジェクトのみ）**

プロジェクトルートに `.mcp.json` を作成：

```bash
cd /path/to/weatherforecast-api
nano .mcp.json
```

以下の内容を記述：

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
- 環境変数のデフォルト値を設定可能（`${VAR:-default}` 構文）
- チームメンバーと設定を共有できる（バージョン管理に含める）

**パスの確認方法**:
```bash
cd /path/to/weatherforecast-api/mcp
pwd
# 出力例: /home/username/weatherforecast-api/mcp
# この場合、パスは /home/username/weatherforecast-api/mcp/server.py
```

### ステップ4: 設定の確認

MCPサーバーが正しく登録されたか確認：

```bash
claude mcp list
```

出力例：
```
weather-forecast (stdio)
  Command: python3 /path/to/weatherforecast-api/mcp/server.py
```

### ステップ5: Claude Codeを再起動

設定を反映させるため、Claude Codeを完全に終了してから再起動します。

### ステップ6: 動作確認

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

1. MCPサーバーが登録されているか確認：
   ```bash
   claude mcp list
   ```

2. Claude Codeを完全に終了して再起動

3. 設定ファイルのJSONフォーマットが正しいか確認：
   ```bash
   # ユーザースコープの場合
   cat ~/.claude.json

   # プロジェクトスコープの場合
   cat .mcp.json
   ```

4. server.pyのパスが正しいか確認
   - ユーザースコープ: 絶対パスを使用
   - プロジェクトスコープ: 絶対パスを使用（相対パスはサポートされていません）

### "Tool not found" エラー

1. MCPサーバーが起動しているか確認：
   ```bash
   # ログファイルを確認
   tail -f ~/.weather-mcp.log
   ```

2. Pythonコマンドが正しいか確認：
   ```bash
   # Pythonのパスを確認
   which python3  # macOS/Linux
   where python   # Windows
   ```

3. server.pyが実行可能か手動テスト：
   ```bash
   python3 /path/to/weatherforecast-api/mcp/server.py
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
