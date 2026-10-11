"""
PAL-DFI API Gateway & Edge Reverse Proxy
Port: 8000
Unified Ingress for PAL-DFI Mobile Wallet and Web Portals.
Routes incoming traffic to autonomous downstream microservices:
  - /api/v1/auth/*        -> Auth Service (Port 8001)
  - /api/v1/biometrics/*  -> Biometrics Service (Port 8002)
  - /api/v1/credentials/* -> Credential Service (Port 8003)
  - /api/v1/zkp/*         -> ZKP Service (Port 8004)
  - /api/v1/fabric/*      -> Fabric Gateway (Port 8005)
  - /api/v1/audit/*       -> Audit Service (Port 8006)
  - /api/v1/health        -> Aggregated Cluster Health Check
  - /*                    -> Static Web Client Simulator Assets
"""

import http.server
import json
import os
import socketserver
import sys
import time
import urllib.parse
import urllib.request
import urllib.error
import secrets

if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

PORT = int(os.environ.get("GATEWAY_PORT", 8000))

# Route table mapping URL path prefix to upstream microservice base URL
ROUTE_TABLE = {
    "/api/v1/auth": os.environ.get("AUTH_SERVICE_URL", "http://localhost:8001"),
    "/api/v1/biometrics": os.environ.get("BIOMETRICS_SERVICE_URL", "http://localhost:8002"),
    "/api/v1/credentials": os.environ.get("CREDENTIAL_SERVICE_URL", "http://localhost:8003"),
    "/api/v1/zkp": os.environ.get("ZKP_SERVICE_URL", "http://localhost:8004"),
    "/api/v1/fabric": os.environ.get("FABRIC_GATEWAY_URL", "http://localhost:8005"),
    "/api/v1/audit": os.environ.get("AUDIT_SERVICE_URL", "http://localhost:8006"),
}

SERVICES_REGISTRY = {
    "auth": {"name": "paldfi-auth-service", "port": 8001, "url": "http://localhost:8001/health"},
    "biometrics": {"name": "paldfi-biometrics-service", "port": 8002, "url": "http://localhost:8002/health"},
    "credentials": {"name": "paldfi-credential-service", "port": 8003, "url": "http://localhost:8003/health"},
    "zkp": {"name": "paldfi-zkp-service", "port": 8004, "url": "http://localhost:8004/health"},
    "fabric": {"name": "paldfi-fabric-gateway", "port": 8005, "url": "http://localhost:8005/health"},
    "audit": {"name": "paldfi-audit-service", "port": 8006, "url": "http://localhost:8006/health"}
}

STATIC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

MIME_TYPES = {
    ".html": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".js": "application/javascript; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".svg": "image/svg+xml",
    ".ico": "image/x-icon"
}

