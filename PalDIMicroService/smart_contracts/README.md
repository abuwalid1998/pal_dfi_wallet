# 📜 PAL-DI Sovereign Smart Contracts & Chaincode Repository
**Palestine Digital Inclusion (PAL-DI / SANAD) — Hyperledger Fabric v2.5 LTS**
**Operating under Palestine Monetary Authority (PMA) Regulatory Sandbox**

---

## 📁 Repository Structure

This directory stores all verified, no-code generated, and production-deployed Hyperledger Fabric smart contracts (Chaincodes) for the PAL-DI Consortium Network.

```
smart_contracts/
├── README.md                           # Architecture and lifecycle overview
├── academic_credentials/               # Higher Education & 5-Department Clearance
│   ├── contract.go                     # Go Smart Contract logic
│   ├── metadata.json                   # Channel, version, endorsement policies
│   └── deploy.ps1                      # Direct peer deployment script
├── land_registry/                      # Sovereign Land Deeds & Municipal Registry
│   ├── contract.go                     # Go Smart Contract logic
│   └── metadata.json                   # Metadata & schema definitions
├── banking_kyc/                        # Banking Gateway & Solvency Verification
│   ├── contract.go                     # Go Smart Contract logic
│   └── metadata.json                   # Metadata & schema definitions
└── health_clearance/                   # Confidential EHR & Emergency Health Pass
    ├── contract.go                     # Go Smart Contract logic
    └── metadata.json                   # Metadata & schema definitions
```

---

## ⚡ Chaincode Lifecycle Protocol (v2.x)

All smart contracts follow the 4-step Hyperledger Fabric Chaincode Lifecycle:

1. **Package**: Source code is bundled into a `.tar.gz` package with a deterministic SHA-256 Package ID.
   ```bash
   peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ./smart_contracts/${CC_NAME} --lang golang --label ${CC_NAME}_${CC_VERSION}
   ```

2. **Install**: The package is installed on the consortium peer nodes:
   - `peer0.nuvte.edu.ps:7051` (Academic & Technical Education Peer)
   - `peer0.bankofpalestine.ps:7051` (Financial Validation & Status Peer)

3. **Approve for My Org**: Each organization's MSP endorses the definition parameters:
   - Sequence number
   - Target Channel (`pal-sovereign-channel`)
   - Endorsement Policy (e.g., `AND('NUVTEMSP.peer', 'BOPMSP.peer')`)

4. **Commit Definition**: The PMA Raft Orderer Cluster (`orderer.pma.gov.ps:7050`) batches the consensus commit transaction once quorum is achieved.

---

## 🔒 Zero-PII Compliance Rule
Every smart contract adhering to the PAL-DI framework enforces the strict **Zero-PII On-Chain Policy**:
- No citizen plaintext names, national ID numbers, or biometric vectors may ever be stored on the ledger state DB.
- Only deterministic cryptographic hashes (SHA-256), blinded root digests, and Bitstring status flags (`0=Valid`, `1=Revoked`) are maintained on-chain.
