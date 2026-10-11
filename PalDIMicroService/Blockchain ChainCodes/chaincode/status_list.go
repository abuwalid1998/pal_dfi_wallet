package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

const (
	StatusListPrefix = "STATUS_LIST_"
)

// InitStatusList initializes a new W3C BitstringStatusList2021 with the given capacity
func (c *PalDfiContract) InitStatusList(ctx contractapi.TransactionContextInterface, listID string, capacity int) error {
	if capacity <= 0 {
		return fmt.Errorf("capacity must be greater than zero")
	}

	key := StatusListPrefix + listID
	exists, err := ctx.GetStub().GetState(key)
	if err != nil {
		return fmt.Errorf("failed to read from world state: %v", err)
	}
	if exists != nil {
		return fmt.Errorf("status list '%s' already exists", listID)
	}

	numBytes := (capacity + 7) / 8
	bits := make([]byte, numBytes) // All bits initialized to 0 (Valid / Not Revoked)
	encoded := base64.StdEncoding.EncodeToString(bits)

	statusList := StatusList{
		ListID:      listID,
		Capacity:    capacity,
		EncodedBits: encoded,
		LastUpdated: time.Now().UTC().Format(time.RFC3339),
	}

	bytes, err := json.Marshal(statusList)
	if err != nil {
		return fmt.Errorf("failed to marshal status list: %v", err)
	}

	return ctx.GetStub().PutState(key, bytes)
}

// GetStatusBit returns the status bit at bitIndex (false = 0 / Valid, true = 1 / Revoked)
func (c *PalDfiContract) GetStatusBit(ctx contractapi.TransactionContextInterface, listID string, bitIndex int) (bool, error) {
	key := StatusListPrefix + listID
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return false, fmt.Errorf("failed to read world state: %v", err)
	}
	if bytes == nil {
		return false, fmt.Errorf("status list '%s' does not exist", listID)
	}

	var statusList StatusList
	if err := json.Unmarshal(bytes, &statusList); err != nil {
		return false, fmt.Errorf("failed to unmarshal status list: %v", err)
	}

	if bitIndex < 0 || bitIndex >= statusList.Capacity {
		return false, fmt.Errorf("bitIndex %d is out of bounds [0, %d)", bitIndex, statusList.Capacity)
	}

	rawBits, err := base64.StdEncoding.DecodeString(statusList.EncodedBits)
	if err != nil {
		return false, fmt.Errorf("failed to decode bitstring: %v", err)
	}

	byteIdx := bitIndex / 8
	bitOffset := uint(bitIndex % 8)

	isRevoked := (rawBits[byteIdx] & (1 << bitOffset)) != 0
	return isRevoked, nil
}

// SetStatusBit updates the status bit at bitIndex
func (c *PalDfiContract) SetStatusBit(ctx contractapi.TransactionContextInterface, listID string, bitIndex int, isRevoked bool) error {
	key := StatusListPrefix + listID
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return fmt.Errorf("failed to read world state: %v", err)
	}
	if bytes == nil {
		return fmt.Errorf("status list '%s' does not exist", listID)
	}

	var statusList StatusList
	if err := json.Unmarshal(bytes, &statusList); err != nil {
		return fmt.Errorf("failed to unmarshal status list: %v", err)
	}

	if bitIndex < 0 || bitIndex >= statusList.Capacity {
		return fmt.Errorf("bitIndex %d is out of bounds [0, %d)", bitIndex, statusList.Capacity)
	}

	rawBits, err := base64.StdEncoding.DecodeString(statusList.EncodedBits)
	if err != nil {
		return fmt.Errorf("failed to decode bitstring: %v", err)
	}

	byteIdx := bitIndex / 8
	bitOffset := uint(bitIndex % 8)

	if isRevoked {
		rawBits[byteIdx] |= (1 << bitOffset)
	} else {
		rawBits[byteIdx] &= ^(1 << bitOffset)
	}

	statusList.EncodedBits = base64.StdEncoding.EncodeToString(rawBits)
	statusList.LastUpdated = time.Now().UTC().Format(time.RFC3339)

	updatedBytes, err := json.Marshal(statusList)
	if err != nil {
		return fmt.Errorf("failed to marshal updated status list: %v", err)
	}

	return ctx.GetStub().PutState(key, updatedBytes)
}
