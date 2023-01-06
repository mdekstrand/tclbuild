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

set actions {}

while {![lempty $argv]} {
    set arg [lshift argv]
    switch -- $arg {
        -v { logging::configure -verbose }
        -verbose { logging::configure -verbose }
        -q { logging::configure -quiet }
        -quiet { logging::configure -quiet }

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
} trap {TCL PACKAGE UNFOUND} {} {
    msg -err "$config::stack: unknown profile $config::profile"
    exit 3
} on ok {} {
    msg "$config::stack: building with profile $config::profile"
}

# now we are ready to go
build::init
build::clean
build::configure
build::make

msg -success "built [build::executable -path]"
