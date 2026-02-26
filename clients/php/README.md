# WeatherForecast API Client - PHP

PHP用のWeatherForecast APIクライアントライブラリです。Iterator/Countableインターフェース実装。

## 📦 インストール

依存パッケージのインストールは不要です。

### 必要な環境

- PHP 7.4以上
- cURL拡張（通常はデフォルトで有効）

### cURL拡張の確認

```bash
php -m | grep curl
```

出力に `curl` が表示されればOKです。

## 🚀 基本的な使い方

```php
<?php
require_once 'WeatherForecastClient.php';

// クライアントを初期化
$client = new WeatherForecastClient('your_api_token');

// 東京の24時間予報を取得
$forecast = $client->getForecast(35.6762, 139.6503, 24);

// 位置情報
echo "緯度: {$forecast->latitude}\n";
echo "経度: {$forecast->longitude}\n";
echo "予報時間数: " . count($forecast) . "\n";

// 最初の時間の詳細
$first = $forecast->at(0);
echo "{$first->datetime}: {$first->temperature}°C\n";
echo "天気: {$first->getWeatherIcon()}\n";
echo "風: {$first->windSpeed}m/s {$first->getWindDirectionCompass()}\n";
```

## 📚 API リファレンス

### WeatherForecastClient

#### 初期化

```php
$client = new WeatherForecastClient(string $apiToken)
```

**パラメータ:**
- `$apiToken` (string): あなたのAPIトークン

#### getForecast(latitude, longitude, hours = 24)

天気予報を取得します。

```php
$forecast = $client->getForecast(35.6762, 139.6503, 24);
```

**パラメータ:**
- `$latitude` (float): 緯度
- `$longitude` (float): 経度
- `$hours` (int, optional): 予報時間数（デフォルト: 24、最大: 172）

**戻り値:** `Forecast` オブジェクト

**例外:**
- `WeatherAPIException`: APIリクエストが失敗した場合

### Forecast

予報データを管理するクラス。Iteratorインターフェースを実装。

#### プロパティ

```php
$forecast->latitude;        // float: 緯度
$forecast->longitude;       // float: 経度
$forecast->grib2fileTime;   // string: 予報基準時刻
$forecast->data;            // array: ForecastItemの配列
```

#### メソッド

##### at(int $hour): ?ForecastItem

指定した時間の予報を取得。

```php
$item = $forecast->at(3);  // 3時間後の予報
```

**戻り値:** `ForecastItem` または `null`

##### temperatureAt(int $hour): ?float

指定した時間の気温を取得。

```php
$temp = $forecast->temperatureAt(3);  // 3時間後の気温
```

**戻り値:** `float` または `null`

##### precipitationAt(int $hour): ?float

指定した時間の降水量を取得。

```php
$rain = $forecast->precipitationAt(3);  // 3時間後の降水量
```

**戻り値:** `float` または `null`

##### all(): array

すべての予報データを配列で取得。

```php
$allForecasts = $forecast->all();
```

**戻り値:** `array<ForecastItem>`

##### count(): int

予報時間数を取得（Countableインターフェース）。

```php
$hours = count($forecast);
```

**戻り値:** `int`

##### Iterator Methods

Iteratorインターフェースを実装しているため、`foreach`で使用可能。

```php
foreach ($forecast as $index => $item) {
    echo "{$index}時間後: {$item->temperature}°C\n";
}
```

### ForecastItem

個別の予報データ。

#### プロパティ

```php
$item->datetime;         // string: 予報日時 (例: "2026-02-25 17:00:00")
$item->temperature;      // float: 気温 (°C)
$item->precipitation;    // float: 降水量 (mm)
$item->windSpeed;        // float: 風速 (m/s)
$item->windDirection;    // float: 風向 (度)
$item->humidity;         // float: 湿度 (%)
$item->cloudCover;       // float: 雲量 (%)
$item->pressure;         // float: 気圧 (hPa)
```

#### メソッド

##### getWindDirectionCompass(): string

風向を16方位で取得。

```php
$direction = $item->getWindDirectionCompass();  // 例: "NE" (北東)
```

**戻り値:** `string`

##### getWeatherIcon(): string

天気状態をアイコン絵文字で取得。

```php
$icon = $item->getWeatherIcon();  // 例: "☀️" (晴れ)
```

**戻り値:** `string`

