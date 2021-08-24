#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG


ton-check-env.sh TON_CLI_CONFIG
ton-check-env.sh TON_CLI
ton-check-env.sh DEPOOL_ADDR


CURRENT_UNIXTIME=$(date +%s)
TON_ELECTION_DEPOOL_VALIDATION_REQ_SENDED="validation.request.sended"
TON_ELECTION_PROXY_FILE_NAME="proxy.addr"
TON_ELECTION_DEPOOL_EVENTS_FILE_NAME="depool-events"
TON_VALIDATOR_QUERY_BOC_FOR_CONSOLE_FILE_NAME="validator-query.for-console.boc"

ELECTION_IS_ACTIVE=$(ton-election-is-active-local.sh)
if (( $ELECTION_IS_ACTIVE == 0 ));
    then
        echo "INFO: Election is not started"
        exit 0
fi

echo "INFO: election is active"

##=================
## region: CHECK ALREADY IN VNEXT
##=================

#TODO
#ton-node-validate-next-local.sh

##=================
## region: CREATE ARTEFACTS
##=================
TON_VALIDATION_NEXT_DATE=$(ton-validation-next-date-local.sh)
TON_ELECTION_SUBFOLDER="$TON_ELECTION_FOLDER/$TON_VALIDATION_NEXT_DATE"
if [ ! -d $TON_ELECTION_SUBFOLDER ]; then
   mkdir $TON_ELECTION_SUBFOLDER
fi

##=================
## region: CHECK validation request sended
##=================

if [ -f $TON_ELECTION_SUBFOLDER/$TON_ELECTION_DEPOOL_VALIDATION_REQ_SENDED ]; then
   echo "INFO: request already sended, see $TON_ELECTION_SUBFOLDER/$TON_ELECTION_DEPOOL_VALIDATION_REQ_SENDED"
   exit
fi

set -x

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
if [ ! -f $TON_ELECTION_SUBFOLDER/validator-query.boc ]; then
   TON_CONSOLE_CONFIG_NEW=$(jq ".wallet_id=\"$DEPOOL_PROXY\"" $TON_CONSOLE_CONFIG)  
   echo $TON_CONSOLE_CONFIG_NEW > $TON_CONSOLE_CONFIG

   ELECTOR_CONFIG_VALIDATORS_ELECTED_FOR=`echo "$TON_CONFIG_15_JSON" | jq ".p15.validators_elected_for"`
   ELECTOR_CONFIG_STAKE_HELD_FOR=`echo "$TON_CONFIG_15_JSON" | jq ".p15.stake_held_for"`

   VALIDATION_START=$TON_CURRENT_VALIDATION_END
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

if [ ! -f "$TON_ELECTION_SUBFOLDER/$TON_VALIDATOR_QUERY_BOC_FOR_CONSOLE_FILE_NAME" ]; then

   TON_PAYLOAD=$(base64 --wrap=0 "${TON_ELECTION_SUBFOLDER}/validator-query.boc")

   $TON_CLI message --raw --output $TON_ELECTION_SUBFOLDER/$TON_VALIDATOR_QUERY_BOC_FOR_CONSOLE_FILE_NAME --abi $TON_CONTRACT_SAFEMULTISIGWALLET_ABI --sign $VALIDATOR_WALLET_PRV_KEY_1 $VALIDATOR_WALLET_ADDR submitTransaction "{\"dest\":\"$DEPOOL_ADDR\",\"value\":\"1000000000\",\"bounce\":true,\"allBalance\":false,\"payload\":\"$TON_PAYLOAD\"}" --lifetime 600
fi

if [ ! -f "$TON_ELECTION_SUBFOLDER/$TON_VALIDATOR_QUERY_BOC_FOR_CONSOLE_FILE_NAME" ]; then
   echo "ERROR: can't find $TON_ELECTION_SUBFOLDER/$TON_VALIDATOR_QUERY_BOC_FOR_CONSOLE_FILE_NAME"
   exit
fi


if [ ! -f $TON_ELECTION_SUBFOLDER/$TON_VALIDATOR_QUERY_SEND_RESULT_SUCCESS ]; then
   TON_VALIDATOR_QUERY_SEND_RESULT=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c "sendmessage $TON_ELECTION_SUBFOLDER/$TON_VALIDATOR_QUERY_BOC_FOR_CONSOLE_FILE_NAME")
   echo $TON_VALIDATOR_QUERY_SEND_RESULT
   TON_VALIDATOR_QUERY_SEND_RESULT_SUCCESS=$(echo $TON_VALIDATOR_QUERY_SEND_RESULT | grep success)
fi

if [ ! -z "$TON_VALIDATOR_QUERY_SEND_RESULT_SUCCESS" ]; then
   echo "$TON_VALIDATOR_QUERY_SEND_RESULT" > "$TON_ELECTION_SUBFOLDER/$TON_ELECTION_DEPOOL_VALIDATION_REQ_SENDED"
fi

exit