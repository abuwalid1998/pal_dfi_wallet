# PAL-DFI System Architecture: Current vs. Target Microservices

**Palestinian Decentralized Financial Identity & Sovereign Academic Wallet (PAL-DFI)**  
*Controlled Academic Pilot at Nablus University for Vocational and Technical Education (NUVTE)*  
*Operating under Palestine Monetary Authority (PMA) Regulatory Sandbox Guidelines*

---

## 📌 Executive Summary

The **PAL-DFI (Palestine Decentralized Financial Identity)** platform enables self-sovereign, cryptographically verifiable academic credentials and biometric identity verification for Palestinian university students, financial institutions, and government authorities.

This document details:
1. **The Current Architecture (As-Is)**: A hybrid prototype featuring a Flutter client, a browser-based FacePal simulator, file-based JSON registries, and standalone Python utility servers.
2. **The Target Microservices Architecture (To-Be)**: A decoupled, enterprise-grade distributed microservices architecture adhering to cloud-native standards (Domain-Driven Design, Database-per-Service, Event-Driven Messaging, Zero-PII on-chain, and Kubernetes orchestration).

---

## 🏛️ 1. Current Architecture (As-Is)

### 1.1 Overview & Topology
The current deployment functions as a **two-tier / monolithic-hybrid setup**:
- **Client Layer**: A Flutter mobile/desktop application alongside an in-browser interactive simulator (`index.html`, `app.js`, `style.css`) hosting face-api.js neural networks, camera capture HUD, noise cancellation algorithms, and simulated biometric enclave logic in `localStorage`.
- **Ad-Hoc Backend Scripts**:
  - `blockchain_gateway/server.py` (Port `5050`): A standalone Python `http.server` script that interfaces with Hyperledger Fabric CLI containers or falls back to a flat-file JSON registry (`gateway_registry.json`).
  - `face_recognition_service/server.py` (Port `5060`): A Python `http.server` script executing CPU-bound cosine similarity searches against a flat-file vector database (`vector_db.json`).
- **Blockchain Layer**: Hyperledger Fabric 2.5 consortium network running peers for PMA (`pma.gov.ps`), NUVTE (`nuvte.edu.ps`), and Bank of Palestine (`bankofpalestine.ps`).

### 1.2 Current Architecture Diagram (Mermaid)

```mermaid
graph TD
    subgraph ClientLayer["🖥️ Client & Presentation Layer"]
        FLUTTER["Flutter Mobile / Web App<br/>(Dart 3.x Client)"]
        WEB_SIM["Browser Simulator & FacePal<br/>(index.html / app.js / style.css)"]
        BROWSER_STORAGE[("Browser LocalStorage<br/>(Client Enclave Simulator)")]
        WEB_SIM <--> BROWSER_STORAGE
    end

    subgraph BackendScripts["⚙️ Current Backend Scripts (Monolithic / Ad-Hoc)"]
        subgraph GatewayScript["Port :5050 (Single Process)"]
            BC_SERVER["blockchain_gateway/server.py<br/>(Python http.server)"]
            JSON_REG[("gateway_registry.json<br/>(Flat File Document Registry)")]
            BC_SERVER <--> JSON_REG
        end

        subgraph FaceScript["Port :5060 (Single Process)"]
            FACE_SERVER["face_recognition_service/server.py<br/>(Python http.server)"]
            VECTOR_DB[("vector_db.json<br/>(Flat File 128-D Vector DB)")]
            FACE_SERVER <--> VECTOR_DB
        end
    end

    subgraph BlockchainNetwork["⛓️ Hyperledger Fabric 2.5 Consortium"]
        FABRIC_CLI["Fabric CLI Container<br/>(paldfi_fabric_cli)"]
        PEER_NUVTE["Peer: NUVTE<br/>(nuvte.edu.ps)"]
        PEER_PMA["Peer: PMA Orderer/Peer<br/>(pma.gov.ps)"]
        PEER_BANK["Peer: Bank of Palestine<br/>(bankofpalestine.ps)"]
        CHAINCODE["Smart Contract: paldfi_academic_contract<br/>(BitstringStatusList2021)"]
    end

    FLUTTER -- "HTTP (Port :5050)" --> BC_SERVER
    FLUTTER -- "HTTP (Port :5060)" --> FACE_SERVER
    WEB_SIM -- "In-Memory / Local Fetch" --> BC_SERVER

    BC_SERVER -- "CLI exec / docker exec" --> FABRIC_CLI
    FABRIC_CLI -- "gRPC" --> PEER_NUVTE
    FABRIC_CLI -- "gRPC" --> PEER_PMA
    FABRIC_CLI -- "gRPC" --> PEER_BANK
    PEER_NUVTE --- CHAINCODE
```

