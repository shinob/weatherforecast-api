// グローバル変数
let map;
let currentMarker;
let tempChart, rainChart, windChart;

// 天気アイコンを決定する関数
function getWeatherIcon(cloudCover, precipitation) {
    if (precipitation > 1.0) {
        return '🌧️'; // 雨
    } else if (precipitation > 0.1) {
        return '🌦️'; // 小雨
    } else if (cloudCover > 70) {
        return '☁️'; // 曇り
    } else if (cloudCover > 30) {
        return '⛅'; // 晴れ時々曇り
    } else {
        return '☀️'; // 晴れ
    }
}

// 風向を角度から方位に変換
function getWindDirection(degrees) {
    const directions = ['北', '北北東', '北東', '東北東', '東', '東南東', '南東', '南南東',
                       '南', '南南西', '南西', '西南西', '西', '西北西', '北西', '北北西'];
    const index = Math.round(degrees / 22.5) % 16;
    return directions[index];
}

// 日時をフォーマット
function formatDateTime(dateTimeStr) {
    const date = new Date(dateTimeStr);
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hours = date.getHours();
    return `${month}/${day} ${hours}:00`;
}

// 詳細な日時フォーマット
function formatDetailedDateTime(dateTimeStr) {
    const date = new Date(dateTimeStr);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}年${month}月${day}日 ${hours}:${minutes}`;
}

// GRIB2ファイル時刻をフォーマット
function formatGribTime(gribTimeStr) {
    // Format: YYYYMMDDhhmmss
    const year = gribTimeStr.substring(0, 4);
    const month = gribTimeStr.substring(4, 6);
    const day = gribTimeStr.substring(6, 8);
    const hour = gribTimeStr.substring(8, 10);
    const minute = gribTimeStr.substring(10, 12);
    return `${year}年${month}月${day}日 ${hour}:${minute}`;
}

// 地図を初期化
function initMap() {
    // 地図の作成
    map = L.map('map').setView(CONFIG.DEFAULT_MAP_CENTER, CONFIG.DEFAULT_ZOOM);

    // OpenStreetMapタイルレイヤーを追加
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 18,
    }).addTo(map);

    // 地図クリックイベント
    map.on('click', onMapClick);

    console.log('✅ 地図の初期化が完了しました');
}

// 地図クリック時の処理
function onMapClick(e) {
    const lat = e.latlng.lat.toFixed(7);
    const lng = e.latlng.lng.toFixed(7);

    console.log(`📍 クリック位置: ${lat}, ${lng}`);

    // マーカーを配置
    if (currentMarker) {
        map.removeLayer(currentMarker);
    }

    currentMarker = L.marker([lat, lng])
        .addTo(map)
        .bindPopup(`<b>選択地点</b><br>緯度: ${lat}<br>経度: ${lng}`)
        .openPopup();

    // 天気予報を取得
    fetchWeatherForecast(lat, lng);
}

// 天気予報を取得
async function fetchWeatherForecast(lat, lng) {
    showLoading();
    hideError();
    hideForecast();

    const url = `${CONFIG.API_BASE_URL}/${CONFIG.API_TOKEN}/${lat},${lng}`;

    try {
        console.log(`🌐 APIリクエスト: ${url}`);

        const response = await fetch(url);

        if (!response.ok) {
            const errorText = await response.text();
            console.error('レスポンスエラー:', errorText);
            throw new Error(`HTTPエラー: ${response.status} ${response.statusText}`);
        }

        const data = await response.json();

        if (data.error) {
            throw new Error(data.error);
        }

        if (data.code !== 200) {
            throw new Error(`APIエラー: コード ${data.code}`);
        }

        console.log('✅ 天気予報データを取得しました', data);

        // 24時間分のデータを抽出
        const forecast24h = data.result.forecast.slice(0, CONFIG.FORECAST_HOURS);

        // 予報を表示
        displayForecast(forecast24h, lat, lng, data.result.grib2file_time);

    } catch (error) {
        console.error('❌ エラー:', error);

        let errorMessage = '天気予報の取得に失敗しました';

        if (error.message.includes('Failed to fetch')) {
            errorMessage += ': サーバーに接続できません。プロキシサーバー（server-proxy.py）が起動しているか確認してください。';
        } else if (error.message.includes('NetworkError')) {
            errorMessage += ': ネットワークエラーが発生しました。インターネット接続を確認してください。';
        } else {
            errorMessage += ': ' + error.message;
        }

        showError(errorMessage);
    } finally {
        hideLoading();
    }
}

// 予報を表示
function displayForecast(forecastData, lat, lng, gribTime) {
    // ヘッダー情報を更新
    document.getElementById('location-title').textContent = '📍 選択地点の24時間予報';
    document.getElementById('coords-display').textContent = `緯度: ${lat}, 経度: ${lng}`;
    document.getElementById('grib-time').textContent = formatGribTime(gribTime);

    // グリッド表示
    const gridContainer = document.getElementById('forecast-grid');
    gridContainer.innerHTML = '';

    forecastData.forEach((item, index) => {
        const forecastItem = document.createElement('div');
        forecastItem.className = 'forecast-item';

        const icon = getWeatherIcon(item.TCDC, item.APCP);
        const windDir = getWindDirection(item.WDIR);

        forecastItem.innerHTML = `
            <div class="forecast-time">${formatDateTime(item.datetime)}</div>
            <div class="forecast-icon">${icon}</div>
            <div class="forecast-temp">${item.TMP.toFixed(1)}°C</div>
            <div class="forecast-details">
                <div><span class="detail-label">降水</span><span class="detail-value">${item.APCP.toFixed(1)}mm</span></div>
                <div><span class="detail-label">風速</span><span class="detail-value">${item.WSPD.toFixed(1)}m/s</span></div>
                <div><span class="detail-label">風向</span><span class="detail-value">${windDir}</span></div>
                <div><span class="detail-label">湿度</span><span class="detail-value">${item.RH.toFixed(0)}%</span></div>
                <div><span class="detail-label">雲量</span><span class="detail-value">${item.TCDC.toFixed(0)}%</span></div>
                <div><span class="detail-label">気圧</span><span class="detail-value">${item.PRES.toFixed(1)}hPa</span></div>
            </div>
        `;

        gridContainer.appendChild(forecastItem);
    });

    // グラフを描画
    drawCharts(forecastData);

    // 予報コンテナを表示
    showForecast();
}

// グラフを描画
function drawCharts(forecastData) {
    const labels = forecastData.map(item => formatDateTime(item.datetime));
    const temps = forecastData.map(item => item.TMP);
    const rains = forecastData.map(item => item.APCP);
    const winds = forecastData.map(item => item.WSPD);

    // 既存のグラフを破棄
    if (tempChart) tempChart.destroy();
    if (rainChart) rainChart.destroy();
    if (windChart) windChart.destroy();

    // 気温グラフ
    const tempCtx = document.getElementById('temp-chart').getContext('2d');
    tempChart = new Chart(tempCtx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: '気温 (°C)',
                data: temps,
                borderColor: 'rgb(255, 99, 132)',
                backgroundColor: 'rgba(255, 99, 132, 0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: false,
                    ticks: {
                        callback: function(value) {
                            return value + '°C';
                        }
                    }
                }
            }
        }
    });

    // 降水量グラフ
    const rainCtx = document.getElementById('rain-chart').getContext('2d');
    rainChart = new Chart(rainCtx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: '降水量 (mm)',
                data: rains,
                backgroundColor: 'rgba(54, 162, 235, 0.6)',
                borderColor: 'rgb(54, 162, 235)',
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return value + 'mm';
                        }
                    }
                }
            }
        }
    });

    // 風速グラフ
    const windCtx = document.getElementById('wind-chart').getContext('2d');
    windChart = new Chart(windCtx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: '風速 (m/s)',
                data: winds,
                borderColor: 'rgb(75, 192, 192)',
                backgroundColor: 'rgba(75, 192, 192, 0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return value + 'm/s';
                        }
                    }
                }
            }
        }
    });
}

// UI制御関数
function showLoading() {
    document.getElementById('loading').classList.remove('hidden');
}

function hideLoading() {
    document.getElementById('loading').classList.add('hidden');
}

function showError(message) {
    const errorEl = document.getElementById('error-message');
    errorEl.textContent = '❌ ' + message;
    errorEl.classList.remove('hidden');
}

function hideError() {
    document.getElementById('error-message').classList.add('hidden');
}

function showForecast() {
    document.getElementById('welcome-message').classList.add('hidden');
    document.getElementById('forecast-container').classList.remove('hidden');
}

function hideForecast() {
    document.getElementById('forecast-container').classList.add('hidden');
}

// アプリケーション初期化
document.addEventListener('DOMContentLoaded', () => {
    console.log('🚀 アプリケーションを起動しています...');
    initMap();
    console.log('✅ アプリケーションの準備が完了しました');
});
