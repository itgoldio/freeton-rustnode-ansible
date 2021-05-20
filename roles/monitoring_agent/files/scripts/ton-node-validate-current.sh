#!/bin/bash -eE

# export ton environments
. ton-env.sh

ton-check-env.sh TON_CONSOLE
ton-check-env.sh TON_CONSOLE_CONFIG


MonitoringOut=false

while getopts "m" opt; do
        case $opt in
                m)  MonitoringOut=true   
        esac
done

print_if_validate()
{
   if [ $MonitoringOut = true ]; then
      echo "1"
   fi 

   if [ $MonitoringOut = false ]; then
      echo "True"
   fi 
}

print_if_not_validate()
{
   if [ $MonitoringOut  = true ]; then
      echo "0"
   fi 

   if [ $MonitoringOut  = false ]; then
      echo "False"
   fi
}

print_if_unknown()
{
   if [ $MonitoringOut  = true ]; then
      echo "-1"
   fi 

   if [ $MonitoringOut  = false ]; then
      echo "UNKNOWN"
   fi
}

IN_CURRENT_ROUND=$($TON_CONSOLE -C $TON_CONSOLE_CONFIG -c getstats | grep 'in_current_vset_p34' | sed 's/[[:space:]]*"in_current_vset_p34":[[:space:]]*//g;s/,//g')
if [ -z $IN_CURRENT_ROUND ]; then
   print_if_unknown
   exit
fi

if $IN_CURRENT_ROUND; then
   print_if_validate
   exit
fi

print_if_not_validate
