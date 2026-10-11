package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LandContract struct {
	contractapi.Contract
}

type LandTitleRecord struct {
	ParcelIDHash         string `json:"parcelIdHash"`
	ZoneCode             string `json:"zoneCode"`
	TitleDeedHash        string `json:"titleDeedHash"`
	MunicipalPermitBit   int    `json:"municipalPermitBit"`
	OwnerBlindedZKPProof string `json:"ownerBlindedZkpProof"`
	IsDisputed           bool   `json:"isDisputed"`
	LastTransferTxID     string `json:"lastTransferTxId"`
}

func (c *LandContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Println("PAL-DFI Land Registry Contract initialized.")
	return nil
}

func (c *LandContract) RegisterDeed(ctx contractapi.TransactionContextInterface, parcelHash string, zone string, deedHash string, permitBit int, zkpProof string) error {
	existing, err := ctx.GetStub().GetState(parcelHash)
	if err != nil {
		return err
	}
	if existing != nil {
		return fmt.Errorf("parcel deed hash %s already registered", parcelHash)
	}

	record := LandTitleRecord{
		ParcelIDHash:         parcelHash,
		ZoneCode:             zone,
		TitleDeedHash:        deedHash,
		MunicipalPermitBit:   permitBit,
		OwnerBlindedZKPProof: zkpProof,
		IsDisputed:           false,
		LastTransferTxID:     ctx.GetStub().GetTxID(),
	}

	bytes, err := json.Marshal(record)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(parcelHash, bytes)
}

func (c *LandContract) QueryDeed(ctx contractapi.TransactionContextInterface, parcelHash string) (*LandTitleRecord, error) {
	bytes, err := ctx.GetStub().GetState(parcelHash)
	if err != nil || bytes == nil {
		return nil, fmt.Errorf("deed not found: %s", parcelHash)
	}
	var record LandTitleRecord
	if err := json.Unmarshal(bytes, &record); err != nil {
		return nil, err
	}
	return &record, nil
}

func main() {
	cc, err := contractapi.NewChaincode(&LandContract{})
	if err != nil {
		fmt.Printf("Error creating land registry contract: %s", err.Error())
		return
	}
	cc.Start()
}
