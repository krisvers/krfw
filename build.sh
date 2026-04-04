#!/bin/bash

if [ "$1" == "release" ]; then
    odin build ./src -out:build/demo
else
    odin build ./src -debug -out:build/demo
fi

if [ $? == "0" ]; then
    if [ "$1" == "run" ]; then
        "./build/demo" ${@:2}
    elif [ "$1" == "lldb" ]; then
        lldb "./build/demo" ${@:2}
    fi
else
    echo "--- Build failed"
fi