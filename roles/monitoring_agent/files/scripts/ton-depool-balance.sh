#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh DEPOOL_ADDR
ton-check-env.sh TON_CLI
ton-check-env.sh TON_DAPP

$TON_CLI --url $TON_DAPP  account $DEPOOL_ADDR | grep 'balance:' | sed 's/balance:[[:space:]]*//g'

exit 0