### 1.3 Key Limitations of the Current Architecture

| Dimension | Current Implementation | Bottlenecks & Architectural Risks |
| :--- | :--- | :--- |
| **Concurrency & Threading** | Single-threaded Python `http.server` | Blocks during heavy I/O or vector similarity calculations; prone to denial of service under multi-user traffic. |
| **State Persistence** | Flat-file JSON (`vector_db.json`, `gateway_registry.json`) | No ACID transactions, risk of race-condition file corruption, lacks indexing, cannot scale past thousands of records. |
| **Coupling** | Monolithic responsibilities in `server.py` | Blockchain gateway handles document issuance, identity verification, institution records, and CLI orchestration in one file. |
| **Security & Auth** | Ad-hoc token and secret checks | Lacks a centralized API Gateway, rate-limiting, WAF, OAuth2/OIDC token exchange, and mutual TLS between services. |
| **Zero-Knowledge Proofs (ZKP)** | Client-side simulation in `app.js` | Off-chain credential proofs are simulated rather than mathematically backed by Circom/SnarkJS or Bulletproofs verifiers. |
| **Service Discovery & Scalability** | Hardcoded `localhost:5050` and `localhost:5060` | No service registry, horizontal pod autoscaling, health checks, or container cluster orchestration. |

---

## 🚀 2. Target Microservices Architecture (To-Be)

### 2.1 Design Principles & Domain Decomposition
The target architecture divides the platform into discrete, independently deployable microservices organized around **Domain-Driven Design (DDD)** boundaries:

1. **API Gateway & Edge Router**: Single unified ingress with mTLS, JWT authorization, rate limiting, and request routing.
2. **PMA ID+ Auth & Sovereign Identity Service**: OIDC/OAuth 2.0 PKCE gateway, national digital identity lifecycle, and DID resolution (`did:paldfi`).
3. **Biometric Face Vector & AI Inference Service**: Denoised facial normalization (5x5 Gaussian + CLAHE), ResNet/FaceNet embedding inference, and high-performance vector search (Milvus/Qdrant).
4. **W3C Verifiable Credential Lifecycle Service**: Issues, validates, and manages cryptographic signatures (Ed25519/ECDSA) for Academic IDs, Graduation Diplomas, and Discharge Clearances.
5. **Zero-Knowledge Proof & Privacy Engine**: Compiles and verifies cryptographic ZK-SNARK proofs for selective credential disclosure without leaking PII.
6. **Hyperledger Fabric Blockchain Gateway Service**: Enterprise gRPC connection pool to Fabric peers, consensus orchestration, and `BitstringStatusList2021` anchor management.
7. **Event Broker / Messaging Fabric**: Asynchronous event dissemination (Kafka / RabbitMQ) for cross-service workflow decoupling.
8. **Audit & Regulatory Compliance Service**: PMA Sandbox audit trail, regulatory telemetry, and immutable logging.

---

### 2.2 Target Microservices Architecture Diagram (Mermaid)

