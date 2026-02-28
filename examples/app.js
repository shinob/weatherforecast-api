// グローバル変数
let map;
let currentMarker;
let tempChart, rainChart, windChart;

let selectedLocation = null;
let latestForecastData = [];
let latestGribTime = '';
let selectedHours = CONFIG.FORECAST_HOURS;

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
    }

    return '☀️'; // 晴れ
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

// GRIB2ファイル時刻をフォーマット
function formatGribTime(gribTimeStr) {
    if (!gribTimeStr || gribTimeStr.length < 12) {
        return '-';
    }

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
    map = L.map('map').setView(CONFIG.DEFAULT_MAP_CENTER, CONFIG.DEFAULT_ZOOM);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 18,
    }).addTo(map);

    map.on('click', onMapClick);

    console.log('✅ 地図の初期化が完了しました');
}

function initControls() {
    const refreshBtn = document.getElementById('refresh-btn');
    const useLocationBtn = document.getElementById('use-location-btn');
    const hoursSelect = document.getElementById('hours-select');
    const downloadCsvBtn = document.getElementById('download-csv-btn');

    useLocationBtn.addEventListener('click', useCurrentLocation);

    refreshBtn.addEventListener('click', () => {
        if (!selectedLocation) {
            return;
        }
        fetchWeatherForecast(selectedLocation.lat, selectedLocation.lng);
    });

    hoursSelect.value = String(CONFIG.FORECAST_HOURS);
    hoursSelect.addEventListener('change', (e) => {
        selectedHours = Number.parseInt(e.target.value, 10);
        if (latestForecastData.length > 0) {
            renderCurrentForecast();
        }
    });

    downloadCsvBtn.addEventListener('click', downloadForecastCsv);
}

// 地図クリック時の処理
function onMapClick(e) {
    const lat = Number(e.latlng.lat.toFixed(7));
    const lng = Number(e.latlng.lng.toFixed(7));

    console.log(`📍 クリック位置: ${lat}, ${lng}`);
    selectLocation(lat, lng);
    fetchWeatherForecast(lat, lng);
}

function selectLocation(lat, lng) {
    const fixedLat = Number(lat.toFixed(7));
    const fixedLng = Number(lng.toFixed(7));
    selectedLocation = { lat: fixedLat, lng: fixedLng };

    if (currentMarker) {
        map.removeLayer(currentMarker);
    }

    currentMarker = L.marker([fixedLat, fixedLng])
        .addTo(map)
        .bindPopup(`<b>選択地点</b><br>緯度: ${fixedLat}<br>経度: ${fixedLng}`)
        .openPopup();

    document.getElementById('refresh-btn').disabled = false;
}

function useCurrentLocation() {
    if (!navigator.geolocation) {
        showError('このブラウザでは位置情報取得がサポートされていません。');
        return;
    }

    hideError();
    showLoading();

    navigator.geolocation.getCurrentPosition(
        (position) => {
            const lat = Number(position.coords.latitude.toFixed(7));
            const lng = Number(position.coords.longitude.toFixed(7));

            map.setView([lat, lng], 10);
            selectLocation(lat, lng);
            fetchWeatherForecast(lat, lng);
        },
        (error) => {
            hideLoading();
            let message = '現在地を取得できませんでした。';

            if (error.code === error.PERMISSION_DENIED) {
                message += ' ブラウザで位置情報の利用を許可してください。';
            } else if (error.code === error.POSITION_UNAVAILABLE) {
                message += ' 位置情報を取得できる環境か確認してください。';
            } else if (error.code === error.TIMEOUT) {
                message += ' タイムアウトしました。再度お試しください。';
            }

            showError(message);
        },
        {
            enableHighAccuracy: false,
            timeout: 10000,
            maximumAge: 600000,
        }
    );
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

        if (!data.result || !Array.isArray(data.result.forecast) || data.result.forecast.length === 0) {
            throw new Error('予報データが空です。');
        }

        console.log('✅ 天気予報データを取得しました', data);

        latestForecastData = data.result.forecast;
        latestGribTime = data.result.grib2file_time;

        renderCurrentForecast();

    } catch (error) {
        console.error('❌ エラー:', error);

        let errorMessage = '天気予報の取得に失敗しました';

        if (error.message.includes('Failed to fetch')) {
            errorMessage += ': サーバーに接続できません。プロキシサーバー（server-proxy.py）が起動しているか確認してください。';
        } else if (error.message.includes('NetworkError')) {
            errorMessage += ': ネットワークエラーが発生しました。インターネット接続を確認してください。';
        } else {
            errorMessage += `: ${error.message}`;
        }

        showError(errorMessage);
    } finally {
        hideLoading();
    }
}

