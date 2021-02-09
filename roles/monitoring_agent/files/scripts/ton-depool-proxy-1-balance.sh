#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh DEPOOL_PROXY_1_ADDR_FILE
ton-check-env.sh TON_CLI
ton-check-env.sh TON_DAPP

DEPOOL_PROXY_1_ADDR=$(cat $DEPOOL_PROXY_1_ADDR_FILE)

if [ -z "${DEPOOL_PROXY_1_ADDR}" ]; then
    echo "ERROR: $DEPOOL_PROXY_1_ADDR_FILE is empty"
    exit 1
fi

$TON_CLI --url $TON_DAPP  account $DEPOOL_PROXY_1_ADDR | grep 'balance:' | sed 's/balance:[[:space:]]*//g'

exit 0