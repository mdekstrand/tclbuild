set tbroot [file dirname [info script]]
set tbroot [file normalize $tbroot]
set auto_path [linsert $auto_path 0 [file join $tbroot common lib]]
set auto_path [linsert $auto_path 0 [file join $tbroot lib]]

package require missing
package require logging
package require tclbuild::signing
namespace import ::tclbuild::signing::load_password

logging::configure -level $env(TCLBUILD_LOG_LEVEL)
set pass_src [lshift argv]
set password [load_password $pass_src]

spawn {*}$argv
expect {
    -re "(confirm\\s+)?passphrase:" {
        msg -debug "sending password"
        send "$password\r"
        exp_continue
    }
    -re "Password.*:" {
        msg -debug "sending password"
        send "$password\r"
        exp_continue
    }
}

set result [wait]
msg -debug "process [lindex $result 0] finished"
if {[lindex $result 2] < 0} {
    msg -err "could not execute subprocess"
    exit 5
} elseif {[set rc [lindex $result 3]]} {
    msg -err "[lindex $argv 0] exited with code $rc"
    exit 3
}
