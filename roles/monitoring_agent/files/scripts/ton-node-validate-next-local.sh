#!/bin/bash -eE
#set -x
# export ton environments
. ton-env.sh

ton-check-env.sh TON_CLI
ton-check-env.sh TON_CLI_CONFIG
ton-check-env.sh TON_NODE_CONFIG
ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG

TON_ELECTOR_TVC="elector.tvc"

MonitoringOut=false

while getopts "m" opt; do
        case $opt in
                m)  MonitoringOut=true ;;
                *)  MonitoringOut=false ;;
        esac
done

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

ELECTION_IS_ACTIVE=$(ton-election-is-active-local.sh)
if (( $ELECTION_IS_ACTIVE == 0 )); then
   print_if_not_validate
   exit 0
fi

#cat $TON_NODE_CONFIG
TON_VALIDATOR_KEYS_COUNT=$(cat $TON_NODE_CONFIG  | jq '.validator_keys|length')

if [[ $TON_VALIDATOR_KEYS_COUNT == 0 ]]; then
   print_if_not_validate
   exit 0
fi

TON_CONFIG_1=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c "getconfig 1")
TON_CONFIG_1_JSON=$(echo $TON_CONFIG_1 | awk '{split($0, a, "param:"); print a[2]}')

ELECTOR_ADDR=$(echo "$TON_CONFIG_1_JSON" | jq -r ".p1" )
ELECTOR_ADDR="-1:"$ELECTOR_ADDR

TON_ELECTOR_TVC_RQW=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c "getaccountstate $ELECTOR_ADDR $TON_ELECTOR_TVC")

TON_PARTICIPANTS_CURRENT=$($TON_CLI -j run --boc $TON_ELECTOR_TVC  get '{}' --abi $TON_CONTRACT_ELECTOR_ABI | jq ".cur_elect.members")

TON_VALIDATION_NEXT_DATE=$(ton-validation-next-date-local.sh)

for (( i=0; i<$TON_VALIDATOR_KEYS_COUNT; i++ ))
do  
   TON_KEYS_FOR_ELECTION_ID=$(cat $TON_NODE_CONFIG | jq ".validator_keys[$i].election_id")

   if [ $TON_KEYS_FOR_ELECTION_ID == $TON_VALIDATION_NEXT_DATE ]; then 

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
