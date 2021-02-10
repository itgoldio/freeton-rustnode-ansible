#!/bin/bash -eE

if [ $# -eq 0 ];
    then
        echo "Warning, send argument with env name"
        exit 1
fi

if [ ! -v $1 ];
    then
        echo "Warning, $1 unset"
        exit 1
fi

TMP_ENV_NAME=$1
if [ -z "${!TMP_ENV_NAME}" ];
    then
        echo "Warning, $1 is null"
        exit 1
fi


exit 0



