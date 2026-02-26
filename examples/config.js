// 天気予報API設定

const CONFIG = {
    // APIトークンをここに設定してください
    // 例: API_TOKEN: 'your_api_token_here'
    API_TOKEN: 'api_sample',  // デフォルトはサンプルトークン。本番環境では必ず変更してください

    // APIベースURL
    // プロキシサーバー経由でアクセス（CORS問題を回避）
    API_BASE_URL: '/api/weather',

    // 直接APIにアクセスする場合は以下を使用（CORS問題が発生する可能性あり）
    // API_BASE_URL: 'https://weather.ittools.biz/api/forecast/GSM',

    // デフォルトの地図中心位置（日本列島の中心付近）
    DEFAULT_MAP_CENTER: [36.5, 138.0],

    // デフォルトの地図ズームレベル
    DEFAULT_ZOOM: 6,

    // 24時間予報のデータ数（1時間ごと）
    FORECAST_HOURS: 24
};

// APIトークンの検証
if (CONFIG.API_TOKEN === 'api_sample') {
    console.warn('⚠️ サンプルトークンを使用しています。本番環境では config.js の API_TOKEN を変更してください。');
}
