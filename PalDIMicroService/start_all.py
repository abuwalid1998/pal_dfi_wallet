"""
PAL-DFI Microservices Master Orchestrator & Supervisor
Starts, monitors, and manages all 7 microservices in parallel.
Cross-platform: Windows, Linux, macOS.
"""

import os
import sys
import time
import subprocess
import signal

SERVICES = [
    {"name": "Auth Service", "path": os.path.join("services", "auth_service", "server.py"), "port": 8001},
    {"name": "Biometrics Service", "path": os.path.join("services", "biometrics_service", "server.py"), "port": 8002},
    {"name": "Credential Service", "path": os.path.join("services", "credential_service", "server.py"), "port": 8003},
    {"name": "ZKP Service", "path": os.path.join("services", "zkp_service", "server.py"), "port": 8004},
    {"name": "Fabric Gateway", "path": os.path.join("services", "fabric_gateway", "server.py"), "port": 8005},
    {"name": "Audit Service", "path": os.path.join("services", "audit_service", "server.py"), "port": 8006},
    {"name": "API Gateway", "path": os.path.join("services", "api_gateway", "server.py"), "port": 8000},
]

processes = []

def cleanup(sig=None, frame=None):
    print("\n[Supervisor] Shutting down PAL-DFI Microservices cluster...")
    for p in processes:
        try:
            p.terminate()
        except Exception:
            pass
    time.sleep(0.5)
    for p in processes:
        try:
            p.kill()
        except Exception:
            pass
    print("[Supervisor] All microservices terminated.")
    sys.exit(0)

def main():
    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    print("=" * 65)
    print("  PAL-DFI Distributed Microservices Architecture Supervisor  ")
    print("=" * 65)

    base_dir = os.path.dirname(os.path.abspath(__file__))

    for s in SERVICES:
        full_path = os.path.join(base_dir, s["path"])
        print(f"-> Starting {s['name']} (Port {s['port']})...")
        proc = subprocess.Popen([sys.executable, full_path], cwd=base_dir)
        processes.append(proc)
        time.sleep(0.3)

    print("\n[Supervisor] All 7 microservices running.")
    print("  Unified API Gateway:  http://localhost:8000")
    print("  Cluster Health Check: http://localhost:8000/api/v1/health")
    print("  Press Ctrl+C to terminate cluster.\n")

    try:
        while True:
            # Check if any process died
            for i, p in enumerate(processes):
                if p.poll() is not None:
                    print(f"[Supervisor WARNING] {SERVICES[i]['name']} exited unexpectedly with code {p.returncode}")
            time.sleep(1)
    except KeyboardInterrupt:
        cleanup()

if __name__ == "__main__":
    main()