```mermaid
graph TB
    subgraph Clients["📱 Client Ingress Layer"]
        MOBILE["Flutter Mobile Wallet<br/>(iOS & Android)"]
        WEB_PORTAL["NUVTE Student/Admin Portal<br/>(Web Client)"]
        VERIFIER_PORTAL["Third-Party Verifier Portal<br/>(Bank of Palestine / Employers)"]
    end

    subgraph EdgeLayer["🛡️ Edge & Security Layer"]
        WAF["Cloudflare / Envoy Edge WAF"]
        APIGW["Kong / Envoy API Gateway<br/>(mTLS, Rate Limit, CORS, OAuth2 JWT Guard)"]
        WAF --> APIGW
    end

    subgraph MicroservicesLayer["🧩 Autonomous Core Microservices"]
        AUTH_SVC["🔐 Auth & PMA ID+ Identity Service<br/>(OIDC, DID Resolution did:paldfi)"]
        BIO_SVC["🧬 Biometric & Vector AI Service<br/>(Denoising, TensorRT, 128-D Extraction)"]
        VC_SVC["📜 W3C Credential Lifecycle Service<br/>(Issuance, Signing, W3C VC 2.0 Engine)"]
        ZKP_SVC["🛡️ ZKP & Privacy Engine<br/>(SnarkJS / Circom Verifier, Selective Disclosure)"]
        FABRIC_GW["⛓️ Hyperledger Fabric Gateway Service<br/>(gRPC Connection Pool, Event Listeners)"]
        NOTIF_SVC["🔔 Push Notification Service<br/>(FCM, Apple APNs, SMS Gateway)"]
        AUDIT_SVC["📊 PMA Compliance & Audit Service<br/>(Sandbox Telemetry, Zero-PII Logs)"]
    end

    subgraph EventMesh["⚡ Asynchronous Event Broker (Message Bus)"]
        KAFKA["Apache Kafka / RabbitMQ Event Mesh<br/>Topics: credential.issued, face.enrolled, status.revoked, verification.requested"]
    end

    subgraph DataLayer["💾 Dedicated Microservice Data Stores (Database-per-Service)"]
        AUTH_DB[("PostgreSQL<br/>(Identities & Sessions)")]
        VECTOR_DB_NEW[("Qdrant / Milvus Vector DB<br/>(128-D Biometric Embeddings)")]
        VC_DB[("PostgreSQL + Vault<br/>(Credentials & PKI Keys)")]
        ZKP_STORE[("Redis Cache<br/>(ZKP Verification Keys & Nonces)")]
        AUDIT_DB[("TimescaleDB / ClickHouse<br/>(Regulatory Audit Logs)")]
    end

    subgraph BlockchainNetwork["⛓️ Hyperledger Fabric 2.5 Consortium (On-Chain Trust Anchor)"]
        ORDERER["PMA Raft Orderer Node<br/>(orderer.pma.gov.ps)"]
        NUVTE_PEER["NUVTE Peer Node<br/>(peer0.nuvte.edu.ps)"]
        BANK_PEER["Bank Peer Node<br/>(peer0.bankofpalestine.ps)"]
        PMA_PEER["PMA Peer Node<br/>(peer0.pma.gov.ps)"]
        SMART_CONTRACT["Chaincode: BitstringStatusList2021<br/>(SHA-256 Hashes, Revocation Bits)"]
    end

    %% Client Routing
    MOBILE --> WAF
    WEB_PORTAL --> WAF
    VERIFIER_PORTAL --> WAF
    APIGW --> AUTH_SVC
    APIGW --> BIO_SVC
    APIGW --> VC_SVC
    APIGW --> ZKP_SVC
    APIGW --> FABRIC_GW

    %% Service to Dedicated Database Links
    AUTH_SVC --> AUTH_DB
    BIO_SVC --> VECTOR_DB_NEW
    VC_SVC --> VC_DB
    ZKP_SVC --> ZKP_STORE
    AUDIT_SVC --> AUDIT_DB

    %% Event Bus Integration
    AUTH_SVC -.-> |"Publish: identity.created"| KAFKA
    BIO_SVC -.-> |"Publish: face.enrolled"| KAFKA
    VC_SVC -.-> |"Publish: credential.issued"| KAFKA
    FABRIC_GW -.-> |"Publish: block.committed"| KAFKA
    KAFKA -.-> |"Subscribe"| NOTIF_SVC
    KAFKA -.-> |"Subscribe"| AUDIT_SVC
    KAFKA -.-> |"Subscribe"| FABRIC_GW

    %% Blockchain Integration
    FABRIC_GW -- "gRPC (Connection Profile)" --> NUVTE_PEER
    FABRIC_GW -- "gRPC (Connection Profile)" --> BANK_PEER
    FABRIC_GW -- "gRPC (Connection Profile)" --> PMA_PEER
    NUVTE_PEER --- SMART_CONTRACT
    BANK_PEER --- SMART_CONTRACT
    PMA_PEER --- SMART_CONTRACT
    ORDERER --- NUVTE_PEER
    ORDERER --- BANK_PEER
    ORDERER --- PMA_PEER

    %% Inter-Service Secure RPC
    VC_SVC -- "gRPC (Verify Face Proof)" --> BIO_SVC
    VC_SVC -- "gRPC (Anchor Hash)" --> FABRIC_GW
    ZKP_SVC -- "gRPC (Check Revocation Bit)" --> FABRIC_GW
```

