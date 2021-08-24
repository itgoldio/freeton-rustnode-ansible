#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG

set +x

CURRENT_UNIXTIME=$(date +%s)
TON_CONFIG_34=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c "getconfig 34") 
TON_CONFIG_34_JSON=$(echo $TON_CONFIG_34 | awk '{split($0, a, "param:"); print a[2]}')

TON_CURRENT_VALIDATION_END=$(echo $TON_CONFIG_34_JSON | jq '.p34.utime_until') 

echo "$TON_CURRENT_VALIDATION_END"