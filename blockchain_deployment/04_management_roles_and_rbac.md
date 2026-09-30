# 04 - University Management Roles & Role-Based Access Control (RBAC)

This document defines the management roles, cryptographic keys, and permission boundaries across the PAL-DFI ecosystem.

---

## 1. Role Definitions

| Role Identifier | Holder Persona | Permissions | Cryptographic Key |
| :--- | :--- | :--- | :--- |
| **`NUVTE_REGISTRAR_ADMIN`** | Dean of Admission & Registration | Issue Student ID, Anchor hash on ledger, Revoke credentials | Ed25519 Private Key (HSM / Hardware Security Module) |
| **`NUVTE_DEAN_ACADEMIC_AFFAIRS`** | Deanship of Academic Affairs | Issue Graduation Certificates & Degree Diplomas | RSA-4096 / Ed25519 Joint Seal |
| **`NUVTE_FINANCIAL_CONTROLLER`** | University Financial Comptroller | Issue Clearance Certificate (Certificate of Discharge) | X.509 Financial Enclave Key |
| **`STUDENT_CREDENTIAL_HOLDER`** | Enrolled Student / Graduate | Decrypt credentials from local vault, generate OpenID4VP presentations | Device Keystore/Keychain (`did:key:z6Mku...`) |
| **`THIRD_PARTY_VERIFIER`** | Bank of Palestine, PalTel, Ministries | Query ledger revocation bit, verify Ed25519 signatures | Client Verification Certificate |
| **`PMA_REGULATORY_OBSERVER`** | Palestine Monetary Authority | Audit zero-PII compliance, monitor consensus telemetry | Orderer Consortium Audit Key |

---

## 2. Policy Enforcement Matrix

```
Operation                    │ Student │ Registrar │ Dean │ Financial Controller │ Verifier
─────────────────────────────┼─────────┼───────────┼──────┼──────────────────────┼─────────
Issue Student ID             │   ❌    │    ✅     │  ❌  │          ❌          │   ❌
Issue Graduation Certificate │   ❌    │    ✅     │  ✅  │          ❌          │   ❌
Issue Clearance Certificate  │   ❌    │    ✅     │  ❌  │          ✅          │   ❌
Set Revocation Status (Bit=1)│   ❌    │    ✅     │  ✅  │          ❌          │   ❌
Query Revocation Status      │   ✅    │    ✅     │  ✅  │          ✅          │   ✅
Decrypt Student PII Payload  │   ✅    │    ❌*    │  ❌* │          ❌*         │   ❌*
Generate Time-Bound Nonce    │   ✅    │    ❌     │  ❌  │          ❌          │   ✅
```
*\* Note: Strict Zero On-Chain PII ensures even the blockchain peers cannot decrypt student PII without holder consent.*

---

## 3. Cryptographic Key Lifecycle

1. **Root CA Generation**:
   - `ca.nuvte.edu.ps` generates the Root PKI certificate valid for 10 years.
   - Anchor certificate fingerprint: `nuvte-pki-cert-ed25519-root-40983bf9`.
2. **Intermediate Department CAs**:
   - Registrar CA (`identity.nuvte.edu.ps`)
   - Deanship CA (`academic.nuvte.edu.ps`)
3. **Revocation Management**:
   - Immediate on-chain invalidation via `BitstringStatusList2021`.
   - Any verifier querying `CheckRevocationBit` receives instantaneous `isRevoked: true` response without waiting for CRL distribution or OCSP timeouts.
