package main

import (
	"crypto/sha256"
	"encoding/hex"
	"log"
	"os"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// PalDfiContract provides functions for managing Palestinian academic credentials & W3C Bitstring revocation
type PalDfiContract struct {
	contractapi.Contract
}

func sha256Hex(data string) string {
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])
}

// InitLedger bootstraps the W3C Bitstring revocation list and initial official NUVTE credentials
func (c *PalDfiContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	log.Println("Initializing PAL-DFI Academic Consortium Ledger...")

	// 1. Initialize 100,000 credential slots in W3C BitstringStatusList2021
	statusListID := DefaultStatusList
	if err := c.InitStatusList(ctx, statusListID, 100000); err != nil {
		log.Printf("Notice: Status list may already exist: %v", err)
	}

	// 2. Seed initial official documents for Persona: Amjad Khaliliah (National ID: 983421560, Student: STU-2024098)
	subjectHash := sha256Hex("983421560")
	issuerDID := "did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA"

	seedDocuments := []struct {
		DocID           string
		DocType         string
		RawPayload      string
		StatusListIndex int
		MetadataJSON    string
	}{
		{
			DocID:           "DOC-NUVTE-2024-STU-098",
			DocType:         string(DocTypeStudentID),
			RawPayload:      "NUVTE::StudentID::983421560::STU-2024098::Cybersecurity",
			StatusListIndex: 101,
			MetadataJSON:    `{"studentId":"STU-2024098","faculty":"Faculty of Information Technology","program":"B.Sc. Cybersecurity & Digital Forensics","gpa":"3.88"}`,
		},
		{
			DocID:           "DOC-NUVTE-2024-GRAD-098",
			DocType:         string(DocTypeGraduation),
			RawPayload:      "NUVTE::Graduation::983421560::Degree-CS-DFI-2024::FirstClassHonors",
			StatusListIndex: 102,
			MetadataJSON:    `{"degreeName":"Bachelor of Science in Cybersecurity & Digital Forensics","honors":"First Class Honors","gpa":"3.88","decreeNumber":"PMA-NUVTE-2024-8812"}`,
		},
		{
			DocID:           "DOC-NUVTE-2024-CLR-098",
			DocType:         string(DocTypeClearance),
			RawPayload:      "NUVTE::Clearance::983421560::CLR-NUVTE-2024-00912::AllDepartmentsCleared",
			StatusListIndex: 103,
			MetadataJSON:    `{"referenceNumber":"CLR-NUVTE-2024-00912","clearedDepartments":["Library","Financial Comptroller","Laboratories","Student Affairs","Registration"]}`,
		},
	}

	for _, seed := range seedDocuments {
		docHash := sha256Hex(seed.RawPayload)
		_, err := c.AnchorDocument(
			ctx,
			seed.DocID,
			seed.DocType,
			docHash,
			issuerDID,
			subjectHash,
			seed.StatusListIndex,
			seed.MetadataJSON,
		)
		if err != nil {
			log.Printf("Notice: Seed document '%s' anchor: %v", seed.DocID, err)
		}
	}

	log.Println("PAL-DFI Academic Consortium Ledger initialization complete.")
	return nil
}

func main() {
	contract, err := contractapi.NewChaincode(&PalDfiContract{})
	if err != nil {
		log.Panicf("Error creating PAL-DFI contract: %v", err)
	}

	serverAddress := os.Getenv("CHAINCODE_SERVER_ADDRESS")
	ccid := os.Getenv("CHAINCODE_ID")

	if serverAddress != "" && ccid != "" {
		log.Printf("Starting PAL-DFI Chaincode Server (CCaaS) at %s with ID %s...", serverAddress, ccid)
		server := &shim.ChaincodeServer{
			CCID:    ccid,
			Address: serverAddress,
			CC:      contract,
			TLSProps: shim.TLSProperties{
				Disabled: true,
			},
		}
		if err := server.Start(); err != nil {
			log.Panicf("Error starting chaincode server: %v", err)
		}
	} else {
		if err := contract.Start(); err != nil {
			log.Panicf("Error starting PAL-DFI chaincode: %v", err)
		}
	}
}