判定ロジック:
- 🌧️ 降水量 > 1.0mm
- 🌦️ 降水量 > 0.1mm
- ☁️ 雲量 > 70%
- ⛅ 雲量 > 30%
- ☀️ その他

##### toArray(): array

すべてのデータを連想配列で取得。

```php
$data = $item->toArray();
// => [
//   'datetime' => "2026-02-25 17:00:00",
//   'temperature' => 9.13,
//   'precipitation' => 0.594,
//   'wind_speed' => 3.42,
//   'wind_direction' => 45,
//   'wind_direction_compass' => "NE",
//   'humidity' => 88.2,
//   'cloud_cover' => 100.0,
//   'pressure' => 1008.8,
//   'weather_icon' => "🌧️"
// ]
```

**戻り値:** `array`

## 💡 使用例

### 例1: 基本的な情報表示

```php
<?php
require_once 'WeatherForecastClient.php';

$client = new WeatherForecastClient('api_sample');
$forecast = $client->getForecast(35.6762, 139.6503);

foreach ($forecast as $i => $item) {
    echo "{$i}時間後: {$item->temperature}°C {$item->getWeatherIcon()}\n";
}
```

### 例2: 最高気温・最低気温の取得

```php
$temps = array_map(fn($item) => $item->temperature, $forecast->all());
$maxTemp = max($temps);
$minTemp = min($temps);

printf("最高気温: %.1f°C\n", $maxTemp);
printf("最低気温: %.1f°C\n", $minTemp);
```

### 例3: 雨が降る時間帯を検索

```php
$rainyHours = array_filter(
    $forecast->all(),
    fn($item) => $item->precipitation > 0.1
);

if (empty($rainyHours)) {
    echo "今後24時間は雨が降らない予報です\n";
} else {
    echo "雨が降る時間帯:\n";
    foreach ($rainyHours as $item) {
        echo "  {$item->datetime}: {$item->precipitation}mm\n";
    }
}
```

### 例4: 平均気温の計算

```php
$total = array_sum(array_map(fn($item) => $item->temperature, $forecast->all()));
$avgTemp = $total / count($forecast);
printf("平均気温: %.1f°C\n", $avgTemp);
```

### 例5: 風の強い時間帯を検索

```php
$windyHours = array_filter(
    $forecast->all(),
    fn($item) => $item->windSpeed > 5.0
);

if (!empty($windyHours)) {
    echo "風の強い時間帯 (5m/s以上):\n";
    foreach ($windyHours as $item) {
        printf(
            "  %s: %.1fm/s %s\n",
            $item->datetime,
            $item->windSpeed,
            $item->getWindDirectionCompass()
        );
    }
}
```

### 例6: エラーハンドリング

```php
<?php
require_once 'WeatherForecastClient.php';

try {
    $client = new WeatherForecastClient('your_api_token');
    $forecast = $client->getForecast(35.6762, 139.6503);

    echo "予報取得成功！\n";
    printf("気温: %.1f°C\n", $forecast->temperatureAt(0));

} catch (WeatherAPIException $e) {
    echo "エラーが発生しました: {$e->getMessage()}\n";

    $errorMsg = $e->getMessage();
    if (strpos($errorMsg, '401') !== false) {
        echo "APIトークンが無効です\n";
    } elseif (strpos($errorMsg, '404') !== false) {
        echo "指定された位置の予報が見つかりません\n";
    } elseif (strpos($errorMsg, 'Request failed') !== false) {
        echo "ネットワークエラーです。接続を確認してください\n";
    } else {
        echo "予期しないエラーです\n";
    }
}
```

## 🎯 実践的な例

### 天気予報レポートの生成

