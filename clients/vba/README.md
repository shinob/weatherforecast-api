# WeatherForecast API Client for VBA

Excel VBA用の気象予報APIクライアントライブラリです。

## 特徴

- ✅ シンプルで直感的なAPI設計
- ✅ 天気アイコン自動判定（Rain, Light Rain, Cloudy, Partly Cloudy, Sunny）
- ✅ 風向の16方位変換
- ✅ エラーハンドリング
- ✅ Excelシートへの直接出力機能
- ✅ 24〜172時間の予報取得

## 必要な環境

- **Excel**: Microsoft Excel 2010以降（Windows版）
- **参照設定**:
  - Microsoft Scripting Runtime (Scrrun.dll)
  - Microsoft WinHTTP Services (Winhttp.dll)

## インストール

### 1. ファイルのインポート

1. Excel を開く
2. `Alt + F11` を押してVBAエディタを開く
3. `ファイル` → `ファイルのインポート` を選択
4. 以下のファイルをインポート:
   - `WeatherForecastClient.bas`
   - `Example.bas` (サンプルコード)

### 2. 参照設定

1. VBAエディタで `ツール` → `参照設定` を選択
2. 以下にチェックを入れる:
   - `Microsoft Scripting Runtime`
   - `Microsoft WinHTTP Services, version 5.1`

### 3. APIトークンの設定

サンプルコード内の `your_api_token` を実際のAPIトークンに置き換えてください。

## クイックスタート

### 基本的な使用方法

```vba
Sub GetWeatherForecast()
    ' クライアントの初期化
    Initialize "your_api_token"

    ' 東京の24時間予報を取得
    Dim forecast As Object
    Set forecast = GetForecast(35.6762, 139.6503, 24)

    ' 最初の時間の気温を取得
    Debug.Print "現在の気温: " & GetTemperatureAt(forecast, 0) & "°C"

    ' すべての予報をループ
    Dim i As Integer
    For i = 0 To GetCount(forecast) - 1
        Dim item As Object
        Set item = GetAt(forecast, i)

        Debug.Print item("DateTime") & " | " & _
                    "気温: " & item("Temperature") & "°C | " & _
                    "天気: " & item("WeatherIcon")
    Next i
End Sub
```

### Excelシートに出力

```vba
Sub ExportWeatherToSheet()
    ' クライアントの初期化
    Initialize "your_api_token"

    ' 大阪の24時間予報を取得
    Dim forecast As Object
    Set forecast = GetForecast(34.6937, 135.5023, 24)

    ' 現在のシートに出力
    ExportToSheet forecast, ActiveSheet, 1

    ' 列幅を自動調整
    ActiveSheet.Columns.AutoFit
End Sub
```

## API リファレンス

### 関数

#### Initialize(ApiToken As String)

クライアントを初期化します。

**パラメータ:**
- `ApiToken`: APIトークン（文字列）

**例:**
```vba
Initialize "your_api_token"
```

#### GetForecast(latitude, longitude, [hours]) As Object

指定した座標の天気予報を取得します。

**パラメータ:**
- `latitude`: 緯度（Double）
- `longitude`: 経度（Double）
- `hours`: 予報時間数（Integer、オプション、デフォルト: 24、最大: 172）

**戻り値:**
- Forecast オブジェクト

**例:**
```vba
Dim forecast As Object
Set forecast = GetForecast(35.6762, 139.6503, 24)
```

#### GetAt(forecast, hour) As Object

特定の時間の予報アイテムを取得します。

**パラメータ:**
- `forecast`: Forecastオブジェクト
- `hour`: 時間インデックス（0始まり）

**戻り値:**
- ForecastItem オブジェクト（範囲外の場合は Nothing）

**例:**
```vba
Dim item As Object
Set item = GetAt(forecast, 0)
```

#### GetTemperatureAt(forecast, hour) As Variant

特定の時間の気温を取得します。

**パラメータ:**
- `forecast`: Forecastオブジェクト
- `hour`: 時間インデックス（0始まり）

**戻り値:**
- 気温（°C）または Null

**例:**
```vba
Dim temp As Double
temp = GetTemperatureAt(forecast, 0)
```

#### GetPrecipitationAt(forecast, hour) As Variant

特定の時間の降水量を取得します。

**パラメータ:**
- `forecast`: Forecastオブジェクト
- `hour`: 時間インデックス（0始まり）

**戻り値:**
- 降水量（mm）または Null

**例:**
```vba
Dim precip As Double
precip = GetPrecipitationAt(forecast, 3)
```

