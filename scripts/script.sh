#!/bin/sh

CHANNEL_NAME=$1
DELAY=$2
TIMEOUT=$3
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kvote.com/orderers/orderer0.kvote.com/msp/tlscacerts/tlsca.kvote.com-cert.pem
LANGUAGE="golang"
CC_SRC_PATH=github.com/chaincode/kvote/go/$CHANNEL_NAME/0.1

. ./scripts/utils.sh

createChannel() {
        setGlobals 0 1

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
                peer channel create -o orderer0.kvote.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel1.tx &> log.txt
                sleep 30
                res=$?
                set +x
        else
                set -x
                peer channel create -o orderer0.kvote.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel1.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA &> log.txt
                sleep 30
                res=$?
                set +x
        fi
        cat log.txt
        verifyResult $res "Channel creation failed"
        echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
        sleep $DELAY
}

joinChannel () {
	sleep $DELAY
#        for org in 1 1; do
            for peer in 0 1 2 3 4; do
                joinChannelWithRetry $peer 1
                echo "===================== peer${peer}.org1 joined on the channel \"$CHANNEL_NAME\" ===================== "
                sleep $DELAY
                echo
            done
#        done
}

updateAnchorPeers() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
                peer channel update -o orderer0.kvote.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors1.tx &> log.txt
                res=$?
                set +x
  else
                set -x
                peer channel update -o orderer0.kvote.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors1.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA &>log.txt
                res=$?
                set +x
  fi
        cat log.txt
        verifyResult $res "Anchor peer update failed"
        echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
        sleep $DELAY
        echo
}

createChannel
joinChannel
updateAnchorPeers 0 1
installChaincode 0 1
installChaincode 1 1
installChaincode 2 1
installChaincode 3 1
installChaincode 4 1
instantiateChaincode 0 1
