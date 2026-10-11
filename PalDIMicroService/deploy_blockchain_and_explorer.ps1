# ==============================================================================
# PAL-DFI Blockchain & Hyperledger Explorer Root Runner
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

$targetScript = Join-Path $PSScriptRoot "blockchain_deployment\deploy_blockchain_and_explorer.ps1"
if (Test-Path $targetScript) {
    & $targetScript -Action $Action -ChannelName $ChannelName -ChaincodeName $ChaincodeName -ChaincodeVersion $ChaincodeVersion -ExplorerPort $ExplorerPort
} else {
    Write-Error "Could not locate blockchain_deployment\deploy_blockchain_and_explorer.ps1"
}
