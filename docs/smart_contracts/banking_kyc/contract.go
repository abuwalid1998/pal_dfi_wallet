package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type BankingKYCContract struct {
	contractapi.Contract
}

type SolvencyAttestation struct {
	AccountDigest             string `json:"accountDigest"`
	KYCClearanceBit           int    `json:"kycClearanceBit"`
	CreditScoreRangeProof     string `json:"creditScoreRangeProof"`
	SolvencyThresholdVerified bool   `json:"solvencyThresholdVerified"`
	IssuingBankMSP            string `json:"issuingBankMSP"`
	AuditNonce                string `json:"auditNonce"`
}

func (c *BankingKYCContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Println("PAL-DFI Banking Solvency Contract initialized.")
	return nil
}

func (c *BankingKYCContract) SubmitSolvencyProof(ctx contractapi.TransactionContextInterface, accDigest string, kycBit int, zkpProof string, thresholdMet bool) error {
	record := SolvencyAttestation{
		AccountDigest:             accDigest,
		KYCClearanceBit:           kycBit,
		CreditScoreRangeProof:     zkpProof,
		SolvencyThresholdVerified: thresholdMet,
		IssuingBankMSP:            "BOPMSP",
		AuditNonce:                ctx.GetStub().GetTxID(),
	}

	bytes, err := json.Marshal(record)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(accDigest, bytes)
}

func (c *BankingKYCContract) QuerySolvency(ctx contractapi.TransactionContextInterface, accDigest string) (*SolvencyAttestation, error) {
	bytes, err := ctx.GetStub().GetState(accDigest)
	if err != nil || bytes == nil {
		return nil, fmt.Errorf("solvency proof not found for: %s", accDigest)
	}
	var record SolvencyAttestation
	if err := json.Unmarshal(bytes, &record); err != nil {
		return nil, err
	}
	return &record, nil
}

func main() {
	cc, err := contractapi.NewChaincode(&BankingKYCContract{})
	if err != nil {
		fmt.Printf("Error creating banking contract: %s", err.Error())
		return
	}
	cc.Start()
}
