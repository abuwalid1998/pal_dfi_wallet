# ==============================================================================
# PAL-DFI Hyperledger Fabric REST Gateway Launcher
# ==============================================================================
$ErrorActionPreference = 'Continue'
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "Verifying paldfi_fabric_cli container..." -ForegroundColor Cyan
$cliRunning = docker ps --filter "name=paldfi_fabric_cli" --filter "status=running" -q
if (-not $cliRunning) {
    Write-Host "Starting paldfi_fabric_cli container..." -ForegroundColor Yellow
    docker rm -f paldfi_fabric_cli 2>$null | Out-Null
    docker run -d `
        --name paldfi_fabric_cli `
        --network paldfi_net `
        -v "$($ProjectRoot -replace '\\', '/')/Blockchain ChainCodes:/workspace/cc" `
        -v "$($ProjectRoot -replace '\\', '/')/blockchain_deployment:/workspace/deploy" `
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric `
        -e CORE_PEER_TLS_ENABLED=true `
        -e CORE_PEER_LOCALMSPID=NuvteMSP `
        -e CORE_PEER_TLS_ROOTCERT_FILE=/workspace/deploy/organizations/peerOrganizations/nuvte.edu.ps/peers/peer0.nuvte.edu.ps/tls/ca.crt `
        -e CORE_PEER_MSPCONFIGPATH=/workspace/deploy/organizations/peerOrganizations/nuvte.edu.ps/users/Admin@nuvte.edu.ps/msp `
        -e CORE_PEER_ADDRESS=peer0.nuvte.edu.ps:7051 `
        hyperledger/fabric-tools:2.5.9 `
        sleep infinity | Out-Null
}

Write-Host "Starting PAL-DFI REST Gateway Bridge Server on port 5050..." -ForegroundColor Green
python "$PSScriptRoot\server.py"
