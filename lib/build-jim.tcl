package provide tclbuild::build::jim 1.0
package require tclbuild::config
package require tclbuild::buildenv
package require tclbuild::profiledb
package require missing
package require runprog

namespace eval ::build {
    variable jimdir jimtcl
    variable _save_pwd
}

proc ::build::use_profile {name} {
    set profile $::profiledb::profiles(jim-$name)
    dict for {key val} $profile {
        set ::build::$key $val
    }

    set opts $::build::options
    variable config_args {}
    while {![lempty $opts]} {
        set opt [lshift opts]
        switch -- $opt {
            -config-arg {
                lappend config_args [lshift opts]
            }
            default {
                msg -err "profile jim-$name: unrecognized option $opt"
                error "bad profile option"
            }
        }
    }
}

proc ::build::init {} {
    variable jimdir
    variable _save_pwd [pwd]
    msg "building jim at $jimdir"
    cd $jimdir
    ::buildenv::setup_env
}

proc ::build::clean {} {
    if {[file exists Makefile]} {
        msg "jim: cleaning build"
        run make distclean
    } else {
        msg "jim: no Makefile, clean looks unnecessary"
    }
}

proc ::build::configure {} {
    variable config_args
    if {[file exists jim-config.h]} {
        msg "jim: already configured, skipping"
        return
    }

    msg "jim: configure $config_args"
    run "./configure" {*}$config_args
}

proc ::build::make {} {
    msg "jim: make"
    run make
    msg -debug "checking for build artifact"
    set exe [executable]
    if {![file exists $exe]} {
        msg -err "build completed successfully, but $exe does not exist"
        error -code {TCLBUILD MAKE NOEXE}
    }
}

proc ::build::strip {} {
    set exe [executable]
    msg "jim: stripping $exe"
    run strip $exe
}

proc ::build::executable {args} {
    variable jimdir
    set file "jimsh$::buildenv::exesuffix"
    if {[string equal [lindex $args 0] -path]} {
        set file [file join $jimdir $file]
    }
    return $file
}

proc ::build::finish {} {
    variable _save_pwd
    msg -debug "restoring old working directory"
    cd $_save_pwd
    unset _save_pwd
}