---

## 📦 3. Microservice Specifications & Responsibility Matrix

### 3.1 Service Catalog

```
                               ┌────────────────────────┐
                               │     API Gateway        │
                               └───────────┬────────────┘
                                           │
         ┌───────────────┬─────────────────┼─────────────────┬───────────────┐
         ▼               ▼                 ▼                 ▼               ▼
┌─────────────────┐ ┌───────────────┐ ┌────────────────┐ ┌───────────────┐ ┌────────────────┐
│  Auth & PMA ID+ │ │ Biometrics AI │ │  VC Lifecycle  │ │  ZKP Privacy  │ │ Fabric Gateway │
│     Service     │ │   & Vector DB │ │    Service     │ │    Engine     │ │    Service     │
└────────┬────────┘ └───────┬───────┘ └────────┬───────┘ └───────┬───────┘ └────────┬───────┘
         │                  │                  │                 │                  │
   [PostgreSQL]       [Qdrant/Milvus]    [PostgreSQL+KV]      [Redis]           [Fabric gRPC]
```

#### 1. API Gateway Service (`paldfi-api-gateway`)
- **Technology**: Envoy Proxy / Kong Gateway
- **Port**: `443` (External) / `8000` (Internal)
- **Responsibilities**:
  - SSL/TLS Termination and mTLS for enterprise consumers.
  - JWT Authentication verification (ID+ access tokens).
  - Rate limiting, IP throttling, and DDoS protection.
  - Semantic routing to downstream microservices.
  - Centralized CORS and security headers configuration.

#### 2. Auth & PMA ID+ Identity Service (`paldfi-auth-service`)
- **Technology**: Go (Golang) / Node.js NestJS
- **Port**: `8001`
- **Database**: PostgreSQL (Identities, roles, sessions)
- **Responsibilities**:
  - PMA ID+ OAuth 2.0 PKCE / OIDC integration.
  - Persona management: Student, University Admin, Verifier Bank.
  - Decentralized Identifier (`did:paldfi:citizen:<id>`) document creation and management.
  - Secure session token issuance and refresh rotation.

#### 3. Biometric & Vector AI Service (`paldfi-biometrics-service`)
- **Technology**: Python (FastAPI, PyTorch / ONNX Runtime / TensorRT)
- **Port**: `8002`
- **Database**: Qdrant / Milvus Vector Database (128-D / 512-D vectors) + Local NVMe Cache
- **Responsibilities**:
  - Multi-stage image noise cancellation (canonical 160×160 alignment, 5×5 spatial Gaussian smoothing, CLAHE histogram equalization).
  - Deterministic invariant vector extraction from facial landmark geometry.
  - High-throughput sub-millisecond Cosine and Euclidean vector similarity search.
  - Hardware Enclave biometric key synthesis (`PAL-FP-XXXX-XXXX-XXXX-XXXX`).

