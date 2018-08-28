### 채널생성
peer channel create -o orderer0.kvote.com:7050 -c kvotechannel -f ./channel-artifacts/channel1.tx

### 채널목록 조회
peer chaincode list -C kvotechannel --installed
peer chaincode list -C kvotechannel --installed --peerAddresses peer4.org1.kvote.com:7051
peer chaincode list -C kvotechannel --instantiated
peer chaincode list -C kvotechannel --instantiated --peerAddresses peer0.org1.kvote.com:7051

### 체인코드 생성 및 초기화
1.peer chaincode instantiate -o orderer0.kvote.com:7050 -C kvotechannel -n fabcar -l golang -v 1.3 -c '{"Args":["Init",""]}' -P 'OR("Org1MSP.peer")'
2.peer chaincode instantiate -o orderer0.kvote.com:7050 -C kvotechannel -n kvote -l golang -v 1.5 -c '{"Args":["init",""]}' -P 'OR("Org1MSP.peer")'

### 체인코드 Invoke 실행
peer chaincode invoke -n fabcar -c '{"Args":["registProducts", "goods", "7", "apply"]}' -C kvotechannel

peer chaincode list -C kvotechannel --installed --peerAddresses peer2.org1.kvote.com
