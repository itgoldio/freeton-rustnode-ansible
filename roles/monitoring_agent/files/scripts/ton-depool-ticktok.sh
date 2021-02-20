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

# get elector address
ELECTOR_ADDR="-1:$($TON_CLI -c $TON_CLI_CONFIG  getconfig 1 | grep 'p1:' | sed 's/Config p1:[[:space:]]*//g' | tr -d \")"

# get elector start (unixtime)
ELECTIONS_DATE=$($TON_CLI -c $TON_CLI_CONFIG runget $ELECTOR_ADDR active_election_id  | grep 'Result:' | sed 's/Result:[[:space:]]*//g' | tr -d \"[])

if [ -z $ELECTIONS_DATE ]; then

   ## hotfix try to use new solidity contract for rustnet.ton.dev
   ELECTION_RESULT=`$TON_CLI -c $TON_CLI_CONFIG run $ELECTOR_ADDR active_election_id {} --abi $TON_CONTRACT_ELECTOR_ABI`
   ELECTIONS_DATE=$(echo $ELECTION_RESULT | awk -F'Result: ' '{print $2}' | jq -r '.value0'  )
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


