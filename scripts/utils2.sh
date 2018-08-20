#!/bin/sh


verifyResult () {
        if [ $1 -ne 0 ] ; then
                echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
                echo
                exit 1
        fi
}


setGlobals () {
        PEER=$1
        ORG=$2
        if [ $ORG -eq 1 ] ; then
                CORE_PEER_LOCALMSPID="Org1MSP"
                CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.kvote.com/users/Admin@org1.kvote.com/msp
                if [ $PEER -eq 0 ]; then
                    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.kvote.com/peers/peer0.org1.kvote.com/tls/ca.crt
                    CORE_PEER_ADDRESS=peer0.org1.kvote.com:7051
                elif [ $PEER -eq 1 ]; then
                    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.kvote.com/peers/peer1.org1.kvote.com/tls/ca.crt
                    CORE_PEER_ADDRESS=peer1.org1.kvote.com:7051
                elif [ $PEER -eq 2 ]; then
                    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.kvote.com/peers/peer2.org1.kvote.com/tls/ca.crt
                    CORE_PEER_ADDRESS=peer2.org1.kvote.com:7051
                elif [ $PEER -eq 3 ]; then
                    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.kvote.com/peers/peer3.org1.kvote.com/tls/ca.crt
                    CORE_PEER_ADDRESS=peer3.org1.kvote.com:7051
                else
                    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.kvote.com/peers/peer4.org1.kvote.com/tls/ca.crt
                    CORE_PEER_ADDRESS=peer4.org1.kvote.com:7051
                fi
        elif [ $ORG -eq 2 ] ; then
                CORE_PEER_LOCALMSPID="Org2MSP"
                CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.kvote.com/users/Admin@org2.kvote.com/msp
                if [ $PEER -eq 0 ]; then
                    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.kvote.com/peers/peer0.org2.kvote.com/tls/ca.crt
                    CORE_PEER_ADDRESS=peer0.org2.kvote.com:7051
                else
                    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.kvote.com/peers/peer1.org2.kvote.com/tls/ca.crt
                    CORE_PEER_ADDRESS=peer1.org2.kvote.com:7051
                fi
        elif [ $ORG -eq 3 ] ; then
                CORE_PEER_LOCALMSPID="Org3MSP"
                CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store3.kvote.com/users/Admin@org3.kvote.com/msp
                if [ $PEER -eq 0 ]; then
                    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store3.kvote.com/peers/peer0.org3.kvote.com/tls/ca.crt
                    CORE_PEER_ADDRESS=peer0.org3.kvote.com:7051
                else
                    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store3.kvote.com/peers/peer1.org3.kvote.com/tls/ca.crt
                    CORE_PEER_ADDRESS=peer1.org3.kvote.com:7051
                fi
        else
                echo "================== ERROR !!! ORG Unknown =================="
        fi

        env |grep CORE
}

joinChannelWithRetry () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG

        set -x
  peer channel join -b $CHANNEL_NAME.block  &> log.txt
  res=$?
        set +x
  cat log.txt
  if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
    COUNTER=` expr $COUNTER + 1`
    echo "peer${PEER}.${ORG} failed to join the channel, Retry after $DELAY seconds"
    sleep $DELAY
    joinChannelWithRetry $PEER $ORG
  else
    COUNTER=1
  fi
  verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.${ORG} has failed to Join the Channel"
}


installChaincode () {
        PEER=$1
        ORG=$2
        setGlobals $PEER $ORG
        VERSION=${3:-0.1}
        set -x
        peer chaincode install -n kvotecc -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} &> log.txt
        res=$?
        set +x
        cat log.txt
        verifyResult $res "Chaincode installation on peers has Failed"
        echo "===================== Chaincode is installed on peers ===================== "
	    sleep $DELAY
        echo
}

instantiateChaincode () {
        PEER=$1
        ORG=$2
        setGlobals $PEER $ORG
        VERSION=${3:-0.1}

        # while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
        # lets supply it directly as we know it using the "-o" option
        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
                peer chaincode instantiate -o orderer0.kvote.com:7050 -C $CHANNEL_NAME -n kvotecc -l ${LANGUAGE} -v ${VERSION} -c '{"Args":["init",""]}' -P "OR  ('Org1MSP.peer')" &> log.txt
                res=$?
                set +x
        else
                set -x
                peer chaincode instantiate -o orderer0.kvote.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n kvotecc -l ${LANGUAGE} -v ${VERSION} -c '{"Args":["init",""]}' -P "OR ('Org1MSP.peer')" &> log.txt
                res=$?
                set +x
        fi
        cat log.txt
        verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' failed"
        echo "===================== Chaincode Instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
	    sleep $DELAY
        echo
}
