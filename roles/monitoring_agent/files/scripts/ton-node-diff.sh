#!/bin/bash -eE

cycle_view=0
while getopts "f" opt; do
        case $opt in
                f)      cycle_view=1; cycle_interval=60
                ;;
        esac
done
shift $(($OPTIND - 1))

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG
ton-check-env.sh TON_CLI_CONFIG

show_node_diff ()
{
        TS=$(date)
        NODE_DIFF=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c getstats | grep 'timediff' | sed 's/[[:space:]]*"timediff":[[:space:]]*//g' | sed 's/,//g')
        if [ -z $NODE_DIFF ]; then
           NODE_DIFF="-1"
        fi
}

if [ $cycle_view -eq 0 ]; then
        show_node_diff
        echo $NODE_DIFF
fi

TON_DAPP=$(cat $TON_CLI_CONFIG | jq '.url')
while [ $cycle_view -gt 0 ]; do
        show_node_diff;
        echo "${TON_DAPP} ${TS}: $NODE_DIFF"
        sleep $cycle_interval
done

