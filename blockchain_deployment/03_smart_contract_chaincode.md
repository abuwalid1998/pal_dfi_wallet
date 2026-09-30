# 03 - Smart Contract Chaincode: BitstringStatusList2021 & Document Anchoring

This contract implements W3C `BitstringStatusList2021` and Zero-PII cryptographic document anchoring on Hyperledger Fabric 2.5 using Go.

---

## 1. Chaincode Source Code (`chaincode/paldfi_contract.go`)

```go
package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing PAL-DFI credentials
type SmartContract struct {
	contractapi.Contract
}

// DocumentAnchor stores strictly ZERO PII on-chain
type DocumentAnchor struct {
	DocHash        string    `json:"docHash"`        // SHA-256 hash of credential
	DocType        string    `json:"docType"`        // ID, Graduation, Clearance
	StudentIdHash  string    `json:"studentIdHash"`  // SHA-256 hash of STU-XXXXXX
	StatusBitIndex int       `json:"statusBitIndex"` // Index in BitstringStatusList2021
	IssuerDID      string    `json:"issuerDID"`      // did:paldfi:nuvte:registrar-root-ca
	Timestamp      time.Time `json:"timestamp"`
	BlockNumber    uint64    `json:"blockNumber"`
}

// BitstringRegistry stores status bits (0 = Active, 1 = Revoked)
type BitstringRegistry struct {
	ListID      string `json:"listID"`      // https://identity.nuvte.edu.ps/status/2021
	TotalBits   int    `json:"totalBits"`   // 100,000 capacity
	EncodedBits string `json:"encodedBits"` // GZIP-compressed base64 bitstring
}

// StatusBitRecord individual bit lookup
type StatusBitRecord struct {
	BitIndex  int  `json:"bitIndex"`
	IsRevoked bool `json:"isRevoked"`
}

// InitLedger initializes the BitstringStatusList2021 registry
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	registry := BitstringRegistry{
		ListID:      "https://identity.nuvte.edu.ps/status/status-list-2021.json",
		TotalBits:   100000,
		EncodedBits: "eJztwTEBAAAAwqD1T20JT6AAAAAAAAAAAAAAAOBvCDAAAQ==",
	}

	registryBytes, err := json.Marshal(registry)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState("BITSTRING_REGISTRY_ROOT", registryBytes)
}

// AnchorDocument registers a SHA-256 document hash on-chain (Strictly Zero PII)
// Accessible only by NUVTE Registrar
func (s *SmartContract) AnchorDocument(
	ctx contractapi.TransactionContextInterface,
	docHash string,
	docType string,
	studentIdHash string,
	statusBitIndex int,
) error {
	// Verify caller identity belongs to NuvteMSP
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil || clientMSPID != "NuvteMSP" {
		return fmt.Errorf("unauthorized: only NuvteMSP registrar can anchor documents")
	}

	txTimestamp, _ := ctx.GetStub().GetTxTimestamp()
	anchor := DocumentAnchor{
		DocHash:        docHash,
		DocType:        docType,
		StudentIdHash:  studentIdHash,
		StatusBitIndex: statusBitIndex,
		IssuerDID:      "did:paldfi:nuvte:registrar-root-ca",
		Timestamp:      time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)),
	}

	anchorBytes, err := json.Marshal(anchor)
	if err != nil {
		return err
	}

	// Key: DOC_<SHA256>
	key := fmt.Sprintf("DOC_%s", docHash)
	return ctx.GetStub().PutState(key, anchorBytes)
}

// CheckRevocationBit queries the BitstringStatusList2021 index (< 3.0s response time)
// Accessible to anyone (Public Verifier, Student, Employer)
func (s *SmartContract) CheckRevocationBit(
	ctx contractapi.TransactionContextInterface,
	bitIndex int,
) (*StatusBitRecord, error) {
	key := fmt.Sprintf("BIT_%d", bitIndex)
	bitBytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to read from ledger: %v", err)
	}

	if bitBytes == nil {
		// Default bit value 0 = Active
		return &StatusBitRecord{BitIndex: bitIndex, IsRevoked: false}, nil
	}

	var record StatusBitRecord
	err = json.Unmarshal(bitBytes, &record)
	if err != nil {
		return nil, err
	}

	return &record, nil
}

// SetRevocationBit toggles the revocation status bit (0=Active, 1=Revoked)
// Accessible only by authorized NUVTE University Management
func (s *SmartContract) SetRevocationBit(
	ctx contractapi.TransactionContextInterface,
	bitIndex int,
	isRevoked bool,
) error {
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil || clientMSPID != "NuvteMSP" {
		return fmt.Errorf("unauthorized: only NUVTE University Management can revoke credentials")
	}

	record := StatusBitRecord{
		BitIndex:  bitIndex,
		IsRevoked: isRevoked,
	}

	recordBytes, err := json.Marshal(record)
	if err != nil {
		return err
	}

	key := fmt.Sprintf("BIT_%d", bitIndex)
	return ctx.GetStub().PutState(key, recordBytes)
}

// GetDocumentAnchor verifies if a SHA-256 hash was anchored by NUVTE
func (s *SmartContract) GetDocumentAnchor(
	ctx contractapi.TransactionContextInterface,
	docHash string,
) (*DocumentAnchor, error) {
	key := fmt.Sprintf("DOC_%s", docHash)
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil || bytes == nil {
		return nil, fmt.Errorf("document anchor not found on ledger")
	}

	var anchor DocumentAnchor
	err = json.Unmarshal(bytes, &anchor)
	if err != nil {
		return nil, err
	}

	return &anchor, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating PAL-DFI chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting PAL-DFI chaincode: %v\n", err)
	}
}
```

---

## 2. Packaging & Deploying Chaincode

Compile and vendor Go dependencies:
```bash
cd chaincode
go mod init paldfi-contract
go mod tidy
go build
```
