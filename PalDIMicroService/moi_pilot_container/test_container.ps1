# ==============================================================================
# Ministry of Interior (MoI) - Container API Smoke Test Suite
# Tests Healthcheck, Civil Records API, Stats, and CSV Download
# ==============================================================================

$baseUrl = "http://localhost:9000"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " MoI National ID Container - API Smoke Test Suite" -ForegroundColor Yellow
Write-Host " Target: $baseUrl" -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Cyan

# Test 1: Healthcheck
Write-Host "`n[TEST 1] Checking Container Health Probe (/health)..." -ForegroundColor White
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    if ($health.status -eq "UP") {
        Write-Host "  -> PASS: Status is UP | Version: $($health.version) | Uptime: $($health.uptime_seconds)s" -ForegroundColor Green
    } else {
        Write-Host "  -> FAIL: Status is not UP" -ForegroundColor Red
    }
} catch {
    Write-Host "  -> ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Civil Records API
Write-Host "`n[TEST 2] Checking Civil Registry Records (/api/v1/moi/records)..." -ForegroundColor White
try {
    $recordsRes = Invoke-RestMethod -Uri "$baseUrl/api/v1/moi/records" -Method Get
    if ($recordsRes.success -and ($recordsRes.count -ge 0)) {
        Write-Host "  -> PASS: Fetched $($recordsRes.count) national ID records successfully" -ForegroundColor Green
        if ($recordsRes.count -gt 0) {
            $sample = $recordsRes.records[0]
            Write-Host "     Sample Record: ID: $($sample.national_id_number) | Name: $($sample.applicant_name_ar) | Status: $($sample.status)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  -> FAIL: Failed to parse records" -ForegroundColor Red
    }
} catch {
    Write-Host "  -> ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Pilot Stats API
Write-Host "`n[TEST 3] Checking Pilot Analytics (/api/v1/moi/stats)..." -ForegroundColor White
try {
    $statsRes = Invoke-RestMethod -Uri "$baseUrl/api/v1/moi/stats" -Method Get
    if ($statsRes.success) {
        $st = $statsRes.stats
        Write-Host "  -> PASS: Stats retrieved successfully:" -ForegroundColor Green
        Write-Host "     Total Applications : $($st.total_applications)" -ForegroundColor Cyan
        Write-Host "     Issued IDs         : $($st.issued_count)" -ForegroundColor Cyan
        Write-Host "     Total Revenue (JOD): $($st.total_revenue_jod)" -ForegroundColor Cyan
        Write-Host "     Average Liveness   : $($st.average_liveness_score)" -ForegroundColor Cyan
    } else {
        Write-Host "  -> FAIL: Stats returned error" -ForegroundColor Red
    }
} catch {
    Write-Host "  -> ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: CSV File Download
Write-Host "`n[TEST 4] Testing CSV Ledger Export (/api/v1/moi/export-csv)..." -ForegroundColor White
try {
    $csvContent = Invoke-RestMethod -Uri "$baseUrl/api/v1/moi/export-csv" -Method Get
    if ($csvContent -match "national_id_number") {
        Write-Host "  -> PASS: CSV export contains valid national ID header row" -ForegroundColor Green
    } else {
        Write-Host "  -> FAIL: CSV export does not contain expected headers" -ForegroundColor Red
    }
} catch {
    Write-Host "  -> ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host " MoI Container Smoke Test Finished!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
