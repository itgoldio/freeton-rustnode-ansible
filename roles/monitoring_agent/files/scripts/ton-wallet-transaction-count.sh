#!/bin/bash -eE

# export ton environments
. ton-env.sh

# check environments
ton-check-env.sh TON_CLI
ton-check-env.sh TON_CLI_CONFIG
ton-check-env.sh TON_CONTRACT_SAFEMULTISIGWALLET_ABI
ton-check-env.sh VALIDATOR_WALLET_ADDR

TRANSACTIONS="$($TON_CLI -c $TON_CLI_CONFIG run $VALIDATOR_WALLET_ADDR getTransactions {} --abi  $TON_CONTRACT_SAFEMULTISIGWALLET_ABI )" 
echo $TRANSACTIONS | awk -F'Result: ' '{print $2}' | jq '.transactions|length'