#### 4. W3C Credential Lifecycle Service (`paldfi-credential-service`)
- **Technology**: TypeScript / Node.js (W3C VC 2.0, DIDKit)
- **Port**: `8003`
- **Database**: PostgreSQL (Metadata, non-PII indices) + HashiCorp Vault (PKI Signing Keys)
- **Responsibilities**:
  - Issuance of the 3 Official Academic Credentials:
    1. Digital Student ID Card (`StudentIdentityCredential`)
    2. Official Graduation Certificate (`GraduationCertificateCredential`)
    3. Clearance / Discharge Certificate (`ClearanceCertificateCredential`)
  - Cryptographic digital signing (ECDSA secp256k1 / Ed25519).
  - Generating and serving credential status bit indexes.
  - Zero on-chain PII: Hashes and anchors SHA-256 fingerprint on blockchain.

#### 5. ZKP & Privacy Engine (`paldfi-zkp-service`)
- **Technology**: Rust / Node.js (Circom, SnarkJS, Arkworks)
- **Port**: `8004`
- **Database**: Redis (Verification keys, challenge nonces, replay cache)
- **Responsibilities**:
  - Verifies zero-knowledge proofs for selective attribute disclosure:
    - Age / Enrolled verification without revealing DOB.
    - Financial clearance verification without revealing account balances.
    - Honors status without revealing individual course grades.
  - OpenID4VP dynamic challenge-response nonce generation.

#### 6. Hyperledger Fabric Gateway Service (`paldfi-fabric-gateway`)
- **Technology**: Node.js / Go (Hyperledger Fabric Gateway SDK v2.5+)
- **Port**: `8005`
- **Connectivity**: gRPC to Peer Nodes (`pma.gov.ps`, `nuvte.edu.ps`, `bankofpalestine.ps`)
- **Responsibilities**:
  - Maintains gRPC connection pools with TLS certificates to all consortium peers.
  - Transaction proposal, endorser consensus gathering, and commit status tracking.
  - Interacting with `BitstringStatusList2021` for real-time revocation queries (< 300ms).
  - Chaincode event listening and message bus dispatching (`block.committed`).

#### 7. Audit & Regulatory Telemetry Service (`paldfi-audit-service`)
- **Technology**: Python / Go
- **Port**: `8006`
- **Database**: TimescaleDB / ClickHouse (Time-series audit trail)
- **Responsibilities**:
  - Real-time compliance monitoring under PMA Regulatory Sandbox rules.
  - Tracks verification frequency, latency, throughput, and error rates.
  - Prometheus metric exporter & OpenTelemetry distributed tracing spans.

---

### 3.2 Inter-Service Communication Protocols

| Communication Path | Mechanism | Protocol | SLA / Target Latency |
| :--- | :--- | :--- | :--- |
| **Client ➔ API Gateway** | Synchronous | HTTPS / JSON / WebSocket | < 120 ms |
| **Gateway ➔ Microservices** | Synchronous | HTTP/2 / gRPC | < 15 ms |
| **Credential Svc ➔ Biometric Svc** | Synchronous RPC | gRPC (Protobuf) | < 25 ms |
| **Credential Svc ➔ Fabric Gateway** | Synchronous RPC | gRPC (Protobuf) | < 800 ms (Consensus) |
| **ZKP Svc ➔ Fabric Gateway** | Read-Only Cache + gRPC | Redis + gRPC Query | < 45 ms |
| **Event Broadcasting** | Asynchronous Pub/Sub | Apache Kafka (Event Mesh) | < 10 ms (P99) |
| **Fabric Gateway ➔ Peers** | Peer Consensus | gRPC over Mutual TLS | < 1.5 s (Endorsement) |

---

## 🔄 4. End-to-End Workflow & Data Flow (Microservices)

### 4.1 Document Issuance by University Management

