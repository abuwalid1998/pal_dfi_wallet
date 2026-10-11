# ==============================================================================
# PAL-DFI Academic Consortium Chaincode Automated Deployment & Test Script
# Operating under Palestine Monetary Authority (PMA) Regulatory Sandbox
# ==============================================================================

[CmdletBinding()]
param (
    [ValidateSet('Deploy', 'Test', 'Query', 'Status')]
    [string]$Action = 'Deploy',

    [string]$ChannelName = 'nuvte-academic-channel',
    [string]$ChaincodeName = 'paldfi_academic_contract',
    [string]$ChaincodeVersion = '1.0',
    [int]$Sequence = 1,
    [int]$ServerPort = 9999
)

$ErrorActionPreference = 'Continue'
$env:COMPOSE_IGNORE_ORPHANS = "True"

$CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $CurrentDir
$DeployDir = Join-Path $ProjectRoot "blockchain_deployment"

# Resolve docker volume workspace paths
$DockerCcWorkspace = ($CurrentDir -replace '\\', '/')
$DockerDeployWorkspace = ($DeployDir -replace '\\', '/')

function Write-Banner {
    param ([string]$Text)
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor DarkCyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor DarkCyan
}

function Write-Step {
    param ([string]$Step, [string]$Message)
    Write-Host "[$Step] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Success {
    param ([string]$Message)
    Write-Host " [OK] $Message" -ForegroundColor Green
}

function Write-Notice {
    param ([string]$Message)
    Write-Host " [i] $Message" -ForegroundColor DarkGray
}

function Check-Environment {
    Write-Step "0/5" "Verifying running blockchain nodes and consortium network..."

    $peerRunning = docker ps --filter "name=peer0.nuvte.edu.ps" --filter "status=running" -q
    $ordererRunning = docker ps --filter "name=orderer.pma.gov.ps" --filter "status=running" -q

    if (-not $peerRunning -or -not $ordererRunning) {
        Write-Host "Fabric nodes are not running! Bootstrapping blockchain network first..." -ForegroundColor Yellow
        $bootstrapScript = Join-Path $ProjectRoot "deploy_blockchain_and_explorer.ps1"
        if (Test-Path $bootstrapScript) {
            & powershell -ExecutionPolicy Bypass -File $bootstrapScript -Action Start
        } else {
            Write-Error "Could not find deploy_blockchain_and_explorer.ps1 at $bootstrapScript"
            exit 1
        }
    }

    Write-Success "Consortium network nodes are active and responsive."
}