```php
<?php
require_once 'WeatherForecastClient.php';

function generateWeatherReport(float $lat, float $lng, string $apiToken): void
{
    try {
        $client = new WeatherForecastClient($apiToken);
        $forecast = $client->getForecast($lat, $lng, 24);

        echo str_repeat("=", 50) . "\n";
        echo "天気予報レポート\n";
        echo str_repeat("=", 50) . "\n";
        printf("位置: %s, %s\n", $forecast->latitude, $forecast->longitude);
        printf("基準時刻: %s\n\n", $forecast->grib2fileTime);

        // 概要統計
        $temps = array_map(fn($item) => $item->temperature, $forecast->all());
        $rains = array_map(fn($item) => $item->precipitation, $forecast->all());

        echo "【24時間の概要】\n";
        printf("最高気温: %.1f°C\n", max($temps));
        printf("最低気温: %.1f°C\n", min($temps));
        printf("平均気温: %.1f°C\n", array_sum($temps) / count($temps));
        printf("総降水量: %.1fmm\n\n", array_sum($rains));

        // 時間帯別の情報
        echo "【時間帯別予報】\n";
        foreach ([0, 6, 12, 18] as $hour) {
            $item = $forecast->at($hour);
            if ($item) {
                printf("\n%d時間後 (%s):\n", $hour, $item->datetime);
                printf("  %s %.1f°C\n", $item->getWeatherIcon(), $item->temperature);
                printf("  降水: %.1fmm\n", $item->precipitation);
                printf(
                    "  風: %.1fm/s (%s)\n",
                    $item->windSpeed,
                    $item->getWindDirectionCompass()
                );
            }
        }

    } catch (WeatherAPIException $e) {
        echo "エラー: {$e->getMessage()}\n";
    }
}

// 使用例
generateWeatherReport(35.6762, 139.6503, 'api_sample');
```

### JSON APIレスポンスの生成

```php
<?php
require_once 'WeatherForecastClient.php';

header('Content-Type: application/json; charset=utf-8');

try {
    $lat = $_GET['lat'] ?? 35.6762;
    $lng = $_GET['lng'] ?? 139.6503;
    $hours = $_GET['hours'] ?? 24;

    $client = new WeatherForecastClient('your_api_token');
    $forecast = $client->getForecast($lat, $lng, $hours);

    $response = [
        'status' => 'success',
        'location' => [
            'latitude' => $forecast->latitude,
            'longitude' => $forecast->longitude
        ],
        'grib2file_time' => $forecast->grib2fileTime,
        'forecast' => array_map(fn($item) => $item->toArray(), $forecast->all())
    ];

    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

} catch (WeatherAPIException $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
```

### HTMLテーブルとして表示

```php
<?php
require_once 'WeatherForecastClient.php';

$client = new WeatherForecastClient('api_sample');
$forecast = $client->getForecast(35.6762, 139.6503, 24);
?>
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>天気予報</title>
    <style>
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>24時間天気予報</h1>
    <p>位置: <?= htmlspecialchars($forecast->latitude) ?>,
       <?= htmlspecialchars($forecast->longitude) ?></p>

    <table>
        <tr>
            <th>時間</th>
            <th>天気</th>
            <th>気温</th>
            <th>降水量</th>
            <th>風</th>
        </tr>
        <?php foreach ($forecast as $i => $item): ?>
        <tr>
            <td><?= htmlspecialchars($item->datetime) ?></td>
            <td><?= $item->getWeatherIcon() ?></td>
            <td><?= number_format($item->temperature, 1) ?>°C</td>
            <td><?= number_format($item->precipitation, 1) ?>mm</td>
            <td><?= number_format($item->windSpeed, 1) ?>m/s
                <?= htmlspecialchars($item->getWindDirectionCompass()) ?></td>
        </tr>
        <?php endforeach; ?>
    </table>
</body>
</html>
```

## 🔧 トラブルシューティング

### Q: cURL拡張がない

```bash
# Ubuntuの場合
sudo apt-get install php-curl

# macOS (Homebrew)
brew install php
```

### Q: APIトークンエラー

```php
// 正しいトークンを使用しているか確認
$client = new WeatherForecastClient('your_actual_token_here');
```

### Q: タイムアウトエラー

デフォルトのタイムアウトは30秒です。`WeatherForecastClient.php`の`CURLOPT_TIMEOUT`を編集して調整できます。

### Q: JSON_UNESCAPED_UNICODEが使えない

PHP 5.4以上が必要です。古いバージョンの場合は、この定数を削除してください。

## 🔒 セキュリティ

### APIトークンの保護

APIトークンをコードに直接書かず、環境変数や設定ファイルから読み込むことを推奨します。

```php
// .env ファイルから読み込む例
$apiToken = getenv('WEATHER_API_TOKEN');
$client = new WeatherForecastClient($apiToken);
```

### XSS対策

HTMLに出力する際は必ず`htmlspecialchars()`を使用してください。

```php
echo htmlspecialchars($forecast->latitude);
```

## 📞 サポート

詳細な使用例は `example.php` を参照してください。

```bash
php example.php
```