```mermaid
sequenceDiagram
    autonumber
    actor Issuer as 🏛️ University Registrar
    participant Portal as Web Admin Portal
    participant APIGW as API Gateway
    participant Auth as Auth & ID Service
    participant VC as Credential Service
    participant FabricGW as Fabric Gateway
    participant Kafka as Event Bus
    participant Peer as NUVTE Fabric Peer
    actor Student as 🎓 Student Wallet

    Issuer->>Portal: Issue Graduation Certificate (Student: STU-1082)
    Portal->>APIGW: POST /api/v1/credentials/issue
    APIGW->>Auth: Validate Registrar JWT Token & Role
    Auth-->>APIGW: Token Verified (Role: Registrar)
    APIGW->>VC: Dispatch Issuance Request
    VC->>VC: Construct W3C VC 2.0 Payload
    VC->>VC: Sign with NUVTE Private Key (Vault)
    VC->>VC: Compute SHA-256 Digest (Zero PII)
    VC->>FabricGW: gRPC AnchorCredentialHash(hash, bitIndex)
    FabricGW->>Peer: Submit Transaction (Endorsement)
    Peer-->>FabricGW: Block Committed (TxID: 0x9f8...)
    FabricGW-->>VC: Success (TxID, BlockNumber)
    VC->>Kafka: Publish "credential.issued" Event
    Kafka->>Student: Push Notification (New Credential in Wallet)
    VC-->>APIGW: Return Signed W3C VC JSON-LD
    APIGW-->>Portal: 201 Created (Credential Anchored)
```

### 4.2 3-Step Verification by Third Party (Bank / Employer)

```mermaid
sequenceDiagram
    autonumber
    actor Verifier as 🏢 Bank of Palestine
    actor Student as 🎓 Student Mobile Wallet
    participant APIGW as API Gateway
    participant ZKP as ZKP & Privacy Engine
    participant FabricGW as Fabric Gateway
    participant Peer as Consortium Fabric Peers

    Verifier->>Student: Present OpenID4VP Verification Request (Nonce, Required Claims)
    Student->>Student: Biometric Unlock (FacePal Oval Reticle + 128-D Match)
    Student->>Student: Generate ZKP Proof (Honors: Yes, Clearance: True | No Grades Disclosed)
    Student->>Verifier: Return Verifiable Presentation (VP) + ZKP Token
    Verifier->>APIGW: POST /api/v1/verify/presentation
    APIGW->>ZKP: Verify Cryptographic Proof
    ZKP->>ZKP: Verify Proof Equations (zk-SNARK verify)
    ZKP->>FabricGW: Check Revocation Status(bitIndex)
    FabricGW->>Peer: Query BitstringStatusList2021
    Peer-->>FabricGW: Status: 0 (Active & Valid)
    FabricGW-->>ZKP: Revocation Check Passed
    ZKP-->>APIGW: Verification Result: VALID (Zero PII Exposed)
    APIGW-->>Verifier: 200 OK (Authenticated & Verified in < 1.8s)
```

---

## 🔒 5. Zero-PII Security & Privacy Guarantee

1. **Strict Zero On-Chain PII**:
   - No names, national IDs, grades, or biometric descriptors are stored on Hyperledger Fabric ledger blocks.
   - Only cryptographic digests (`SHA-256(Canonical_VC)`) and revocation status bits in `BitstringStatusList2021` are anchored on the blockchain.
2. **Biometric Enclave Isolation**:
   - The Biometric Service extracts normalized 128-D vectors. Raw biometric images are discarded immediately after embedding derivation.
   - Vector matching operates against isolated vector databases encrypted at rest using AES-256.
3. **Decentralized Key Custody**:
   - Private keys for students are stored within hardware security modules (Secure Enclave on iOS / StrongBox KeyStore on Android).
   - University signing keys are protected by enterprise HashiCorp Vault instances with strict quorum access.

---

## 🗺️ 6. Implementation & Migration Roadmap

