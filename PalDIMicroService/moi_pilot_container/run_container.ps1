# ==============================================================================
# Ministry of Interior (MoI) - Palestinian Digital National ID Container
# Automated Build & Launch Script (Windows PowerShell)
# ==============================================================================

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " Palestinian Ministry of Interior (MoI) - National ID Pilot Service" -ForegroundColor Yellow
Write-Host " Container Deployment Automation (Windows PowerShell)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. Check Docker status
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Docker is not installed or not in PATH. Please install Docker Desktop." -ForegroundColor Red
    Exit 1
}

# 2. Check if .env exists, if not copy from .env.example
if (-not (Test-Path ".env")) {
    Write-Host "[INFO] Creating .env from .env.example..." -ForegroundColor Green
    Copy-Item ".env.example" ".env"
}

# 3. Create persistent data directory if missing
if (-not (Test-Path "data")) {
    New-Item -ItemType Directory -Path "data" | Out-Null
    Write-Host "[INFO] Created local persistent data directory: ./data" -ForegroundColor Green
}

# 4. Stop existing container if running
Write-Host "[INFO] Checking for existing MoI container..." -ForegroundColor DarkGray
docker-compose down 2>$null

# 5. Build and run container
Write-Host "[INFO] Building and starting MoI National ID Container..." -ForegroundColor Green
docker-compose up -d --build

# 6. Verify status
Start-Sleep -Seconds 3
$containerStatus = docker ps --filter "name=moi_national_id_pilot" --format "{{.Status}}"
if ($containerStatus) {
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "[SUCCESS] MoI National ID Container is RUNNING!" -ForegroundColor Green
    Write-Host " Status     : $containerStatus" -ForegroundColor White
    Write-Host " Portal URL : http://localhost:9000/" -ForegroundColor Yellow
    Write-Host " Healthcheck: http://localhost:9000/health" -ForegroundColor Yellow
    Write-Host " API Ledger : http://localhost:9000/api/v1/moi/records" -ForegroundColor Yellow
    Write-Host " CSV Storage: ./data/moi_national_ids.csv" -ForegroundColor White
    Write-Host "==================================================================" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Container may not have started properly. Checking logs:" -ForegroundColor Yellow
    docker-compose logs
}
