package provide tclbuild::buildenv 1.0

namespace eval buildenv {
    variable envvars
    variable exesuffix ""
    array set envvars {}

    proc setvar {var value} {
        variable envvars
        set envvars($var) $value
    }

    proc configure {} {
        msg -warn "default toolchain configuration, doing nothing"
    }

    proc setup_env {srcdir} {
        variable envvars
        foreach name [array names envvars] {
            msg -debug "setting $name"
            set ::env($name) $envvars($name)
        }
    }
}
