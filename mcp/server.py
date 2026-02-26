#!/usr/bin/env python3
"""
Weather Forecast MCP Server

MCPサーバーとして動作し、天気予報APIへのアクセスを提供します。
"""

import os
import sys
import logging
from typing import Any, Optional
import json

# 親ディレクトリのclientsモジュールをインポートできるようにパスを追加
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from mcp.server import Server
from mcp.types import Tool, TextContent, ImageContent, EmbeddedResource
import mcp.server.stdio

from clients.python.weather_forecast_client import (
    WeatherForecastClient,
    WeatherAPIError,
    ForecastItem,
    Forecast
)
from city_coordinates import get_city_coordinates, get_available_cities, search_city

# ログ設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.path.expanduser('~/.weather-mcp.log')),
        logging.StreamHandler(sys.stderr)
    ]
)
logger = logging.getLogger('weather-mcp')

# MCPサーバーインスタンス
app = Server("weather-forecast-mcp")

# APIトークンを環境変数から取得
API_TOKEN = os.getenv('WEATHER_API_TOKEN', 'api_sample')
if API_TOKEN == 'api_sample':
    logger.warning('⚠️ サンプルトークンを使用しています。環境変数 WEATHER_API_TOKEN を設定してください。')

# Weather APIクライアント
weather_client = WeatherForecastClient(API_TOKEN)


def format_forecast_summary(forecast: Forecast, city_name: Optional[str] = None) -> str:
    """
    天気予報を人間が読みやすい形式にフォーマット

    Args:
        forecast: Forecast オブジェクト
        city_name: 都市名（オプション）

    Returns:
        フォーマットされた予報文字列
    """
    lines = []

    # ヘッダー
    if city_name:
        lines.append(f"# {city_name}の天気予報")
    else:
        lines.append("# 天気予報")

    lines.append(f"📍 位置: 緯度 {forecast.latitude:.4f}, 経度 {forecast.longitude:.4f}")
    lines.append(f"📅 データ生成時刻: {forecast.grib2file_time}")
    lines.append(f"⏰ 予報時間数: {len(forecast)}時間\n")

    # サマリー統計
    temps = [item.temperature for item in forecast]
    precips = [item.precipitation for item in forecast]
    rainy_hours = len([p for p in precips if p > 0.1])

    lines.append("## 概要")
    lines.append(f"🌡️ 最高気温: {max(temps):.1f}°C")
    lines.append(f"🌡️ 最低気温: {min(temps):.1f}°C")
    lines.append(f"💧 総降水量: {sum(precips):.1f}mm")
    lines.append(f"🌧️ 降水時間: {rainy_hours}時間\n")

    # 最初の24時間の詳細（または全データが24時間未満の場合は全て）
    display_hours = min(24, len(forecast))
    lines.append(f"## {display_hours}時間予報\n")

    for i, item in enumerate(forecast.data[:display_hours]):
        icon = item.weather_icon()
        wind_dir = item.wind_direction_compass()

        line = (
            f"{item.datetime} {icon} "
            f"気温:{item.temperature:.1f}°C "
            f"降水:{item.precipitation:.1f}mm "
            f"風速:{item.wind_speed:.1f}m/s({wind_dir}) "
            f"湿度:{item.humidity:.0f}% "
            f"雲量:{item.cloud_cover:.0f}% "
            f"気圧:{item.pressure:.1f}hPa"
        )
        lines.append(line)

    return "\n".join(lines)


