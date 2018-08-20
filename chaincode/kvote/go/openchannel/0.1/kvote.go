package main

import (
	"bytes"
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

type VoteChaincode struct{}

//index, ID, Enc(데이터), 시그니처(전자서명+pubkey)
type CommonVO struct {
	ComIdx        string `json:"cidx"`
	ComId         string `json:"cid"`
	ComData       string `json:"cdata"`
	ComSign       string `json:"csign"`
	ComRegistDate string `json:"cdate"`
}

// ===================================================================================
// Main
// ===================================================================================
func main() {
	err := shim.Start(new(VoteChaincode))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}

func (t *VoteChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

// Invoke - Our entry point for Invocations
// ========================================
func (t *VoteChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()

	if function == "writeLedger" {
		return t.writeLedger(stub, args)
	} else if function == "queryLedger" {
		return t.queryBySelector(stub, args)
	} else if function == "readLedger" {
		return t.queryByRange(stub, args)
	}

	return shim.Error("Received unknown function invocation")
}

//arguments 를 받아 struct 로 변환하여 장부에 기록한다.
func (t *VoteChaincode) writeLedger(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	voteVO := CommonVO{args[0], args[1], args[2], args[3], args[4]}
	voteVOAsBytes, _ := json.Marshal(voteVO)
	//id+서명을 key 데이터로 사용한다.
	err := stub.PutState(voteVO.ComId+voteVO.ComSign, voteVOAsBytes)
	if err != nil {
		return shim.Error("Ledger putstate error")
	}
	return shim.Success(nil)
}

//arguments 를 key range 기준으로 조회한다.
func (t *VoteChaincode) queryByRange(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	var startKey = args[0]
	var endKey = args[1]
	resultsIterator, err := stub.GetStateByRange(startKey, endKey)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()
	return shim.Success(queryResult(resultsIterator))
}

//조건별로 검색한다.
func (t *VoteChaincode) queryBySelector(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}
	voteVO := CommonVO{args[0], args[1], args[2], args[3], args[4]}
	query, _ := json.Marshal(voteVO)
	queryString := fmt.Sprintf("{\"selector\":%s}", string(query))
	resultsIterator, err := stub.GetQueryResult(queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()
	return shim.Success(queryResult(resultsIterator))
}

//조건에 맞는 결과값을 []bytes 로 출력한다.
func queryResult(resultsIterator shim.StateQueryIteratorInterface) []byte {
	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")
	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, _ := resultsIterator.Next()
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{Key:")
		//buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		//buffer.WriteString("\"")

		buffer.WriteString(", Record:")
		// Record is a JSON object, so we write as-is
		//buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString(queryResponse.String())
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")
	return buffer.Bytes()
}

