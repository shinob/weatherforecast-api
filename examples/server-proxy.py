#!/usr/bin/env python3
"""
CORS対応のプロキシサーバー

天気予報APIへのリクエストをプロキシして、CORS問題を解決します。
"""

import http.server
import socketserver
import socket
import urllib.request
import urllib.error
import json
import sys
from urllib.parse import urlparse, parse_qs

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000

class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    """CORS対応のプロキシハンドラー"""

    def end_headers(self):
        """CORSヘッダーを追加"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

    def do_OPTIONS(self):
        """プリフライトリクエストに対応"""
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        """GETリクエストの処理"""

        # プロキシAPIパスの場合
        if self.path.startswith('/api/weather/'):
            self.handle_weather_api()
        else:
            # 通常のファイル配信
            super().do_GET()

    def handle_weather_api(self):
        """天気予報APIへのプロキシリクエスト"""
        try:
            # パスから緯度経度を抽出
            # /api/weather/{token}/{lat},{lng}
            path_parts = self.path.split('/')
            if len(path_parts) < 5:
                self.send_error(400, "Invalid API path")
                return

            token = path_parts[3]
            coords = path_parts[4]

            # 天気予報APIにリクエスト
            api_url = "https://weather.ittools.biz/api/forecast/GSM/{}/{}".format(token, coords)

            print("📡 プロキシリクエスト: {}".format(api_url))

            req = urllib.request.Request(
                api_url,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Weather Forecast App)',
                    'Accept': 'application/json'
                }
            )

            with urllib.request.urlopen(req, timeout=30) as response:
                data = response.read()

                # レスポンスを返す
                self.send_response(200)
                self.send_header('Content-Type', 'application/json; charset=utf-8')
                self.end_headers()
                self.wfile.write(data)

                print("✅ プロキシ成功: {} bytes".format(len(data)))

        except urllib.error.HTTPError as e:
            print("❌ HTTPエラー: {} {}".format(e.code, e.reason))
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_data = json.dumps({
                'error': 'API Error: {} {}'.format(e.code, e.reason)
            }).encode()
            self.wfile.write(error_data)

        except urllib.error.URLError as e:
            print("❌ URLエラー: {}".format(e.reason))
            self.send_response(502)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_data = json.dumps({
                'error': 'Connection Error: {}'.format(e.reason)
            }).encode()
            self.wfile.write(error_data)

        except Exception as e:
            print("❌ エラー: {}".format(e))
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_data = json.dumps({
                'error': 'Server Error: {}'.format(str(e))
            }).encode()
            self.wfile.write(error_data)

    def log_message(self, format, *args):
        """ログメッセージのカスタマイズ"""
        if not self.path.startswith('/api/weather/'):
            # API以外のリクエストは簡潔に
            return
        super().log_message(format, *args)


class IPv6TCPServer(socketserver.TCPServer):
    """IPv6対応のTCPサーバー"""
    address_family = socket.AF_INET6
    allow_reuse_address = True


httpd = None
try:
    httpd = IPv6TCPServer(("", PORT), ProxyHandler)
    print("=" * 70)
    print("CORS対応プロキシサーバーを起動しました")
    print("=" * 70)
    print("\nポート: {}".format(PORT))
    print("\nアクセス方法:")
    print("  - http://localhost:{}".format(PORT))
    print("  - http://127.0.0.1:{}".format(PORT))
    print("  - http://[::1]:{}".format(PORT))

    # システムのIPv6アドレスを取得
    try:
        import subprocess
        result = subprocess.run(['ip', '-6', 'addr', 'show', 'scope', 'global'],
                              capture_output=True, text=True)
        if result.returncode == 0:
            lines = result.stdout.split('\n')
            for line in lines:
                if 'inet6' in line:
                    parts = line.strip().split()
                    if len(parts) >= 2:
                        addr = parts[1].split('/')[0]
                        print("  - http://[{}]:{}".format(addr, PORT))
    except:
        pass

    print("\n機能:")
    print("  ✓ 天気予報APIへのプロキシ")
    print("  ✓ CORS問題の自動解決")
    print("  ✓ IPv4/IPv6 両対応")
    print("\nAPIエンドポイント:")
    print("  /api/weather/{token}/{lat},{lng}")
    print("\n終了するには Ctrl+C を押してください")
    print("=" * 70)
    print()

    httpd.serve_forever()

except KeyboardInterrupt:
    print("\n\nサーバーを停止しました")
except OSError as e:
    if e.errno == 98:
        print("\nエラー: ポート {} は既に使用されています".format(PORT))
        print("別のポート番号を指定してください:")
        print("  python3 server-proxy.py 8080")
    else:
        print("\nエラー: {}".format(e))
    sys.exit(1)
finally:
    if httpd:
        httpd.server_close()
