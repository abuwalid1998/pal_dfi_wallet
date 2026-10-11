# PAL-DFI Microservices Shutdown Script
Write-Host "Shutting down PAL-DFI Microservices..." -ForegroundColor Yellow

if (Test-Path ".running_microservices.pids") {
    $pids = Get-Content ".running_microservices.pids"
    foreach ($p in $pids) {
        if ($p) {
            Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
            Write-Host "Stopped process ID $p" -ForegroundColor Gray
        }
    }
    Remove-Item ".running_microservices.pids" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "No active PID file found. Checking ports 8000-8006..." -ForegroundColor Gray
    8000..8006 | ForEach-Object {
        $conn = Get-NetTCPConnection -LocalPort $_ -ErrorAction SilentlyContinue
        if ($conn) {
            Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
            Write-Host "Terminated process on port $_" -ForegroundColor Gray
        }
    }
}

Write-Host "All microservices successfully stopped." -ForegroundColor Green
