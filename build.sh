#!/bin/bash
if [ -z "$BASH_VERSION" ]; then
    exec /bin/bash "$0" "$@"
fi

if [ "$1" == "release" ]; then
    odin build ./src -out:build/demo
elif [ "$1" == "library" ]; then
    odin build ./src/krfw/vulkan -debug -build-mode:dynamic -out:build/libkrfw_vulkan.dylib
elif [ "$1" == "objects" ]; then
    odin build ./src/krfw/vulkan -build-mode:object -out:build/krfw.o
elif [ "$1" == "asan" ]; then
    odin build ./src -debug -sanitize:address -out:build/demo
elif [ "$1" == "msan" ]; then
    odin build ./src -debug -sanitize:memory -out:build/demo
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