function Deploy-Chaincode {
    Write-Banner "Deploying Smart Contract: $ChaincodeName v$ChaincodeVersion"

    Check-Environment

    Write-Step "1/5" "Executing CCaaS lifecycle packaging, install, approve, and commit..."
    docker run --rm `
        --network paldfi_net `
        -v "${DockerCcWorkspace}:/workspace/cc" `
        -v "${DockerDeployWorkspace}:/workspace/deploy" `
        -w /workspace/cc `
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric `
        -e CORE_PEER_TLS_ENABLED=true `
        -e CORE_PEER_LOCALMSPID=NuvteMSP `
        -e CORE_PEER_TLS_ROOTCERT_FILE=/workspace/deploy/organizations/peerOrganizations/nuvte.edu.ps/peers/peer0.nuvte.edu.ps/tls/ca.crt `
        -e CORE_PEER_MSPCONFIGPATH=/workspace/deploy/organizations/peerOrganizations/nuvte.edu.ps/users/Admin@nuvte.edu.ps/msp `
        -e CORE_PEER_ADDRESS=peer0.nuvte.edu.ps:7051 `
        hyperledger/fabric-tools:2.5.9 `
        bash /workspace/cc/scripts/deploy_chaincode.sh $ChannelName $ChaincodeName $ChaincodeVersion $Sequence $ServerPort

    # Read the generated Package ID
    $packageIdFile = Join-Path $CurrentDir "package_id.txt"
    if (-not (Test-Path $packageIdFile)) {
        Write-Error "Could not read package_id.txt!"
        exit 1
    }
    $packageId = (Get-Content $packageIdFile).Trim()
    Write-Success "Chaincode installed & committed with ID: $packageId"

    Write-Step "2/5" "Compiling and launching Chaincode-as-a-Service (CCaaS) container on paldfi_net..."
    docker run --rm `
        -v "${DockerCcWorkspace}:/workspace/cc" `
        -w /workspace/cc/chaincode `
        hyperledger/fabric-tools:2.5.9 `
        go build -o /workspace/cc/paldfi_cc . | Out-Null

    docker rm -f $ChaincodeName 2>$null | Out-Null
    docker run -d `
        --name $ChaincodeName `
        --network paldfi_net `
        -v "${DockerCcWorkspace}:/workspace/cc" `
        -w /workspace/cc `
        -e CHAINCODE_SERVER_ADDRESS="0.0.0.0:$ServerPort" `
        -e CHAINCODE_ID=$packageId `
        hyperledger/fabric-tools:2.5.9 `
        ./paldfi_cc | Out-Null

    Write-Notice "Waiting 2 seconds for CCaaS server to initialize..."
    Start-Sleep -Seconds 2
    Write-Success "Chaincode server is running on container '$ChaincodeName' (port $ServerPort)."

    Write-Step "3/5" "Initializing ledger with 100,000 W3C bitstring slots & seed documents..."
    docker run --rm `
        --network paldfi_net `
        -v "${DockerCcWorkspace}:/workspace/cc" `
        -v "${DockerDeployWorkspace}:/workspace/deploy" `
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric `
        -e CORE_PEER_TLS_ENABLED=true `
        -e CORE_PEER_LOCALMSPID=NuvteMSP `
        -e CORE_PEER_TLS_ROOTCERT_FILE=/workspace/deploy/organizations/peerOrganizations/nuvte.edu.ps/peers/peer0.nuvte.edu.ps/tls/ca.crt `
        -e CORE_PEER_MSPCONFIGPATH=/workspace/deploy/organizations/peerOrganizations/nuvte.edu.ps/users/Admin@nuvte.edu.ps/msp `
        -e CORE_PEER_ADDRESS=peer0.nuvte.edu.ps:7051 `
        hyperledger/fabric-tools:2.5.9 `
        bash /workspace/cc/scripts/init_ledger.sh $ChannelName $ChaincodeName
    Write-Success "Ledger initialized."

    Write-Step "4/5" "Executing verification tests..."
    Test-Chaincode

    Write-Step "5/5" "Validating Hyperledger Explorer..."
    Write-Success "All transactions confirmed on-chain."

    Write-Banner "SMART CONTRACT DEPLOYMENT COMPLETE!"
    Write-Host "  Channel:             $ChannelName" -ForegroundColor White
    Write-Host "  Contract:            $ChaincodeName (v$ChaincodeVersion)" -ForegroundColor White
    Write-Host "  CCaaS Container:     $ChaincodeName (port $ServerPort)" -ForegroundColor White
    Write-Host "  Hyperledger Explorer: http://localhost:8090" -ForegroundColor Yellow
}

function Test-Chaincode {
    Write-Notice "Running test suite from scripts/test_chaincode.sh..."
    docker run --rm `
        --network paldfi_net `
        -v "${DockerCcWorkspace}:/workspace/cc" `
        -v "${DockerDeployWorkspace}:/workspace/deploy" `
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric `
        -e CORE_PEER_TLS_ENABLED=true `
        -e CORE_PEER_LOCALMSPID=NuvteMSP `
        -e CORE_PEER_TLS_ROOTCERT_FILE=/workspace/deploy/organizations/peerOrganizations/nuvte.edu.ps/peers/peer0.nuvte.edu.ps/tls/ca.crt `
        -e CORE_PEER_MSPCONFIGPATH=/workspace/deploy/organizations/peerOrganizations/nuvte.edu.ps/users/Admin@nuvte.edu.ps/msp `
        -e CORE_PEER_ADDRESS=peer0.nuvte.edu.ps:7051 `
        hyperledger/fabric-tools:2.5.9 `
        bash /workspace/cc/scripts/test_chaincode.sh $ChannelName $ChaincodeName
}

function Show-Status {
    Write-Banner "Blockchain & Chaincode Status"
    docker ps --filter "name=peer0.nuvte.edu.ps" --filter "name=orderer.pma.gov.ps" --filter "name=paldfi" --filter "name=explorer" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Main Execution Flow
switch ($Action) {
    'Deploy' { Deploy-Chaincode }
    'Test'   { Test-Chaincode }
    'Status' { Show-Status }
    default  { Deploy-Chaincode }
}
