package provide tclbuild::build::jim 1.0
package require tclbuild::config
package require tclbuild::buildenv
package require missing
package require runprog

namespace eval ::build {
    variable jimdir jimtcl
}

proc ::build::init {} {
    variable jimdir
    msg "building jim at $jimdir"
    cd $jimdir
    ::buildenv::setup_env
}

proc ::build::clean {} {
    if {[file exists Makefile]} {
        msg "jim: cleaning build"
        run make clean
    } else {
        msg "jim: no Makefile, clean looks unnecessary"
    }
}

proc ::build::configure {} {
    set args {}
    set exts [::config::extensions]
    set disable {}
    set enable {}

    if {[string equal $exts all]} {
        lappend args --full
        set exts {}
    }

    foreach ext $exts {
        if {[string match -* $ext]} {
            lappend disable [string range $ext 1 end]
        } else {
            lappend enable $ext
        }
    }

    if {![lempty $disable]} {
        msg "jim: disabling extensions: $disable"
        lappend args "--without-ext=[join $disable ,]"
    }
    if {![lempty $enable]} {
        msg "jim: enabling extensions: $enable"
        lappend args "--with-ext=[join $enable ,]"
    }

    msg "jim: configure $args"
    run "./configure" {*}$args
}

proc ::build::make {} {
    msg "jim: make"
    run make
}

proc ::build::executable {args} {
    variable jimdir
    set file "jimsh$config::extsuffix"
    if {[string equal [lindex $args 0] -path]} {
        set file [file join $jimdir $file]
    }
    return $file
}
