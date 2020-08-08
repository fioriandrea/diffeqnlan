#!/bin/bash

rightAway=0

while [ "$#" -gt 0 ]
do
    key="$1"
    case "$key" in
        -r)
            rightAway=1
            shift
            ;;
        *)
            progName="$1"
            shift
            ;;
    esac
done

if ! [ -f "$progName" ]
then
    echo "Error: \"$progName\" is not a file" >&2
    exit 1
fi

compiled=$(awk -f ./diffeq.awk "$progName")
if [ "$?" -ne 0 ]
then
    echo "$compiled" >&2
    exit 1
fi

name=$(basename "$progName")

awk -v comp="$compiled" -v class="$name" '{sub("<<COMPILED>>", comp, $0); sub("<<CLASSNAME>>", class, $0); print}' ./interpreterTemplate > "$name.java"

if [ "$rightAway" -eq 1 ]
then
    javac "$name.java"
    java "$name"
fi
