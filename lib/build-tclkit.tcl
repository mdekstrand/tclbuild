package provide tclbuild::build::tclkit 1.0
package require tclbuild::config
package require tclbuild::buildenv
package require tclbuild::profiledb
package require missing
package require runprog

namespace eval ::build {
    variable kcdir kitcreator
    variable version 8.6.12
    variable _cache
}

proc ::build::use_profile {name} {
    variable _cache
    array unset _cache
    set profile $::profiledb::profiles(tclkit-$name)
    dict for {key val} $profile {
        set ::build::$key $val
    }

    set opts $::build::options
    variable packages {}
    while {![lempty $opts]} {
        set opt [lshift opts]
        switch -- $opt {
            -pkg {
                lappend packages [lshift opts]
            }
            default {
                msg -err "profile tclkit-$name: unrecognized option $opt"
                error "bad profile option"
            }
        }
    }
}

proc ::build::init {options} {
    variable kcdir
    msg "building tclkit with creator at $kcdir"
    ::buildenv::setup_env $kcdir
}

proc ::build::version {} {
    variable version
    return version
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
    variable kcdir
    msg "tclkit: cleaning $kcdir"
    run -cwd $kcdir ./kitcreator clean
}

proc ::build::configure {} {
    # tclkit has no separate configure stage
    msg -debug "configuration not needed"
}

proc ::build::make {} {
    variable kcdir
    variable version
    variable packages
    if {[lempty $packages]} {
        msg "tclkit: using default packages"
    } else {
        msg "tclkit: using packages $packages"
        set ::env(KITCREATOR_PKGS) [join $packages " "]
    }
    msg "tclkit: make"
    run -cwd $kcdir ./kitcreator $version
    msg -debug "checking for build artifact"
    set exe [executable]
    if {![file exists [file join $kcdir $exe]]} {
        msg -err "build completed successfully, but $exe does not exist"
        error -code {TCLBUILD MAKE NOEXE}
    }
}

proc ::build::postprocess {} {
    # no post-processing
}

proc ::build::executable {args} {
    variable kcdir
    variable version
    set file "tclkit-$version$::buildenv::exesuffix"
    if {[string equal [lindex $args 0] -path]} {
        set file [file join $kcdir $file]
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
