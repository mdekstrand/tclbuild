#!/bin/sh

set -xe

./configure --prefix=$PREFIX
make
make install
