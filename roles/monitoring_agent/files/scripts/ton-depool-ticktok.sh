#!/bin/bash -eE


TON_ELECTION_TICKTOK_IS_SENDED="depool.ticktock.sended"

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CLI
ton-check-env.sh TON_CLI_CONFIG
ton-check-env.sh DEPOOL_ADDR
ton-check-env.sh TIK_ADDR
ton-check-env.sh TIK_PRV_KEY

if [ $# == 1 ];then
   if [ $1 = '-f' ] || [ $1 = '-force' ];then
       echo "INFO: force mod"
       $TON_CLI -c $TON_CLI_CONFIG depool --addr $DEPOOL_ADDR ticktock -w $TIK_ADDR -s $TIK_PRV_KEY
       exit
    fi
fi

#check election data
ELECTION_STATE=$(ton-election-state.sh)
if [ $ELECTION_STATE != "ACTIVE" ];then
   echo "INFO: Election is not started"
   exit
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

TON_ELECTION_SUBFOLDER="$TON_ELECTION_FOLDER/$ELECTIONS_DATE"
if [ ! -d $TON_ELECTION_SUBFOLDER ]; then
   mkdir $TON_ELECTION_SUBFOLDER
fi

if [ -f $TON_ELECTION_SUBFOLDER/$TON_ELECTION_TICKTOK_IS_SENDED ]; then
   echo "INFO: ticktok already sended"
   exit
fi
   
DEPOOL_TICKTOK_RESULT="$($TON_CLI -c $TON_CLI_CONFIG depool --addr $DEPOOL_ADDR ticktock -w $TIK_ADDR -s $TIK_PRV_KEY)"

DEPOOL_TICKTOK_TRANSACTION_ID="$(echo $DEPOOL_TICKTOK_RESULT | awk -F'Result: ' '{print $2}' | jq -r '.transId')"
if [ -z "$DEPOOL_TICKTOK_TRANSACTION_ID" ];then
   echo "ERROR: can't create ticktok $DEPOOL_TICKTOK_RESULT"
   exit
fi

touch $TON_ELECTION_SUBFOLDER/$TON_ELECTION_TICKTOK_IS_SENDED
echo $DEPOOL_TICKTOK_RESULT >> $TON_ELECTION_SUBFOLDER/$TON_ELECTION_TICKTOK_IS_SENDED
echo "$DEPOOL_TICKTOK_RESULT"


