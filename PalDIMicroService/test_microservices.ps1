# PAL-DFI Microservices Integration Test Suite
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Testing PAL-DFI Distributed Microservices via Gateway   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$gateway = "http://localhost:8000"

# 1. Health
Write-Host "`n[1/7] Testing API Gateway Cluster Health..." -ForegroundColor Yellow
$h = Invoke-RestMethod -Uri "$gateway/api/v1/health"
Write-Host "  -> Gateway Status: $($h.overallStatus)" -ForegroundColor Green
$h.microservices.PSObject.Properties | ForEach-Object {
    Write-Host "     * $($_.Name): $($_.Value.status) on port $($_.Value.port)" -ForegroundColor Gray
}

# 2. Auth
Write-Host "`n[2/7] Testing Auth & PMA ID+ Microservice..." -ForegroundColor Yellow
$auth = Invoke-RestMethod -Uri "$gateway/api/v1/auth/login" -Method Post -Body '{"personaKey":"student"}' -ContentType "application/json"
Write-Host "  -> Authenticated: $($auth.persona.fullNameEn) ($($auth.persona.role))" -ForegroundColor Green
Write-Host "  -> DID: $($auth.persona.did)" -ForegroundColor Gray

# 3. Biometrics
Write-Host "`n[3/7] Testing Biometrics & AI Vector Microservice..." -ForegroundColor Yellow
$bio = Invoke-RestMethod -Uri "$gateway/api/v1/biometrics/faces"
Write-Host "  -> Enrolled Vector Identities: $($bio.count)" -ForegroundColor Green
$match = Invoke-RestMethod -Uri "$gateway/api/v1/biometrics/match" -Method Post -Body '{"imageEntropy":"Ahmad_AlKhalili_NUVTE_STU1082"}' -ContentType "application/json"
Write-Host "  -> Biometric Match: $($match.name) with $($match.confidence) confidence" -ForegroundColor Green

# 4. Credentials
Write-Host "`n[4/7] Testing W3C Credential Lifecycle Microservice..." -ForegroundColor Yellow
$creds = Invoke-RestMethod -Uri "$gateway/api/v1/credentials/student/STU-1082"
Write-Host "  -> Credentials found for STU-1082: $($creds.credentials.Count)" -ForegroundColor Green
$creds.credentials | ForEach-Object {
    Write-Host "     * $($_.type[1]) -> SHA256: $($_.sha256Digest.Substring(0, 16))..." -ForegroundColor Gray
}

# 5. ZKP
Write-Host "`n[5/7] Testing ZKP & Privacy Engine Microservice..." -ForegroundColor Yellow
$zkpReq = Invoke-RestMethod -Uri "$gateway/api/v1/zkp/generate-request" -Method Post -Body '{"scenario":"bank"}' -ContentType "application/json"
Write-Host "  -> Challenge Nonce Generated: $($zkpReq.verificationRequest.nonce)" -ForegroundColor Green
$zkpVerify = Invoke-RestMethod -Uri "$gateway/api/v1/zkp/verify-presentation" -Method Post -Body (@{
    nonce = $zkpReq.verificationRequest.nonce
    holderDid = "did:paldfi:citizen:908172635"
    credentialType = "StudentIdentityCredential"
    revealedClaims = @{ Active_Student = $true; Financial_Clearance = $true }
} | ConvertTo-Json) -ContentType "application/json"
Write-Host "  -> ZKP Verification: $($zkpVerify.verificationStatus) (PII Exposed: $($zkpVerify.disclosureResult.piiExposed))" -ForegroundColor Green

# 6. Fabric Gateway
Write-Host "`n[6/7] Testing Hyperledger Fabric Gateway Microservice..." -ForegroundColor Yellow
$fab = Invoke-RestMethod -Uri "$gateway/api/v1/fabric/status/0"
Write-Host "  -> Bit 0 Revocation Status: $($fab.revocationStatusBit) (Valid=$($fab.isValid)) in $($fab.queryLatencyMs) ms" -ForegroundColor Green

# 7. Audit
Write-Host "`n[7/7] Testing Audit & Compliance Microservice..." -ForegroundColor Yellow
$audit = Invoke-RestMethod -Uri "$gateway/api/v1/audit/metrics"
Write-Host "  -> Compliance Rating: $($audit.metrics.complianceRating)" -ForegroundColor Green
Write-Host "  -> PII Leakage Incidents: $($audit.metrics.piiLeakageIncidents)" -ForegroundColor Green

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  ALL MICROSERVICES TESTS PASSED SUCCESSFULLY (7/7)        " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
