#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CLI
ton-check-env.sh TON_CLI_CONFIG
ton-check-env.sh TON_NODE_CONFIG
ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG


ELECTION_STATE=$(ton-election-state.sh)
if [ $ELECTION_STATE != "ACTIVE" ];
    then
        echo "UNKNOWN"
        exit 0
fi

# get elector address
ELECTOR_ADDR="-1:$($TON_CLI -c $TON_CLI_CONFIG getconfig 1 | grep 'p1:' | sed 's/Config p1:[[:space:]]*//g' | tr -d \")"

# get elector start (unixtime)
ELECTIONS_DATE=$($TON_CLI -c $TON_CLI_CONFIG runget $ELECTOR_ADDR active_election_id  | grep 'Result:' | sed 's/Result:[[:space:]]*//g' | tr -d \"[])

## hotfix try to use new solidity contract for rustnet.ton.dev
if [ -z $ELECTIONS_DATE ]; then

   ELECTION_RESULT=`$TON_CLI -c $TON_CLI_CONFIG run $ELECTOR_ADDR active_election_id {} --abi $TON_CONTRACT_ELECTOR_ABI`
   ELECTIONS_DATE=$(echo $ELECTION_RESULT | awk -F'Result: ' '{print $2}' | jq -r '.value0'  )
fi

#cat $TON_NODE_CONFIG
TON_VALIDATOR_KEYS_COUNT=$(cat $TON_NODE_CONFIG  | jq '.validator_keys|length')

if [[ $TON_VALIDATOR_KEYS_COUNT == 0 ]]; then
   echo "NOT_FOUND"
   exit 0
fi

for (( i=0; i<$TON_VALIDATOR_KEYS_COUNT; i++ ))
do  
   TON_KEYS_FOR_ELECTION_ID=$(cat $TON_NODE_CONFIG | jq ".validator_keys[$i].election_id")

   if [ $TON_KEYS_FOR_ELECTION_ID == $ELECTIONS_DATE ]; then 

      TON_ADNL_KEY_HASH=$(cat $TON_NODE_CONFIG | jq ".validator_keys[$i].validator_key_id"| tr -d \")
      TON_ADNL_KEY="$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c "exportpub $TON_ADNL_KEY_HASH" | awk -F"imported key:" '{print $2}' | awk -F" " '{print $1}' )"
      
      TON_ADNL_KEY_FROM_ELECTOR=$($TON_CLI -c $TON_CLI_CONFIG runget $ELECTOR_ADDR participant_list_extended | grep "$TON_ADNL_KEY")

      if [ -z "$TON_ADNL_KEY_FROM_ELECTOR" ]; then
            echo "NOT_FOUND"
            exit
      else
            echo "ACTIVE"
            exit
      fi
   fi
done

echo "NOT_FOUND"