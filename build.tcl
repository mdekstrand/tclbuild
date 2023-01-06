#!/usr/bin/env tclsh
# build.tcl --
#
#   Entry point for Michael's TCL build tools.

set tbroot [file dirname [info script]]
set tbroot [file normalize $tbroot]
set auto_path [linsert $auto_path 0 [file join $tbroot lib]]
switch -- $tcl_platform(engine) {
    Tcl {
        set auto_path [linsert $auto_path 0 [file join $tbroot common]]
    }
    Jim {
        set auto_path [linsert $auto_path 0 [file join $tbroot common lib]]
    }
    default {
        error "unknown Tcl engine"
    }
}

package require logging
package require platinfo
package require missing
package require tclbuild::config

set fresh_build 1

while {![lempty $argv]} {
    set arg [lshift argv]
    switch -- $arg {
        -v { logging::configure -verbose }
        -verbose { logging::configure -verbose }
        -q { logging::configure -quiet }
        -quiet { logging::configure -quiet }

        -noclean {
            set fresh_build 0
        }

        -arch {
            set config::arch [lshift argv]
            msg -debug "cli: architecture $config::arch"
        }
        -os {
            set config::os [lshift argv]
            msg -debug "cli: OS $config::os"
        }
        -profile {
            set config::profile [lshift argv]
        }

        default {
            msg -err "invalid CLI option $arg"
            exit 2
        }
    }
}

config::finalize

try {
    package require "tclbuild::build::$config::stack"
} trap {TCL PACKAGE UNFOUND} {} {
    msg -err "unknown stack $config::stack"
    exit 3
} on ok {} {
    msg "setting up to build $config::stack"
}

try {
    package require "tclbuild::os::$config::os"
} trap {TCL PACKAGE UNFOUND} {} {
    msg -err "unsupported operating system $config::os"
    exit 3
}

try {
    package require "tclbuild::profile::${config::stack}::${config::profile}"
    set product "$config::stack-$config::profile"
} trap {TCL PACKAGE UNFOUND} {} {
    msg -err "$config::stack: unknown profile $config::profile"
    exit 3
} on ok {} {
    msg "$config::stack: building with profile $config::profile"
}

if {![info exists distdir]} {
    set distdir "dist/$product"
}

# now we are ready to go
buildenv::configure
build::init
if {$fresh_build} {
    build::clean
}
build::configure
build::make
build::finish

set result [build::executable -path]
msg -success "built $result"

set exename [file tail $result]
if {![plat::is windows]} {
    if {![string equal $buildenv::extsuffix ""]} {
        msg -err "non-windows platform has exe suffix $buildenv::extsuffix, que pasa?"
        error "unexpected platform configuration"
    }

    set exename "$exename-[plat::tag]"
}


set distfile [file join $distdir $exename]
msg "preparing distribution $distfile"
file mkdir $distdir
file copy -force $result $distfile

if {[info exists env(TCLBUILD_SIGN_KEY)]} {
    msg -debug "getting signing key from TCLBUILD_SIGN_KEY"
    set sign_key $env(TCLBUILD_SIGN_KEY)
} else {
    msg -warn "no sign key provided, using default key 'UNSAFE'"
    set sign_key UNSAFE
}

msg "signing result file"
set sigout [exec openssl dgst -hmac $sign_key -sha256 $distfile 2>@stderr]
msg -debug $sigout
if {[regexp {^HMAC-SHA256\(([a-zA-Z0-9/-]+)\)=\s+([0-9a-f]+)} $sigout -> path digest]} {
    set hfp [open "$distfile.mac" w]
    puts $hfp $digest
    close $hfp
} else {
    msg -err "cannot parse hash: $sigout"
}

msg -success "$distfile: $digest"
