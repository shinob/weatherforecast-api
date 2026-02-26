#!/usr/bin/env python3
"""
IPv6対応のシンプルなHTTPサーバー

使い方:
    python3 server-ipv6.py [port]

デフォルトポート: 8000

アクセス方法:
    - ローカル: http://[::1]:8000
    - リンクローカル: http://[fe80::1234:5678:9abc:def0%eth0]:8000
    - グローバル: http://[2001:db8::1]:8000
"""

import http.server
import socketserver
import sys
import socket

# ポート番号の取得
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000

class IPv6HTTPServer(socketserver.TCPServer):
    """IPv6対応のHTTPサーバー"""
    address_family = socket.AF_INET6
    allow_reuse_address = True

Handler = http.server.SimpleHTTPRequestHandler

try:
    with IPv6HTTPServer(("", PORT), Handler) as httpd:
        # サーバー情報を表示
        print("=" * 60)
        print("IPv6対応 HTTPサーバーを起動しました")
        print("=" * 60)
        print("\nポート: {}".format(PORT))
        print("\nアクセス方法:")
        print("  - ローカル (IPv6):     http://[::1]:{}".format(PORT))
        print("  - ローカル (IPv4):     http://127.0.0.1:{}".format(PORT))
        print("  - ローカル (hostname): http://localhost:{}".format(PORT))

        # システムのIPv6アドレスを取得して表示
        try:
            import subprocess
            result = subprocess.run(['ip', '-6', 'addr', 'show'],
                                  capture_output=True, text=True)
            if result.returncode == 0:
                lines = result.stdout.split('\n')
                global_addrs = []
                link_local_addrs = []

                for line in lines:
                    if 'inet6' in line:
                        parts = line.strip().split()
                        if len(parts) >= 2:
                            addr = parts[1].split('/')[0]
                            if 'scope global' in line:
                                global_addrs.append(addr)
                            elif 'scope link' in line and not addr.startswith('fe80:'):
                                link_local_addrs.append(addr)

                if global_addrs:
                    print("\n  - グローバルIPv6:")
                    for addr in global_addrs:
                        print("    http://[{}]:{}".format(addr, PORT))

        except Exception as e:
            print("\n  (IPv6アドレスの自動取得に失敗: {})".format(e))

        print("\n終了するには Ctrl+C を押してください")
        print("=" * 60)
        print()

        httpd.serve_forever()

except KeyboardInterrupt:
    print("\n\nサーバーを停止しました")
except OSError as e:
    if e.errno == 98:
        print("\nエラー: ポート {} は既に使用されています".format(PORT))
        print("別のポート番号を指定してください:")
        print("  python3 server-ipv6.py 8080")
    else:
        print("\nエラー: {}".format(e))
    sys.exit(1)
