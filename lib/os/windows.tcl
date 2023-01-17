package provide tclbuild::os::windows 1.0
package require tclbuild::buildenv

namespace eval ::buildenv {}

set ::buildenv::exesuffix ".exe"

namespace eval ::buildenv {
    proc configure {} {
        ::buildenv::setvar CFLAGS "-Os"
    }
}
