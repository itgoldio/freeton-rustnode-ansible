#!/bin/bash -eE

# export ton environments
. ton-env.sh

TON_ELECTION_PROXY_FILE_NAME="proxy.addr"
TON_ELECTION_DEPOOL_EVENTS_FILE_NAME="depool-events"
TON_ELECTION_DEPOOL_VALIDATION_REQ_SENDED="validation.request.sended"

ton-check-env.sh TON_CLI_CONFIG
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

CURRENT_UNIXTIME=$(date +%s)

if [[ $CURRENT_UNIXTIME > $ELECTION_DATE_START && $ELECTION_DATE_END > $CURRENT_UNIXTIME ]]; then
   :
else
   echo "ERROR: election ended or don't start"
   exit 1
fi

ELECTIONS_DATE=$(ton-election-date.sh)
if [ $ELECTIONS_DATE = "-1" ]; then
   echo "ERROR: Can't get election date"
   exit
fi

if [ $ELECTIONS_DATE = "0" ]; then
   echo "INFO: Election is not started"
   exit
fi

echo "INFO: election is active"

##=================
## region: CHECK ALREADY IN VNEXT
##=================

#ALREADY_VNEXT_LIST=$(ton-node-validate-next.sh)
#if [ $ALREADY_VNEXT_LIST == "True" ]
#   then
#        echo "INFO: already in vnext list"
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

##=================
## region: CHECK validation request sended
##=================

if [ -f $TON_ELECTION_SUBFOLDER/$TON_ELECTION_DEPOOL_VALIDATION_REQ_SENDED ]; then
   if [ $1 = '-f' ] || [ $1 = '-force' ];then
      echo "INFO: force mod"
      rm $TON_ELECTION_SUBFOLDER/$TON_ELECTION_DEPOOL_VALIDATION_REQ_SENDED
   else
      echo "INFO: request already sended, see $TON_ELECTION_SUBFOLDER/$TON_ELECTION_DEPOOL_VALIDATION_REQ_SENDED"
      exit
   fi
fi

if [ ! -f $TON_ELECTION_SUBFOLDER/$TON_ELECTION_PROXY_FILE_NAME ]; then
   TON_DEPOOL_EVENTS=$($TON_CLI -c $TON_CLI_CONFIG depool --addr $DEPOOL_ADDR  events)
   echo "$TON_DEPOOL_EVENTS" > "$TON_ELECTION_SUBFOLDER/$TON_ELECTION_DEPOOL_EVENTS_FILE_NAME"

   TON_PROXY=$(echo "$TON_DEPOOL_EVENTS" | grep $ELECTIONS_DATE | jq ".proxy")
   if [ -z $TON_PROXY  ]; then
      echo "ERROR: can't find proxy, see events $TON_DEPOOL_EVENTS"
      rm $TON_ELECTION_SUBFOLDER/$TON_ELECTION_DEPOOL_EVENTS_FILE_NAME
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


   ELECTOR_CONFIG=`$TON_CLI -c $TON_CLI_CONFIG getconfig 15` 
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

TON_VALIDATOR_QUERY_SEND_RESULT=$($TON_CLI -c $TON_CLI_CONFIG call $VALIDATOR_WALLET_ADDR submitTransaction "{\"dest\":\"$DEPOOL_ADDR\",\"value\":\"1000000000\",\"bounce\":true,\"allBalance\":false,\"payload\":\"$TON_PAYLOAD\"}" --abi $TON_CONTRACT_SAFEMULTISIGWALLET_ABI --sign $VALIDATOR_WALLET_PRV_KEY_1)

echo "$TON_VALIDATOR_QUERY_SEND_RESULT"

TON_VALIDATOR_QUERY_SEND_RESULT_SUCCESS=$(echo "$TON_VALIDATOR_QUERY_SEND_RESULT" | grep "transId")

if [ ! -z "$TON_VALIDATOR_QUERY_SEND_RESULT_SUCCESS" ]; then
   echo "$TON_VALIDATOR_QUERY_SEND_RESULT" > "$TON_ELECTION_SUBFOLDER/$TON_ELECTION_DEPOOL_VALIDATION_REQ_SENDED"
fi