def format_forecast_json(forecast: Forecast, city_name: Optional[str] = None) -> dict[str, Any]:
    """
    天気予報をJSON形式にフォーマット

    Args:
        forecast: Forecast オブジェクト
        city_name: 都市名（オプション）

    Returns:
        JSON形式の予報データ
    """
    temps = [item.temperature for item in forecast]
    precips = [item.precipitation for item in forecast]
    rainy_hours = len([p for p in precips if p > 0.1])

    result = {
        "location": {
            "latitude": forecast.latitude,
            "longitude": forecast.longitude,
        },
        "data_time": forecast.grib2file_time,
        "forecast": [item.to_dict() for item in forecast.data],
        "summary": {
            "max_temp": max(temps),
            "min_temp": min(temps),
            "total_precipitation": sum(precips),
            "rainy_hours": rainy_hours,
            "forecast_hours": len(forecast)
        }
    }

    if city_name:
        result["location"]["city"] = city_name

    return result


@app.list_tools()
async def list_tools() -> list[Tool]:
    """
    利用可能なツールのリストを返す
    """
    return [
        Tool(
            name="get_weather_forecast",
            description=(
                "指定した緯度経度の天気予報を取得します。"
                "1時間ごとの詳細な気象情報（気温、降水量、風速、風向、湿度、雲量、気圧）を提供します。"
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "latitude": {
                        "type": "number",
                        "description": "緯度（-90 〜 90の範囲）。例: 35.6762（東京）",
                        "minimum": -90,
                        "maximum": 90
                    },
                    "longitude": {
                        "type": "number",
                        "description": "経度（-180 〜 180の範囲）。例: 139.6503（東京）",
                        "minimum": -180,
                        "maximum": 180
                    },
                    "hours": {
                        "type": "integer",
                        "description": "予報時間数（デフォルト: 24、最大: 172）",
                        "default": 24,
                        "minimum": 1,
                        "maximum": 172
                    },
                    "format": {
                        "type": "string",
                        "description": "出力形式（'text' または 'json'、デフォルト: 'text'）",
                        "enum": ["text", "json"],
                        "default": "text"
                    }
                },
                "required": ["latitude", "longitude"]
            }
        ),
        Tool(
            name="get_weather_by_city",
            description=(
                "日本の主要都市名から天気予報を取得します。"
                "都道府県庁所在地、主要都市、観光地など70以上の都市に対応しています。"
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "city": {
                        "type": "string",
                        "description": "都市名（例: '東京', '大阪', '札幌', 'Tokyo'）。利用可能な都市を確認するには list_available_cities ツールを使用してください。"
                    },
                    "hours": {
                        "type": "integer",
                        "description": "予報時間数（デフォルト: 24、最大: 172）",
                        "default": 24,
                        "minimum": 1,
                        "maximum": 172
                    },
                    "format": {
                        "type": "string",
                        "description": "出力形式（'text' または 'json'、デフォルト: 'text'）",
                        "enum": ["text", "json"],
                        "default": "text"
                    }
                },
                "required": ["city"]
            }
        ),
        Tool(
            name="list_available_cities",
            description=(
                "利用可能な都市の一覧を取得します。"
                "get_weather_by_city ツールで使用できる都市名を確認できます。"
            ),
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="search_cities",
            description=(
                "都市名を部分一致で検索します。"
                "都市名が不明確な場合に使用してください。"
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "検索クエリ（部分一致）。例: '京'で検索すると '東京', '京都' などがヒットします。"
                    }
                },
                "required": ["query"]
            }
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """
    ツールを実行
    """
    try:
        logger.info(f"Tool called: {name} with arguments: {arguments}")

        if name == "get_weather_forecast":
            return await handle_get_weather_forecast(arguments)

        elif name == "get_weather_by_city":
            return await handle_get_weather_by_city(arguments)

        elif name == "list_available_cities":
            return await handle_list_available_cities()

        elif name == "search_cities":
            return await handle_search_cities(arguments)

        else:
            logger.error(f"Unknown tool: {name}")
            return [TextContent(type="text", text=f"エラー: 不明なツール '{name}'")]

    except Exception as e:
        logger.exception(f"Error in tool {name}: {e}")
        return [TextContent(type="text", text=f"エラーが発生しました: {str(e)}")]


