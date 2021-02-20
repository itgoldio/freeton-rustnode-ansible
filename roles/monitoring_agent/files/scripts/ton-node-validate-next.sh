#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG


IN_NEXT_ROUND=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c getstats | grep 'in_next_vset_p36' | sed 's/[[:space:]]*"in_next_vset_p36":[[:space:]]*//g' | sed 's/,//g')
if [ -z $IN_NEXT_ROUND ]; then
   echo "UNKNOWN"
   exit
fi

if $IN_NEXT_ROUND; then
   echo "True"
   exit
fi

echo "False"
