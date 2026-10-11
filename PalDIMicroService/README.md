# PalDIMicroService

### Palestinian Decentralized Financial Identity & Sovereign Academic Wallet (Microservices Edition)
**Controlled Academic Pilot at Nablus University for Vocational and Technical Education (NUVTE)**  
**Operating under Palestine Monetary Authority (PMA) Regulatory Sandbox Guidelines**

---

## 📌 Overview

**PalDIMicroService** is the decomposed, distributed microservices implementation of the PAL-DFI platform. It transitions the application from a coupled prototype into an autonomous, domain-driven microservices architecture featuring:
- Dedicated **API Gateway & Edge Reverse Proxy** (Port 8000).
- Autonomous microservices with database-per-service isolation.
- Asynchronous **Event Mesh** for domain event propagation.
- **Zero On-Chain PII** enforcement with cryptographic SHA-256 fingerprint anchoring.
- W3C Verifiable Credentials 2.0 and zk-SNARK Selective Disclosure verification.

---

## 🏛️ Microservice Topology & Port Catalog

| Port | Service Component | Technology | Primary Domain Responsibility |
| :--- | :--- | :--- | :--- |
| **8000** | **API Gateway** | Python / Envoy Reverse Proxy | Unified ingress, routing, CORS, rate limiting, and health aggregation |
| **8001** | **Auth & PMA ID+ Service** | Python (OIDC Mock) | Sovereign persona authentication, W3C DID resolution (`did:paldfi:...`) |
| **8002** | **Biometrics & AI Vector Service** | Python (Gaussian + CLAHE) | 128-D vector extraction, noise cancellation, vector DB, similarity matching |
| **8003** | **W3C Credential Service** | Python (W3C VC 2.0) | Issuing Student ID, Graduation Diploma, Clearance Certificate, Ed25519 signing |
| **8004** | **ZKP & Privacy Engine** | Python (zk-SNARK Engine) | OpenID4VP challenge nonces, selective disclosure, zero-PII proofs |
| **8005** | **Fabric Blockchain Gateway** | Python / Fabric Gateway | Hyperledger Fabric 2.5 REST bridge, `BitstringStatusList2021` revocation queries |
| **8006** | **Audit & Compliance Service** | Python (Event Subscriber) | PMA Sandbox audit trail logging, real-time telemetry & latency metrics |

---

## 🚀 How to Run the Microservices Cluster

### Option A: Native Supervisor (Cross-Platform Windows / Mac / Linux)
Start all 7 microservices in parallel with health monitoring:
```bash
python start_all.py
```
Or on Windows PowerShell:
```powershell
.\start_microservices.ps1
```

To stop all services:
```powershell
.\stop_microservices.ps1
```

### Option B: Docker Compose
```bash
docker-compose up --build
```

---

## 🧪 Testing & Verification

Run the integration test suite verifying every microservice endpoint and end-to-end routing through the API Gateway:
```powershell
.\test_microservices.ps1
```

Or via direct HTTP check:
```bash
curl http://localhost:8000/api/v1/health
```

Sample Aggregated Cluster Response:
```json
{
  "gateway": "paldfi-api-gateway",
  "version": "1.0.0-microservices",
  "port": 8000,
  "overallStatus": "HEALTHY",
  "microservices": {
    "auth": { "status": "UP", "port": 8001 },
    "biometrics": { "status": "UP", "port": 8002 },
    "credentials": { "status": "UP", "port": 8003 },
    "zkp": { "status": "UP", "port": 8004 },
    "fabric": { "status": "UP", "port": 8005 },
    "audit": { "status": "UP", "port": 8006 }
  }
}
```

---

## 📁 Directory Structure

```
PalDIMicroService/
├── services/
│   ├── api_gateway/           # Port 8000: Edge Reverse Proxy & Routing
│   ├── auth_service/          # Port 8001: PMA ID+ Auth & DID Resolution
│   ├── biometrics_service/    # Port 8002: AI Vector DB & Denoising Engine
│   ├── credential_service/    # Port 8003: W3C VC 2.0 Lifecycle & Issuance
│   ├── zkp_service/           # Port 8004: Zero-Knowledge Privacy Engine
│   ├── fabric_gateway/        # Port 8005: Hyperledger Fabric 2.5 Gateway
│   ├── audit_service/         # Port 8006: PMA Sandbox Audit & Telemetry
│   └── event_bus/             # Asynchronous Pub/Sub Domain Event Mesh
├── docker-compose.yml         # Container orchestration manifest
├── start_all.py               # Cross-platform cluster supervisor
├── start_microservices.ps1    # PowerShell launcher
├── stop_microservices.ps1     # Process terminator
├── test_microservices.ps1     # Integration test suite
├── ARCHITECTURE.md            # Detailed architectural documentation & diagrams
└── README.md                  # Project overview & usage guide
```
