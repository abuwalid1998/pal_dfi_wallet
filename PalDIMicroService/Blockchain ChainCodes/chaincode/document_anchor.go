package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

const (
	DocPrefix        = "DOC_"
	DefaultStatusList = "nuvte-status-list-2024"
)

// AnchorDocument registers a Zero-PII academic credential on-chain
func (c *PalDfiContract) AnchorDocument(
	ctx contractapi.TransactionContextInterface,
	docID string,
	docType string,
	docHash string,
	issuerDID string,
	subjectHash string,
	statusListIndex int,
	metadataJSON string,
) (*AcademicDocument, error) {
	if docID == "" || docHash == "" {
		return nil, fmt.Errorf("docID and docHash must not be empty")
	}

	key := DocPrefix + docID
	existing, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to query ledger: %v", err)
	}
	if existing != nil {
		return nil, fmt.Errorf("document '%s' already anchored on ledger", docID)
	}

	txID := ctx.GetStub().GetTxID()
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	var issDate string
	if err == nil && txTimestamp != nil {
		issDate = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)
	} else {
		issDate = time.Now().UTC().Format(time.RFC3339)
	}

	doc := AcademicDocument{
		DocID:           docID,
		DocType:         DocumentType(docType),
		DocHash:         docHash,
		IssuerDID:       issuerDID,
		SubjectHash:     subjectHash,
		StatusListIndex: statusListIndex,
		Status:          StatusActive,
		IssuanceDate:    issDate,
		TxID:            txID,
		MetadataJSON:    metadataJSON,
	}

	// Ensure the bit in BitstringStatusList2021 is set to 0 (valid)
	_ = c.SetStatusBit(ctx, DefaultStatusList, statusListIndex, false)

	docBytes, err := json.Marshal(doc)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal document: %v", err)
	}

	if err := ctx.GetStub().PutState(key, docBytes); err != nil {
		return nil, fmt.Errorf("failed to save document to ledger: %v", err)
	}

	_ = ctx.GetStub().SetEvent("DocumentAnchored", docBytes)
	return &doc, nil
}

// VerifyDocument evaluates the on-chain anchor integrity and W3C Bitstring revocation status
func (c *PalDfiContract) VerifyDocument(
	ctx contractapi.TransactionContextInterface,
	docID string,
	docHash string,
) (*VerificationResponse, error) {
	key := DocPrefix + docID
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to read document from ledger: %v", err)
	}
	if bytes == nil {
		return &VerificationResponse{
			IsValid:               false,
			IsRevoked:             false,
			DocID:                 docID,
			DocHash:               docHash,
			VerificationTimestamp: time.Now().UTC().Format(time.RFC3339),
			Message:               "Document not found on ledger",
		}, nil
	}

	var doc AcademicDocument
	if err := json.Unmarshal(bytes, &doc); err != nil {
		return nil, fmt.Errorf("failed to unmarshal document: %v", err)
	}

	// 1. Verify cryptographic hash match
	hashMatches := (doc.DocHash == docHash)

	// 2. Query BitstringStatusList2021 bit
	isBitRevoked, err := c.GetStatusBit(ctx, DefaultStatusList, doc.StatusListIndex)
	if err != nil {
		isBitRevoked = (doc.Status == StatusRevoked)
	}

	isRevoked := isBitRevoked || (doc.Status == StatusRevoked)
	isValid := hashMatches && !isRevoked

	message := "Document is valid, authentic, and actively registered on Hyperledger Fabric."
	if !hashMatches {
		message = "Cryptographic integrity failure: presented hash does not match on-chain anchor."
	} else if isRevoked {
		message = fmt.Sprintf("Document has been officially revoked. Reason: %s", doc.RevocationReason)
	}

	resp := &VerificationResponse{
		IsValid:               isValid,
		IsRevoked:             isRevoked,
		DocID:                 doc.DocID,
		DocType:               doc.DocType,
		DocHash:               doc.DocHash,
		Status:                doc.Status,
		IssuanceDate:          doc.IssuanceDate,
		VerificationTimestamp: time.Now().UTC().Format(time.RFC3339),
		TxID:                  ctx.GetStub().GetTxID(),
		Message:               message,
	}

	return resp, nil
}

