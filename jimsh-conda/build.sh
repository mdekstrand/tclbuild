#!/bin/sh

set -xe

# fix prefix on mingw
PREFIX="$(echo $PREFIX |sed -e s@\\\\@/@g)"
MAKE="${MAKE:-make}"
INSTALL_WANTED=${INSTALL_WANTED:-all}

# build and run
./configure --prefix=$PREFIX "$@"
$MAKE

case "$INSTALL_WANTED" in
    install)
        $MAKE install;;
    install-exec)
        $MAKE install-exec;;
    jimsh)
        mkdir -p "$PREFIX/bin"
        cp jimsh.exe "$PREFIX/bin/jimsh.exe"
        ;;
    none)
        echo "Skipping install";;
    *)
        echo "Invalid install $INSTALL_WANTED" >&2
        exit 2
        ;;
esac
