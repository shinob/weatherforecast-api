Attribute VB_Name = "WeatherForecastClient"
'===================================================================
' WeatherForecast API Client for VBA
' Excel VBA用の気象予報APIクライアントライブラリ
'
' 必要な参照設定:
' - Microsoft Scripting Runtime (Scrrun.dll)
' - Microsoft WinHTTP Services (Winhttp.dll)
'
' 使用例:
'   Dim client As New WeatherClient
'   client.Initialize "your_api_token"
'   Dim forecast As Object
'   Set forecast = client.GetForecast(35.6762, 139.6503, 24)
'   Debug.Print forecast.TemperatureAt(0)
'===================================================================

Option Explicit

Public Const API_BASE_URL As String = "https://weather.ittools.biz/api/forecast/GSM"

'===================================================================
' WeatherClient クラス
' APIトークンを使用して天気予報を取得するメインクライアント
'===================================================================
Public Type WeatherClient
    ApiToken As String
End Type

Private m_Client As WeatherClient

' クライアントの初期化
Public Sub Initialize(ApiToken As String)
    m_Client.ApiToken = ApiToken
End Sub

' 天気予報を取得
' latitude: 緯度
' longitude: 経度
' hours: 予報時間数 (デフォルト: 24, 最大: 172)
' 戻り値: Forecast オブジェクト
Public Function GetForecast(latitude As Double, longitude As Double, Optional hours As Integer = 24) As Object
    On Error GoTo ErrorHandler

    ' URL構築
    Dim url As String
    url = API_BASE_URL & "/" & m_Client.ApiToken & "/" & _
          Format(latitude, "0.0000") & "," & Format(longitude, "0.0000")

    ' HTTP リクエスト
    Dim http As Object
    Set http = CreateObject("WinHttp.WinHttpRequest.5.1")

    http.Open "GET", url, False
    http.setTimeouts 30000, 30000, 30000, 30000 ' 30秒タイムアウト
    http.send

    ' レスポンスチェック
    If http.Status <> 200 Then
        Err.Raise vbObjectError + 1001, "GetForecast", "HTTP Error: " & http.Status
    End If

    ' JSONパース
    Dim json As Object
    Set json = ParseJson(http.responseText)

    ' エラーチェック
    If json.Exists("error") Then
        Err.Raise vbObjectError + 1002, "GetForecast", "API Error: " & json("error")
    End If

    If json("code") <> 200 Then
        Err.Raise vbObjectError + 1003, "GetForecast", "API Error: Code " & json("code")
    End If

    ' Forecastオブジェクト作成
    Set GetForecast = CreateForecast(json("result"), hours)

    Exit Function

ErrorHandler:
    Err.Raise Err.Number, Err.Source, "Failed to get forecast: " & Err.Description
End Function

'===================================================================
' Forecast クラス
' 天気予報データを格納するオブジェクト
'===================================================================
Private Function CreateForecast(result As Object, hours As Integer) As Object
    Dim forecast As Object
    Set forecast = CreateObject("Scripting.Dictionary")

    ' 座標情報
    Dim latLng() As String
    latLng = Split(result("latlng"), ",")
    forecast.Add "Latitude", CDbl(latLng(0))
    forecast.Add "Longitude", CDbl(latLng(1))
    forecast.Add "Grib2FileTime", result("grib2file_time")

    ' 予報データ
    Dim forecastData As Object
    Set forecastData = CreateObject("Scripting.Dictionary")

    Dim i As Integer
    Dim maxItems As Integer
    maxItems = IIf(result("forecast").Count < hours, result("forecast").Count, hours)

    For i = 0 To maxItems - 1
        Dim item As Object
        Set item = CreateForecastItem(result("forecast")(i))
        forecastData.Add i, item
    Next i

    forecast.Add "Data", forecastData
    forecast.Add "Count", maxItems

    ' メソッド追加（関数ポインタの代わりにキーとして保存）
    forecast.Add "TemperatureAt", "GetTemperatureAt"
    forecast.Add "PrecipitationAt", "GetPrecipitationAt"
    forecast.Add "At", "GetAt"

    Set CreateForecast = forecast
End Function

'===================================================================
' ForecastItem クラス
' 個別の予報アイテム
'===================================================================
Private Function CreateForecastItem(data As Object) As Object
    Dim item As Object
    Set item = CreateObject("Scripting.Dictionary")

    ' データ格納
    item.Add "DateTime", data("datetime")
    item.Add "Temperature", data("TMP")        ' 気温 (°C)
    item.Add "Precipitation", data("APCP")     ' 降水量 (mm)
    item.Add "WindSpeed", data("WSPD")         ' 風速 (m/s)
    item.Add "WindDirection", data("WDIR")     ' 風向 (度)
    item.Add "Humidity", data("RH")            ' 湿度 (%)
    item.Add "CloudCover", data("TCDC")        ' 雲量 (%)
    item.Add "Pressure", data("PRES")          ' 気圧 (hPa)

    ' 計算されたプロパティ
    item.Add "WindDirectionCompass", GetWindDirectionCompass(data("WDIR"))
    item.Add "WeatherIcon", GetWeatherIcon(data("APCP"), data("TCDC"))

    Set CreateForecastItem = item
End Function

'===================================================================
' ヘルパー関数
'===================================================================

' 特定の時間の気温を取得
Public Function GetTemperatureAt(forecast As Object, hour As Integer) As Variant
    Dim item As Object
    Set item = GetAt(forecast, hour)

    If Not item Is Nothing Then
        GetTemperatureAt = item("Temperature")
    Else
        GetTemperatureAt = Null
    End If
End Function

