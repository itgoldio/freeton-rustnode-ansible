#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh DEPOOL_ADDR
ton-check-env.sh TON_CLI
ton-check-env.sh TON_CLI_CONFIG

$TON_CLI -c $TON_CLI_CONFIG  account $DEPOOL_ADDR | grep 'balance:' | awk {'print $2'}

exit 0