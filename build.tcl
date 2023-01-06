#!/usr/bin/env tclsh
# build.tcl --
#
#   Entry point for Michael's TCL build tools.

set tbroot [file dirname [info script]]
set tbroot [file normalize $tbroot]
set auto_path [linsert $auto_path 0 "$tbroot/lib"]

package require logging
package require platinfo

set plat [plat::tag]
msg "initialized for $plat"