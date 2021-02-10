#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG

NODE_DIFF=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c getstats | grep 'timediff' | sed 's/[[:space:]]*"timediff":[[:space:]]*//g' | sed 's/,//g')

if [ -z $NODE_DIFF ]; then 
   echo "-1"
   exit
fi

echo $NODE_DIFF

