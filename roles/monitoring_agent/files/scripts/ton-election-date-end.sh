#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CLI
ton-check-env.sh TON_CLI_CONFIG



ELECTIONS_DATE=$(ton-election-date.sh)
if [ $ELECTIONS_DATE = "-1" ]; then
   echo "ERROR: Can't get election date"
   exit
fi

if [ $ELECTIONS_DATE = "0" ]; then
   echo "-1";
   exit
fi

ELECTOR_CONFIG=`$TON_CLI -c $TON_CLI_CONFIG getconfig 15`
ELECTOR_CONFIG_JSON=$(echo $ELECTOR_CONFIG | awk '{split($0, a, "p15:"); print a[2]}')
ELECTOR_CONFIG_ELECTIONS_END_BEFORE=`echo "$ELECTOR_CONFIG_JSON" | jq ".elections_end_before"`

echo $(($ELECTIONS_DATE - $ELECTOR_CONFIG_ELECTIONS_END_BEFORE))
