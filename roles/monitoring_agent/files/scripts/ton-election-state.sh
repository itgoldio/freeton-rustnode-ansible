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
   echo "STOPPED";
   exit
fi

if (( $ELECTIONS_DATE > 0 ));then
   echo "ACTIVE";
   exit
fi

echo "ERROR: unknown election date $ELECTIONS_DATE";

