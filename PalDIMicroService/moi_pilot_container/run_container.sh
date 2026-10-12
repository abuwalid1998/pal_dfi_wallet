#!/bin/bash
# ==============================================================================
# Ministry of Interior (MoI) - Palestinian Digital National ID Container
# Automated Build & Launch Script (Linux / macOS / Bash)
# ==============================================================================

set -e

echo "=================================================================="
echo " Palestinian Ministry of Interior (MoI) - National ID Pilot Service"
echo " Container Deployment Automation (Linux / Bash)"
echo "=================================================================="

# 1. Check Docker status
if ! command -v docker &> /dev/null; then
    echo "[ERROR] Docker is not installed or not in PATH."
    exit 1
fi

# 2. Check if .env exists, if not copy from .env.example
if [ ! -f ".env" ]; then
    echo "[INFO] Creating .env from .env.example..."
    cp .env.example .env
fi

# 3. Create persistent data directory if missing
mkdir -p data

# 4. Stop existing container if running
echo "[INFO] Checking for existing MoI container..."
docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true

# 5. Build and run container
echo "[INFO] Building and starting MoI National ID Container..."
if command -v docker compose &> /dev/null; then
    docker compose up -d --build
else
    docker-compose up -d --build
fi

# 6. Verify status
sleep 3
if docker ps --filter "name=moi_national_id_pilot" --format '{{.Status}}' | grep -q "Up"; then
    echo "=================================================================="
    echo "[SUCCESS] MoI National ID Container is RUNNING!"
    echo " Portal URL : http://localhost:9000/"
    echo " Healthcheck: http://localhost:9000/health"
    echo " API Ledger : http://localhost:9000/api/v1/moi/records"
    echo " CSV Storage: ./data/moi_national_ids.csv"
    echo "=================================================================="
else
    echo "[WARNING] Container may not have started properly. Checking logs:"
    docker compose logs || docker-compose logs
fi
