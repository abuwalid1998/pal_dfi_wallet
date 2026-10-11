package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract defines the PAL-DFI Academic Credential Smart Contract
type SmartContract struct {
	contractapi.Contract
}

// AcademicAnchor represents an on-chain zero-PII credential anchor
type AcademicAnchor struct {
	DocumentHash     string `json:"documentHash"`
	CredentialType   string `json:"credentialType"`
	IssuerDID        string `json:"issuerDID"`
	StatusBitIndex   int    `json:"statusBitIndex"`
	RevocationStatus bool   `json:"revocationStatus"` // false = Valid, true = Revoked
	ZKPRootDigest    string `json:"zkpRootDigest"`
	Timestamp        string `json:"timestamp"`
	TxID             string `json:"txId"`
}

// InitLedger initializes the ledger with genesis state
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Println("PAL-DFI Academic Contract initialized under PMA Sandbox.")
	return nil
}

// AnchorDocument anchors a cryptographic hash of an academic certificate (Zero-PII)
func (s *SmartContract) AnchorDocument(ctx contractapi.TransactionContextInterface, docHash string, credType string, issuerDID string, bitIndex int, zkpDigest string, timestamp string) error {
	exists, err := s.DocumentExists(ctx, docHash)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the document hash %s is already anchored on-chain", docHash)
	}

	txID := ctx.GetStub().GetTxID()
	record := AcademicAnchor{
		DocumentHash:     docHash,
		CredentialType:   credType,
		IssuerDID:        issuerDID,
		StatusBitIndex:   bitIndex,
		RevocationStatus: false,
		ZKPRootDigest:    zkpDigest,
		Timestamp:        timestamp,
		TxID:             txID,
	}

	recordJSON, err := json.Marshal(record)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(docHash, recordJSON)
}

// VerifyStatus queries the revocation state of an anchored credential
func (s *SmartContract) VerifyStatus(ctx contractapi.TransactionContextInterface, docHash string) (*AcademicAnchor, error) {
	recordJSON, err := ctx.GetStub().GetState(docHash)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if recordJSON == nil {
		return nil, fmt.Errorf("document hash %s does not exist on-chain", docHash)
	}

	var record AcademicAnchor
	err = json.Unmarshal(recordJSON, &record)
	if err != nil {
		return nil, err
	}

	return &record, nil
}

// RevokeDocument marks a credential as revoked in the sovereign status registry
func (s *SmartContract) RevokeDocument(ctx contractapi.TransactionContextInterface, docHash string) error {
	record, err := s.VerifyStatus(ctx, docHash)
	if err != nil {
		return err
	}

	record.RevocationStatus = true
	recordJSON, err := json.Marshal(record)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(docHash, recordJSON)
}

// DocumentExists returns true when document hash is anchored
func (s *SmartContract) DocumentExists(ctx contractapi.TransactionContextInterface, docHash string) (bool, error) {
	recordJSON, err := ctx.GetStub().GetState(docHash)
	if err != nil {
		return false, fmt.Errorf("failed to read world state: %v", err)
	}
	return recordJSON != nil, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating paldfi_academic_contract: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting paldfi_academic_contract: %s", err.Error())
	}
}
