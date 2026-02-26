Attribute VB_Name = "Example"
'===================================================================
' WeatherForecast API Client の使用例
' このモジュールは、WeatherForecastClient.bas の使い方を示します
'===================================================================

Option Explicit

'===================================================================
' 例1: 基本的な使用方法
'===================================================================
Sub Example1_BasicUsage()
    ' クライアントの初期化
    Dim client As WeatherClient
    Initialize "your_api_token"

    ' 東京（緯度35.6762, 経度139.6503）の24時間予報を取得
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
                    "降水量: " & item("Precipitation") & "mm | " & _
                    "天気: " & item("WeatherIcon")
    Next i
End Sub

'===================================================================
' 例2: Excelシートに出力
'===================================================================
Sub Example2_ExportToSheet()
    ' クライアントの初期化
    Initialize "your_api_token"

    ' 大阪（緯度34.6937, 経度135.5023）の24時間予報を取得
    Dim forecast As Object
    Set forecast = GetForecast(34.6937, 135.5023, 24)

    ' 新しいシートを作成
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets.Add
    ws.Name = "大阪天気予報"

    ' シートに出力
    ExportToSheet forecast, ws, 1

    ' 列幅を自動調整
    ws.Columns.AutoFit

    Debug.Print "天気予報データをシートに出力しました"
End Sub

'===================================================================
' 例3: 最高・最低気温を計算
'===================================================================
Sub Example3_MinMaxTemperature()
    ' クライアントの初期化
    Initialize "your_api_token"

    ' 札幌（緯度43.0642, 経度141.3469）の24時間予報を取得
    Dim forecast As Object
    Set forecast = GetForecast(43.0642, 141.3469, 24)

    ' 最高・最低気温を計算
    Dim minTemp As Double
    Dim maxTemp As Double
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
    Debug.Print "気温差: " & (maxTemp - minTemp) & "°C"
End Sub

'===================================================================
' 例4: 雨が降る時間帯を検索
'===================================================================
Sub Example4_FindRainyHours()
    ' クライアントの初期化
    Initialize "your_api_token"

    ' 福岡（緯度33.5904, 経度130.4017）の24時間予報を取得
    Dim forecast As Object
    Set forecast = GetForecast(33.5904, 130.4017, 24)

    Debug.Print "=== 雨が降る時間帯 ==="

    Dim i As Integer
    Dim rainyCount As Integer
    rainyCount = 0

    For i = 0 To GetCount(forecast) - 1
        Dim item As Object
        Set item = GetAt(forecast, i)

        ' 降水量が0.1mm以上の場合
        If item("Precipitation") > 0.1 Then
            Debug.Print item("DateTime") & " | " & _
                        "降水量: " & item("Precipitation") & "mm | " & _
                        "天気: " & item("WeatherIcon")
            rainyCount = rainyCount + 1
        End If
    Next i

    If rainyCount = 0 Then
        Debug.Print "今後24時間は雨は降りません"
    Else
        Debug.Print "---"
        Debug.Print "合計 " & rainyCount & " 時間雨が降る予報です"
    End If
End Sub

'===================================================================
' 例5: 強風警報
'===================================================================
Sub Example5_WindAlert()
    ' クライアントの初期化
    Initialize "your_api_token"

    ' 那覇（緯度26.2124, 経度127.6809）の24時間予報を取得
    Dim forecast As Object
    Set forecast = GetForecast(26.2124, 127.6809, 24)

    Debug.Print "=== 強風警報（10m/s以上） ==="

    Dim i As Integer
    Dim alertCount As Integer
    alertCount = 0

    For i = 0 To GetCount(forecast) - 1
        Dim item As Object
        Set item = GetAt(forecast, i)

        ' 風速が10m/s以上の場合
        If item("WindSpeed") >= 10 Then
            Debug.Print item("DateTime") & " | " & _
                        "風速: " & item("WindSpeed") & "m/s | " & _
                        "風向: " & item("WindDirectionCompass")
            alertCount = alertCount + 1
        End If
    Next i

    If alertCount = 0 Then
        Debug.Print "今後24時間は強風の心配はありません"
    Else
        Debug.Print "---"
        Debug.Print "警告: " & alertCount & " 時間で強風が予想されます"
    End If
