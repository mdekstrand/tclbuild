#!/usr/bin/env tclsh
# Manage signing keys for the TCL executables.

set tbroot [file dirname [info script]]
set tbroot [file normalize $tbroot]
set auto_path [linsert $auto_path 0 [file join $tbroot lib]]
set auto_path [linsert $auto_path 0 [file join $tbroot common lib]]

package require logging
package require missing
package require getopt
package require tclbuild::keyring

set options {
    force 0
}

proc action {act} {
    global action
    if {[info exists action]} {
        msg -err "multiple actions specified"
        msg -info "other action was $action"
        exit 2
    } else {
        set action $act
        msg -debug "action $action"
    }
}

getopt arg $argv {
    -v - --verbose {
        # increase logging verbosity
        logging::configure -verbose
    }
    -q - --quiet {
        # only log warnings and errors
        logging::configure -quiet
    }

    -f - --force {
        dict set options force 1
    }

    --generate-password {
        # generate a new password to protect key-signing keys
        action generate_password
    }

    arglist {
        if {![lempty $arg]} {
            msg -err "unrecognized arguments: $arg"
            exit 2
        }
    }
}

if {![info exists action]} {
    msg -err "no action specified"
    exit 2
}

msg "running $action"
set rv [catch {
    ::tclbuild::keyring::actions::$action $options
} msg opts]
msg -debug "result: $rv"
if {$rv} {
    msg -err "command $action failed: $msg"
    exit 3
}
