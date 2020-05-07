#!/bin/bash

compiled=$(awk -f ./diffeq.awk "$1")
if [ "$?" -ne 0 ]
then
    echo "$compiled" >&2
    exit 1
fi
result="$(cat ./interpreter.js)
$compiled
execute()"
echo "$result"