End Sub

'===================================================================
' 例6: 複数地点の天気を比較
'===================================================================
Sub Example6_CompareLocations()
    ' クライアントの初期化
    Initialize "your_api_token"

    ' 複数地点の座標
    Dim locations As Object
    Set locations = CreateObject("Scripting.Dictionary")
    locations.Add "東京", Array(35.6762, 139.6503)
    locations.Add "大阪", Array(34.6937, 135.5023)
    locations.Add "名古屋", Array(35.1815, 136.9066)

    ' 各地点の現在の気温を取得
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
                    "天気: " & item("WeatherIcon") & " | " & _
                    "湿度: " & item("Humidity") & "%"
    Next location
End Sub

'===================================================================
' 例7: グラフを作成
'===================================================================
Sub Example7_CreateChart()
    ' クライアントの初期化
    Initialize "your_api_token"

    ' 京都（緯度35.0116, 経度135.7681）の24時間予報を取得
    Dim forecast As Object
    Set forecast = GetForecast(35.0116, 135.7681, 24)

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

    Debug.Print "グラフを作成しました"
End Sub

'===================================================================
' 例8: エラーハンドリング
'===================================================================
Sub Example8_ErrorHandling()
    On Error GoTo ErrorHandler

    ' クライアントの初期化（無効なトークン）
    Initialize "invalid_token"

    ' 予報取得を試みる
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

'===================================================================
' 例9: 長期予報（72時間）
'===================================================================
Sub Example9_LongTermForecast()
    ' クライアントの初期化
    Initialize "your_api_token"

    ' 仙台（緯度38.2682, 経度140.8694）の72時間予報を取得
    Dim forecast As Object
    Set forecast = GetForecast(38.2682, 140.8694, 72)

    Debug.Print "=== 仙台 3日間の予報 ==="
    Debug.Print "予報データ数: " & GetCount(forecast) & "時間"

    ' 24時間ごとにサマリーを表示
    Dim day As Integer
    For day = 0 To 2
        Dim startHour As Integer
        startHour = day * 24

        Debug.Print "---"
        Debug.Print "Day " & (day + 1) & ":"

        ' その日の最高・最低気温
        Dim minTemp As Double
        Dim maxTemp As Double
        minTemp = 999
        maxTemp = -999

        Dim totalPrecip As Double
        totalPrecip = 0

        Dim i As Integer
        For i = startHour To startHour + 23
            If i < GetCount(forecast) Then
                Dim temp As Double
                temp = GetTemperatureAt(forecast, i)

                If temp < minTemp Then minTemp = temp
                If temp > maxTemp Then maxTemp = temp

                totalPrecip = totalPrecip + GetPrecipitationAt(forecast, i)
            End If
        Next i

        Debug.Print "  最低気温: " & Round(minTemp, 1) & "°C"
        Debug.Print "  最高気温: " & Round(maxTemp, 1) & "°C"
        Debug.Print "  総降水量: " & Round(totalPrecip, 1) & "mm"
    Next day
End Sub

'===================================================================
' 例10: ユーザーフォームで表示
'===================================================================
Sub Example10_ShowInUserForm()
    ' クライアントの初期化
    Initialize "your_api_token"

    ' 広島（緯度34.3853, 経度132.4553）の24時間予報を取得
    Dim forecast As Object
    Set forecast = GetForecast(34.3853, 132.4553, 24)

    ' メッセージボックスで表示（簡易版）
    Dim message As String
    message = "=== 広島の天気予報 ===" & vbCrLf & vbCrLf

    Dim i As Integer
    For i = 0 To 5 ' 最初の6時間だけ表示
        Dim item As Object
        Set item = GetAt(forecast, i)

        message = message & item("DateTime") & vbCrLf & _
                  "  気温: " & item("Temperature") & "°C" & vbCrLf & _
                  "  天気: " & item("WeatherIcon") & vbCrLf & vbCrLf
    Next i

    MsgBox message, vbInformation, "広島の天気予報"
End Sub
