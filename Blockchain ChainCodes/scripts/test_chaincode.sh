#!/bin/bash
set -e

CHANNEL_NAME=${1:-nuvte-academic-channel}
CHAINCODE_NAME=${2:-paldfi_academic_contract}

echo "=================================================================="
echo "  Testing Smart Contract: ${CHAINCODE_NAME} on ${CHANNEL_NAME}"
echo "=================================================================="

# 1. Query Official Graduation Certificate Anchor
echo "==> [Test 1/3] Querying Graduation Certificate (DOC-NUVTE-2024-GRAD-098)..."
peer chaincode query \
    -C ${CHANNEL_NAME} \
    -n ${CHAINCODE_NAME} \
    -c '{"function":"GetDocument","Args":["DOC-NUVTE-2024-GRAD-098"]}'
echo ""

# 2. Verify Document cryptographic hash & unrevoked status
echo "==> [Test 2/4] Verifying Document Authenticity via SHA-256 Digest Match..."
peer chaincode query \
    -C ${CHANNEL_NAME} \
    -n ${CHAINCODE_NAME} \
    -c '{"function":"VerifyDocument","Args":["DOC-NUVTE-2024-GRAD-098","07d7f05362c14b9b3e4566a66e413fb9a59e792324449238fdb3216b8048e98c"]}'
echo ""

# 3. Query W3C Bitstring Status Bit (Index 102)
echo "==> [Test 3/4] Querying W3C BitstringStatusList2021 (Bit 102 - false=Valid)..."
peer chaincode query \
    -C ${CHANNEL_NAME} \
    -n ${CHAINCODE_NAME} \
    -c '{"function":"GetStatusBit","Args":["nuvte-status-list-2024","102"]}'
echo ""

# 4. Record Third-Party Verification Audit on Ledger
AUDIT_ID="AUDIT-BOP-$(date +%s)"
echo "==> [Test 4/4] Recording Third-Party Audit (${AUDIT_ID})..."
peer chaincode invoke -o orderer.pma.gov.ps:7050 \
    --ordererTLSHostnameOverride orderer.pma.gov.ps \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --tls \
    --cafile /workspace/deploy/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem \
    --waitForEvent \
    -c "{\"function\":\"RecordVerificationAudit\",\"Args\":[\"${AUDIT_ID}\",\"did:key:z6MkuBankOfPalestineCompliance\",\"Bank of Palestine (Compliance/HR)\",\"DOC-NUVTE-2024-GRAD-098\",\"did:key:z6MkuStudentAmjadKhaliliah\",\"nonce-99214\",\"VALID\"]}"
echo ""

# 5. Read back the audit record
echo "==> [Verification] Reading Audit Record ${AUDIT_ID} from Ledger..."
peer chaincode query \
    -C ${CHANNEL_NAME} \
    -n ${CHAINCODE_NAME} \
    -c "{\"function\":\"GetVerificationAudit\",\"Args\":[\"${AUDIT_ID}\"]}"
echo ""

echo "=================================================================="
echo "  All on-chain smart contract tests completed successfully!"
echo "=================================================================="
