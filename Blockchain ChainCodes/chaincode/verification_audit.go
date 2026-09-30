package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

const (
	AuditPrefix = "AUDIT_"
)

// RecordVerificationAudit logs an immutable third-party credential verification event
func (c *PalDfiContract) RecordVerificationAudit(
	ctx contractapi.TransactionContextInterface,
	auditID string,
	verifierDID string,
	verifierName string,
	docID string,
	studentDID string,
	nonce string,
	verificationResult string,
) (*VerificationAudit, error) {
	if auditID == "" || verifierDID == "" || docID == "" {
		return nil, fmt.Errorf("auditID, verifierDID, and docID must not be empty")
	}

	key := AuditPrefix + auditID
	existing, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to query ledger: %v", err)
	}
	if existing != nil {
		return nil, fmt.Errorf("audit record '%s' already exists", auditID)
	}

	txID := ctx.GetStub().GetTxID()
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	var timestamp string
	if err == nil && txTimestamp != nil {
		timestamp = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)
	} else {
		timestamp = time.Now().UTC().Format(time.RFC3339)
	}

	audit := VerificationAudit{
		AuditID:            auditID,
		VerifierDID:        verifierDID,
		VerifierName:       verifierName,
		DocID:              docID,
		StudentDID:         studentDID,
		Nonce:              nonce,
		VerificationResult: verificationResult,
		Timestamp:          timestamp,
		TxID:               txID,
	}

	bytes, err := json.Marshal(audit)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal audit record: %v", err)
	}

	if err := ctx.GetStub().PutState(key, bytes); err != nil {
		return nil, fmt.Errorf("failed to save audit record: %v", err)
	}

	_ = ctx.GetStub().SetEvent("VerificationAudited", bytes)
	return &audit, nil
}

// GetVerificationAudit retrieves a specific audit log by its unique ID
func (c *PalDfiContract) GetVerificationAudit(
	ctx contractapi.TransactionContextInterface,
	auditID string,
) (*VerificationAudit, error) {
	key := AuditPrefix + auditID
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to read from ledger: %v", err)
	}
	if bytes == nil {
		return nil, fmt.Errorf("audit record '%s' not found", auditID)
	}

	var audit VerificationAudit
	if err := json.Unmarshal(bytes, &audit); err != nil {
		return nil, fmt.Errorf("failed to unmarshal audit record: %v", err)
	}

	return &audit, nil
}
