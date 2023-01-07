package provide tclbuild::signing 1.0

array set KR_DEFAULTS {
    key_dir keys
    pass_ev SIGNING_KEY_PASSWORD
    pass_file keys/keyprotect.pass
    pass_len 32
}

namespace eval ::tclbuild::signing {}
namespace eval ::tclbuild::signing::actions {}

proc ::tclbuild::signing::actions::generate_password {options} {
    global KR_DEFAULTS
    set pass_file $KR_DEFAULTS(pass_file)
    set pass_len $KR_DEFAULTS(pass_len)

    if {[file exists $pass_file]} {
        if {[dict get $options force]} {
            msg -warn "file $pass_file already exists, overwriting"
        } else {
            msg -err "file $pass_file already exists"
            error "file exists"
        }
    }


    msg "generating new password of lenth $pass_len"
    msg -debug "loading key material"
    set urh [open /dev/urandom rb]
    set bytes [read $urh $pass_len]
    close $urh

    msg -debug "encoding key"
    set pass [binary encode base64 $bytes]

    msg "saving password to $pass_file"
    set fp [open $pass_file w]
    puts $fp $pass
    close $fp
}
