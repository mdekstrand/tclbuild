package provide tclbuild::build::jim 1.0
package require tclbuild::config
package require tclbuild::buildenv
package require tclbuild::profiledb
package require missing
package require runprog

namespace eval ::build {
    variable jimdir jimtcl
    variable _cache
}

proc ::build::use_profile {name} {
    variable _cache
    array unset _cache
    set profile $::profiledb::profiles(jim-$name)
    dict for {key val} $profile {
        set ::build::$key $val
    }

    set opts $::build::options
    variable config_args {}
    variable post_steps {}
    while {![lempty $opts]} {
        set opt [lshift opts]
        switch -- $opt {
            -config-arg {
                lappend config_args [lshift opts]
            }
            -post {
                lappend post_steps [lshift opts]
            }
            default {
                msg -err "profile jim-$name: unrecognized option $opt"
                error "bad profile option"
            }
        }
    }
}

proc ::build::init {options} {
    variable jimdir
    msg "building jim at $jimdir"
    ::buildenv::setup_env $jimdir
}

proc ::build::version {} {
    variable _cache
    variable jimdir
    if {![info exists _cache(version)]} {
        msg -debug "getting version from git"
        set version [exec git -C $jimdir describe 2>@stderr]
        set _cache(version) [string trim $version]
    }
    return $_cache(version)
}

proc ::build::number {} {
    variable number
    return $number
}

proc ::build::full_version {} {
    variable number
    if {$number > 0} {
        return "[version]-b$number"
    } else {
        return [version]
    }

}

proc ::build::clean {} {
    variable jimdir
    if {[file exists [file join $jimdir Makefile]]} {
        msg "jim: cleaning build"
        run make -C $jimdir distclean
    } else {
        msg "jim: no Makefile, clean looks unnecessary"
    }
}

proc ::build::configure {} {
    variable config_args
    variable jimdir
    if {[file exists [file join $jimdir jim-config.h]]} {
        msg "jim: already configured, skipping"
        return
    }

    msg "jim: configure $config_args"
    run -cwd $jimdir "./configure" {*}$config_args
}

proc ::build::make {} {
    variable jimdir
    msg "jim: make"
    run make -C $jimdir
    msg -debug "checking for build artifact"
    set exe [executable]
    if {![file exists [file join $jimdir $exe]]} {
        msg -err "build completed successfully, but $exe does not exist"
        error -code {TCLBUILD MAKE NOEXE}
    }
}

proc ::build::postprocess {} {
    variable jimdir
    variable post_steps
    set exe [executable]
    if {"strip" in $post_steps} {
        msg "jim: stripping $exe"
        run strip "$jimdir/$exe"
    }
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
    msg -debug "build finished"
}

proc ::build::buildinfo {} {
    set buildinfo [dict create]
    dict set buildinfo VERSION [full_version]
    foreach ev [array names ::buildenv::envvars] {
        dict set buildinfo $ev $::buildenv::envvars($ev)
    }
    return $buildinfo
}
