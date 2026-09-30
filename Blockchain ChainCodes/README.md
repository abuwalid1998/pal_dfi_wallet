# PAL-DFI Academic Consortium Smart Contracts

> **Hyperledger Fabric 2.5 Smart Contracts for Nablus University for Vocational and Technical Education (NUVTE)**  
> **Regulatory Oversight**: Palestine Monetary Authority (PMA) Regulatory Sandbox Guidelines  
> **Standards Compliance**: W3C Verifiable Credentials 2.0 & BitstringStatusList2021  

---

## 📂 Architecture & Directory Structure

```text
Blockchain ChainCodes/
├── chaincode/
│   ├── contract.go             # Main contract router, InitLedger, chaincode entrypoint
│   ├── document_anchor.go      # Zero-PII SHA-256 document anchoring, verify, revoke, history
│   ├── status_list.go          # W3C BitstringStatusList2021 100,000-bit revocation registry
│   ├── verification_audit.go   # Third-party verifier (Bank of Palestine) audit trails
│   ├── models.go               # Structs for credentials, lists, and audit records
│   ├── go.mod                  # Go module definition (Go 1.22)
│   ├── go.sum                  # Cryptographic dependency checksums
├── scripts/
│   ├── deploy_chaincode.sh     # Linux container deployment helper (package, install, approve, commit)
│   ├── init_ledger.sh          # Initializes ledger with 100,000 W3C bitstring slots & seed documents
│   └── test_chaincode.sh       # Comprehensive automated test suite (GetDocument, VerifyDocument, Bitstring, Audit)
├── deploy_chaincodes.ps1       # 1-Click Windows PowerShell deployment & verification script
├── paldfi_cc                   # Pre-compiled high-performance Linux binary for CCaaS
└── README.md                   # This documentation
```

---

## ⚡ 1-Click Deployment & Execution

To deploy, initialize, and execute the smart contracts on your running blockchain network:

```powershell
# Full automated deployment & test execution:
.\deploy_chaincodes.ps1 -Action Deploy

# Run on-chain tests against active contract:
.\deploy_chaincodes.ps1 -Action Test

# Check live container and port status:
.\deploy_chaincodes.ps1 -Action Status
```

---

## 📜 Smart Contract API Reference (`PalDfiContract`)

### 1. `InitLedger`
- **Function**: Bootstraps the ledger with the `nuvte-status-list-2024` (100,000 bit capacity) and anchors 3 official seed credentials for Persona *Amjad Khaliliah* (`STU-2024098`, National ID `983421560`).
- **Invocation**:
  ```bash
  peer chaincode invoke -C nuvte-academic-channel -n paldfi_academic_contract -c '{"function":"InitLedger","Args":[]}'
  ```

---

### 2. `AnchorDocument`
- **Function**: Registers a new official academic document anchor on-chain with Zero-PII.
- **Parameters**:
  1. `docId` (e.g. `"DOC-NUVTE-2024-GRAD-098"`)
  2. `docType` (`"StudentIdentityCredential"`, `"GraduationCertificateCredential"`, or `"ClearanceCertificateCredential"`)
  3. `docHash` (SHA-256 digest of decrypted W3C JSON-LD)
  4. `issuerDid` (`"did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA"`)
  5. `subjectHash` (SHA-256 digest of citizen National ID)
  6. `statusListIndex` (Integer index `0` to `99999` in the revocation bitstring)
  7. `metadataJson` (Non-PII metadata like faculty, degree name, honors, or clearance departments)
- **Invocation**:
  ```bash
  peer chaincode invoke -C nuvte-academic-channel -n paldfi_academic_contract -c '{"function":"AnchorDocument","Args":["DOC-NUVTE-2024-STU-098","StudentIdentityCredential","e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","did:key:nuvte","sha256(983421560)","101","{\"gpa\":\"3.88\"}"]}'
  ```

---

### 3. `VerifyDocument`
- **Function**: Third-party verifiers (e.g. Bank of Palestine) verify the cryptographic validity and revocation status of a presented credential in `< 3.0 seconds`.
- **Parameters**:
  1. `docId` (e.g. `"DOC-NUVTE-2024-GRAD-098"`)
  2. `docHash` (SHA-256 hash computed from student's decrypted presentation)
- **Returns**:
  ```json
  {
    "isValid": true,
    "isRevoked": false,
    "docId": "DOC-NUVTE-2024-GRAD-098",
    "docType": "GraduationCertificateCredential",
    "status": "ACTIVE",
    "issuanceDate": "2024-06-25T10:00:00Z",
    "verificationTimestamp": "2026-09-23T08:26:00Z",
    "message": "Document is valid, authentic, and actively registered on Hyperledger Fabric."
  }
  ```

---

### 4. `RevokeDocument`
- **Function**: University Management revokes an issued document (e.g., student expelled or certificate re-issued). Automatically flips the corresponding bit in `BitstringStatusList2021` to `1` (Revoked).
- **Parameters**:
  1. `docId`
  2. `reason` (e.g. `"Academic Disciplinary Board Decision #44"`)

---

### 5. `GetDocumentHistory`
- **Function**: Returns the immutable provenance audit trail of all ledger transactions modifying this document anchor.

---

### 6. `RecordVerificationAudit`
- **Function**: Records a tamper-proof audit log when a third-party verifier inspects a student's credential.
- **Parameters**:
  1. `auditId` (e.g. `"AUDIT-BOP-2024-001"`)
  2. `verifierDid` (`"did:key:z6MkuBankOfPalestineCompliance"`)
  3. `verifierName` (`"Bank of Palestine (Compliance/HR)"`)
  4. `docId` (`"DOC-NUVTE-2024-GRAD-098"`)
  5. `studentDid` (`"did:key:z6MkuStudentAmjadKhaliliah"`)
  6. `nonce` (Single-use presentation challenge nonce)
  7. `verificationResult` (`"VALID"`, `"REVOKED"`, or `"HASH_MISMATCH"`)

---

## 🌐 Visualizing on Hyperledger Explorer

Once deployed:
1. Navigate to **[http://localhost:8090](http://localhost:8090)**
2. Log in with `admin` / `password`.
3. Open the **Chaincode** tab to see `paldfi_academic_contract` running on `nuvte-academic-channel`.
4. Open the **Transactions** tab to inspect all `AnchorDocument`, `InitLedger`, and `RecordVerificationAudit` transactions.
