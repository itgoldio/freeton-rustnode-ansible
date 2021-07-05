#!/bin/bash -eE
#set -x
# export ton environments
. ton-env.sh

ton-check-env.sh TON_CLI
ton-check-env.sh TON_CLI_CONFIG
ton-check-env.sh TON_NODE_CONFIG
ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG

MonitoringOut=false

while getopts "m" opt; do
        case $opt in
                m)  MonitoringOut=true   
        esac
done

get_participants ()
{
   TON_PARTICIPANTS_CURRENT=$($TON_CLI -c $TON_CLI_CONFIG runget $ELECTOR_ADDR participant_list_extended)
}

# rustcup have unique elector
get_participants_rustcup ()
{
   TON_ELECTOR_GET=$($TON_CLI -c $TON_CLI_CONFIG run $ELECTOR_ADDR get {} --abi $TON_CONTRACT_ELECTOR_ABI)
   TON_PARTICIPANTS_CURRENT=$(echo $TON_ELECTOR_GET | awk -F'Result: ' '{print $2}' | jq ".cur_elect")
}

print_if_validate()
{
   if [ $MonitoringOut = true ]; then
      echo "1"
   fi 

   if [ $MonitoringOut = false ]; then
      echo "True"
   fi 
}

print_if_not_validate()
{
   if [ $MonitoringOut  = true ]; then
      echo "0"
   fi 

   if [ $MonitoringOut  = false ]; then
      echo "False"
   fi
}


# already in validator set 
IN_NEXT_ROUND=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c getstats | grep 'in_next_vset_p36' | sed 's/[[:space:]]*"in_next_vset_p36":[[:space:]]*//g;s/,//g')
if [ ! -z $IN_NEXT_ROUND ]; then
   if $IN_NEXT_ROUND; then
      print_if_validate
      exit
   fi
fi


# check election
ELECTION_STATE=$(ton-election-state.sh)
if [ $ELECTION_STATE != "ACTIVE" ];
    then
        print_if_not_validate
        exit
fi

ELECTIONS_DATE=$(ton-election-date.sh)
if [ $ELECTIONS_DATE = "-1" ]; then
   print_if_not_validate
   exit
fi

if [ $ELECTIONS_DATE = "0" ]; then
   print_if_not_validate
   exit
fi


# get elector address
ELECTOR_ADDR="-1:$($TON_CLI -c $TON_CLI_CONFIG  getconfig 1 | grep 'p1:' | sed 's/Config p1:[[:space:]]*//g' | tr -d \")"


#cat $TON_NODE_CONFIG
TON_VALIDATOR_KEYS_COUNT=$(cat $TON_NODE_CONFIG  | jq '.validator_keys|length')

if [[ $TON_VALIDATOR_KEYS_COUNT == 0 ]]; then
   print_if_not_validate
   exit 0
fi

if [ $TON_IS_RUSTNET -eq 1 ]; then
   get_participants_rustcup
else
   get_election_date
fi

for (( i=0; i<$TON_VALIDATOR_KEYS_COUNT; i++ ))
do  
   TON_KEYS_FOR_ELECTION_ID=$(cat $TON_NODE_CONFIG | jq ".validator_keys[$i].election_id")

   if [ $TON_KEYS_FOR_ELECTION_ID == $ELECTIONS_DATE ]; then 

      TON_ADNL_KEY_HASH=$(cat $TON_NODE_CONFIG | jq ".validator_keys[$i].validator_key_id"| tr -d \")
      TON_ADNL_KEY=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c "exportpub $TON_ADNL_KEY_HASH" | awk -F"imported key:" '{print $2}' | awk -F" " '{print $1}' | tr -d "\n" )

      TON_ADNL_KEY_FROM_ELECTOR=$( echo "$TON_PARTICIPANTS_CURRENT"  | { grep "$TON_ADNL_KEY" || true; } )

      if [ -z "$TON_ADNL_KEY_FROM_ELECTOR" ]; then
            print_if_not_validate
            exit
      else
            print_if_validate
            exit
      fi
   fi
done

print_if_not_validate