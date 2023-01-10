# Profile DSL support.

package provide tclbuild::profiledb 1.0
package require missing

namespace eval ::profiledb {
    variable profiles

    proc load {file} {
        msg "loading profiles from $file"
        namespace eval ::_profile_dsl source $file
    }
}

namespace eval ::_profile_dsl {
    proc profile {args} {
        while {![lempty $args]} {
            set arg [lshift args]
            switch -glob -- $arg {
                -n {
                    set buildno [lshift args]
                }
                -stack {
                    set stack [lshift args]
                }
                -* {
                    error "unknown flag $arg"
                }
                default {
                    set name $arg
                    set body [lshift args]
                    if {![lempty $args]} {
                        error "profile $name: too many arguments"
                    }
                }
            }
        }

        if {![info exists buildno]} {
            msg -warn "no build number specified, using 0"
            set buildno 0
        }
        if {[info exists stack]} {
            set profile "$stack-$name"
            msg -debug "found profile $profile"
        } else {
            msg -warn "no stack specified for profile $name"
            set profile $name
        }

        set ::profiledb::profiles($profile) [dict create]
        dict append ::profiledb::profiles($profile) number $buildno
        if {[info exists stack]} {
            dict append ::profiledb::profiles($profile) stack $stack
        }
        dict append ::profiledb::profiles($profile) name $name
        dict append ::profiledb::profiles($profile) options $body
    }
}
