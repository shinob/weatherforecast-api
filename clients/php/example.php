#!/usr/bin/env php
<?php
/**
 * 使用例: WeatherForecast API Client for PHP
 */

require_once __DIR__ . '/WeatherForecastClient.php';

// 使用例
$apiToken = 'api_sample';  // あなたのAPIトークンに置き換えてください

// クライアントを初期化
$client = new WeatherForecastClient($apiToken);

try {
    // 東京の天気予報を取得（24時間分）
    echo "東京の24時間天気予報を取得中...\n";
    $forecast = $client->getForecast(35.6762, 139.6503, 24);

    echo "\n📍 位置: {$forecast->latitude}, {$forecast->longitude}\n";
    echo "📅 基準時刻: {$forecast->grib2fileTime}\n";
    echo "⏱️  予報時間数: " . count($forecast) . "時間\n\n";

    // 最初の3時間の詳細を表示
    echo "【最初の3時間の詳細】\n";
    foreach (array_slice($forecast->data, 0, 3) as $i => $item) {
        echo "\n--- {$i}時間後 ({$item->datetime}) ---\n";
        echo $item->getWeatherIcon() . " 天気アイコン\n";
        echo "🌡️  気温: " . round($item->temperature, 1) . "°C\n";
        echo "💧 降水量: " . round($item->precipitation, 1) . "mm\n";
        echo "💨 風速: " . round($item->windSpeed, 1) . "m/s ({$item->getWindDirectionCompass()})\n";
        echo "💦 湿度: " . round($item->humidity, 0) . "%\n";
        echo "☁️  雲量: " . round($item->cloudCover, 0) . "%\n";
        echo "🎚️  気圧: " . round($item->pressure, 1) . "hPa\n";
    }

    // 24時間の気温推移を表示
    echo "\n\n【24時間の気温推移】\n";
    $i = 0;
    foreach ($forecast as $item) {
        $temp = $item->temperature;
        $bar = str_repeat('█', (int)($temp / 2));
        printf("%2d時間後: %5.1f°C %s\n", $i, $temp, $bar);
        $i++;
    }

    // 特定の時間の気温を取得
    echo "\n\n【簡単なアクセス方法】\n";
    printf("3時間後の気温: %.1f°C\n", $forecast->temperatureAt(3));
    printf("6時間後の降水量: %.1fmm\n", $forecast->precipitationAt(6));

    // 配列アクセス
    echo "\n【配列アクセス】\n";
    $first = $forecast->at(0);
    printf("最初の予報: %s - %.1f°C\n", $first->datetime, $first->temperature);

    // 平均気温計算
    echo "\n【平均気温計算】\n";
    $totalTemp = 0;
    foreach ($forecast as $item) {
        $totalTemp += $item->temperature;
    }
    $avgTemp = $totalTemp / count($forecast);
    printf("24時間平均気温: %.1f°C\n", $avgTemp);

} catch (WeatherAPIException $e) {
    echo "❌ エラー: {$e->getMessage()}\n";
}
