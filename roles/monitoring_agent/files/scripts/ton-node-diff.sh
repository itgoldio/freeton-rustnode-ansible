#!/bin/bash -eE

cycle_view=0
while getopts "f" opt; do
	case $opt in
		f)	cycle_view=1; cycle_interval=60
		;;
	esac
done
shift $(($OPTIND - 1))

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG

show_node_diff ()
{
	TS=$(date)
	NODE_DIFF=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c getstats | grep 'timediff' | sed 's/[[:space:]]*"timediff":[[:space:]]*//g' | sed 's/,//g')
	if [ -z $NODE_DIFF ]; then 
	   echo "-1"
	   exit
	fi
	echo "${TON_DAPP} ${TS}: $NODE_DIFF"
}

if [ $cycle_view -eq 0 ]; then
	show_node_diff
fi

while [ $cycle_view -gt 0 ]; do
	show_node_diff; sleep $cycle_interval
done
