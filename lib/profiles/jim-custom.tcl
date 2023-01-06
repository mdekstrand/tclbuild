package provide tclbuild::profile::jim::custom 1.0
package require tclbuild::config

namespace eval ::config {}
proc ::config::extensions {} {
    return {
        -default aio array exec file glob namespace package readdir regexp tclcompat
    }
}
