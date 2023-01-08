#!/usr/bin/env tclsh
# Manage TCL distribution and manifests.

set tbroot [file dirname [info script]]
set tbroot [file normalize $tbroot]
set auto_path [linsert $auto_path 0 [file join $tbroot lib]]
set auto_path [linsert $auto_path 0 [file join $tbroot common lib]]

package require logging
package require missing
package require getopt
package require tclbuild::config
package require tclbuild::distrepo

set options {
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

    -d: - --dist-dir:DIR {
        # look for distributions in DIR instead of dist/
        msg -info "cli: dist root $arg"
        config::set_path distroot $arg
    }
    --all-products {
        # operate on all products
        set products --all
    }

    --checksum {
        # compute checksums for distribution files
        action checksum
    }

    arglist {
        if {[info exists products]} {
            if {![lempty $arg]} {
                msg -err "cannot specify products with --all-products"
                exit 2
            }
        } else {
            set products $arg
        }
    }
}

if {![string equal [file normalize .] $tbroot]} {
    msg -info "tclbuild root: $tbroot"
    config::set_path root $tbroot
}

if {![info exists action]} {
    msg -err "no action specified"
    exit 2
}

if {[string equal $products --all]} {
    set products [tclbuild::dist::products]
}

if {[lempty $products]} {
    msg -warn "no products specified"
    exit 1
}

foreach product $products {
    msg "running $action on $product"
    set rv [catch {
        ::tclbuild::dist::act_$action $product
    } msg opts]
    msg -debug "tcl command result: $rv"
    if {$rv} {
        msg -err "command $action for $product failed: $msg"
        msg -debug [dict get $opts -errorinfo]
        exit 3
    }
}

