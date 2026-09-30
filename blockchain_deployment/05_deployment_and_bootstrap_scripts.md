# 05 - Deployment & Bootstrap Scripts

This guide provides the complete shell commands to spin up the network, join channels, deploy the chaincode, and initialize the Bitstring status list.

---

## 1. Network Bootstrap Script (`bootstrap_network.sh`)

Save this file as `bootstrap_network.sh`:

```bash
#!/bin/bash
set -e

echo "=========================================================="
echo " Starting PAL-DFI Hyperledger Fabric 2.5 Blockchain Network"
echo "=========================================================="

export COMPOSE_PROJECT_NAME=paldfi
export CHANNEL_NAME=nuvte-academic-channel
export CHAINCODE_NAME=paldfi_contract
export CHAINCODE_VERSION=1.0
export CHAINCODE_SEQUENCE=1

# 1. Clean previous artifacts
echo "[1/7] Cleaning previous containers and crypto material..."
docker compose -f docker-compose-fabric.yaml down --volumes --remove-orphans || true
rm -rf organizations/channel-artifacts organizations/peerOrganizations organizations/ordererOrganizations

# 2. Generate Crypto Material
echo "[2/7] Generating crypto material using cryptogen..."
cryptogen generate --config=./crypto-config.yaml --output="organizations"

# 3. Generate Genesis Block
echo "[3/7] Generating channel genesis block..."
mkdir -p organizations/channel-artifacts
configtxgen -profile TwoOrgsApplicationGenesis -outputBlock ./organizations/channel-artifacts/${CHANNEL_NAME}.block -channelID ${CHANNEL_NAME}

# 4. Start Docker Containers
echo "[4/7] Starting Fabric nodes via Docker Compose..."
docker compose -f docker-compose-fabric.yaml up -d

# Wait for nodes to initialize
sleep 5

# 5. Join Channel
echo "[5/7] Joining NUVTE peer to channel..."
export FABRIC_CFG_PATH=$PWD/organizations/peerOrganizations/nuvte.edu.ps
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="NuvteMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/nuvte.edu.ps/peers/peer0.nuvte.edu.ps/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/nuvte.edu.ps/users/Admin@nuvte.edu.ps/msp
export CORE_PEER_ADDRESS=localhost:7051

peer channel join -b ./organizations/channel-artifacts/${CHANNEL_NAME}.block

# 6. Package and Install Chaincode
echo "[6/7] Packaging and installing chaincode..."
peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz --path ./chaincode/ --lang golang --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION}
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz

export CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CHAINCODE_NAME}.tar.gz)
echo "Chaincode Package ID: ${CC_PACKAGE_ID}"

# Approve for NuvteOrg
peer lifecycle chaincode approveformyorg -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.pma.gov.ps \
  --channelID ${CHANNEL_NAME} \
  --name ${CHAINCODE_NAME} \
  --version ${CHAINCODE_VERSION} \
  --package-id ${CC_PACKAGE_ID} \
  --sequence ${CHAINCODE_SEQUENCE} \
  --tls \
  --cafile $PWD/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem

# Commit Chaincode
peer lifecycle chaincode commit -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.pma.gov.ps \
  --channelID ${CHANNEL_NAME} \
  --name ${CHAINCODE_NAME} \
  --version ${CHAINCODE_VERSION} \
  --sequence ${CHAINCODE_SEQUENCE} \
  --tls \
  --cafile $PWD/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem

# 7. Initialize BitstringStatusList2021
echo "[7/7] Initializing BitstringStatusList2021 registry on ledger..."
peer chaincode invoke -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.pma.gov.ps \
  --channelID ${CHANNEL_NAME} \
  --name ${CHAINCODE_NAME} \
  --tls \
  --cafile $PWD/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem \
  -c '{"function":"InitLedger","Args":[]}'

echo "=========================================================="
echo " PAL-DFI Hyperledger Fabric Network is READY!"
echo " Status List Bit capacity: 100,000 slots initialized"
echo " Channel: ${CHANNEL_NAME}"
echo "=========================================================="
```

Make executable and run:
```bash
chmod +x bootstrap_network.sh
./bootstrap_network.sh
```

---

## 2. Testing Queries via CLI

### Anchor a new document hash:
```bash
peer chaincode invoke -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.pma.gov.ps \
  --channelID nuvte-academic-channel \
  --name paldfi_contract \
  --tls \
  --cafile organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem \
  -c '{"function":"AnchorDocument","Args":["8f92ab381742ca9841f89c011e89f41","GraduationCertificate","hash-stu-2024098","42"]}'
```

### Query revocation bit (< 3.0s):
```bash
peer chaincode query \
  -C nuvte-academic-channel \
  -n paldfi_contract \
  -c '{"function":"CheckRevocationBit","Args":["42"]}'
```
Expected output:
```json
{"bitIndex":42,"isRevoked":false}
```