' 特定の時間の降水量を取得
Public Function GetPrecipitationAt(forecast As Object, hour As Integer) As Variant
    Dim item As Object
    Set item = GetAt(forecast, hour)

    If Not item Is Nothing Then
        GetPrecipitationAt = item("Precipitation")
    Else
        GetPrecipitationAt = Null
    End If
End Function

' 特定の時間の予報アイテムを取得
Public Function GetAt(forecast As Object, hour As Integer) As Object
    If hour >= 0 And hour < forecast("Count") Then
        Set GetAt = forecast("Data")(hour)
    Else
        Set GetAt = Nothing
    End If
End Function

' 風向を16方位に変換
Private Function GetWindDirectionCompass(degrees As Double) As String
    Dim directions As Variant
    directions = Array("N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", _
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW")

    Dim index As Integer
    index = CInt((degrees / 22.5) + 0.5) Mod 16

    GetWindDirectionCompass = directions(index)
End Function

' 天気アイコンを取得
Private Function GetWeatherIcon(precipitation As Double, cloudCover As Double) As String
    If precipitation > 1 Then
        GetWeatherIcon = "Rain"         ' 🌧️
    ElseIf precipitation > 0.1 Then
        GetWeatherIcon = "Light Rain"   ' 🌦️
    ElseIf cloudCover > 70 Then
        GetWeatherIcon = "Cloudy"       ' ☁️
    ElseIf cloudCover > 30 Then
        GetWeatherIcon = "Partly Cloudy" ' ⛅
    Else
        GetWeatherIcon = "Sunny"        ' ☀️
    End If
End Function

'===================================================================
' JSON パーサー
' 軽量なJSONパーサー（VBA-JSON等の外部ライブラリ推奨）
'===================================================================
Private Function ParseJson(jsonText As String) As Object
    On Error GoTo ErrorHandler

    ' ScriptControlを使用した簡易JSON解析
    Dim sc As Object
    Set sc = CreateObject("ScriptControl")
    sc.Language = "JScript"

    ' JSONオブジェクトを評価
    Dim jsonObj As Object
    Set jsonObj = sc.Eval("(" & jsonText & ")")

    ' VBA Dictionaryに変換
    Set ParseJson = ConvertToVBAObject(jsonObj, sc)

    Exit Function

ErrorHandler:
    Err.Raise vbObjectError + 1004, "ParseJson", "Failed to parse JSON: " & Err.Description
End Function

Private Function ConvertToVBAObject(jsObj As Object, sc As Object) As Object
    Dim result As Object

    ' 配列かオブジェクトか判定
    If sc.Eval("Array.isArray")(jsObj) Then
        ' 配列の場合
        Set result = CreateObject("Scripting.Dictionary")

        Dim i As Long
        Dim length As Long
        length = jsObj.length

        For i = 0 To length - 1
            Dim item As Variant
            If IsObject(jsObj.Item(i)) Then
                Set item = ConvertToVBAObject(jsObj.Item(i), sc)
                Set result(i) = item
            Else
                result(i) = jsObj.Item(i)
            End If
        Next i

        result.Add "Count", length
    Else
        ' オブジェクトの場合
        Set result = CreateObject("Scripting.Dictionary")

        ' オブジェクトのキーを取得
        Dim keys As Object
        Set keys = sc.Eval("Object.keys")(jsObj)

        Dim key As Variant
        For i = 0 To keys.length - 1
            key = keys.Item(i)

            Dim value As Variant
            If IsObject(sc.Eval(key)(jsObj)) Then
                Set value = ConvertToVBAObject(sc.Eval(key)(jsObj), sc)
                Set result(key) = value
            Else
                result(key) = sc.Eval(key)(jsObj)
            End If
        Next i
    End If

    Set ConvertToVBAObject = result
End Function

'===================================================================
' ユーティリティ関数
'===================================================================

' すべての予報データを取得
Public Function GetAllItems(forecast As Object) As Object
    Set GetAllItems = forecast("Data")
End Function

' 予報データ数を取得
Public Function GetCount(forecast As Object) As Integer
    GetCount = forecast("Count")
End Function

' 予報データをExcelシートに出力
Public Sub ExportToSheet(forecast As Object, ws As Worksheet, Optional startRow As Integer = 1)
    ' ヘッダー
    ws.Cells(startRow, 1).value = "日時"
    ws.Cells(startRow, 2).value = "気温(°C)"
    ws.Cells(startRow, 3).value = "降水量(mm)"
    ws.Cells(startRow, 4).value = "風速(m/s)"
    ws.Cells(startRow, 5).value = "風向"
    ws.Cells(startRow, 6).value = "湿度(%)"
    ws.Cells(startRow, 7).value = "雲量(%)"
    ws.Cells(startRow, 8).value = "気圧(hPa)"
    ws.Cells(startRow, 9).value = "天気"

    ' データ
    Dim i As Integer
    Dim item As Object

    For i = 0 To forecast("Count") - 1
        Set item = forecast("Data")(i)

        ws.Cells(startRow + i + 1, 1).value = item("DateTime")
        ws.Cells(startRow + i + 1, 2).value = item("Temperature")
        ws.Cells(startRow + i + 1, 3).value = item("Precipitation")
        ws.Cells(startRow + i + 1, 4).value = item("WindSpeed")
        ws.Cells(startRow + i + 1, 5).value = item("WindDirectionCompass")
        ws.Cells(startRow + i + 1, 6).value = item("Humidity")
        ws.Cells(startRow + i + 1, 7).value = item("CloudCover")
        ws.Cells(startRow + i + 1, 8).value = item("Pressure")
        ws.Cells(startRow + i + 1, 9).value = item("WeatherIcon")
    Next i

    ' ヘッダーを太字に
    ws.Range(ws.Cells(startRow, 1), ws.Cells(startRow, 9)).Font.Bold = True
End Sub
