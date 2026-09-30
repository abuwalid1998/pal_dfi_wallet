#!/bin/bash
set -e

CHANNEL_NAME=${1:-nuvte-academic-channel}
CHAINCODE_NAME=${2:-paldfi_academic_contract}

echo "=================================================================="
echo "  Initializing Ledger: ${CHAINCODE_NAME} on ${CHANNEL_NAME}"
echo "=================================================================="

peer chaincode invoke -o orderer.pma.gov.ps:7050 \
    --ordererTLSHostnameOverride orderer.pma.gov.ps \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --tls \
    --cafile /workspace/deploy/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem \
    --waitForEvent \
    -c '{"function":"InitLedger","Args":[]}'

echo "==> Ledger initialization transaction committed successfully."
