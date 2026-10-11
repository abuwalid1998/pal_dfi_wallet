# PAL-DFI Citizen & Student Mobile Wallet (Flutter MVP)
### Controlled Academic Pilot at Nablus University for Vocational and Technical Education (NUVTE)
**Operating under Palestine Monetary Authority (PMA) Regulatory Sandbox Guidelines**

---

## 📌 Executive Summary

The **Palestinian Decentralized Financial Identity Network (PAL-DFI)** addresses the challenge of fragmented student and citizen identity and manual verifications. Manual document verifications incur risks of document forgery and inquiry costs exceeding \$2.50 per instance.

The **PAL-DFI Citizen & Student Wallet** is a decentralized, sovereign mobile and web client built on **Flutter 3.x (Dart 3.x)**. It empowers students to claim, store, visualize, authorize, and cryptographically present academic credentials to external third parties (banks, employers, campus gates) with **Strict Zero On-Chain PII**.

---

## 🌟 Key Features & Functional Modules

### 1. 🔑 ID+ by Palestine Monetary Authority (PMA) Authentication
- **1-Click Sovereign Login**: Unified national authentication gateway via PMA ID+.
- **No Sign-Up Needed**: Pre-verified identity enclaves for:
  - 🎓 **Citizen / Student**: Enrolled student with verified national ID.
  - 🏛️ **University Management**: Registrar, Academic Affairs, and Deans.
  - 🏢 **Third-Party Verifier**: Financial institutions (e.g. Bank of Palestine) and employers.
- Built-in Mock provider with instant toggle for live OAuth 2.0 PKCE / OpenID Connect endpoints.

### 2. 📜 Three Official University Documents
The university issues cryptographically signed W3C Verifiable Credentials 2.0:
1. 💳 **Digital Student ID Card** (`StudentIdentityCredential`): Student ID (`STU-XXXXXX`), Faculty, Program, GPA, blood type, and live status badge.
2. 📜 **Official Graduation Certificate** (`GraduationCertificateCredential`): Degree diploma, graduation date, honors classification (*First Class Honors / مرتبة الشرف الأولى*), and Deans Council resolution decree.
3. 📑 **Certificate of Discharge / Clearance Certificate** (`ClearanceCertificateCredential`): Official university clearance verifying zero financial liabilities across 5 departments (Library, Financial Comptroller, Laboratories & Workshops, Student Affairs, Registration).

### 3. 🔄 Automatic Ingestion & Live Sync
- When University Management issues any of these documents, it is signed with NUVTE's PKI key, anchored on the **Hyperledger Fabric 2.5** ledger, and **immediately written and visible in the student's wallet view**.

### 4. 🤝 3-Step Third-Party Request & Verification Flow
1. **Step 1 (Request)**: A third party (e.g. Bank of Palestine) dispatches a document request to the student with a fresh cryptographic nonce.
2. **Step 2 (Authorize & Decrypt)**: Student receives an authorization notification in their wallet, approves disclosure, and shares the decrypted document from their secure vault.
3. **Step 3 (Blockchain Verification)**: The third party sends a query to the NUVTE Hyperledger Fabric blockchain to verify that the cryptographic signature is authentic and the status bit is valid (`0 = Active`) in `BitstringStatusList2021` (< 3.0s response time).

### 5. 🎨 Aesthetic Palette & Bilingual Support
- **Color Palette**: Royal & Navy Blue (`#0B2545`, `#134074`) with Radiant Academic Gold / Yellow (`#FFC72C`) and Obsidian Black touches (`#080B10`).
- **Bilingual**: Instant toggle between **العربية (Arabic - RTL)** and **English (LTR)**.

---

## 🏗️ Architecture & Security Model

