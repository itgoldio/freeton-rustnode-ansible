#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG
ton-check-env.sh DEPOOL_ADDR
ton-check-env.sh TIK_ADDR
ton-check-env.sh TIK_PRV_KEY

TON_DEPOOL_ELECTOR_UNFREEZE_LAG_SEC="120"
TON_ELECTION_TICKTOK_IS_SENDED_RETURN_STAKE="depool.ticktock.sended.returntsake"
TON_ELECTION_TICKTOK_IS_SENDED="depool.ticktock.sended"


# TODO move to ton.env
TON_TVM="/opt/freeton/tools/tvm_linker"
TON_TIK_VALUE=$((1 * 980000000))
TON_TIK_PAYLOAD="te6ccgEBAQEABgAACCiAmCM="


ELECTION_IS_ACTIVE=$(ton-election-is-active-local.sh)
if (( $ELECTION_IS_ACTIVE == 0 ));
    then
        echo "INFO: Election is not started"
        exit 0
fi

NOW=$(date +%s)
ELECTION_DATE_START=$(ton-election-date-start-local.sh)
TICKTOK_MIN_TIME_TO_SEND=$(($ELECTION_DATE_START + $TON_DEPOOL_ELECTOR_UNFREEZE_LAG_SEC))
if [ $NOW -lt $TICKTOK_MIN_TIME_TO_SEND ]; then
   echo "INFO: wait $TON_DEPOOL_ELECTOR_UNFREEZE_LAG_SEC after election started"
   exit
fi

NOW=$(date +%s)
TON_VALIDATION_NEXT_DATE=$(ton-validation-next-date-local.sh)
TON_ELECTION_SUBFOLDER="$TON_ELECTION_FOLDER/$TON_VALIDATION_NEXT_DATE"
if [ ! -d $TON_ELECTION_SUBFOLDER ]; then
   mkdir $TON_ELECTION_SUBFOLDER
fi


if [ -f $TON_ELECTION_SUBFOLDER/$TON_ELECTION_TICKTOK_IS_SENDED ]; then
   echo "INFO: ticktok has been sent already"
   exit
fi


DEPOOL_TICK_KEY_FILE_NAME_BIN_DATA=$DEPOOL_TICK_KEY_FILE_NAME.bin
# GENERATE BIN KEY FROM PRV KEY 
DEPOOL_TICK_PUBLIC_KEY=$(cat $TIK_PRV_KEY | jq ".public" -r)
DEPOOL_TICK_PIVATE_KEY=$(cat $TIK_PRV_KEY | jq ".secret" -r)
echo "${DEPOOL_TICK_PIVATE_KEY}${DEPOOL_TICK_PUBLIC_KEY}" | xxd -r -p - $KEYS_DIR/$DEPOOL_TICK_KEY_FILE_NAME_BIN_DATA

TON_MSG_FILENAME=$($TON_TVM message $TIK_ADDR -a $TON_CONTRACT_SAFEMULTISIGWALLET_ABI -m submitTransaction -p "{\"dest\":\"$DEPOOL_ADDR\",\"value\":$TON_TIK_VALUE,\"bounce\":true,\"allBalance\":false,\"payload\":\"$TON_TIK_PAYLOAD\"}"  -w 0 --setkey $KEYS_DIR/$DEPOOL_TICK_KEY_FILE_NAME_BIN_DATA | grep "boc file created:" | awk -F"boc file created:" '{print $2}')

DEPOOL_TICKTOK_RESULT=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c "sendmessage $TON_MSG_FILENAME")

DEPOOL_TICKTOK_RESULT_SUCCESS=$(echo $DEPOOL_TICKTOK_RESULT | grep success)

if [ -z "$DEPOOL_TICKTOK_RESULT_SUCCESS" ]; then
   echo "ERROR: can't create ticktok $DEPOOL_TICKTOK_RESULT"
   exit
fi


if [ ! -f $TON_ELECTION_SUBFOLDER/$TON_ELECTION_TICKTOK_IS_SENDED_RETURN_STAKE ]; then
   touch $TON_ELECTION_SUBFOLDER/$TON_ELECTION_TICKTOK_IS_SENDED_RETURN_STAKE
   echo $DEPOOL_TICKTOK_RESULT >> $TON_ELECTION_SUBFOLDER/$TON_ELECTION_TICKTOK_IS_SENDED_RETURN_STAKE
   echo "$DEPOOL_TICKTOK_RESULT"
   exit
fi


touch $TON_ELECTION_SUBFOLDER/$TON_ELECTION_TICKTOK_IS_SENDED
echo $DEPOOL_TICKTOK_RESULT >> $TON_ELECTION_SUBFOLDER/$TON_ELECTION_TICKTOK_IS_SENDED
echo "$DEPOOL_TICKTOK_RESULT"