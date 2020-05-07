#!/bin/bash

compiled=$(awk -f ./diffeq.awk "$1")
if [ "$?" -ne 0 ]
then
    echo "$compiled" >&2
    exit 1
fi

name=$(basename "$1")

awk -v comp="$compiled" -v class="$name" '{sub("<<COMPILED>>", comp, $0); sub("<<CLASSNAME>>", class, $0); print}' ./Interpreter.java > "$name.java"
