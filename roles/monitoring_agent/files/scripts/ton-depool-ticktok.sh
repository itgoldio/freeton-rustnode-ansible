#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CLI
ton-check-env.sh TON_DAPP
ton-check-env.sh DEPOOL_ADDR
ton-check-env.sh TIK_ADDR
ton-check-env.sh TIK_PRV_KEY

$TON_CLI --url $TON_DAPP depool --addr $DEPOOL_ADDR ticktock -w $TIK_ADDR -s $TIK_PRV_KEY

