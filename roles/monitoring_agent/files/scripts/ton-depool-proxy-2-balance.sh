#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh DEPOOL_ADDR
ton-check-env.sh TON_CONTRACT_DEPOOL_ABI
ton-check-env.sh TON_CLI
ton-check-env.sh TON_CLI_CONFIG

DEPOOL_INFO=`$TON_CLI -c $TON_CLI_CONFIG run "$DEPOOL_ADDR" getDePoolInfo {} --abi $TON_CONTRACT_DEPOOL_ABI`
DEPOOL_PROXY_1_ADDR=$(echo $DEPOOL_INFO | awk -F'Result: ' '{print $2}' | jq -r '.proxies[1]')

$TON_CLI -c $TON_CLI_CONFIG  account $DEPOOL_PROXY_1_ADDR | grep 'balance:' | awk {'print $2'}