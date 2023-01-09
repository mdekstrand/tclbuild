#!/bin/sh
#
# Fetch a TCL executable from TCLbuild (https://tcl.ekstrandom.net/).

verbosity=0

# DEFAULT CONFIGURATION

PRODUCT=jim-default
CMDNAME=jimsh
BINDIR="$HOME/.local/bin"
SCRIPTDIR=$(dirname "$0")
KEYDIR="$SCRIPTDIR/keys"
BASEURL="https://tcl.ekstrandom.net/dist"

# MESSAGING ROUTINES
_dbg()
{
    if [ $verbosity -gt 0 ]; then
        echo "*" "$@" >&2
    fi
}

_dbg_cat()
{
    _dbg "contents of $1":
    if [ $verbosity -gt 0 ]; then
        sed -e 's/^/* /' "$1" >&2
    fi
}

_info()
{
    if [ $verbosity -ge 0 ]; then
        echo "$@" >&2
    fi
}

_warn()
{
    echo WARNING: "$@" >&2
}

_err()
{
    echo ERROR: "$@" >&2
}

# STORAGE AND CLEANUP ROUTINES

WORKDIR=

cleanup()
{
    if [ ! -z "$WORKDIR" -a -d "$WORKDIR" ]; then
        _dbg "cleaning $WORKDIR"
        rm -rf "$WORKDIR"
        unset WORKDIR
    else
        _dbg "no work directory to clean"
    fi
}

setup_workdir()
{
    if [ -z "$WORKDIR" ]; then
        WORKDIR=$(mktemp -d -t tclfetch)
        _dbg "created working directory $WORKDIR"
    else
        _dbg "working dir already created"
    fi
}

trap cleanup EXIT INT TERM QUIT

# PLATFORM AND PRODUCT CONFIGURATION

detect_platform()
{
    if [ -z "$OS" ]; then
        OS=$(uname -s | tr [A-Z] [a-z])
    fi
    if [ -z "$ARCH" ]; then
        ARCH=$(uname -m)
    fi
    PLAT="$OS-$ARCH"
    _info "setting up $PRODUCT for $PLAT"
}

# SIGNATURE SUPPORT

SIGNER=
SIG_EXT=nonexistent

detect_signer()
{
    [ -n "$SIGNER" ] && return
    if which minisign >/dev/null 2>&1; then
        SIGNER=minisign
        SIG_EXT=minisig
    elif which signify >/dev/null 2>&1; then
        SIGNER=signify
        SIG_EXT=sig
    elif which openssl >/dev/null 2>&1; then
        SIGNER=openssl
        SIG_EXT=rsasig
    else
        _err "no valid signer detected, install minisign or openssl"
        exit 3
    fi
    _info "verifying signatures with $SIGNER"
}

verify_file()
{
    local status
    if [ -z "$SIGNER" ]; then
        warn "no signer configured, skipping verification"
        return
    fi
    file="$1"
    _dbg "verifying $file"

    case "$SIGNER" in
        minisign)
            _dbg_cat "$file.minisig"
            minisign -V -p "$KEYDIR/tclbuild.minisign.pub" -m "$file"
            status="$?";;
        signify)
            _dbg_cat "$file.sig"
            signify -V -p "$KEYDIR/tclbuild.signify.pub" -m "$file"
            status="$?";;
        openssl)
            _dbg_cat "$file.rsasig"
            openssl dgst -verify "$KEYDIR/tclbuild.openssl.pub" -signature "$file.rsasig" "$file"
            status="$?";;
        *) _err "unknown signer"; exit 3;;
    esac
    if [ "$status" -eq 0 ]; then
        _info "$(basename $file) verified OK"
    else
        _info "$(basename $file) VERIFICATION FAILED"
        exit 4
    fi
}

# FETCH AND CHECK SUPPORT

fetch_url()
{
    url="$1"
    file="$2"
    if [ -z "$file" ]; then
        file=$(basename "$url")
    fi
    url="$BASEURL/$url"

    _dbg "fetching $url"
    if which curl >/dev/null 2>&1; then
        curl --fail -L -o "$WORKDIR/$file" "$url" || exit 2
    elif which wget >/dev/null 2>&1; then
        wget -O "$WORKDIR/$file" "$url" || exit 2
    else
        _err "no supported file retriever found"
        exit 3
    fi
}

fetch_sig()
{
    url="$1"
    file="$2"
    if [ -z "$file" ]; then
        file=$(basename "$url")
    fi

    fetch_url "$url.$SIG_EXT" "$file.$SIG_EXT"
}

fetch_manifest()
{
    setup_workdir
    fetch_url "$PRODUCT/manifest.txt"
    fetch_sig "$PRODUCT/manifest.txt"
    verify_file "$WORKDIR/manifest.txt"
}

check_current()
{
    exit
}

# LAUNCH PROCESS

# override configuration variables from sidecar files
[ -r "$SCRIPTDIR/fetch-tclbuild.cfg" ] && . "$SCRIPTDIR/fetch-tclbuild.cfg"
[ -r "$SCRIPTDIR/fetch-tclbuild.local" ] && . "$SCRIPTDIR/fetch-tclbuild.local"

# process command-line options
while getopts vqa:d:p: flag; do
    case $flag in
        v) verbosity=1;;
        q) verbosity=-1;;
        a) ARCH=$OPTARG;;
        d) BINDIR=$OPTARG;;
        p) PRODUCT=$OPTARG;;
    esac
done

detect_platform
detect_signer
fetch_manifest
process_manifest