#### GetCount(forecast) As Integer

予報データ数を取得します。

**パラメータ:**
- `forecast`: Forecastオブジェクト

**戻り値:**
- データ数（Integer）

**例:**
```vba
Dim count As Integer
count = GetCount(forecast)
```

#### ExportToSheet(forecast, ws, [startRow])

予報データをExcelシートに出力します。

**パラメータ:**
- `forecast`: Forecastオブジェクト
- `ws`: 出力先ワークシート
- `startRow`: 開始行（Integer、オプション、デフォルト: 1）

**例:**
```vba
ExportToSheet forecast, ActiveSheet, 1
```

### オブジェクト

#### Forecast オブジェクト

天気予報データを格納するオブジェクトです。

**プロパティ:**
- `Latitude`: 緯度（Double）
- `Longitude`: 経度（Double）
- `Grib2FileTime`: GRIBファイル時刻（String）
- `Data`: 予報アイテムのコレクション（Dictionary）
- `Count`: データ数（Integer）

#### ForecastItem オブジェクト

個別の予報アイテムです。

**プロパティ:**
- `DateTime`: 日時（String）
- `Temperature`: 気温（°C、Double）
- `Precipitation`: 降水量（mm、Double）
- `WindSpeed`: 風速（m/s、Double）
- `WindDirection`: 風向（度、Double）
- `WindDirectionCompass`: 風向（16方位、String）
- `Humidity`: 湿度（%、Double）
- `CloudCover`: 雲量（%、Double）
- `Pressure`: 気圧（hPa、Double）
- `WeatherIcon`: 天気アイコン（String）

## 使用例

### 1. 最高・最低気温を計算

```vba
Sub Example_MinMaxTemperature()
    Initialize "your_api_token"

    Dim forecast As Object
    Set forecast = GetForecast(43.0642, 141.3469, 24) ' 札幌

    Dim minTemp As Double, maxTemp As Double
    minTemp = 999
    maxTemp = -999

    Dim i As Integer
    For i = 0 To GetCount(forecast) - 1
        Dim temp As Double
        temp = GetTemperatureAt(forecast, i)

        If temp < minTemp Then minTemp = temp
        If temp > maxTemp Then maxTemp = temp
    Next i

    Debug.Print "最低気温: " & minTemp & "°C"
    Debug.Print "最高気温: " & maxTemp & "°C"
End Sub
```

### 2. 雨が降る時間帯を検索

```vba
Sub Example_FindRainyHours()
    Initialize "your_api_token"

    Dim forecast As Object
    Set forecast = GetForecast(33.5904, 130.4017, 24) ' 福岡

    Debug.Print "=== 雨が降る時間帯 ==="

    Dim i As Integer
    For i = 0 To GetCount(forecast) - 1
        Dim item As Object
        Set item = GetAt(forecast, i)

        If item("Precipitation") > 0.1 Then
            Debug.Print item("DateTime") & " | " & _
                        "降水量: " & item("Precipitation") & "mm"
        End If
    Next i
End Sub
```

### 3. 複数地点の天気を比較

```vba
Sub Example_CompareLocations()
    Initialize "your_api_token"

    ' 各地点の座標
    Dim locations As Object
    Set locations = CreateObject("Scripting.Dictionary")
    locations.Add "東京", Array(35.6762, 139.6503)
    locations.Add "大阪", Array(34.6937, 135.5023)
    locations.Add "名古屋", Array(35.1815, 136.9066)

    Debug.Print "=== 各地点の現在の天気 ==="

    Dim location As Variant
    For Each location In locations.Keys
        Dim coords As Variant
        coords = locations(location)

        Dim forecast As Object
        Set forecast = GetForecast(coords(0), coords(1), 1)

        Dim item As Object
        Set item = GetAt(forecast, 0)

        Debug.Print location & " | " & _
                    "気温: " & item("Temperature") & "°C | " & _
                    "天気: " & item("WeatherIcon")
    Next location
End Sub
```

### 4. グラフを作成

```vba
Sub Example_CreateChart()
    Initialize "your_api_token"

    Dim forecast As Object
    Set forecast = GetForecast(35.0116, 135.7681, 24) ' 京都

    ' 新しいシートを作成
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets.Add
    ws.Name = "京都天気予報"

    ' データをシートに出力
    ExportToSheet forecast, ws, 1

    ' グラフ作成
    Dim chart As ChartObject
    Set chart = ws.ChartObjects.Add(Left:=10, Top:=400, Width:=600, Height:=300)

    With chart.chart
        .ChartType = xlLine
        .SetSourceData Source:=ws.Range("A1:C" & (GetCount(forecast) + 1))
        .HasTitle = True
        .ChartTitle.Text = "京都 気温と降水量の推移"
    End With
End Sub
```

