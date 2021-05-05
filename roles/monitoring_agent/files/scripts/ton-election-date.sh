#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CLI
ton-check-env.sh TON_CLI_CONFIG


get_election_date ()
{
   ELECTIONS_START=$($TON_CLI -c $TON_CLI_CONFIG runget $ELECTOR_ADDR active_election_id  | grep 'Result:' | sed 's/Result:[[:space:]]*//g' | tr -d \"[])
}

# rustcup have unique elector
get_election_date_rustcup ()
{
   ELECTION_RESULT=`$TON_CLI -c $TON_CLI_CONFIG run $ELECTOR_ADDR active_election_id {} --abi $TON_CONTRACT_ELECTOR_ABI`
   ELECTIONS_START=$(echo $ELECTION_RESULT | awk -F'Result: ' '{print $2}' | jq -r '.value0'  )
}

# get elector address
ELECTOR_ADDR="-1:$($TON_CLI -c $TON_CLI_CONFIG  getconfig 1 | grep 'p1:' | sed 's/Config p1:[[:space:]]*//g' | tr -d \")"

if [ $TON_IS_RUSTNET -eq 1 ]; then
   get_election_date_rustcup
else
   get_election_date
fi

if [ -z $ELECTIONS_START ]; then
   echo "-1";
   exit
fi

echo "$ELECTIONS_START"