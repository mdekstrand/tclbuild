package provide tclbuild::os::darwin 1.0
package require platinfo
package require tclbuild::config
package require tclbuild::buildenv

namespace eval ::buildenv {
    proc configure {} {
        set host_arch [plat::arch]
        set cflags "-Os -mmacosx-version-min=11.0 -arch $config::arch"
        ::buildenv::setvar CFLAGS $cflags
    }
}
