#!/bin/bash -eE

# export ton environments
. ton-env.sh

# check environments
ton-check-env.sh TON_CLI
ton-check-env.sh TON_DAPP
ton-check-env.sh TON_CONTRACT_SAFEMULTISIGWALLET_ABI

#set wallet and depool addr
VALIDATOR_WALLET_ADDR=""
DEPOOL_ADDR=""

if [ $# != 2 ];then
   
   ton-check-env.sh VALIDATOR_WALLET_ADDR_FILE
   VALIDATOR_WALLET_ADDR=$(cat $VALIDATOR_WALLET_ADDR_FILE)
   if [ -z "${VALIDATOR_WALLET_ADDR}" ]; then
       echo "Warning, send argument with wallet addr and dapp addr or write it data to ton-env.sh"
       exit 1
   fi

   ton-check-env.sh DEPOOL_ADDR_FILE
   DEPOOL_ADDR=$(cat $DEPOOL_ADDR_FILE)

   if [ -z "${DEPOOL_ADDR}" ]; then
       echo "Warning, send argument with wallet addr and dapp addr or write it data to ton-env.sh"
      exit 1
   fi

else
   VALIDATOR_WALLET_ADDR=$1
   DEPOOL_ADDR=$2
fi

TRANSACTIONS="$($TON_CLI --url $TON_DAPP run $VALIDATOR_WALLET_ADDR getTransactions {} --abi  $TON_CONTRACT_SAFEMULTISIGWALLET_ABI )" 
TRANSACTIONS_COUNT=$(echo $TRANSACTIONS | awk -F'Result: ' '{print $2}' | jq '.transactions|length')

if [[ $TRANSACTIONS_COUNT == 0 ]]; then
   echo "INFO: nothing to confirm"
   exit 0
fi

for (( i=0; i<$TRANSACTIONS_COUNT; i++ ))
do  
   TON_ADDRESS_DESTINATION=$(echo $TRANSACTIONS| awk -F"Result: " '{print $2}' | jq ".transactions[$i].dest" | tr -d \")
   TON_TRANSACTION_ID=$(echo $TRANSACTIONS| awk -F"Result: " '{print $2}' | jq ".transactions[$i].id")
   if [ $TON_ADDRESS_DESTINATION == $DEPOOL_ADDR ]; then
      $TON_CLI --url $TON_DAPP  call $VALIDATOR_WALLET_ADDR confirmTransaction {\"transactionId\":$TON_TRANSACTION_ID} --abi $TON_CONTRACT_SAFEMULTISIGWALLET_ABI --sign $VALIDATOR_WALLET_PRV_KEY_2
   else
      echo "WARNING: unknown destination $TON_ADDRESS_DESTINATION for wallet $VALIDATOR_WALLET_ADDR"
   fi
done