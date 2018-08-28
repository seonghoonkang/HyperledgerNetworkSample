## 준비
 Hyperledger fabric images 가져오기 : curl -sSL https://goo.gl/6wtTN5 | bash -s 1.2.0 <br>
 Hyperledger fabric samples binery 가져오기 : curl -sSL http://bit.ly/2ysbOFE | bash -s 1.2.0

## Step 1. Docker swarm 설정

1. Master 서버에서 docker swarm init 을 실행한다.
2. docker swarm join-token manager 를 실행하여 조인 토큰을 발행한다.
3. Sub 서버에서 Master에서 생성한 토큰을 실행한다.
4. docker network create --attachable --driver overlay [네트워크 이름] 을 실행한다.
5. docker network ls 를 실행하여 swarm overlay로 생성된 것을 확인한다.

## Step 2. 인증서 생성 및 채널관련 파일 생성 

cryptogen generate --config=./crypto-config.yaml

mkdir channel-artifacts
export FABRIC_CFG_PATH=$PWD
configtxgen -profile OrgsOrdererGenesis -outputBlock ./channel-artifacts/orderer.genesis.block

export CHANNEL_NAME=kvotechannel
configtxgen -profile OrgsChannel1 -outputCreateChannelTx ./channel-artifacts/channel1.tx -channelID $CHANNEL_NAME
configtxgen -profile OrgsChannel1 -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors1.tx -channelID $CHANNEL_NAME -asOrg Org1MSP


export CHANNEL_NAME=openchannel
configtxgen -profile OrgsChannel2 -outputCreateChannelTx ./channel-artifacts/channel2.tx -channelID $CHANNEL_NAME
configtxgen -profile OrgsChannel2 -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors2.tx -channelID $CHANNEL_NAME -asOrg Org1MSP


### Step 3. 도커 컨테이너 실행
docker-compose -f bc-node1.yaml down
docker-compose -f bc-node1.yaml up -d
