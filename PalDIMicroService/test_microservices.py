import json
import sys
import time
import urllib.request
import urllib.error

if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

GATEWAY_URL = "http://localhost:8000"

def make_request(url: str, method: str = "GET", payload: dict = None, headers: dict = None):
    req_headers = {"Content-Type": "application/json"}
    if headers:
        req_headers.update(headers)
    
    data = json.dumps(payload).encode('utf-8') if payload else None
    req = urllib.request.Request(url, data=data, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=5.0) as resp:
            body = resp.read().decode('utf-8')
            return resp.status, json.loads(body)
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8')
        try:
            return e.code, json.loads(body)
        except Exception:
            return e.code, {"error": body}
    except Exception as e:
        return 0, {"error": str(e)}

def run_tests():
    print("=" * 65)
    print("  PAL-DFI Distributed Microservices Integration Test Suite")
    print("=" * 65)

    passed = 0
    failed = 0

    def assert_test(name: str, condition: bool, details: str = ""):
        nonlocal passed, failed
        if condition:
            print(f"  [PASS] {name}")
            passed += 1
        else:
            print(f"  [FAIL] {name} - {details}")
            failed += 1

    # 1. API Gateway Aggregated Health
    print("\n--- 1. API Gateway Ingress (Port 8000) ---")
    st, res = make_request(f"{GATEWAY_URL}/api/v1/health")
    assert_test("Gateway Health Check", st == 200 and res.get("gateway") == "paldfi-api-gateway", f"Status: {st}")
    ms = res.get("microservices", {})
    assert_test("All 6 Microservices Online", res.get("overallStatus") == "HEALTHY", f"Services: {ms}")

    # 2. Auth Service via Gateway
    print("\n--- 2. Auth & PMA ID+ Microservice (/api/v1/auth) ---")
    st, res = make_request(f"{GATEWAY_URL}/api/v1/auth/login", method="POST", payload={"personaKey": "student"})
    assert_test("PMA ID+ Student Login", st == 200 and res.get("success") is True and "token" in res, f"Response: {res}")
    token = res.get("token")

    st, res = make_request(f"{GATEWAY_URL}/api/v1/auth/verify-token", method="POST", payload={"token": token})
    assert_test("Verify Sovereign Token", st == 200 and res.get("valid") is True, f"Response: {res}")

    st, res = make_request(f"{GATEWAY_URL}/api/v1/auth/did/908172635")
    assert_test("Resolve W3C DID Document", st == 200 and "didDocument" in res, f"Response: {res}")

    # 3. Biometrics Service via Gateway
    print("\n--- 3. Biometrics & AI Vector Microservice (/api/v1/biometrics) ---")
    st, res = make_request(f"{GATEWAY_URL}/api/v1/biometrics/faces")
    assert_test("List Enrolled Vector DB Identities", st == 200 and res.get("count", 0) >= 3, f"Count: {res.get('count')}")

    st, res = make_request(f"{GATEWAY_URL}/api/v1/biometrics/extract", method="POST", payload={"name": "Ahmad_AlKhalili_NUVTE_STU1082"})
    assert_test("Extract 128-D Invariant Vector with Noise Filter", st == 200 and res.get("vectorLength") == 128, f"Response: {res}")

    st, res = make_request(f"{GATEWAY_URL}/api/v1/biometrics/match", method="POST", payload={"imageEntropy": "Ahmad_AlKhalili_NUVTE_STU1082"})
    assert_test("Match Known Biometric Profile", st == 200 and res.get("matched") is True and res.get("name") == "Ahmad M. Al-Khalili", f"Response: {res}")

    # 4. Credential Service via Gateway
    print("\n--- 4. W3C Credential Lifecycle Microservice (/api/v1/credentials) ---")
    st, res = make_request(f"{GATEWAY_URL}/api/v1/credentials/student/STU-1082")
    assert_test("Fetch Issued Academic Credentials", st == 200 and len(res.get("credentials", [])) >= 3, f"Count: {len(res.get('credentials', []))}")

    new_cred = {
        "type": "StudentIdentityCredential",
        "subject": {
            "studentId": "STU-9901",
            "fullNameEn": "Yasmeen K. Ramallah",
            "faculty": "Faculty of Informatics",
            "gpa": "3.91"
        }
    }
    st, res = make_request(f"{GATEWAY_URL}/api/v1/credentials/issue", method="POST", payload=new_cred)
    assert_test("Issue New W3C VC 2.0 with Zero-PII Digest", st == 201 and "sha256Digest" in res.get("credential", {}), f"Response: {res}")

    # 5. ZKP Privacy Engine via Gateway
    print("\n--- 5. ZKP & Privacy Engine Microservice (/api/v1/zkp) ---")
    st, res = make_request(f"{GATEWAY_URL}/api/v1/zkp/generate-request", method="POST", payload={"scenario": "bank"})
    assert_test("Generate OpenID4VP Challenge Nonce", st == 200 and "nonce" in res.get("verificationRequest", {}), f"Response: {res}")
    nonce = res.get("verificationRequest", {}).get("nonce")

    vp_payload = {
        "nonce": nonce,
        "holderDid": "did:paldfi:citizen:908172635",
        "credentialType": "StudentIdentityCredential",
        "revealedClaims": {"Active_Enrolled_Student": True, "Clean_Financial_Clearance": True}
    }
    st, res = make_request(f"{GATEWAY_URL}/api/v1/zkp/verify-presentation", method="POST", payload=vp_payload)
    assert_test("Verify zk-SNARK Selective Disclosure (Zero-PII)", st == 200 and res.get("valid") is True, f"Response: {res}")

    # 6. Fabric Gateway via Gateway
    print("\n--- 6. Hyperledger Fabric Gateway Microservice (/api/v1/fabric) ---")
    st, res = make_request(f"{GATEWAY_URL}/api/v1/fabric/channels")
    assert_test("Query Consortium Channel & Smart Contracts", st == 200 and len(res.get("channels", [])) >= 1, f"Response: {res}")

    st, res = make_request(f"{GATEWAY_URL}/api/v1/fabric/status/0")
    assert_test("Query Real-time Bitstring Revocation Bit", st == 200 and res.get("revocationStatusBit") == "0", f"Response: {res}")

    st, res = make_request(f"{GATEWAY_URL}/api/v1/fabric/anchor", method="POST", payload={"sha256Digest": "a1b2c3d4e5f6...", "docId": "urn:uuid:test-doc"})
    assert_test("Anchor Zero-PII Digest on Fabric Consortium", st == 201 and "txId" in res.get("transaction", {}), f"Response: {res}")

    # 7. Audit Service via Gateway
    print("\n--- 7. PMA Audit & Regulatory Compliance Microservice (/api/v1/audit) ---")
    st, res = make_request(f"{GATEWAY_URL}/api/v1/audit/logs")
    assert_test("Retrieve PMA Sandbox Audit Trail", st == 200 and res.get("count", 0) >= 1, f"Count: {res.get('count')}")

    st, res = make_request(f"{GATEWAY_URL}/api/v1/audit/metrics")
    assert_test("Retrieve System Compliance Metrics", st == 200 and "metrics" in res, f"Metrics: {res.get('metrics')}")

    print("\n" + "=" * 65)
    print(f"  Test Suite Completed: {passed} PASSED, {failed} FAILED")
    print("=" * 65)

    return failed == 0

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
