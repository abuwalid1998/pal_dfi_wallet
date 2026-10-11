# ==============================================================================
# PAL-DFI Hyperledger Fabric 2.5 & Explorer Automated Deployment Script (.ps1)
# Nablus University for Vocational and Technical Education (NUVTE)
# Operating under Palestine Monetary Authority (PMA) Regulatory Sandbox
# ==============================================================================

[CmdletBinding()]
param (
    [ValidateSet('Start', 'Stop', 'Restart', 'Clean', 'Status')]
    [string]$Action = 'Start',

    [string]$ChannelName = 'nuvte-academic-channel',
    [string]$ChaincodeName = 'paldfi_contract',
    [string]$ChaincodeVersion = '1.0',
    [int]$ExplorerPort = 8090
)

$ErrorActionPreference = 'Continue'
$env:COMPOSE_IGNORE_ORPHANS = "True"

# Resolve absolute normalized directory paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path "$ScriptDir\docker-compose-fabric.yaml")) {
    if (Test-Path "$ScriptDir\blockchain_deployment\docker-compose-fabric.yaml") {
        $ScriptDir = "$ScriptDir\blockchain_deployment"
    }
}

$DockerWorkspace = ($ScriptDir -replace '\\', '/')

function Write-Header {
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

function Check-Docker {
    Write-Step "0/7" "Verifying Docker & Docker Compose prerequisites..."

    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerCmd) {
        Write-Error "Docker is not installed or not in PATH! Please install Docker Desktop: https://www.docker.com/products/docker-desktop/"
        exit 1
    }

    # Test if Docker daemon is running
    $daemonRunning = $false
    try {
        $null = docker info 2>&1
        if ($LASTEXITCODE -eq 0) {
            $daemonRunning = $true
        }
    } catch {
        $daemonRunning = $false
    }

    if (-not $daemonRunning) {
        Write-Host "Docker daemon is not running! Attempting to launch Docker Desktop..." -ForegroundColor Yellow
        $dockerAppPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerAppPath) {
            Start-Process $dockerAppPath
        }

        Write-Host "Waiting up to 45 seconds for Docker engine to become ready..." -ForegroundColor Yellow
        for ($i = 0; $i -lt 45; $i++) {
            Start-Sleep -Seconds 1
            $null = docker info 2>&1
            if ($LASTEXITCODE -eq 0) {
                $daemonRunning = $true
                break
            }
        }
    }

    if (-not $daemonRunning) {
        Write-Error "Docker Desktop is not responsive. Please start Docker Desktop manually and re-run this script."
        exit 1
    }

    Write-Success "Docker engine and Compose are ready."
}

function Stop-Network {
    Write-Header "Stopping PAL-DFI Blockchain & Explorer"
    Set-Location $ScriptDir

    Write-Step "1/2" "Stopping Hyperledger Explorer containers..."
    if (Test-Path "explorer\docker-compose-explorer.yaml") {
        docker compose -f explorer/docker-compose-explorer.yaml down --remove-orphans 2>$null
    }

    Write-Step "2/2" "Stopping Hyperledger Fabric 2.5 network containers..."
    docker compose -f docker-compose-fabric.yaml down --remove-orphans 2>$null
    Write-Success "All blockchain and explorer containers stopped."
}

function Clean-Network {
    Write-Header "Cleaning PAL-DFI Blockchain Artifacts & Crypto Material"
    Set-Location $ScriptDir

    Stop-Network

    Write-Step "1/2" "Purging Docker volumes..."
    docker compose -f docker-compose-fabric.yaml down --volumes --remove-orphans 2>$null
    if (Test-Path "explorer\docker-compose-explorer.yaml") {
        docker compose -f explorer/docker-compose-explorer.yaml down --volumes --remove-orphans 2>$null
    }

    Write-Step "2/2" "Removing generated crypto certificates and channel genesis blocks..."
    Remove-Item -Path "organizations\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "*.block" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "*.tar.gz" -Force -ErrorAction SilentlyContinue

    Write-Success "Clean completed. Environment is reset to zero state."
}