function renderCurrentForecast() {
    if (!selectedLocation || latestForecastData.length === 0) {
        return;
    }

    const dataToShow = latestForecastData.slice(0, selectedHours);
    displayForecast(dataToShow, selectedLocation.lat, selectedLocation.lng, latestGribTime);
}

// 予報を表示
function displayForecast(forecastData, lat, lng, gribTime) {
    const roundedLat = Number(lat).toFixed(7);
    const roundedLng = Number(lng).toFixed(7);

    document.getElementById('location-title').textContent = `📍 選択地点の${selectedHours}時間予報`;
    document.getElementById('coords-display').textContent = `緯度: ${roundedLat}, 経度: ${roundedLng}`;
    document.getElementById('grib-time').textContent = formatGribTime(gribTime);

    const gridContainer = document.getElementById('forecast-grid');
    gridContainer.innerHTML = '';

    forecastData.forEach((item) => {
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

    renderSummary(forecastData);
    drawCharts(forecastData);

    document.getElementById('download-csv-btn').disabled = false;

    showForecast();
}

function renderSummary(forecastData) {
    const summaryEl = document.getElementById('forecast-summary');

    if (!forecastData.length) {
        summaryEl.innerHTML = '';
        return;
    }

    const minTemp = Math.min(...forecastData.map((item) => item.TMP));
    const maxTemp = Math.max(...forecastData.map((item) => item.TMP));
    const avgHumidity = forecastData.reduce((sum, item) => sum + item.RH, 0) / forecastData.length;
    const totalRain = forecastData.reduce((sum, item) => sum + item.APCP, 0);
    const maxWind = Math.max(...forecastData.map((item) => item.WSPD));

    summaryEl.innerHTML = `
        <div class="summary-card"><span class="summary-label">最低気温</span><span class="summary-value">${minTemp.toFixed(1)}°C</span></div>
        <div class="summary-card"><span class="summary-label">最高気温</span><span class="summary-value">${maxTemp.toFixed(1)}°C</span></div>
        <div class="summary-card"><span class="summary-label">平均湿度</span><span class="summary-value">${avgHumidity.toFixed(0)}%</span></div>
        <div class="summary-card"><span class="summary-label">累積降水量</span><span class="summary-value">${totalRain.toFixed(1)}mm</span></div>
        <div class="summary-card"><span class="summary-label">最大風速</span><span class="summary-value">${maxWind.toFixed(1)}m/s</span></div>
    `;
}

function downloadForecastCsv() {
    if (!selectedLocation || latestForecastData.length === 0) {
        showError('ダウンロードできる予報データがありません。');
        return;
    }

    const rows = latestForecastData.slice(0, selectedHours);
    const headers = ['datetime', 'TMP_C', 'APCP_mm', 'WSPD_mps', 'WDIR_deg', 'RH_percent', 'TCDC_percent', 'PRES_hPa'];

    const csvRows = [headers.join(',')];

    rows.forEach((item) => {
        csvRows.push([
            item.datetime,
            item.TMP,
            item.APCP,
            item.WSPD,
            item.WDIR,
            item.RH,
            item.TCDC,
            item.PRES,
        ].join(','));
    });

    const blob = new Blob([csvRows.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    const fileLat = selectedLocation.lat.toFixed(3);
    const fileLng = selectedLocation.lng.toFixed(3);
    link.setAttribute('href', url);
    link.setAttribute('download', `forecast_${fileLat}_${fileLng}_${selectedHours}h.csv`);

    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
}

// グラフを描画
function drawCharts(forecastData) {
    const labels = forecastData.map(item => formatDateTime(item.datetime));
    const temps = forecastData.map(item => item.TMP);
    const rains = forecastData.map(item => item.APCP);
    const winds = forecastData.map(item => item.WSPD);

    if (tempChart) tempChart.destroy();
    if (rainChart) rainChart.destroy();
    if (windChart) windChart.destroy();

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
    initControls();
    console.log('✅ アプリケーションの準備が完了しました');
});
