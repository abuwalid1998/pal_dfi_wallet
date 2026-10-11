#!/bin/bash
set -e

CHANNEL_NAME=${1:-nuvte-academic-channel}
CHAINCODE_NAME=${2:-paldfi_academic_contract}
CHAINCODE_VERSION=${3:-1.0}
SEQUENCE=${4:-1}
CC_SERVER_PORT=${5:-9999}

echo "=================================================================="
echo "  Deploying Smart Contract: ${CHAINCODE_NAME} v${CHAINCODE_VERSION} (Seq: ${SEQUENCE})"
echo "  Channel: ${CHANNEL_NAME}"
echo "=================================================================="

# 1. Package chaincode as CCaaS (Chaincode-as-a-Service)
echo "==> [1/4] Building CCaaS package..."
PKG_DIR="/tmp/ccaas_pkg"
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/code"

cat << EOF > "$PKG_DIR/code/connection.json"
{
  "address": "${CHAINCODE_NAME}:${CC_SERVER_PORT}",
  "dial_timeout": "10s",
  "tls_required": false
}
EOF

tar -czf "$PKG_DIR/code.tar.gz" -C "$PKG_DIR/code" connection.json

cat << EOF > "$PKG_DIR/metadata.json"
{
  "type": "ccaas",
  "label": "${CHAINCODE_NAME}_${CHAINCODE_VERSION}"
}
EOF

tar -czf "/workspace/cc/${CHAINCODE_NAME}.tar.gz" -C "$PKG_DIR" metadata.json code.tar.gz
echo "Packaging complete: /workspace/cc/${CHAINCODE_NAME}.tar.gz"

# 2. Install on NUVTE peer
echo "==> [2/4] Installing chaincode package on peer0.nuvte.edu.ps:7051..."
peer lifecycle chaincode install "/workspace/cc/${CHAINCODE_NAME}.tar.gz"

# 3. Calculate package ID
CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid "/workspace/cc/${CHAINCODE_NAME}.tar.gz")
echo "Chaincode Package ID: ${CC_PACKAGE_ID}"

# Save package ID to file for PowerShell runner
echo "${CC_PACKAGE_ID}" > "/workspace/cc/package_id.txt"

# 4. Approve for NuvteOrg
echo "==> [3/4] Approving chaincode definition for NuvteOrg..."
peer lifecycle chaincode approveformyorg -o orderer.pma.gov.ps:7050 \
    --ordererTLSHostnameOverride orderer.pma.gov.ps \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --package-id ${CC_PACKAGE_ID} \
    --sequence ${SEQUENCE} \
    --tls \
    --cafile /workspace/deploy/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem

# 5. Commit to channel
echo "==> [4/4] Committing chaincode definition to channel '${CHANNEL_NAME}'..."
peer lifecycle chaincode commit -o orderer.pma.gov.ps:7050 \
    --ordererTLSHostnameOverride orderer.pma.gov.ps \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --sequence ${SEQUENCE} \
    --tls \
    --cafile /workspace/deploy/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem

echo "==> Lifecycle definition committed successfully."
