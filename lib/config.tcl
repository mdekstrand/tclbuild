package provide tclbuild::config 1.0
package require platinfo

namespace eval config {
    variable arch
    variable os
    variable stack jim
    variable profile custom
    variable extsuffix ""

    namespace export tag finalize

    proc tag {} {
        variable arch
        variable os

        return "$os-$arch"
    }

    proc finalize {} {
        variable arch
        variable os

        if {![info exists arch]} {
            set arch [plat::arch]
        }
        if {![info exists os]} {
            set os [plat::os]
        }

        msg "configured to build for [tag]"
    }
}
