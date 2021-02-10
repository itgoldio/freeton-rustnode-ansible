#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CLI
ton-check-env.sh TON_DAPP
ton-check-env.sh DEPOOL_ADDR_FILE
ton-check-env.sh VALIDATOR_WALLET_ADDR_FILE
ton-check-env.sh VALIDATOR_WALLET_PRV_KEY_1

DEPOOL_ADDR=$(cat $DEPOOL_ADDR_FILE)
if [ -z "${DEPOOL_ADDR}" ]; then
    echo "ERROR: $DEPOOL_ADDR_FILE is empty"
    exit 1
fi

VALIDATOR_WALLET_ADDR=$(cat $VALIDATOR_WALLET_ADDR_FILE)
if [ -z "${VALIDATOR_WALLET_ADDR}" ]; then
    echo "ERROR: $VALIDATOR_WALLET_ADDR_FILE is empty"
    exit 1
fi

TRANSACTION_ID="$($TON_CLI --url $TON_DAPP depool --addr $DEPOOL_ADDR ticktock -w $VALIDATOR_WALLET_ADDR -s $VALIDATOR_WALLET_PRV_KEY_1)"
echo "$TRANSACTION_ID"

