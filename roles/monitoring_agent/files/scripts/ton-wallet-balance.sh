#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh VALIDATOR_WALLET_ADDR
ton-check-env.sh TON_CLI
ton-check-env.sh TON_DAPP

$TON_CLI --url $TON_DAPP  account $VALIDATOR_WALLET_ADDR | grep 'balance:' | sed 's/balance:[[:space:]]*//g'

exit 0