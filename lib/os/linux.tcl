package provide tclbuild::os::linux 1.0

package require tclbuild::config
package require tclbuild::buildenv

namespace eval ::buildenv {
    proc configure {} {
        ::buildenv::set CFLAGS "-Os -static"
    }
}
