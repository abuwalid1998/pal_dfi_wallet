# 02 - Network Topology & Membership Service Providers (MSP)

This document outlines the consortium topology and cryptographic PKI setup for the PAL-DFI network under the Palestine Monetary Authority (PMA) sandbox.

---

## 1. Consortium Topology

The pilot network consists of 3 organizations connected to a Raft consensus ordering cluster:

```
                          ┌───────────────────────────┐
                          │     OrdererOrg (PMA)      │
                          │  orderer.pma.gov.ps:7050  │
                          │  Raft Consensus Service   │
                          └─────────────┬─────────────┘
                                        │
                      nuvte-academic-channel (TLS 1.3)
                                        │
           ┌────────────────────────────┴───────────────────────────┐
           │                                                        │
           ▼                                                        ▼
┌──────────────────────────────┐              ┌──────────────────────────────┐
│        NuvteOrg (MSP)        │              │       VerifierOrg (MSP)      │
│     Academic Issuer Node     │              │     External Verifier Node   │
│   peer0.nuvte.edu.ps:7051    │              │  peer0.verifier.paldfi.ps:9051│
│  ca.nuvte.edu.ps:7054 (CA)   │              │ ca.verifier.paldfi.ps:8054(CA)│
└──────────────────────────────┘              └──────────────────────────────┘
```

---

## 2. Organization Specifications

| Organization | Domain | MSP ID | Node Role | Responsibilities |
| :--- | :--- | :--- | :--- | :--- |
| **PMA Orderer** | `pma.gov.ps` | `PmaOrdererMSP` | Ordering Node (Raft) | Block creation, transaction sequencing, consortium governance |
| **NUVTE Academic** | `nuvte.edu.ps` | `NuvteMSP` | Peer & Fabric CA | Academic document anchor commits, revocation bit management |
| **Verifier Org** | `verifier.paldfi.ps` | `VerifierMSP` | Peer & Fabric CA | External third-party read-only verification queries (< 3.0s) |

---

## 3. Cryptographic Generator Configuration (`crypto-config.yaml`)

Save this file as `crypto-config.yaml` to generate the X.509 certificates and keys:

```yaml
OrdererOrgs:
  - Name: PMAOrderer
    Domain: pma.gov.ps
    EnableNodeOUs: true
    Specs:
      - Hostname: orderer

PeerOrgs:
  - Name: NuvteOrg
    Domain: nuvte.edu.ps
    EnableNodeOUs: true
    Template:
      Count: 1
    Users:
      Count: 2 # RegistrarAdmin, AcademicDean

  - Name: VerifierOrg
    Domain: verifier.paldfi.ps
    EnableNodeOUs: true
    Template:
      Count: 1
    Users:
      Count: 1 # ComplianceAuditor
```

Generate credentials using `cryptogen`:
```bash
cryptogen generate --config=./crypto-config.yaml --output="organizations"
```

---

## 4. Channel Configuration (`configtx.yaml`)

Define the consortium channel profile `NuvteAcademicChannel`:

```yaml
---
Organizations:
  - &PMAOrderer
    Name: PMAOrderer
    ID: PMAOrdererMSP
    MSPDir: organizations/ordererOrganizations/pma.gov.ps/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('PMAOrdererMSP.member')"
      Writers:
        Type: Signature
        Rule: "OR('PMAOrdererMSP.member')"
      Admins:
        Type: Signature
        Rule: "OR('PMAOrdererMSP.admin')"

  - &NuvteOrg
    Name: NuvteOrg
    ID: NuvteMSP
    MSPDir: organizations/peerOrganizations/nuvte.edu.ps/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('NuvteMSP.admin', 'NuvteMSP.peer', 'NuvteMSP.client')"
      Writers:
        Type: Signature
        Rule: "OR('NuvteMSP.admin', 'NuvteMSP.client')"
      Admins:
        Type: Signature
        Rule: "OR('NuvteMSP.admin')"
      Endorsement:
        Type: Signature
        Rule: "OR('NuvteMSP.peer')"

  - &VerifierOrg
    Name: VerifierOrg
    ID: VerifierMSP
    MSPDir: organizations/peerOrganizations/verifier.paldfi.ps/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('VerifierMSP.admin', 'VerifierMSP.peer', 'VerifierMSP.client')"
      Writers:
        Type: Signature
        Rule: "OR('VerifierMSP.admin')"
      Admins:
        Type: Signature
        Rule: "OR('VerifierMSP.admin')"
      Endorsement:
        Type: Signature
        Rule: "OR('VerifierMSP.peer')"

Capabilities:
  Channel: &ChannelCapabilities
    V2_0: true
  Orderer: &OrdererCapabilities
    V2_0: true
  Application: &ApplicationCapabilities
    V2_5: true

Profiles:
  TwoOrgsApplicationGenesis:
    <<: *ChannelDefaults
    Orderer:
      <<: *OrdererDefaults
      OrdererType: etcdraft
      Organizations:
        - *PMAOrderer
      Capabilities: *OrdererCapabilities
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *NuvteOrg
        - *VerifierOrg
      Capabilities: *ApplicationCapabilities
```
