# ==============================================================================
# PAL-DFI Academic Consortium Chaincode Root Runner Proxy
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

$targetScript = Join-Path $PSScriptRoot "Blockchain ChainCodes\deploy_chaincodes.ps1"
if (Test-Path $targetScript) {
    & powershell -ExecutionPolicy Bypass -File $targetScript -Action $Action -ChannelName $ChannelName -ChaincodeName $ChaincodeName -ChaincodeVersion $ChaincodeVersion -Sequence $Sequence -ServerPort $ServerPort
} else {
    Write-Error "Could not locate 'Blockchain ChainCodes\deploy_chaincodes.ps1'"
}
