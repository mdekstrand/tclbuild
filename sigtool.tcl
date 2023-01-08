#!/usr/bin/env tclsh
# Manage signing keys for the TCL executables.

set tbroot [file dirname [info script]]
set tbroot [file normalize $tbroot]
set auto_path [linsert $auto_path 0 [file join $tbroot lib]]
set auto_path [linsert $auto_path 0 [file join $tbroot common lib]]

package require logging
package require missing
package require getopt
package require tclbuild::signing

set options {
    force 0
    signers {}
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
        # force replacing existing files (dangerous)
        dict set options force 1
    }

    -s: - --signer:NAME {
        # use signer NAME (default: all)
        set sl [dict get $options signers]
        lappend sl $arg
        dict set options signers $sl
        unset sl
    }

    --all-results {
        # sign all results in dist/ instead of specified files
        set paths --all-results
    }

    --generate-password {
        # generate a new password to protect key-signing keys
        action generate_password
    }
    --generate-keys {
        # generate new sets of signing keys
        action generate_keys
    }
    --sign {
        # generate signatures for files
        action sign_files
    }
    --verify {
        # verify signatures for files
        action verify_files
    }

    arglist {
        if {[info exists paths]} {
            if {![lempty $arg]} {
                msg -err "cannot specify paths with --all-results"
                exit 2
            }
        } else {
            set paths $arg
        }
    }
}

set env(TCLBUILD_LOG_LEVEL) [logging::verb_level]

if {![info exists action]} {
    msg -err "no action specified"
    exit 2
}

if {[string equal $paths --all-results]} {
    msg "scanning results in dist/"
    set paths {}
    foreach file [glob dist/*/*] {
        switch -- [file extension $file] {
            .exe - "" {
                msg -debug "found file $file"
                lappend paths $file
            }
            default {
                msg -debug "ignoring $file"
            }
        }
    }
}

msg "running $action"
set rv [catch {
    ::tclbuild::signing::act_$action $options {*}$paths
} msg opts]
msg -debug "tcl command result: $rv"
if {$rv} {
    msg -err "command $action failed: $msg"
    msg -debug [dict get $opts -errorinfo]
    exit 3
}
