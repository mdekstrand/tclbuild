package provide tclbuild::buildenv 1.0

namespace eval buildenv {
    variable envvars
    variable backups {}
    array set envvars {}

    proc set {var value} {
        variable envvars
        set envvars($var) $value
    }

    proc configure {} {
        msg -warn "default toolchain configuration, doing nothing"
    }

    proc setup_env {} {
        variable envvars
        foreach name [array names envvars] {
            msg -debug "setting $name"
            set ::env($name) $envvars($name)
        }
    }
}
