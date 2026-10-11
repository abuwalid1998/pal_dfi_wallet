import http.server
import socketserver
import os
import sys
import threading

DIRECTORY = os.path.join(os.path.dirname(__file__), 'build', 'web')

class NoCacheSPARequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Force aggressive anti-cache headers on every single request
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

    def do_GET(self):
        # Translate path to disk path
        path_without_query = self.path.split('?')[0]
        local_path = os.path.join(DIRECTORY, path_without_query.lstrip('/'))

        # If file does not exist, fall back to index.html (SPA routing support)
        if not os.path.exists(local_path) and not os.path.isfile(local_path):
            self.path = '/index.html'

        return super().do_GET()

def start_server(port):
    try:
        class DualStackServer(socketserver.ThreadingTCPServer):
            allow_reuse_address = True

        with DualStackServer(('0.0.0.0', port), NoCacheSPARequestHandler) as httpd:
            print(f'Serving PAL-DFI Web on http://localhost:{port} (Anti-Cache Enabled, SPA fallback)')
            httpd.serve_forever()
    except Exception as e:
        print(f'Warning: could not bind port {port}: {e}')

if __name__ == '__main__':
    ports = [8088, 8080]
    threads = []
    for p in ports:
        t = threading.Thread(target=start_server, args=(p,), daemon=True)
        t.start()
        threads.append(t)

    print("Servers running on ports 8088 and 8080. Press Ctrl+C to stop.")
    for t in threads:
        t.join()
