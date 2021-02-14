#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CLI
ton-check-env.sh TON_DAPP


# get elector address
ELECTOR_ADDR="-1:$($TON_CLI --url $TON_DAPP  getconfig 1 | grep 'p1:' | sed 's/Config p1:[[:space:]]*//g' | tr -d \")"

# get elector start (unixtime)
ELECTIONS_START=$($TON_CLI --url $TON_DAPP runget $ELECTOR_ADDR active_election_id  | grep 'Result:' | sed 's/Result:[[:space:]]*//g' | tr -d \"[])

if [ -z $ELECTION_START ]; then

   ## hotfix try to use new solidity contract for rustnet.ton.dev
   ELECTION_RESULT=`$TON_CLI --url $TON_DAPP run $ELECTOR_ADDR active_election_id {} --abi $TON_CONTRACT_ELECTOR_ABI`
   ELECTIONS_START=$(echo $ELECTION_RESULT | awk -F'Result: ' '{print $2}' | jq -r '.value0'  )
fi


if [ -z $ELECTION_START ]; then
   echo "STOPPED"
   exit
fi


if (( $ELECTIONS_START == 0 ));then
   echo "STOPPED";
   exit
fi

if (( $ELECTIONS_START > 0 ));then
   echo "ACTIVE";
   exit
fi

echo "ERROR";