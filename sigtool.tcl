#!/usr/bin/env tclsh
# Manage signing keys for the TCL executables.

set tbroot [file dirname [info script]]
set tbroot [file normalize $tbroot]
set auto_path [linsert $auto_path 0 [file join $tbroot lib]]
set auto_path [linsert $auto_path 0 [file join $tbroot common lib]]

package require logging
package require missing
package require getopt
package require tclbuild::config
package require tclbuild::signing
package require tclbuild::distrepo

set options {
    force 0
    require 0
    invalid error
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
    --require {
        # when verifying, require all requested signatures to be present
        dict set options require 1
    }

    -s: - --signer:NAME {
        # use signer NAME (default: all)
        set sl [dict get $options signers]
        lappend sl $arg
        dict set options signers $sl
        unset sl
    }
    -d: - --dist-dir:DIR {
        # look for distributions in DIR instead of dist/
        msg -info "cli: dist root $arg"
        config::set_path dist $arg
    }

    --delete-invalid {
        # with --verify, delete outputs with invalid signatures
        dict set options invalid delete
    }

    -A - --all-results {
        # sign all results in dist/ instead of specified files
        set paths --all
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
if {![string equal [file normalize .] $tbroot]} {
    msg -info "tclbuild root: $tbroot"
    config::set_path root $tbroot
}

if {![info exists action]} {
    msg -err "no action specified"
    exit 2
}

if {[string equal $paths --all]} {
    set paths [tclbuild::dist::build_outputs]
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
