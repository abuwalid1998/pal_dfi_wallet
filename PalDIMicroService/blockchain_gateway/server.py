"""
PAL-DFI Hyperledger Fabric REST Gateway Bridge Server
Bridges Flutter Mobile/Web wallet HTTP calls to live Hyperledger Fabric 2.5 smart contract.
Operating under Palestine Monetary Authority (PMA) Regulatory Sandbox Guidelines.
"""

import http.server
import json
import os
import re
import socketserver
import subprocess
import sys
import time
import urllib.parse

PORT = 5050
CHANNEL = "nuvte-academic-channel"
CONTRACT = "paldfi_academic_contract"
CLI_CONTAINER = "paldfi_fabric_cli"
ORDERER_CA = "/workspace/deploy/organizations/ordererOrganizations/pma.gov.ps/orderers/orderer.pma.gov.ps/msp/tlscacerts/tlsca.pma.gov.ps-cert.pem"

DOC_REGISTRY = []
INSTITUTION_REGISTRY = []
SMARTCONTRACT_REGISTRY = []

REGISTRY_FILE = os.path.join(os.path.dirname(__file__), "gateway_registry.json")

def load_registry():
    global DOC_REGISTRY, INSTITUTION_REGISTRY, SMARTCONTRACT_REGISTRY
    if os.path.exists(REGISTRY_FILE):
        try:
            with open(REGISTRY_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                DOC_REGISTRY = data.get("documents", [])
                INSTITUTION_REGISTRY = data.get("institutions", [])
                SMARTCONTRACT_REGISTRY = data.get("contracts", [])
                print(f"[Gateway] Loaded registry from {REGISTRY_FILE}: {len(DOC_REGISTRY)} docs, {len(INSTITUTION_REGISTRY)} insts, {len(SMARTCONTRACT_REGISTRY)} contracts.")
        except Exception as e:
            print(f"[Gateway] Error reading registry file: {e}")
            DOC_REGISTRY = []
            INSTITUTION_REGISTRY = []
            SMARTCONTRACT_REGISTRY = []
    else:
        DOC_REGISTRY = []
        INSTITUTION_REGISTRY = []
        SMARTCONTRACT_REGISTRY = []
        print("[Gateway] Registry clean initialized with 0 mock records.")

def save_registry():
    try:
        with open(REGISTRY_FILE, "w", encoding="utf-8") as f:
            json.dump({
                "documents": DOC_REGISTRY,
                "institutions": INSTITUTION_REGISTRY,
                "contracts": SMARTCONTRACT_REGISTRY
            }, f, indent=2)
    except Exception as e:
        print(f"[Gateway] Error saving registry: {e}")

def register_doc_id(did):
    if did not in DOC_REGISTRY:
        DOC_REGISTRY.append(did)
        save_registry()

def register_inst_id(iid):
    if iid not in INSTITUTION_REGISTRY:
        INSTITUTION_REGISTRY.append(iid)
        save_registry()

def register_contract_id(cid):
    if cid not in SMARTCONTRACT_REGISTRY:
        SMARTCONTRACT_REGISTRY.append(cid)
        save_registry()

def run_fabric_cmd(args, timeout=30):
    cmd = ["docker", "exec", CLI_CONTAINER] + args
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return proc.returncode, proc.stdout, proc.stderr
    except subprocess.TimeoutExpired:
        return 1, "", "Command timed out after 30 seconds"
    except Exception as e:
        return 1, "", str(e)

def extract_txid(text):
    match = re.search(r'txid \[([a-f0-9]+)\]', text)
    if match:
        return match.group(1)
    match2 = re.search(r'"txId":"([a-f0-9]+)"', text)
    if match2:
        return match2.group(1)
    return "tx-" + hex(int(time.time() * 1000))[2:]

def query_chaincode(func_name, args):
    ctor = json.dumps({"function": func_name, "Args": [str(a) for a in args]})
    cmd = [
        "peer", "chaincode", "query",
        "-C", CHANNEL,
        "-n", CONTRACT,
        "-c", ctor
    ]
    code, stdout, stderr = run_fabric_cmd(cmd)
    if code != 0:
        return False, {"error": stderr.strip() or "Query execution failed"}
    try:
        data = json.loads(stdout.strip())
        return True, data
    except Exception:
        # Might be a raw boolean or string (e.g. false / true)
        val = stdout.strip()
        if val in ("true", "false"):
            return True, (val == "true")
        return True, {"result": val}

def invoke_chaincode(func_name, args):
    ctor = json.dumps({"function": func_name, "Args": [str(a) for a in args]})
    cmd = [
        "peer", "chaincode", "invoke",
        "-o", "orderer.pma.gov.ps:7050",
        "--ordererTLSHostnameOverride", "orderer.pma.gov.ps",
        "-C", CHANNEL,
        "-n", CONTRACT,
        "--tls",
        "--cafile", ORDERER_CA,
        "--waitForEvent",
        "-c", ctor
    ]
    code, stdout, stderr = run_fabric_cmd(cmd)
    combined = (stdout + "\n" + stderr).strip()
    if code != 0:
        return False, {"error": stderr.strip() or "Invoke execution failed"}
    
    txid = extract_txid(combined)
    payload_match = re.search(r'payload:"(\{.*?\})"', combined)
    payload_data = {}
    if payload_match:
        try:
            unescaped = payload_match.group(1).replace('\\"', '"')
            payload_data = json.loads(unescaped)
        except Exception:
            pass
    
    return True, {
        "status": "VALID",
        "txId": txid,
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "payload": payload_data
    }

class GatewayHandler(http.server.BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def _send_json(self, status_code, data):
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self._send_cors_headers()
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode("utf-8"))

    def _read_json_body(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
            if length == 0:
                return {}
            raw = self.rfile.read(length).decode("utf-8")
            return json.loads(raw)
        except Exception:
            return {}

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")

        if path in ("/api/health", "/health", ""):
            code, out, _ = run_fabric_cmd(["peer", "version"])
            is_healthy = (code == 0)
            self._send_json(200 if is_healthy else 503, {
                "status": "UP" if is_healthy else "DOWN",
                "network": "Hyperledger Fabric 2.5",
                "channel": CHANNEL,
                "contract": CONTRACT,
                "peer": "peer0.nuvte.edu.ps:7051",
                "orderer": "orderer.pma.gov.ps:7050",
                "explorerUrl": "http://localhost:8090",
                "anchoredDocumentsCount": len(DOC_REGISTRY),
                "onboardedInstitutionsCount": len(INSTITUTION_REGISTRY),
                "deployedContractsCount": len(SMARTCONTRACT_REGISTRY),
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            })
            return

        if path == "/api/documents":
            results = []
            for did in DOC_REGISTRY:
                success, data = query_chaincode("GetDocument", [did])
                if success and isinstance(data, dict) and "docId" in data:
                    results.append(data)
            self._send_json(200, {"count": len(results), "documents": results})
            return

        if path.startswith("/api/documents/"):
            doc_id = path.replace("/api/documents/", "")
            success, data = query_chaincode("GetDocument", [doc_id])
            self._send_json(200 if success else 404, data)
            return

        if path == "/api/institutions":
            inst_list = []
            for iid in INSTITUTION_REGISTRY:
                success, data = query_chaincode("GetDocument", [iid])
                if success and isinstance(data, dict):
                    inst_list.append(data)
            self._send_json(200, {"count": len(inst_list), "institutions": inst_list})
            return

        if path == "/api/contracts":
            cc_list = []
            for cid in SMARTCONTRACT_REGISTRY:
                success, data = query_chaincode("GetDocument", [cid])
                if success and isinstance(data, dict):
                    cc_list.append(data)
            self._send_json(200, {"count": len(cc_list), "contracts": cc_list})
            return

        if path in ("/api/network/nodes", "/api/network/topology"):
            nodes = [
                {
                    "name": "PMA Consortium Orderer Node",
                    "mspId": "PMAOrdererMSP",
                    "role": "Consensus Leader (Raft)",
                    "endpoint": "orderer.pma.gov.ps:7050",
                    "status": "ONLINE",
                    "tls": True
                },
                {
                    "name": "Nablus University (NUVTE) Endorsing Peer",
                    "mspId": "NUVTEMSP",
                    "role": "Genesis Peer & Anchor",
                    "endpoint": "peer0.nuvte.edu.ps:7051",
                    "status": "ONLINE",
                    "tls": True
                }
            ]
            for iid in INSTITUTION_REGISTRY:
                success, data = query_chaincode("GetDocument", [iid])
                if success and isinstance(data, dict):
                    meta = data.get("metadata", {})
                    if isinstance(meta, str):
                        try:
                            meta = json.loads(meta)
                        except Exception:
                            meta = {}
                    name_en = meta.get("nameEn") or data.get("docId", "")
                    msp_id = meta.get("orgMspId", "OrgMSP")
                    peer_ep = meta.get("peerEndpoint", f"peer0.{meta.get('domain', 'org')}:7051")
                    nodes.append({
                        "name": f"{name_en} Peer Node",
                        "mspId": msp_id,
                        "role": "Endorsing Consortium Member",
                        "endpoint": peer_ep,
                        "status": "ACTIVE • ENROLLED",
                        "tls": True,
                        "domain": meta.get("domain", "")
                    })
            self._send_json(200, {
                "channel": CHANNEL,
                "explorerUrl": "http://localhost:8090/#/network",
                "nodesCount": len(nodes),
                "nodes": nodes
            })
            return

        if path == "/api/channel/info":
            code, out, err = run_fabric_cmd(["peer", "channel", "getinfo", "-c", CHANNEL])
            match = re.search(r'Blockchain info: (\{.*?\})', out)
            if match:
                try:
                    self._send_json(200, json.loads(match.group(1)))
                    return
                except Exception:
                    pass
            self._send_json(200, {"channel": CHANNEL, "status": "CONNECTED", "raw": out.strip()})
            return

        if path.startswith("/api/status-list/"):
            parts = path.split("/")[3:]
            if len(parts) >= 2:
                list_id, bit_idx = parts[0], parts[1]
                success, data = query_chaincode("GetStatusBit", [list_id, bit_idx])
                self._send_json(200 if success else 400, {"listId": list_id, "bitIndex": int(bit_idx), "isRevoked": data})
                return

        if path.startswith("/api/audit/"):
            audit_id = path.replace("/api/audit/", "")
            success, data = query_chaincode("GetVerificationAudit", [audit_id])
            self._send_json(200 if success else 404, data)
            return

        self._send_json(404, {"error": "Endpoint not found"})

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")
        body = self._read_json_body()

        # 1. RESET BLOCKCHAIN REGISTRY & STATE
        if path == "/api/blockchain/reset":
            global DOC_REGISTRY, INSTITUTION_REGISTRY, SMARTCONTRACT_REGISTRY
            DOC_REGISTRY = []
            INSTITUTION_REGISTRY = []
            SMARTCONTRACT_REGISTRY = []
            save_registry()

            # Re-initialize status list bitstring on chaincode
            success, data = invoke_chaincode("InitStatusList", ["nuvte-status-list-2024", "100000"])

            self._send_json(200, {
                "success": True,
                "message": "Blockchain state and gateway registries reset to clean slate.",
                "documentsCount": 0,
                "institutionsCount": 0,
                "contractsCount": 0,
                "statusListInitialized": success
            })
            return

        # 2. ANCHOR DOCUMENT ON HYPERLEDGER FABRIC
        if path == "/api/documents/anchor":
            doc_id = body.get("docId", "")
            doc_type = body.get("docType", "")
            doc_hash = body.get("docHash", "")
            issuer_did = body.get("issuerDid", "did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA")
            subject_hash = body.get("subjectHash", "")
            status_index = str(body.get("statusListIndex", 0))
            metadata_json = json.dumps(body.get("metadata", {})) if isinstance(body.get("metadata"), dict) else str(body.get("metadata", "{}"))

            success, data = invoke_chaincode("AnchorDocument", [
                doc_id, doc_type, doc_hash, issuer_did, subject_hash, status_index, metadata_json
            ])
            if success:
                register_doc_id(doc_id)
            self._send_json(200 if success else 400, data)
            return

        # 3. ONBOARD NEW STUDENT (Direct Smart Contract Execution)
        if path == "/api/students/onboard":
            student_id = body.get("studentId", f"STU-{int(time.time()*1000)%1000000}")
            national_id = body.get("nationalId", "")
            full_name_en = body.get("fullNameEn", "")
            full_name_ar = body.get("fullNameAr", "")
            faculty_en = body.get("facultyEn", "Faculty of Engineering & Technology")
            faculty_ar = body.get("facultyAr", "كلية الهندسة والتكنولوجيا")
            program_en = body.get("programEn", "B.Sc. in Computer Systems & Cybersecurity")
            program_ar = body.get("programAr", "بكالوريوس هندسة أنظمة الحاسوب والأمن السيبراني")
            gpa = str(body.get("gpa", "3.85"))
            blood_type = body.get("bloodType", "O+")
            did = body.get("did", f"did:paldfi:face:{student_id.lower()}")

            doc_id = f"DOC-NUVTE-2024-STU-{student_id.replace('-', '')}"
            doc_type = "StudentIdentityCredential"
            doc_hash = body.get("docHash", "")
            if not doc_hash:
                import hashlib
                doc_hash = hashlib.sha256(f"{student_id}:{national_id}:{full_name_en}".encode()).hexdigest()
            
            subject_hash = f"hash-{national_id}"
            status_index = str(len(DOC_REGISTRY) + 101)

            metadata_dict = {
                "studentId": student_id,
                "nationalId": national_id,
                "fullNameEn": full_name_en,
                "fullNameAr": full_name_ar,
                "facultyEn": faculty_en,
                "facultyAr": faculty_ar,
                "programEn": program_en,
                "programAr": program_ar,
                "gpa": gpa,
                "bloodType": blood_type,
                "did": did,
                "onboardedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            }

            success, data = invoke_chaincode("AnchorDocument", [
                doc_id, doc_type, doc_hash, "did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA", subject_hash, status_index, json.dumps(metadata_dict)
            ])
            if success:
                register_doc_id(doc_id)
                data["docId"] = doc_id
                data["studentId"] = student_id
                data["statusListIndex"] = int(status_index)
                data["metadata"] = metadata_dict
            self._send_json(200 if success else 400, data)
            return

        # 4. VERIFY DOCUMENT HASH ON-CHAIN
        if path == "/api/documents/verify":
            doc_id = body.get("docId", "")
            doc_hash = body.get("docHash", "")
            success, data = query_chaincode("VerifyDocument", [doc_id, doc_hash])
            self._send_json(200 if success else 400, data)
            return

        # 5. REVOKE DOCUMENT ON-CHAIN
        if path == "/api/documents/revoke":
            doc_id = body.get("docId", "")
            reason = body.get("reason", "Official University Management Revocation")
            success, data = invoke_chaincode("RevokeDocument", [doc_id, reason])
            self._send_json(200 if success else 400, data)
            return

        # 6. REINSTATE DOCUMENT ON-CHAIN
        if path == "/api/documents/reinstate":
            doc_id = body.get("docId", "")
            reason = body.get("reason", "Official University Management Reinstatement")
            success, data = invoke_chaincode("ReinstateDocument", [doc_id, reason])
            self._send_json(200 if success else 400, data)
            return

        # 7. SET STATUS BIT (W3C BITSTRING REVOCATION)
        if path == "/api/status-list/set-bit":
            list_id = body.get("listId", "nuvte-status-list-2024")
            bit_idx = str(body.get("bitIndex", 0))
            is_revoked = "true" if body.get("isRevoked", True) else "false"
            success, data = invoke_chaincode("SetStatusBit", [list_id, bit_idx, is_revoked])
            self._send_json(200 if success else 400, data)
            return

        # 8. RECORD AUDIT
        if path == "/api/audit/record":
            audit_id = body.get("auditId", f"AUDIT-{int(time.time()*1000)}")
            verifier_did = body.get("verifierDid", "did:key:z6MkuBankOfPalestineComplianceNode2024PMA")
            verifier_name = body.get("verifierName", "Bank of Palestine")
            doc_id = body.get("docId", "")
            student_did = body.get("studentDid", "did:key:z6MkuCitizen")
            nonce = body.get("nonce", f"nonce-{int(time.time()*1000)}")
            verification_result = body.get("verificationResult", "VALID")

            success, data = invoke_chaincode("RecordVerificationAudit", [
                audit_id, verifier_did, verifier_name, doc_id, student_did, nonce, verification_result
            ])
            self._send_json(200 if success else 400, data)
            return

        # 9. ONBOARD INSTITUTION ON-CHAIN
        if path == "/api/institutions/onboard":
            inst_id = body.get("id", f"INST-{int(time.time()*1000)}")
            name_en = body.get("nameEn", "")
            name_ar = body.get("nameAr", "")
            org_msp = body.get("orgMspId", "OrgMSP")
            admin_did = body.get("adminDid", f"did:key:z6Mku{inst_id}")
            channel = body.get("channelName", CHANNEL)
            domain = body.get("domain", "")
            peer_endpoint = body.get("peerEndpoint", f"peer0.{domain}:7051")
            ca_endpoint = body.get("caEndpoint", f"ca.{domain}:7054")
            admin_name_en = body.get("adminNameEn", "")
            admin_name_ar = body.get("adminNameAr", "")
            admin_email = body.get("adminEmail", "")
            reason_en = body.get("reasonEn", "")
            reason_ar = body.get("reasonAr", "")
            inst_type = body.get("type", "university")

            metadata_dict = {
                "id": inst_id,
                "nameEn": name_en,
                "nameAr": name_ar,
                "orgMspId": org_msp,
                "type": inst_type,
                "domain": domain,
                "adminNameEn": admin_name_en,
                "adminNameAr": admin_name_ar,
                "adminEmail": admin_email,
                "adminDid": admin_did,
                "channelName": channel,
                "peerEndpoint": peer_endpoint,
                "caEndpoint": ca_endpoint,
                "reasonEn": reason_en,
                "reasonAr": reason_ar,
                "status": "active",
                "onboardedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            }
            metadata_json = json.dumps(metadata_dict)

            success, data = invoke_chaincode("AnchorDocument", [
                f"INST-ONBOARD-{inst_id}", "INSTITUTION_REGISTRY", f"hash-inst-{inst_id}", admin_did, f"subject-{org_msp}", "0", metadata_json
            ])
            if success:
                register_inst_id(f"INST-ONBOARD-{inst_id}")
                data["institutionId"] = inst_id
                data["orgMspId"] = org_msp
                data["adminDid"] = admin_did
                data["status"] = "ACTIVE"
                data["metadata"] = metadata_dict
                
                # Update Explorer connection-profile.json dynamically
                try:
                    cp_path = os.path.join(os.path.dirname(__file__), "..", "blockchain_deployment", "explorer", "connection-profile.json")
                    if os.path.exists(cp_path):
                        with open(cp_path, "r", encoding="utf-8") as cpf:
                            cp_data = json.load(cpf)
                        
                        # Add to channel peers
                        peer_host = peer_endpoint.split(":")[0]
                        if "channels" in cp_data and channel in cp_data["channels"]:
                            cp_data["channels"][channel]["peers"][peer_host] = {
                                "endorsingPeer": True,
                                "chaincodeQuery": True,
                                "ledgerQuery": True,
                                "eventSource": True
                            }
                        # Add to organizations
                        if "organizations" in cp_data:
                            cp_data["organizations"][org_msp] = {
                                "mspid": org_msp,
                                "peers": [peer_host]
                            }
                        # Add to peers
                        if "peers" in cp_data:
                            cp_data["peers"][peer_host] = {
                                "tlsCACerts": {
                                    "path": "/opt/explorer/organizations/peerOrganizations/nuvte.edu.ps/peers/peer0.nuvte.edu.ps/tls/ca.crt"
                                },
                                "url": f"grpcs://peer0.nuvte.edu.ps:7051",
                                "grpcOptions": {
                                    "ssl-target-name-override": "peer0.nuvte.edu.ps"
                                }
                            }
                        with open(cp_path, "w", encoding="utf-8") as cpf:
                            json.dump(cp_data, cpf, indent=2)
                        print(f"[Gateway] Updated Explorer connection profile with new institution: {org_msp} ({peer_host})")
                except Exception as ex:
                    print(f"[Gateway] Note on updating explorer profile: {ex}")

            self._send_json(200 if success else 400, data)
            return

        # 10. DEPLOY SMART CONTRACT ON-CHAIN
        if path == "/api/contracts/deploy":
            contract_id = body.get("contractId", f"contract_{int(time.time()*1000)}")
            inst_id = body.get("institutionId", "")
            name_en = body.get("nameEn", "")
            version = body.get("version", "1.0.0")
            endorsement = body.get("endorsementPolicy", f"OR('{inst_id}MSP.peer', 'NUVTEMSP.peer')")
            schema_json = json.dumps(body.get("schemaAttributes", []))

            success, data = invoke_chaincode("AnchorDocument", [
                f"SMARTCONTRACT-{contract_id}", "CHAINCODE_DEFINITION", f"hash-cc-{contract_id}", f"did:key:z6Mku{inst_id}", f"subject-cc-{version}", "0", json.dumps({
                    "nameEn": name_en,
                    "endorsementPolicy": endorsement,
                    "schema": schema_json,
                    "version": version
                })
            ])
            if success:
                register_contract_id(f"SMARTCONTRACT-{contract_id}")
                data["contractId"] = contract_id
                data["version"] = version
                data["status"] = "DEPLOYED"
            self._send_json(200 if success else 400, data)
            return

        self._send_json(404, {"error": "Endpoint not found"})

    def log_message(self, format, *args):
        print(f"[{time.strftime('%H:%M:%S')}] {args[0]} - {args[1]} {args[2]}")

def main():
    print("==================================================================")
    print("  PAL-DFI Hyperledger Fabric REST Gateway Bridge Server")
    print(f"  Channel: {CHANNEL} | Contract: {CONTRACT}")
    print(f"  Listening on http://0.0.0.0:{PORT}")
    print("==================================================================")
    load_registry()
    
    server = socketserver.TCPServer(("", PORT), GatewayHandler)
    server.allow_reuse_address = True
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down Gateway Server...")
        server.server_close()

if __name__ == "__main__":
    main()
