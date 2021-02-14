#!/bin/bash -eE

# export ton environments
. ton-env.sh

TON_ELECTION_PROXY_FILE_NAME="proxy.addr"
TON_ELECTION_DEPOOL_EVENTS_FILE_NAME="depool-events"

ton-check-env.sh TON_DAPP
ton-check-env.sh DEPOOL_ADDR
ton-check-env.sh VALIDATOR_WALLET_ADDR
ton-check-env.sh TON_CONTRACT_SAFEMULTISIGWALLET_ABI
ton-check-env.sh VALIDATOR_WALLET_PRV_KEY_1

##=================
## region: CHECK ELECTION STATE AND DATA
##=================

ELECTION_STATE=$(ton-election-state.sh)
if [ $ELECTION_STATE != "ACTIVE" ];
    then
        echo "INFO: Election is not started"
        exit 0
fi

ELECTION_DATE_START=$(ton-election-date-start.sh)
if (( $ELECTION_DATE_START == -1 ));
    then
        echo "INFO: Election is not started"
        exit 0
fi

ELECTION_DATE_END=$(ton-election-date-end.sh)
if (( $ELECTION_DATE_END == -1 ));
    then
        echo "INFO: Election is not started"
        exit 0
fi


CURRENT_TIME=$(date +%s)

if [[ $CURRENT_TIME > $ELECTION_DATE_START && $ELECTION_DATE_END > $CURRENT_TIME ]]; then
   :
else
   echo "ERROR: election ended or don't start"
   exit 1
fi

# get elector address
ELECTOR_ADDR="-1:$($TON_CLI --url $TON_DAPP  getconfig 1 | grep 'p1:' | sed 's/Config p1:[[:space:]]*//g' | tr -d \")"

# get elector start (unixtime)
ELECTIONS_DATE=$($TON_CLI --url $TON_DAPP runget $ELECTOR_ADDR active_election_id  | grep 'Result:' | sed 's/Result:[[:space:]]*//g' | tr -d \"[])


## hotfix try to use new solidity contract for rustnet.ton.dev
if [ -z $ELECTIONS_DATE ]; then

   ELECTION_RESULT=`$TON_CLI --url $TON_DAPP run $ELECTOR_ADDR active_election_id {} --abi $TON_CONTRACT_ELECTOR_ABI`
   ELECTIONS_DATE=$(echo $ELECTION_RESULT | awk -F'Result: ' '{print $2}' | jq -r '.value0'  )
fi

echo "INFO: eclection is active"


##=================
## region: CHECK ALREADY PARTICIPANT
##=================

#already completed request for election
#PARTICIPANT_STATE=$(ton-node-participant-state.sh)
#if [ $PARTICIPANT_STATE == "ACTIVE" ]
#   then
#        echo "INFO: already in participants list"
#        exit 0
#fi;


##=================
## region: CHECK UNCOMPLITE TRANSACTION
##=================

#has uncomplite transaction
All_TRANSACTIONS_COUNT=$(ton-wallet-transaction-count.sh)
if (( ! $All_TRANSACTIONS_COUNT == 0 )); then
    echo "WARNING: has $TRANSACTIONS_COUNT uncomplite transactions"
    exit 0
fi;

##=================
## region: CREATE ARTEFACTS
##=================

TON_ELECTION_SUBFOLDER="$TON_ELECTION_FOLDER/$ELECTIONS_DATE"
if [ ! -d $TON_ELECTION_SUBFOLDER ]; then
   mkdir $TON_ELECTION_SUBFOLDER
fi

if [ ! -f $TON_ELECTION_SUBFOLDER/$TON_ELECTION_PROXY_FILE_NAME ]; then
   TON_DEPOOL_EVENTS=$($TON_CLI --url $TON_DAPP depool --addr $DEPOOL_ADDR  events)
   echo "$TON_DEPOOL_EVENTS" > "$TON_ELECTION_SUBFOLDER/$TON_ELECTION_DEPOOL_EVENTS_FILE_NAME"

   TON_PROXY=$(echo "$TON_DEPOOL_EVENTS" | grep $ELECTIONS_DATE | jq ".proxy")
   if [ -z $TON_PROXY  ]; then
      echo "ERROR: can't find proxy, see events in $TON_ELECTION_SUBFOLDER/$TON_ELECTION_DEPOOL_EVENTS_FILE_NAME"
      exit 1
   fi

   echo $TON_PROXY > "$TON_ELECTION_SUBFOLDER/$TON_ELECTION_PROXY_FILE_NAME"
fi


##=================
## region: CREATE validator-query.boc
##=================
if [ ! -f $TON_ELECTION_SUBFOLDER/$TON_ELECTION_PROXY_FILE_NAME ]; then
   echo "ERROR: can't find $TON_ELECTION_SUBFOLDER/$TON_ELECTION_PROXY_FILE_NAME"
fi

TON_PROXY=$(cat $TON_ELECTION_SUBFOLDER/$TON_ELECTION_PROXY_FILE_NAME)

if [ -z $TON_PROXY ]; then
   echo "ERROR: proxy data is empty $TON_ELECTION_SUBFOLDER/$TON_ELECTION_PROXY_FILE_NAME"
fi

if [ ! -f $TON_ELECTION_SUBFOLDER/validator-query.boc ]; then
   TON_CONSOLE_CONFIG_NEW=$(jq ".wallet_id=$TON_PROXY" $TON_CONSOLE_CONFIG)  
   echo $TON_CONSOLE_CONFIG_NEW > $TON_CONSOLE_CONFIG


   ELECTOR_CONFIG=`$TON_CLI --url $TON_DAPP getconfig 15` 
   ELECTOR_CONFIG_JSON=$(echo $ELECTOR_CONFIG | awk '{split($0, a, "p15:"); print a[2]}')
   ELECTOR_CONFIG_VALIDATORS_ELECTED_FOR=`echo "$ELECTOR_CONFIG_JSON" | jq ".validators_elected_for"`
   ELECTOR_CONFIG_STAKE_HELD_FOR=`echo "$ELECTOR_CONFIG_JSON" | jq ".stake_held_for"`

   VALIDATION_START=$ELECTIONS_DATE
   VALIDATION_END=$(($VALIDATION_START + $ELECTOR_CONFIG_VALIDATORS_ELECTED_FOR + $ELECTOR_CONFIG_STAKE_HELD_FOR + 600))

   $TON_CONSOLE -C $TON_CONSOLE_CONFIG -c "election-bid $VALIDATION_START $VALIDATION_END"
   mv validator-query.boc "${TON_ELECTION_SUBFOLDER}"
fi

##=================
## region: SEND VALIDATION REQUEST
##=================
if [ ! -f "$TON_ELECTION_SUBFOLDER/validator-query.boc" ]; then
   echo "ERROR: can't find $TON_ELECTION_SUBFOLDER/validator-query.boc"
   exit
fi

TON_PAYLOAD=$(base64 --wrap=0 "${TON_ELECTION_SUBFOLDER}/validator-query.boc")

$TON_CLI --url $TON_DAPP call $VALIDATOR_WALLET_ADDR submitTransaction "{\"dest\":\"$DEPOOL_ADDR\",\"value\":\"1000000000\",\"bounce\":true,\"allBalance\":false,\"payload\":\"$TON_PAYLOAD\"}" --abi $TON_CONTRACT_SAFEMULTISIGWALLET_ABI --sign $VALIDATOR_WALLET_PRV_KEY_1