// RevokeDocument marks an academic document as revoked and flips its W3C bit
func (c *PalDfiContract) RevokeDocument(
	ctx contractapi.TransactionContextInterface,
	docID string,
	reason string,
) (*AcademicDocument, error) {
	key := DocPrefix + docID
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to query ledger: %v", err)
	}
	if bytes == nil {
		return nil, fmt.Errorf("document '%s' does not exist", docID)
	}

	var doc AcademicDocument
	if err := json.Unmarshal(bytes, &doc); err != nil {
		return nil, fmt.Errorf("failed to unmarshal document: %v", err)
	}

	if doc.Status == StatusRevoked {
		return &doc, nil // Already revoked
	}

	// Flip Bitstring bit to 1 (Revoked)
	if err := c.SetStatusBit(ctx, DefaultStatusList, doc.StatusListIndex, true); err != nil {
		return nil, fmt.Errorf("failed to update status list bit: %v", err)
	}

	doc.Status = StatusRevoked
	doc.RevocationDate = time.Now().UTC().Format(time.RFC3339)
	doc.RevocationReason = reason

	updatedBytes, err := json.Marshal(doc)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal revoked document: %v", err)
	}

	if err := ctx.GetStub().PutState(key, updatedBytes); err != nil {
		return nil, fmt.Errorf("failed to update ledger: %v", err)
	}

	_ = ctx.GetStub().SetEvent("DocumentRevoked", updatedBytes)
	return &doc, nil
}

// ReinstateDocument clears revocation for an academic document and flips its W3C bit back to 0 (Active)
func (c *PalDfiContract) ReinstateDocument(
	ctx contractapi.TransactionContextInterface,
	docID string,
	reason string,
) (*AcademicDocument, error) {
	key := DocPrefix + docID
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to query ledger: %v", err)
	}
	if bytes == nil {
		return nil, fmt.Errorf("document '%s' does not exist", docID)
	}

	var doc AcademicDocument
	if err := json.Unmarshal(bytes, &doc); err != nil {
		return nil, fmt.Errorf("failed to unmarshal document: %v", err)
	}

	// Flip Bitstring bit to 0 (Active)
	if err := c.SetStatusBit(ctx, DefaultStatusList, doc.StatusListIndex, false); err != nil {
		return nil, fmt.Errorf("failed to update status list bit: %v", err)
	}

	doc.Status = StatusActive
	doc.RevocationDate = ""
	doc.RevocationReason = reason

	updatedBytes, err := json.Marshal(doc)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal reinstated document: %v", err)
	}

	if err := ctx.GetStub().PutState(key, updatedBytes); err != nil {
		return nil, fmt.Errorf("failed to update ledger: %v", err)
	}

	_ = ctx.GetStub().SetEvent("DocumentReinstated", updatedBytes)
	return &doc, nil
}

// GetDocument returns the stored document anchor
func (c *PalDfiContract) GetDocument(
	ctx contractapi.TransactionContextInterface,
	docID string,
) (*AcademicDocument, error) {
	key := DocPrefix + docID
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to query ledger: %v", err)
	}
	if bytes == nil {
		return nil, fmt.Errorf("document '%s' not found", docID)
	}

	var doc AcademicDocument
	if err := json.Unmarshal(bytes, &doc); err != nil {
		return nil, fmt.Errorf("failed to unmarshal document: %v", err)
	}

	return &doc, nil
}

// GetDocumentHistory retrieves the complete immutable audit trail of a document
func (c *PalDfiContract) GetDocumentHistory(
	ctx contractapi.TransactionContextInterface,
	docID string,
) ([]HistoryRecord, error) {
	key := DocPrefix + docID
	iter, err := ctx.GetStub().GetHistoryForKey(key)
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve history: %v", err)
	}
	defer iter.Close()

	var records []HistoryRecord
	for iter.HasNext() {
		mod, err := iter.Next()
		if err != nil {
			return nil, fmt.Errorf("error reading history iterator: %v", err)
		}

		var doc AcademicDocument
		if len(mod.Value) > 0 {
			_ = json.Unmarshal(mod.Value, &doc)
		}

		records = append(records, HistoryRecord{
			TxID:      mod.TxId,
			Timestamp: time.Unix(mod.Timestamp.Seconds, int64(mod.Timestamp.Nanos)).UTC(),
			IsDelete:  mod.IsDelete,
			Value:     &doc,
		})
	}

	return records, nil
}
