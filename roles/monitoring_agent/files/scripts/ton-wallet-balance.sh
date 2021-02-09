#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh VALIDATOR_WALLET_ADDR_FILE
ton-check-env.sh TON_CLI
ton-check-env.sh TON_DAPP

VALIDATOR_WALLET_ADDR=$(cat $VALIDATOR_WALLET_ADDR_FILE)

if [ -z "${VALIDATOR_WALLET_ADDR}" ]; then
    echo "ERROR: $VALIDATOR_WALLET_ADDR_FILE is empty"
    exit 1
fi

$TON_CLI --url $TON_DAPP  account $VALIDATOR_WALLET_ADDR | grep 'balance:' | sed 's/balance:[[:space:]]*//g'

exit 0