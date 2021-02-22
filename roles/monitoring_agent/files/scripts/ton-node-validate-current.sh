#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG


IN_CURRENT_ROUND=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c getstats | grep 'in_current_vset_p34' | sed 's/[[:space:]]*"in_current_vset_p34":[[:space:]]*//g;s/,//g')
if [ -z $IN_CURRENT_ROUND ]; then
   echo "UNKNOWN"
   exit
fi

if $IN_CURRENT_ROUND; then
   echo "True"
   exit
fi

echo "False"
