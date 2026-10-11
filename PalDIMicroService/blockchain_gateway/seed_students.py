import urllib.request
import json
import time

docs = [
    {
        'docId': 'DOC-NUVTE-2024-STU-105',
        'docType': 'StudentIdentityCredential',
        'docHash': 'b5e1c0d48f72a91e4c76b91d2345e8a1f6c7d8e90a1b2c3d4e5f60718293a4b5',
        'issuerDid': 'did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA',
        'subjectHash': '984123567-yara-mansour',
        'statusListIndex': 105,
        'metadata': {'studentId': 'STU-2024105', 'program': 'B.Tech. Renewable Energy', 'gpa': '3.92'}
    },
    {
        'docId': 'DOC-NUVTE-2024-GRAD-105',
        'docType': 'GraduationCertificateCredential',
        'docHash': 'c6f2d1e59a83b02f5d87c02e3456f9b2a7d8e9f01b2c3d4e5f60718293a4b5c6',
        'issuerDid': 'did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA',
        'subjectHash': '984123567-yara-mansour',
        'statusListIndex': 106,
        'metadata': {'studentId': 'STU-2024105', 'honors': 'First Class Honors', 'gpa': '3.92'}
    },
    {
        'docId': 'DOC-NUVTE-2023-STU-012',
        'docType': 'StudentIdentityCredential',
        'docHash': 'd7a3e2f60b94c13a6e98d13f4567a0c3b8e9f0a12c3d4e5f60718293a4b5c6d7',
        'issuerDid': 'did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA',
        'subjectHash': '971842901-kareem-alqadi',
        'statusListIndex': 99,
        'metadata': {'studentId': 'STU-2023012', 'program': 'Diploma Fintech', 'gpa': '2.10'}
    }
]

for d in docs:
    data = json.dumps(d).encode()
    req = urllib.request.Request('http://localhost:5050/api/documents/anchor', data=data, headers={'Content-Type': 'application/json'})
    try:
        res = urllib.request.urlopen(req)
        print("Anchored " + d["docId"] + ": " + res.read().decode()[:80])
    except Exception as e:
        print("Error " + d["docId"] + ": " + str(e))
    time.sleep(1)

# Revoke Kareem on chain
rev_data = json.dumps({'docId': 'DOC-NUVTE-2023-STU-012', 'reason': 'Disciplinary Suspension'}).encode()
req = urllib.request.Request('http://localhost:5050/api/documents/revoke', data=rev_data, headers={'Content-Type': 'application/json'})
try:
    res = urllib.request.urlopen(req)
    print("Revoked DOC-NUVTE-2023-STU-012: " + res.read().decode()[:80])
except Exception as e:
    print("Error revoking: " + str(e))