```mermaid
gantt
    title PAL-DFI Microservices Transformation Roadmap
    dateFormat  YYYY-MM-DD
    section Phase 1: Foundation
    Containerize Current Services (Docker/Compose)   :p1_1, 2026-10-15, 14d
    Deploy API Gateway (Kong / Envoy)                :p1_2, after p1_1, 14d
    Establish PostgreSQL & Qdrant Data Stores        :p1_3, after p1_1, 14d

    section Phase 2: Decoupling
    Extract Auth & PMA ID+ Microservice              :p2_1, after p1_2, 21d
    Extract Biometric AI & Vector Search Service     :p2_2, after p1_3, 21d
    Refactor Fabric Gateway to gRPC Pool             :p2_3, after p2_1, 21d

    section Phase 3: Privacy & Events
    Implement Kafka Event Mesh                       :p3_1, after p2_2, 14d
    Deploy ZKP & Selective Disclosure Engine         :p3_2, after p3_1, 28d
    Integrate W3C VC 2.0 Lifecycle Service           :p3_3, after p3_1, 21d

    section Phase 4: Production Cloud
    Kubernetes Helm Charts & Orchestration           :p4_1, after p3_2, 21d
    PMA Sandbox Security & Load Stress Audit         :p4_2, after p4_1, 14d
    Production Multi-Region Cutover                  :p4_3, after p4_2, 7d
```

### Detailed Phase Milestones

- **Phase 1: Foundation & Gateway (Weeks 1–4)**
  - Transition from standalone `.py` scripts to production Docker containers with multi-stage builds.
  - Place Kong/Envoy API Gateway in front of existing services to standardize URLs and terminate TLS.
  - Migrate flat JSON files (`gateway_registry.json`, `vector_db.json`) to PostgreSQL and Qdrant.

- **Phase 2: Domain Decomposition (Weeks 5–8)**
  - Isolate PMA ID+ authentication into an independent OIDC service.
  - Refactor `face_recognition_service` to expose gRPC and REST endpoints with GPU/TensorRT acceleration.
  - Upgrade `blockchain_gateway` from CLI container execution to native Hyperledger Fabric Gateway SDK v2.5 with persistent connection pools.

- **Phase 3: Event-Driven Core & ZKP (Weeks 9–12)**
  - Introduce Apache Kafka / RabbitMQ to handle asynchronous events (`credential.issued`, `audit.logged`).
  - Deploy the W3C Verifiable Credential 2.0 Lifecycle Service.
  - Implement real zk-SNARK verification for selective attribute disclosure using Circom circuits.

- **Phase 4: Kubernetes Orchestration & Regulatory Audit (Weeks 13–16)**
  - Package all microservices into Kubernetes Helm charts with Horizontal Pod Autoscalers (HPA).
  - Deploy Prometheus and Grafana dashboards for PMA Regulatory Sandbox audit reporting.
  - Conduct final penetration testing and live university pilot cutover.

---

## 🛠️ 7. Docker Compose Microservices Reference Blueprint

To test the decoupled services locally before Kubernetes deployment, the following architecture is defined:

