package provide tclbuild::profile::jim::full 1.0
package require tclbuild::config

namespace eval ::config {}
proc ::config::extensions {} {
    return "all"
}