> 📖 **Full System Architecture Document**: For an in-depth breakdown comparing the current implementation against the target enterprise microservices architecture with detailed Mermaid diagrams, service specifications, and migration roadmap, see [ARCHITECTURE.md](file:///c:/Users/HP/.gemini/antigravity-ide/scratch/pal_dfi_wallet/ARCHITECTURE.md).

```
   ┌───────────────────────┐          ┌───────────────────────────┐
   │ University Management │          │   Student Mobile Wallet   │
   │  (Issuer Persona)     │          │    (Holder Persona)       │
   └───────────┬───────────┘          └─────────────┬─────────────┘
               │                                    │
               │ Issues W3C VC 2.0                  │ Decrypts & generates
               │ Anchors SHA-256 Hash               │ OpenID4VP dynamic QR
               ▼                                    ▼
   ┌──────────────────────────────────────────────────────────────┐
   │        HYPERLEDGER FABRIC 2.5 TRUST LAYER (ZERO PII)         │
   │  - Channel: nuvte-academic-channel                           │
   │  - Smart Contract: BitstringStatusList2021                   │
   │  - Storage: SHA-256 Hashes & Bit Indexes (NO PII ON-CHAIN)   │
   └──────────────────────────────┬───────────────────────────────┘
                                  ▲
                                  │ Real-Time Query (< 3.0s)
                                  │
                     ┌────────────┴─────────────┐
                     │   Third-Party Verifier   │
                     │  (Bank / Employer / Gate)│
                     └──────────────────────────┘
```

---

## 🚀 How to Run Locally

### Prerequisites
- [Flutter SDK 3.22+ LTS](https://flutter.dev/docs/get-started/install)
- Chrome Browser or Windows Desktop build tools

### 1. Clone & Enter Project Directory
```bash
cd C:\Users\HP\.gemini\antigravity-ide\scratch\pal_dfi_wallet
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Static Analysis & Tests
```bash
flutter analyze
flutter test
```

### 4. Launch Application
- **Run on Chrome (Web)**:
  ```bash
  flutter run -d chrome
  ```
- **Run on Windows Desktop**:
  ```bash
  flutter run -d windows
  ```
- **Run on Android Device / Emulator**:
  ```bash
  flutter run -d android
  ```

---

## 📦 How to Build for Production

### Build Web Release Bundle
```bash
flutter build web --release
```
The compiled output is located in `build/web/`.

### Build Android APK
```bash
flutter build apk --release
```
The compiled APK is in `build/app/outputs/flutter-apk/app-release.apk`.

### Build Windows Desktop Executable
```bash
flutter build windows --release
```
The executable bundle is in `build/windows/x64/runner/Release/`.

---

## 🌐 How to Deploy to a Server

### Method A: Docker & Nginx Deployment (Recommended)

Create a `Dockerfile` in the root of the project:
```dockerfile
# Multi-stage build
FROM ghcr.io/cirruslabs/flutter:3.22.0 AS build
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# Production Nginx Server
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
```

Create `nginx.conf`:
```nginx
server {
    listen 80;
    server_name wallet.nuvte.edu.ps;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name wallet.nuvte.edu.ps;

    ssl_certificate /etc/letsencrypt/live/wallet.nuvte.edu.ps/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/wallet.nuvte.edu.ps/privkey.pem;
    ssl_protocols TLSv1.3;

    root /usr/share/nginx/html;
    index index.html;

    # Security Headers (OWASP Top 10)
    add_header X-Frame-Options "DENY";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

Run with Docker Compose:
```bash
docker compose up -d --build
```

---

## ⚙️ Configuration & Environment Settings

### PMA ID+ Live Configuration
In [`lib/core/services/id_plus_auth_service.dart`](file:///C:/Users/HP/.gemini/antigravity-ide/scratch/pal_dfi_wallet/lib/core/services/id_plus_auth_service.dart):
```dart
// Toggle between mock simulation and live PMA sandbox OIDC gateway:
bool isLivePmaEndpoint = true; // Set to true for live integration
String pmaOidcEndpoint = 'https://idplus.pma.ps/oauth/v2/token';
```

### Hyperledger Fabric Connection Profile
In [`lib/core/services/fabric_ledger_service.dart`](file:///C:/Users/HP/.gemini/antigravity-ide/scratch/pal_dfi_wallet/lib/core/services/fabric_ledger_service.dart):
Configure your Fabric Peer endpoint and Root PKI certificate:
```dart
final String issuerDid = 'did:paldfi:nuvte:registrar-root-ca';
final String fabricPeerEndpoint = 'grpcs://peer0.nuvte.edu.ps:7051';
```

---

## 📂 Blockchain Deployment & Hyperledger Explorer

You can initialize and run the entire Hyperledger Fabric 2.5 network, smart contracts, and Hyperledger Explorer with a **single 1-Click PowerShell script**:

```powershell
# Run from repository root:
.\deploy_blockchain_and_explorer.ps1
```

This automated script performs:
1. **Prerequisites Check**: Verifies Docker Desktop is running.
2. **Cryptographic PKI Generation**: Generates certificates and MSP keys using `cryptogen`.
3. **Genesis Block Creation**: Generates `nuvte-academic-channel.block` using `configtxgen`.
4. **Fabric Node Startup**: Boots PMA Raft Orderer (7050), NUVTE Peer (7051), and CA (7054).
5. **Channel Join**: Joins NUVTE Peer to `nuvte-academic-channel`.
6. **Smart Contract Deployment**: Packages, approves, and commits `paldfi_contract` with `InitLedger` initializing 100,000 Bitstring revocation slots.
7. **Hyperledger Explorer**: Deploys the visual blockchain explorer UI at **`http://localhost:8090`** (Login: `admin` / `password`).

For in-depth architectural and operational documentation, visit the [`blockchain_deployment/`](./blockchain_deployment/) directory:
- [`deploy_blockchain_and_explorer.ps1`](./deploy_blockchain_and_explorer.ps1): Automated deployment script
- [`01_prerequisites_and_environment.md`](./blockchain_deployment/01_prerequisites_and_environment.md): Environment requirements & setup
- [`02_network_topology_and_msp.md`](./blockchain_deployment/02_network_topology_and_msp.md): Network topology & MSP
- [`03_smart_contract_chaincode.md`](./blockchain_deployment/03_smart_contract_chaincode.md): Go chaincode implementation
- [`04_management_roles_and_rbac.md`](./blockchain_deployment/04_management_roles_and_rbac.md): RBAC matrix & management roles
- [`05_deployment_and_bootstrap_scripts.md`](./blockchain_deployment/05_deployment_and_bootstrap_scripts.md): CLI testing queries & bash bootstrap
- [`explorer/`](./blockchain_deployment/explorer): Explorer Docker Compose & connection profile
- [`docker-compose-fabric.yaml`](./blockchain_deployment/docker-compose-fabric.yaml): Production Docker Compose file

---

## 📜 Blockchain Smart Contracts (`Blockchain ChainCodes/`)

Production-grade Go smart contracts are located in [`Blockchain ChainCodes/`](./Blockchain%20ChainCodes/):
- **Document Anchoring**: Zero-PII SHA-256 integrity anchors with metadata (`AnchorDocument`, `VerifyDocument`, `RevokeDocument`).
- **W3C Revocation Registry**: `BitstringStatusList2021` with 100,000 credential capacity slots (`SetStatusBit`, `GetStatusBit`).
- **Audit Logging**: Tamper-proof on-chain verification logs for third-party verifiers (`RecordVerificationAudit`, `GetVerificationAudit`).

### 1-Click Chaincode Deployment & Automated Tests
```powershell
# Deploy & test chaincode on running network:
.\deploy_chaincodes.ps1 -Action Deploy

# Run on-chain verification test suite:
.\deploy_chaincodes.ps1 -Action Test

# Check blockchain & chaincode container status:
.\deploy_chaincodes.ps1 -Action Status
```

---

## 📄 License & Regulatory Notice

This project operates under the **Palestine Monetary Authority (PMA) Regulatory Sandbox Guidelines** for the controlled academic pilot at **Nablus University for Vocational and Technical Education (NUVTE)**.
All student Personally Identifiable Information (PII) is strictly stored off-chain.
