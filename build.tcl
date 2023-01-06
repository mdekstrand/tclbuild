#!/usr/bin/env tclsh
# build.tcl --
#
#   Entry point for Michael's TCL build tools.

set tbroot [file dirname [info script]]
set tbroot [file normalize $tbroot]
foreach dir {lib common} {
    set auto_path [linsert $auto_path 0 [file join $tbroot $dir]]
}
unset $dir

package require logging
package require platinfo

set plat [plat::tag]
msg "initialized for $plat"
