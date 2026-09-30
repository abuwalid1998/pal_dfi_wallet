# PAL-DFI Hyperledger Fabric 2.5 Blockchain Trust Layer
## Controlled Academic Pilot at Nablus University for Vocational & Technical Education (NUVTE)
### Under Palestine Monetary Authority (PMA) Regulatory Sandbox Guidelines

This directory contains the architecture, setup instructions, chaincode smart contracts, management roles, and deployment scripts for the **Hyperledger Fabric 2.5** blockchain network powering the **Palestinian Decentralized Financial Identity Network (PAL-DFI)**.

---

## 1. Architectural Philosophy: Strict Zero On-Chain PII

```
      ISSUER (NUVTE Registrar)                  HOLDER (Student Wallet)
   ┌──────────────────────────────┐          ┌───────────────────────────┐
   │ University SIS Database      │          │ Local Hardware Key Vault  │
   │ Full Student PII (Off-Chain) │          │ AES-256 Encrypted VCs     │
   └──────────────┬───────────────┘          └─────────────┬─────────────┘
                  │                                        │
                  │ SHA-256 Hash +                         │ Dynamic OpenID4VP
                  │ Bit Index (No PII)                     │ Presentation QR
                  ▼                                        ▼
   ┌─────────────────────────────────────────────────────────────────────┐
   │             HYPERLEDGER FABRIC 2.5 BLOCKCHAIN TRUST LAYER           │
   │  - Channel: nuvte-academic-channel                                  │
   │  - Smart Contract: BitstringStatusList2021 & Document Anchoring     │
   │  - Stored Data: SHA-256 hashes, Issuer PKI certs, Bitstring status  │
   │  - ZERO BYTES OF STUDENT PII STORED ON LEDGER                      │
   └───────────────────────────────────┬─────────────────────────────────┘
                                       ▲
                                       │ Real-time Query (< 3.0s)
                                       │
                             VERIFIER / THIRD PARTY
                        ┌──────────────────────────────┐
                        │ Bank of Palestine / PalTel   │
                        │ Signature & Ledger Check     │
                        └──────────────────────────────┘
```

---

| Document / Script | Purpose |
| :--- | :--- |
| [`deploy_blockchain_and_explorer.ps1`](./deploy_blockchain_and_explorer.ps1) | **Automated 1-Click PowerShell Runner**: Generates crypto, genesis block, boots Fabric 2.5 nodes, joins channel, deploys smart contract, and launches Hyperledger Explorer |
| [`crypto-config.yaml`](./crypto-config.yaml) | Cryptogen configuration for PMA Orderer and NUVTE Peer MSP |
| [`configtx.yaml`](./configtx.yaml) | Consortium channel genesis block profile `TwoOrgsApplicationGenesis` |
| [`docker-compose-fabric.yaml`](./docker-compose-fabric.yaml) | Core Fabric nodes: PMA Orderer (7050), NUVTE Peer (7051), CA (7054) |
| [`explorer/`](./explorer) | Hyperledger Explorer web dashboard & PostgreSQL container config (Port 8090) |
| [`chaincode/paldfi_contract.go`](./chaincode/paldfi_contract.go) | Go smart contract implementation of `BitstringStatusList2021` |
| [`01_prerequisites_and_environment.md`](./01_prerequisites_and_environment.md) | System requirements, Docker, Go, and Fabric binary installation |
| [`02_network_topology_and_msp.md`](./02_network_topology_and_msp.md) | Consortium topology, PMA Orderer, NUVTE Peer, MSP cryptogen |
| [`03_smart_contract_chaincode.md`](./03_smart_contract_chaincode.md) | Smart contract specification and methods |
| [`04_management_roles_and_rbac.md`](./04_management_roles_and_rbac.md) | University Management roles (Registrar, Deans, Auditor, PMA Observer) |
| [`05_deployment_and_bootstrap_scripts.md`](./05_deployment_and_bootstrap_scripts.md) | Bash equivalent terminal execution guide (`bootstrap_network.sh`) |

---

## ⚡ 1-Click Automated PowerShell Quickstart

To initialize the entire blockchain, join channels, deploy smart contracts, and start Hyperledger Explorer in one command:

```powershell
# From project root:
.\deploy_blockchain_and_explorer.ps1

# Or from inside blockchain_deployment directory:
cd blockchain_deployment
.\deploy_blockchain_and_explorer.ps1
```

### Script Options:
```powershell
# Check running containers and node health:
.\deploy_blockchain_and_explorer.ps1 -Action Status

# Stop all containers:
.\deploy_blockchain_and_explorer.ps1 -Action Stop

# Clean up all containers, volumes, certificates, and reset to zero state:
.\deploy_blockchain_and_explorer.ps1 -Action Clean

# Custom Explorer port:
.\deploy_blockchain_and_explorer.ps1 -ExplorerPort 8095
```

### 🌐 Accessing Hyperledger Explorer
Once running, open your browser:
- **URL**: `http://localhost:8090`
- **Username**: `admin`
- **Password**: `password`

---

## 3. High-Level Flow Summary

1. **Document Issuance**: NUVTE Registrar generates a signed W3C Verifiable Credential 2.0 (Student ID, Graduation Diploma, or Clearance Certificate). The SHA-256 hash is anchored on the `nuvte-academic-channel`, and its status bit is marked `0` (Active).
2. **Third-Party Request**: A third party (e.g. Bank of Palestine) requests a document from the student.
3. **Student Authorization**: Student decrypts the credential from their local vault and generates a time-bounded OpenID4VP presentation with a fresh nonce.
4. **Blockchain Verification**: Verifier queries `CheckRevocationStatus(bitIndex)` on the Fabric peer and validates the signature against NUVTE's public PKI certificate in < 3.0 seconds.
