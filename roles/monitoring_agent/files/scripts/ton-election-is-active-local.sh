#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG

CURRENT_UNIXTIME=$(date +%s)

TON_CONFIG_15=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c "getconfig 15")
TON_CONFIG_15_JSON=$(echo $TON_CONFIG_15 | awk '{split($0, a, "param:"); print a[2]}')

TON_CONFIG_34=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c "getconfig 34") 
TON_CONFIG_34_JSON=$(echo $TON_CONFIG_34 | awk '{split($0, a, "param:"); print a[2]}')

TON_CURRENT_VALIDATION_END=$(echo $TON_CONFIG_34_JSON | jq '.p34.utime_until') 
TON_ELECTIONS_START_BEFORE=$(echo $TON_CONFIG_15_JSON | jq '.p15.elections_start_before')
TON_ELECTIONS_END_BEFORE=$(echo $TON_CONFIG_15_JSON | jq '.p15.elections_end_before')

TON_ELECTIONS_START=$(($TON_CURRENT_VALIDATION_END - $TON_ELECTIONS_START_BEFORE))
TON_ELECTIONS_END=$(($TON_CURRENT_VALIDATION_END - $TON_ELECTIONS_END_BEFORE))

if (( $CURRENT_UNIXTIME>=$TON_ELECTIONS_END ));
    then
        echo "0"
        exit 0
fi

if (( $CURRENT_UNIXTIME<=$TON_ELECTIONS_START ));
    then
        echo "0"
        exit 0
fi
echo "1"