```yaml
version: '3.8'

services:
  # 1. Edge Ingress
  api-gateway:
    image: kong:3.6-alpine
    ports:
      - "80:8000"
      - "443:8443"
    environment:
      KONG_DATABASE: "off"
      KONG_DECLARATIVE_CONFIG: /etc/kong/kong.yml
    volumes:
      - ./deploy/kong.yml:/etc/kong/kong.yml:ro

  # 2. Event Mesh
  message-broker:
    image: confluentinc/cp-kafka:7.5.0
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: 'CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT'
      KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://message-broker:9092'
      KAFKA_PROCESS_ROLES: 'broker,controller'
      KAFKA_CONTROLLER_QUORUM_VOTERS: '1@message-broker:9093'
      KAFKA_LISTENERS: 'PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093'

  # 3. Microservice Databases
  postgres-core:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: paldfi_core
      POSTGRES_USER: paldfi_admin
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data

  vector-db:
    image: qdrant/qdrant:v1.7.4
    ports:
      - "6333:6333"
    volumes:
      - qdrantdata:/qdrant/storage

  cache-redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  # 4. Domain Services
  auth-service:
    build: ./services/auth_service
    environment:
      PORT: 8001
      DATABASE_URL: postgres://paldfi_admin:${DB_PASSWORD}@postgres-core:5432/paldfi_core
      KAFKA_BROKERS: message-broker:9092

  biometrics-service:
    build: ./face_recognition_service
    environment:
      PORT: 8002
      VECTOR_DB_URL: http://vector-db:6333
      KAFKA_BROKERS: message-broker:9092

  credential-service:
    build: ./services/credential_service
    environment:
      PORT: 8003
      DATABASE_URL: postgres://paldfi_admin:${DB_PASSWORD}@postgres-core:5432/paldfi_core
      FABRIC_GW_URL: http://fabric-gateway:8005
      KAFKA_BROKERS: message-broker:9092

  zkp-privacy-service:
    build: ./services/zkp_service
    environment:
      PORT: 8004
      REDIS_URL: redis://cache-redis:6379
      FABRIC_GW_URL: http://fabric-gateway:8005

  fabric-gateway:
    build: ./blockchain_gateway
    environment:
      PORT: 8005
      CHANNEL_NAME: nuvte-academic-channel
      CHAINCODE_NAME: paldfi_academic_contract
      KAFKA_BROKERS: message-broker:9092

volumes:
  pgdata:
  qdrantdata:

---

## 8. Sovereign Consortium Blockchain Monitoring Dashboard

The web interface integrates a real-time Consortium Node Monitoring HUD, live performance telemetry sparkline canvas, interactive multi-attribute block explorer, and consensus event terminal:

```mermaid
graph TD
    Client["Client / Enclave Studio<br/>(ECDSA secp256k1)"] -->|"1. Proposal"| NUVTE["peer0.nuvte.edu.ps:7051<br/>Academic Endorsing Peer<br/>(CouchDB v3.3)"]
    NUVTE -->|"2. Endorsement"| BOP["peer0.bankofpalestine.ps:7051<br/>Validating & Status Peer<br/>(BitstringStatusList2021)"]
    BOP -->|"3. Envelope"| PMA["orderer.pma.gov.ps:7050<br/>PMA Raft Consensus Leader<br/>(Term #41, 3 Nodes)"]
    PMA -->|"4. Batch Block Cut"| Commit["Ledger State DB Commit<br/>(Channel: pal-sovereign-channel)"]
    Commit -->|"5. Update Telemetry"| HUD["Monitoring Dashboard HUD<br/>(TPS, Latency, Zero-PII Audit)"]
```

### Consortium Node Topology Specifications

| Node Endpoint | Consortium Organization | Cluster Role | Protocol & Security | State DB / Storage |
| :--- | :--- | :--- | :--- | :--- |
| `orderer.pma.gov.ps:7050` | Palestine Monetary Authority (PMA) | Raft Consensus Leader | Mutual TLS 1.3, gRPC Raft | Ledger File Store |
| `peer0.nuvte.edu.ps:7051` | Nat. Univ. of Vocational & Tech Education | Smart Chaincode Host | Mutual TLS 1.3, CouchDB | CouchDB v3.3 (Indexed) |
| `peer0.bankofpalestine.ps:7051` | Bank of Palestine (BOP) | Validating & Revocation Host | Mutual TLS 1.3, StatusList | BitstringStatusList2021 |

### Key Dashboard Capabilities
1. **Interactive Ping & Health Telemetry**: Live ping probes test peer latency across nodes with visual flash states and consensus uptime monitoring.
2. **Dynamic Consensus Pulse**: Simulates Raft leader heartbeat transmission across endorsing and validating peers.
3. **Consensus Pipeline Flow**: Step-by-step visual animation tracking credential transactions through Client Sign ➔ NUVTE Endorsement ➔ BOP Validation ➔ PMA Ordering ➔ Ledger Commit.
4. **Deep Block & Transaction Inspector**: Modal inspecting Block Height, TxID, PrevHash, DataHash, Merkle Root, Consortium Endorsement signatures (3/3), and confirming 100% Zero-PII on-chain privacy guarantees.
5. **Real-time Search & Multi-Pill Filter**: Query blocks by Block #, TxID, State Hash, Student ID, or category (Graduation, Identity, Clearance, KYC).
6. **Consensus Event Terminal**: Streaming monospace log ticker displaying live Hyperledger Fabric consensus events.

