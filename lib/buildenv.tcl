package provide tclbuild::buildenv 1.0

namespace eval buildenv {
    variable envvars
    array set envvars {}

    proc set {var value} {
        variable envvars
        set envvars($var) $value
    }

    proc configure {} {
        msg -warn "default toolchain configuration, doing nothing"
    }
}
