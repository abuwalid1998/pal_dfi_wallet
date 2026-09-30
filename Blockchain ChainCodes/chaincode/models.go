package main

import "time"

// DocumentType represents the official supported Palestinian academic credentials
type DocumentType string

const (
	DocTypeStudentID  DocumentType = "StudentIdentityCredential"
	DocTypeGraduation DocumentType = "GraduationCertificateCredential"
	DocTypeClearance  DocumentType = "ClearanceCertificateCredential"
)

// DocumentStatus represents the cryptographic lifecycle status of an anchor
type DocumentStatus string

const (
	StatusActive    DocumentStatus = "ACTIVE"
	StatusRevoked   DocumentStatus = "REVOKED"
	StatusSuspended DocumentStatus = "SUSPENDED"
)

// AcademicDocument represents the Zero-PII on-chain anchor for an academic document
type AcademicDocument struct {
	DocID            string         `json:"docId"`
	DocType          DocumentType   `json:"docType"`
	DocHash          string         `json:"docHash"`          // SHA-256 digest of decrypted W3C credential
	IssuerDID        string         `json:"issuerDid"`        // NUVTE Sovereign DID
	SubjectHash      string         `json:"subjectHash"`      // SHA-256 digest of National ID (Zero-PII)
	StatusListIndex  int            `json:"statusListIndex"`  // Bit index in BitstringStatusList2021
	Status           DocumentStatus `json:"status"`           // ACTIVE, REVOKED, SUSPENDED
	IssuanceDate     string         `json:"issuanceDate"`     // RFC3339 timestamp
	RevocationDate   string         `json:"revocationDate"`
	RevocationReason string         `json:"revocationReason"`
	TxID             string         `json:"txId"`
	MetadataJSON     string         `json:"metadataJson"` // Non-PII metadata (faculty, program, honors)
}

// StatusList implements the W3C BitstringStatusList2021 on-chain structure
type StatusList struct {
	ListID      string `json:"listId"`
	Capacity    int    `json:"capacity"`    // Total credentials slots (e.g. 100,000)
	EncodedBits string `json:"encodedBits"` // Base64 encoded bitstring
	LastUpdated string `json:"lastUpdated"`
}

// VerificationAudit records tamper-proof verification proofs for third-party verifiers
type VerificationAudit struct {
	AuditID            string `json:"auditId"`
	VerifierDID        string `json:"verifierDid"`  // e.g. did:key for Bank of Palestine
	VerifierName       string `json:"verifierName"` // Human-readable entity name
	DocID              string `json:"docId"`
	StudentDID         string `json:"studentDid"`
	Nonce              string `json:"nonce"` // Cryptographic single-use nonce
	VerificationResult string `json:"verificationResult"`
	Timestamp          string `json:"timestamp"`
	TxID               string `json:"txId"`
}

// VerificationResponse returned during third-party ledger verification queries
type VerificationResponse struct {
	IsValid               bool           `json:"isValid"`
	IsRevoked             bool           `json:"isRevoked"`
	DocID                 string         `json:"docId"`
	DocType               DocumentType   `json:"docType"`
	DocHash               string         `json:"docHash"`
	Status                DocumentStatus `json:"status"`
	IssuanceDate          string         `json:"issuanceDate"`
	VerificationTimestamp string         `json:"verificationTimestamp"`
	TxID                  string         `json:"txId"`
	Message               string         `json:"message"`
}

// HistoryRecord represents an immutable provenance ledger change
type HistoryRecord struct {
	TxID      string            `json:"txId"`
	Timestamp time.Time         `json:"timestamp"`
	IsDelete  bool              `json:"isDelete"`
	Value     *AcademicDocument `json:"value"`
}
