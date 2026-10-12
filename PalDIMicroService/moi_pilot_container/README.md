# 🏛️ Ministry of Interior (MoI) — State of Palestine
## Independent National ID Pilot Container
### First-Time Digital National ID Issuance & Civil Registry Platform

---

## 📌 1. Overview & Objectives

This independent, self-contained container provides the complete **Ministry of Interior (MoI) Digital National ID Issuance Platform** for the Palestinian national pilot phase. It transitions the traditional 8-day counter visit into an automated, zero-trust digital transaction.

### Key Capabilities Included:
- **Zero-Dependency Architecture**: Runs on pure Node.js 20 with zero external npm runtime dependencies — 100% functional in isolated, air-gapped government intranets.
- **Air-Gapped Neural Models**: All biometrics and facial landmark models (`tiny_face_detector`, `face_landmark_68`, `face_recognition`) are bundled locally within the container. No outbound internet connection required.
- **Client & Counter UI**: Bilingual (Arabic/English) progressive web application supporting citizen self-service and counter agent verification.
- **Automated Validation Suite**:
  - Palestinian 9-digit civil Luhn checksum validation.
  - Neural eye blink anti-spoofing liveness detection (EAR $\le 0.22$).
  - 1:1 Euclidean biometric face vector verification ($L_2 \le 0.50$, $\ge 82\%$ similarity).
  - Civil age and fee calculation (16.0–16.5 exempt; 16.5+ penalized 15.00 JOD).
  - PCI/Luhn banking card fee settlement.
- **Persistent Civil Registry Ledger**: Records are permanently saved to `/app/data/moi_national_ids.csv` via volume mounting, ensuring zero data loss across container lifecycle updates.
- **Kubernetes & Cloud Health Probes**: Active `/health` endpoint for enterprise clustering and zero-downtime rolling deployments.

---

## 🚀 2. Quickstart Deployment

### Option A: One-Click Launch Script (Recommended)

#### On Windows (PowerShell):
```powershell
cd moi_pilot_container
.\run_container.ps1
```

#### On Linux / macOS (Bash):
```bash
cd moi_pilot_container
chmod +x run_container.sh test_container.sh
./run_container.sh
```

---

### Option B: Using Docker Compose

```bash
# 1. Enter container directory
cd moi_pilot_container

# 2. Build and launch in background
docker compose up -d --build

# 3. Verify container is healthy
docker compose ps
```

---

### Option C: Using Raw Docker CLI

```bash
# 1. Build image
docker build -t paldi/moi-national-id:pilot-v1.0 .

# 2. Run container with persistent data volume
docker run -d \
  --name moi_national_id_pilot \
  --restart unless-stopped \
  -p 9000:9000 \
  -v $(pwd)/data:/app/data \
  paldi/moi-national-id:pilot-v1.0
```

---

## 🌐 3. Access Endpoints

| Resource | URL | Description |
| :--- | :--- | :--- |
| **Citizen & Counter Portal** | `http://localhost:9000/` | Main National ID Issuance Application |
| **Health Probe** | `http://localhost:9000/health` | Container health, uptime, memory, storage status |
| **Civil Records API** | `http://localhost:9000/api/v1/moi/records` | JSON list of all issued & pending IDs |
| **Pilot Analytics** | `http://localhost:9000/api/v1/moi/stats` | Aggregated metrics, revenue, liveness averages |
| **Export CSV Ledger** | `http://localhost:9000/api/v1/moi/export-csv` | Direct download of `moi_national_ids.csv` |
| **Instant ID Verification**| `http://localhost:9000/api/v1/moi/verify/{ID}` | Verification by 9-digit ID or App ID |

---

## ⚙️ 4. Configuration Environment Variables

Configure via `.env` file in the root of `moi_pilot_container/`:

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `PORT` | `9000` | Internal server listen port |
| `MOI_PORT` | `9000` | Host port mapped via `docker-compose.yml` |
| `DATA_DIR` | `/app/data` | Path to persistent storage directory |
| `CORS_ORIGIN` | `*` | Allowed CORS origins (lock down in production) |
| `APP_VERSION` | `1.0.0-pilot` | Version metadata reported by `/health` |
| `GSB_GATEWAY_URL` | `http://gsb.gov.ps/api/v1` | Government Service Bus integration hook |
| `PMA_ID_PLUS_URL` | `http://idplus.pma.ps/api/v1` | PMA Banking Gateway integration hook |

---

## 🔌 5. REST API Specification

### 1. Healthcheck Probe
`GET /health`
```json
{
  "status": "UP",
  "service": "moi-national-id-pilot",
  "version": "1.0.0-pilot",
  "uptime_seconds": 3600,
  "database": {
    "storage_type": "CSV_LEDGER",
    "file_path": "/app/data/moi_national_ids.csv",
    "exists": true,
    "total_records": 9
  }
}
```

### 2. Fetch All Records
`GET /api/v1/moi/records`
```json
{
  "success": true,
  "count": 9,
  "records": [
    {
      "application_id": "MOI-APP-2026-0081",
      "national_id_number": "408921843",
      "did": "did:paldi:moi:408921843",
      "applicant_name_ar": "طارق إبراهيم القدومي",
      "applicant_name_en": "Tariq Ibrahim Al-Qaddoumi",
      "dob": "2010-04-14",
      "status": "ISSUED",
      "total_fee_jod": "2.00",
      "liveness_score": "98.6%"
    }
  ]
}
```

### 3. Settle Fee & Issue National ID
`POST /api/v1/moi/settle`
- **Request Body**:
```json
{
  "application_id": "MOI-APP-2026-0912",
  "national_id_number": "408900115",
  "did": "did:paldi:moi:408900115",
  "applicant_name_ar": "طارق إبراهيم خليل القدومي",
  "applicant_name_en": "Tariq Ibrahim Al-Qaddoumi",
  "dob": "2010-04-14",
  "age": "16.5",
  "birth_place": "رام الله والبيرة",
  "gender": "ذكر",
  "blood_type": "O+",
  "parent_id": "901452813",
  "parent_name": "إبراهيم خليل محمد القدومي",
  "base_fee_jod": "2.00",
  "penalty_fee_jod": "0.00",
  "total_fee_jod": "2.00",
  "payment_tx_id": "TX-BOP-981241",
  "biometric_hash": "PAL-FP-5E62-91E8-3C62-EAD3",
  "liveness_score": "99.6%"
}
```
- **Response**:
```json
{
  "success": true,
  "message": "National ID successfully issued and recorded in Civil Registry CSV database",
  "record": { ... }
}
```

### 4. Pilot Analytics
`GET /api/v1/moi/stats`
```json
{
  "success": true,
  "stats": {
    "total_applications": 9,
    "issued_count": 9,
    "pending_count": 0,
    "total_base_fees_jod": "18.00",
    "total_penalties_jod": "15.00",
    "total_revenue_jod": "33.00",
    "average_liveness_score": "99.1%"
  }
}
```

---

## 🧪 6. Testing & Verification

Run the included automated smoke test suite:

```powershell
# Windows
.\test_container.ps1
```

```bash
# Linux / macOS
./test_container.sh
```

---

## 🔒 7. Security & Compliance Notes
1. **ICAO 9303 Compliance**: Generated National IDs include Machine Readable Zone (MRZ) TD1 compliance format.
2. **W3C Verifiable Credentials**: Identity payloads follow W3C VC 1.1 JSON-LD standards.
3. **Non-Root Execution**: Container runs strictly under `node` (UID: 1000) for security hardening.
4. **Air-Gapped Ready**: Contains no external CDN links or remote analytics telemetry.