## 天気アイコン判定

天気アイコンは以下のロジックで自動判定されます：

| アイコン | 条件 |
|---------|------|
| Rain | 降水量 > 1.0mm |
| Light Rain | 降水量 > 0.1mm |
| Cloudy | 雲量 > 70% |
| Partly Cloudy | 雲量 > 30% |
| Sunny | その他 |

## 風向変換

風向は以下の16方位に変換されます：

```
N (北), NNE (北北東), NE (北東), ENE (東北東),
E (東), ESE (東南東), SE (南東), SSE (南南東),
S (南), SSW (南南西), SW (南西), WSW (西南西),
W (西), WNW (西北西), NW (北西), NNW (北北西)
```

## エラーハンドリング

```vba
Sub Example_ErrorHandling()
    On Error GoTo ErrorHandler

    Initialize "your_api_token"

    Dim forecast As Object
    Set forecast = GetForecast(35.6762, 139.6503, 24)

    Debug.Print "予報を取得しました"
    Exit Sub

ErrorHandler:
    Debug.Print "エラーが発生しました: " & Err.Description
    MsgBox "天気予報の取得に失敗しました。" & vbCrLf & _
           "APIトークンとネットワーク接続を確認してください。", _
           vbExclamation, "エラー"
End Sub
```

## 主要な都市の座標

| 都市 | 緯度 | 経度 |
|------|------|------|
| 東京 | 35.6762 | 139.6503 |
| 大阪 | 34.6937 | 135.5023 |
| 名古屋 | 35.1815 | 136.9066 |
| 札幌 | 43.0642 | 141.3469 |
| 福岡 | 33.5904 | 130.4017 |
| 仙台 | 38.2682 | 140.8694 |
| 広島 | 34.3853 | 132.4553 |
| 京都 | 35.0116 | 135.7681 |
| 那覇 | 26.2124 | 127.6809 |

## トラブルシューティング

### エラー: "ユーザー定義型は定義されていません"

参照設定を確認してください：
1. VBAエディタで `ツール` → `参照設定`
2. `Microsoft Scripting Runtime` にチェック

### エラー: "実行時エラー -2147012889"

ネットワーク接続を確認してください。プロキシ環境下では設定が必要な場合があります。

### エラー: "API Error: Code 401"

APIトークンが無効です。正しいトークンを設定してください。

### JSONパースエラー

ScriptControl が利用できない場合（64bit Excel）は、VBA-JSON等の外部ライブラリの使用を検討してください。

## パフォーマンスの考慮事項

- 複数地点のデータを取得する場合は、適度な間隔を空けてAPIを呼び出してください
- 大量のデータを処理する場合は、配列を使用してシートへの書き込み回数を最小限に抑えてください
- タイムアウトはデフォルトで30秒です（必要に応じて調整可能）

## セキュリティ

### APIトークンの保護

APIトークンをコード内に直接記述するのは推奨されません。以下の方法を検討してください：

1. **ワークシートのセルから読み込む:**
   ```vba
   Dim apiToken As String
   apiToken = ThisWorkbook.Worksheets("Config").Range("A1").Value
   Initialize apiToken
   ```

2. **環境変数から読み込む:**
   ```vba
   Dim apiToken As String
   apiToken = Environ("WEATHER_API_TOKEN")
   Initialize apiToken
   ```

3. **暗号化されたファイルから読み込む**（上級者向け）

## 制限事項

- ScriptControlは64bit Excelでは動作しません（代替ライブラリの使用を推奨）
- Windows版Excelのみサポート（Mac版では動作しません）
- 同時リクエスト数に制限がある場合があります（API仕様を確認してください）

## サンプルファイル

`Example.bas` には10種類の実用的なサンプルコードが含まれています：

1. 基本的な使用方法
2. Excelシートに出力
3. 最高・最低気温を計算
4. 雨が降る時間帯を検索
5. 強風警報
6. 複数地点の天気を比較
7. グラフを作成
8. エラーハンドリング
9. 長期予報（72時間）
10. ユーザーフォームで表示

## ライセンス

MIT License

## サポート

- **メインプロジェクト**: [../README.md](../README.md)
- **API仕様**: [https://weather.ittools.biz/](https://weather.ittools.biz/)

---

**Happy Coding! 🚀**
