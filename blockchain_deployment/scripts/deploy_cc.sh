#!/bin/bash
set -e

CHANNEL_NAME=${1:-nuvte-academic-channel}
CHAINCODE_NAME=${2:-paldfi_contract}
CHAINCODE_VERSION=${3:-1.0}

echo "=========================================================="
echo " Packaging & Installing Smart Contract: ${CHAINCODE_NAME}"
echo "=========================================================="

# 1. Package chaincode
peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz \
    --path /workspace/chaincode/ \
    --lang golang \
    --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION}

# 2. Install on peer
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz

# 3. Calculate package ID
CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CHAINCODE_NAME}.tar.gz)
echo "Chaincode Package ID: ${CC_PACKAGE_ID}"

# 4. Approve for NuvteOrg
peer lifecycle chaincode approveformyorg -o orderer.pma.gov.ps:7050 \
    --ordererTLSHostnameOverride orderer.pma.gov.ps \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --package-id ${CC_PACKAGE_ID} \
    --sequence 1 \
    --tls \
    --cafile /workspace/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem

# 5. Commit to channel
peer lifecycle chaincode commit -o orderer.pma.gov.ps:7050 \
    --ordererTLSHostnameOverride orderer.pma.gov.ps \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --sequence 1 \
    --tls \
    --cafile /workspace/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem

# 6. Initialize ledger
echo "Initializing BitstringStatusList2021 registry on ledger..."
peer chaincode invoke -o orderer.pma.gov.ps:7050 \
    --ordererTLSHostnameOverride orderer.pma.gov.ps \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --tls \
    --cafile /workspace/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem \
    -c '{"function":"InitLedger","Args":[]}'

echo "Chaincode deployment and initialization complete."