async def handle_get_weather_forecast(arguments: dict[str, Any]) -> list[TextContent]:
    """
    緯度経度から天気予報を取得
    """
    latitude = arguments["latitude"]
    longitude = arguments["longitude"]
    hours = arguments.get("hours", 24)
    output_format = arguments.get("format", "text")

    try:
        logger.info(f"Fetching forecast for lat={latitude}, lng={longitude}, hours={hours}")

        forecast = weather_client.get_forecast(latitude, longitude, hours)

        if output_format == "json":
            result = format_forecast_json(forecast)
            text = json.dumps(result, ensure_ascii=False, indent=2)
        else:
            text = format_forecast_summary(forecast)

        logger.info(f"Forecast retrieved successfully: {len(forecast)} hours")
        return [TextContent(type="text", text=text)]

    except WeatherAPIError as e:
        logger.error(f"Weather API error: {e}")
        return [TextContent(type="text", text=f"天気予報APIエラー: {str(e)}")]
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return [TextContent(type="text", text=f"予期しないエラー: {str(e)}")]


async def handle_get_weather_by_city(arguments: dict[str, Any]) -> list[TextContent]:
    """
    都市名から天気予報を取得
    """
    city = arguments["city"]
    hours = arguments.get("hours", 24)
    output_format = arguments.get("format", "text")

    # 都市の座標を取得
    coords = get_city_coordinates(city)
    if coords is None:
        # 部分一致で検索してサジェスト
        suggestions = search_city(city)
        if suggestions:
            suggestion_text = "、".join(suggestions[:5])
            return [TextContent(
                type="text",
                text=f"都市 '{city}' が見つかりませんでした。\n\n類似する都市: {suggestion_text}\n\n利用可能な都市の完全なリストを取得するには list_available_cities ツールを使用してください。"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"都市 '{city}' が見つかりませんでした。\n\n利用可能な都市のリストを取得するには list_available_cities ツールを使用してください。"
            )]

    latitude, longitude = coords

    try:
        logger.info(f"Fetching forecast for city={city}, lat={latitude}, lng={longitude}, hours={hours}")

        forecast = weather_client.get_forecast(latitude, longitude, hours)

        if output_format == "json":
            result = format_forecast_json(forecast, city)
            text = json.dumps(result, ensure_ascii=False, indent=2)
        else:
            text = format_forecast_summary(forecast, city)

        logger.info(f"Forecast retrieved successfully for {city}: {len(forecast)} hours")
        return [TextContent(type="text", text=text)]

    except WeatherAPIError as e:
        logger.error(f"Weather API error for {city}: {e}")
        return [TextContent(type="text", text=f"天気予報APIエラー: {str(e)}")]
    except Exception as e:
        logger.exception(f"Unexpected error for {city}: {e}")
        return [TextContent(type="text", text=f"予期しないエラー: {str(e)}")]


async def handle_list_available_cities() -> list[TextContent]:
    """
    利用可能な都市のリストを取得
    """
    cities = get_available_cities()
    text = f"# 利用可能な都市 ({len(cities)}件)\n\n"
    text += "、".join(cities)

    logger.info(f"Listed {len(cities)} available cities")
    return [TextContent(type="text", text=text)]


async def handle_search_cities(arguments: dict[str, Any]) -> list[TextContent]:
    """
    都市を検索
    """
    query = arguments["query"]
    results = search_city(query)

    if results:
        text = f"# '{query}' の検索結果 ({len(results)}件)\n\n"
        text += "、".join(results)
    else:
        text = f"'{query}' に一致する都市が見つかりませんでした。"

    logger.info(f"City search for '{query}': {len(results)} results")
    return [TextContent(type="text", text=text)]


async def main():
    """
    MCPサーバーを起動
    """
    logger.info("Weather Forecast MCP Server starting...")
    logger.info(f"API Token: {'***' if API_TOKEN != 'api_sample' else 'api_sample (warning: using sample token)'}")

    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        logger.info("Server initialized, waiting for requests...")
        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