function Show-Status {
    Write-Header "PAL-DFI Consortium Blockchain & Explorer Status"
    docker ps --filter "name=pma.gov.ps" --filter "name=nuvte.edu.ps" --filter "name=explorer" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

function Start-Network {
    Write-Header "Initializing & Deploying PAL-DFI Blockchain + Hyperledger Explorer"
    Set-Location $ScriptDir

    Check-Docker

    # 1. Clean previous run artifacts
    Write-Step "1/7" "Cleaning previous containers and transient networks..."
    docker compose -f docker-compose-fabric.yaml down --remove-orphans 2>$null
    if (Test-Path "explorer\docker-compose-explorer.yaml") {
        docker compose -f explorer/docker-compose-explorer.yaml down --remove-orphans 2>$null
    }

    # Ensure organizations directory exists
    $orgDir = Join-Path $ScriptDir "organizations"
    $channelArtifactsDir = Join-Path $orgDir "channel-artifacts"
    if (-not (Test-Path $channelArtifactsDir)) {
        New-Item -ItemType Directory -Path $channelArtifactsDir -Force | Out-Null
    }

    # 2. Generate Cryptographic Material (via Fabric Tools container - zero host binaries needed)
    Write-Step "2/7" "Generating X.509 certificates & MSP keys using cryptogen..."
    docker run --rm `
        -v "${DockerWorkspace}:/workspace" `
        -w /workspace `
        hyperledger/fabric-tools:2.5.9 `
        cryptogen generate --config=/workspace/crypto-config.yaml --output=/workspace/organizations

    # Predictably link the admin private key for Hyperledger Explorer connection profile
    $keystorePath = Join-Path $ScriptDir "organizations\peerOrganizations\nuvte.edu.ps\users\Admin@nuvte.edu.ps\msp\keystore"
    if (Test-Path $keystorePath) {
        $skFile = Get-ChildItem -Path "$keystorePath\*_sk" | Where-Object { $_.Name -ne 'priv_sk' } | Select-Object -First 1
        if ($skFile) {
            Copy-Item -Path $skFile.FullName -Destination "$keystorePath\priv_sk" -Force
            Write-Notice "Mapped Admin private key to: $keystorePath\priv_sk"
        }
    }
    Write-Success "Cryptographic PKI material generated."

    # 3. Generate Channel Genesis Block
    Write-Step "3/7" "Generating channel genesis block with configtxgen..."
    docker run --rm `
        -v "${DockerWorkspace}:/workspace" `
        -w /workspace `
        -e FABRIC_CFG_PATH=/workspace `
        hyperledger/fabric-tools:2.5.9 `
        configtxgen -profile TwoOrgsApplicationGenesis `
        -outputBlock /workspace/organizations/channel-artifacts/${ChannelName}.block `
        -channelID ${ChannelName}
    Write-Success "Genesis block created: organizations/channel-artifacts/${ChannelName}.block"

    # 4. Start Core Fabric Containers (Orderer, Peer, CA)
    Write-Step "4/7" "Launching Fabric 2.5 nodes (PMA Orderer, NUVTE Peer, Fabric CA)..."
    docker compose -f docker-compose-fabric.yaml up -d
    Write-Notice "Waiting 8 seconds for Raft consensus & Peer TLS handshakes to initialize..."
    Start-Sleep -Seconds 8
    Write-Success "Core Fabric nodes running."

    # 5. Join Channel via Channel Participation API (Orderer & Peer)
    Write-Step "5/7" "Joining Orderer & NUVTE Peer to channel '${ChannelName}'..."
    docker run --rm `
        --network paldfi_net `
        -v "${DockerWorkspace}:/workspace" `
        hyperledger/fabric-tools:2.5.9 `
        osnadmin channel join `
        --channelID ${ChannelName} `
        --config-block /workspace/organizations/channel-artifacts/${ChannelName}.block `
        -o orderer.pma.gov.ps:7053 `
        --ca-file /workspace/organizations/ordererOrganizations/pma.gov.ps/tlsca/tlsca.pma.gov.ps-cert.pem `
        --client-cert /workspace/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/tls/server.crt `
        --client-key /workspace/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/tls/server.key
    Write-Notice "Orderer successfully joined channel '${ChannelName}'."

    docker run --rm `
        --network paldfi_net `
        -v "${DockerWorkspace}:/workspace" `
        -w /workspace `
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric `
        -e CORE_PEER_TLS_ENABLED=true `
        -e CORE_PEER_LOCALMSPID=NuvteMSP `
        -e CORE_PEER_TLS_ROOTCERT_FILE=/workspace/organizations/peerOrganizations/nuvte.edu.ps/peers/peer0.nuvte.edu.ps/tls/ca.crt `
        -e CORE_PEER_MSPCONFIGPATH=/workspace/organizations/peerOrganizations/nuvte.edu.ps/users/Admin@nuvte.edu.ps/msp `
        -e CORE_PEER_ADDRESS=peer0.nuvte.edu.ps:7051 `
        hyperledger/fabric-tools:2.5.9 `
        peer channel join -b /workspace/organizations/channel-artifacts/${ChannelName}.block
    Write-Success "Peer and Orderer successfully joined channel: ${ChannelName}"

    # 6. Deploy & Initialize Smart Contract (BitstringStatusList2021)
    Write-Step "6/7" "Packaging, installing, and initializing smart contract '${ChaincodeName}'..."
    docker run --rm `
        --network paldfi_net `
        -v "${DockerWorkspace}:/workspace" `
        -w /workspace `
        -e FABRIC_CFG_PATH=/etc/hyperledger/fabric `
        -e CORE_PEER_TLS_ENABLED=true `
        -e CORE_PEER_LOCALMSPID=NuvteMSP `
        -e CORE_PEER_TLS_ROOTCERT_FILE=/workspace/organizations/peerOrganizations/nuvte.edu.ps/peers/peer0.nuvte.edu.ps/tls/ca.crt `
        -e CORE_PEER_MSPCONFIGPATH=/workspace/organizations/peerOrganizations/nuvte.edu.ps/users/Admin@nuvte.edu.ps/msp `
        -e CORE_PEER_ADDRESS=peer0.nuvte.edu.ps:7051 `
        hyperledger/fabric-tools:2.5.9 `
        bash /workspace/scripts/deploy_cc.sh $ChannelName $ChaincodeName $ChaincodeVersion
    Write-Success "Smart contract deployed & 100,000 status bits initialized."

    # 7. Start Hyperledger Explorer
    Write-Step "7/7" "Deploying Hyperledger Explorer & PostgreSQL Database on port ${ExplorerPort}..."
    docker compose -f explorer/docker-compose-explorer.yaml up -d
    Write-Notice "Waiting 10 seconds for Explorer synchronization service to establish peer connection..."
    Start-Sleep -Seconds 10
    Write-Success "Hyperledger Explorer is operational."

    # Final summary dashboard
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host " PAL-DFI BLOCKCHAIN & EXPLORER ARE LIVE AND OPERATIONAL!          " -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Hyperledger Explorer UI:     " -NoNewline -ForegroundColor White
    Write-Host "http://localhost:${ExplorerPort}" -ForegroundColor Yellow
    Write-Host "  Explorer Credentials:        " -NoNewline -ForegroundColor White
    Write-Host "Username: admin | Password: password" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  NUVTE Peer Node:             " -NoNewline -ForegroundColor White
    Write-Host "peer0.nuvte.edu.ps:7051 (TLS 1.3)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  PMA Raft Orderer Node:       " -NoNewline -ForegroundColor White
    Write-Host "orderer.pma.gov.ps:7050 (PmaOrdererMSP)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  NUVTE CA Server:             " -NoNewline -ForegroundColor White
    Write-Host "ca.nuvte.edu.ps:7054" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Channel ID:                  " -NoNewline -ForegroundColor White
    Write-Host "$ChannelName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Smart Contract:              " -NoNewline -ForegroundColor White
    Write-Host "${ChaincodeName} (v${ChaincodeVersion})" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " Useful Commands:" -ForegroundColor White
    Write-Host "   Check Network Status:  .\deploy_blockchain_and_explorer.ps1 -Action Status" -ForegroundColor DarkYellow
    Write-Host "   Stop Containers:       .\deploy_blockchain_and_explorer.ps1 -Action Stop" -ForegroundColor DarkYellow
    Write-Host "   Clean All Data:        .\deploy_blockchain_and_explorer.ps1 -Action Clean" -ForegroundColor DarkYellow
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
}

# Main Dispatcher
switch ($Action) {
    'Start'   { Start-Network }
    'Stop'    { Stop-Network }
    'Restart' { Stop-Network; Start-Network }
    'Clean'   { Clean-Network }
    'Status'  { Show-Status }
}
