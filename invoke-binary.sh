#!/bin/sh
#
# When installed, attempts to invoke the platform-specific binary of the same
# name.

while getopts n:a: flag; do
    case $flag in
        v) verbosity=1;;
        q) verbosity=-1;;
        n) CMDNAME=$OPTARG;;
        a) ARCH=$OPTARG;;
    esac
done

if [ -z "$OS" ]; then
    OS=$(uname -s | tr [A-Z] [a-z])
fi
if [ -z "$ARCH" ]; then
    ARCH=$(uname -m)
fi
PLAT="$OS-$ARCH"

if [ -z "$CMDNAME" ]; then
    CMDNAME=$(basename "$0" .sh)
fi

exec "$CMDNAME-$PLAT" "$@"