class ApiGatewayHandler(http.server.BaseHTTPRequestHandler):
    def send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Trace-ID, X-Requested-With")

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_cors_headers()
        self.end_headers()

    def respond_json(self, status: int, data: dict, extra_headers: dict = None):
        body = json.dumps(data, indent=2, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_cors_headers()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        if extra_headers:
            for k, v in extra_headers.items():
                self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def proxy_request(self, upstream_url: str, trace_id: str):
        length = int(self.headers.get("Content-Length", 0))
        body_bytes = self.rfile.read(length) if length > 0 else None

        headers = {
            "Content-Type": self.headers.get("Content-Type", "application/json"),
            "X-Trace-ID": trace_id
        }
        if "Authorization" in self.headers:
            headers["Authorization"] = self.headers["Authorization"]

        req = urllib.request.Request(
            url=upstream_url,
            data=body_bytes,
            headers=headers,
            method=self.command
        )

        try:
            with urllib.request.urlopen(req, timeout=8.0) as resp:
                resp_bytes = resp.read()
                self.send_response(resp.status)
                self.send_cors_headers()
                self.send_header("Content-Type", resp.headers.get("Content-Type", "application/json"))
                self.send_header("X-Trace-ID", trace_id)
                self.send_header("Content-Length", str(len(resp_bytes)))
                self.end_headers()
                self.wfile.write(resp_bytes)
        except urllib.error.HTTPError as e:
            err_bytes = e.read()
            self.send_response(e.code)
            self.send_cors_headers()
            self.send_header("Content-Type", "application/json")
            self.send_header("X-Trace-ID", trace_id)
            self.send_header("Content-Length", str(len(err_bytes)))
            self.end_headers()
            self.wfile.write(err_bytes)
        except urllib.error.URLError as e:
            self.respond_json(503, {
                "error": "Upstream Microservice Unavailable",
                "upstreamUrl": upstream_url,
                "reason": str(e.reason),
                "traceId": trace_id,
                "suggestion": "Ensure the target microservice is started and running."
            })
        except Exception as e:
            self.respond_json(500, {
                "error": "API Gateway Proxy Error",
                "details": str(e),
                "traceId": trace_id
            })

    def handle_static(self, req_path: str):
        if req_path in ["/", ""]:
            req_path = "/index.html"
        
        # Clean relative path
        rel_path = req_path.lstrip("/").replace("/", os.sep)
        file_path = os.path.join(STATIC_DIR, rel_path)

        if not os.path.exists(file_path) or os.path.isdir(file_path):
            self.respond_json(404, {"error": "Static asset not found", "path": req_path})
            return

        ext = os.path.splitext(file_path)[1].lower()
        content_type = MIME_TYPES.get(ext, "application/octet-stream")

        try:
            with open(file_path, "rb") as f:
                content = f.read()
            self.send_response(200)
            self.send_cors_headers()
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(content)))
            self.end_headers()
            self.wfile.write(content)
        except Exception as e:
            self.respond_json(500, {"error": "Error reading static file", "details": str(e)})

    def do_GET(self):
        trace_id = self.headers.get("X-Trace-ID") or f"trc_{int(time.time()*1000)}_{secrets.token_hex(3)}"
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path in ["/health", "/api/v1/health"]:
            self.check_aggregated_health(trace_id)
            return

        # Check API Gateway Routing
        for prefix, upstream_base in ROUTE_TABLE.items():
            if path.startswith(prefix):
                target_url = f"{upstream_base}{self.path}"
                self.proxy_request(target_url, trace_id)
                return

        # Serve static assets
        self.handle_static(path)

    def do_POST(self):
        trace_id = self.headers.get("X-Trace-ID") or f"trc_{int(time.time()*1000)}_{secrets.token_hex(3)}"
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        for prefix, upstream_base in ROUTE_TABLE.items():
            if path.startswith(prefix):
                target_url = f"{upstream_base}{self.path}"
                self.proxy_request(target_url, trace_id)
                return

        self.respond_json(404, {"error": "No microservice route matched", "path": path, "traceId": trace_id})

    def check_aggregated_health(self, trace_id: str):
        services_status = {}
        all_up = True

        for key, info in SERVICES_REGISTRY.items():
            try:
                req = urllib.request.Request(info["url"])
                with urllib.request.urlopen(req, timeout=1.5) as resp:
                    if resp.status == 200:
                        services_status[key] = {"name": info["name"], "port": info["port"], "status": "UP"}
                    else:
                        services_status[key] = {"name": info["name"], "port": info["port"], "status": f"HTTP {resp.status}"}
                        all_up = False
            except Exception:
                services_status[key] = {"name": info["name"], "port": info["port"], "status": "OFFLINE"}
                all_up = False

        overall_status = "HEALTHY" if all_up else "DEGRADED"
        self.respond_json(200 if all_up else 207, {
            "gateway": "paldfi-api-gateway",
            "version": "1.0.0-microservices",
            "port": PORT,
            "overallStatus": overall_status,
            "timestamp": time.time(),
            "traceId": trace_id,
            "microservices": services_status
        })

def run_server():
    with socketserver.ThreadingTCPServer(("", PORT), ApiGatewayHandler) as httpd:
        httpd.allow_reuse_address = True
        print(f"[ApiGateway] PAL-DFI API Gateway running at http://localhost:{PORT}")
        print("  Routes:")
        for prefix, target in ROUTE_TABLE.items():
            print(f"    - {prefix}/*  -->  {target}")
        httpd.serve_forever()

if __name__ == "__main__":
    run_server()
