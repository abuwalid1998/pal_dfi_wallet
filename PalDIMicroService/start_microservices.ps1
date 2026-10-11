# PAL-DFI Microservices Launch Script for Windows PowerShell
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Starting PAL-DFI Distributed Microservices Architecture   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$services = @(
    @{ Name = "Auth & PMA ID+ Service"; Path = "services\auth_service\server.py"; Port = 8001 },
    @{ Name = "Biometrics & AI Vector Service"; Path = "services\biometrics_service\server.py"; Port = 8002 },
    @{ Name = "W3C Credential Lifecycle Service"; Path = "services\credential_service\server.py"; Port = 8003 },
    @{ Name = "ZKP & Privacy Engine"; Path = "services\zkp_service\server.py"; Port = 8004 },
    @{ Name = "Fabric Blockchain Gateway"; Path = "services\fabric_gateway\server.py"; Port = 8005 },
    @{ Name = "Audit & Compliance Service"; Path = "services\audit_service\server.py"; Port = 8006 }
)

$processes = @()

foreach ($s in $services) {
    Write-Host "-> Launching $($s.Name) on port $($s.Port)..." -ForegroundColor Yellow
    $p = Start-Process python -ArgumentList $s.Path -PassThru -NoNewWindow
    $processes += @{ Name = $s.Name; Process = $p; Port = $s.Port }
    Start-Sleep -Milliseconds 400
}

# Finally start the API Gateway
Write-Host "-> Launching API Gateway & Edge Reverse Proxy on port 8000..." -ForegroundColor Green
$gw = Start-Process python -ArgumentList "services\api_gateway\server.py" -PassThru -NoNewWindow
$processes += @{ Name = "API Gateway"; Process = $gw; Port = 8000 }

Start-Sleep -Seconds 2

# Save PIDs for stop script
$pids = $processes | ForEach-Object { $_.Process.Id }
$pids | Out-File -FilePath ".running_microservices.pids" -Force

Write-Host "`nAll 7 Microservices successfully initialized!" -ForegroundColor Green
Write-Host "  Unified API Gateway: http://localhost:8000" -ForegroundColor White
Write-Host "  Cluster Health Check: http://localhost:8000/api/v1/health" -ForegroundColor White
Write-Host "To shut down all services, run: .\stop_microservices.ps1" -ForegroundColor Gray
