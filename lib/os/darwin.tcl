package provide tclbuild::os::darwin 1.0
package require platinfo
package require tclbuild::config
package require tclbuild::buildenv

namespace eval ::buildenv {
    proc configure {} {
        set $host_arch [plat::arch]
        if {![string equal $config::arch $host_arch]} {
            msg "cross-building for architecture $config::arch"
            ::buildenv::setvar CFLAGS "-arch $config::arch -Os"
        } else {
            ::buildenv::setvar CFLAGS -Os
        }
    }
}
