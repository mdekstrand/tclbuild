package provide tclbuild::signing 1.0

array set KR_DEFAULTS {
    key_dir keys
    pass_ev SIGNING_KEY_PASSWORD
    pass_file keys/keyprotect.pass
    pass_len 32
}
set SIGN_SYSTEMS {
    openssl
    minisign
}

namespace eval ::tbs {}
namespace eval ::tclbuild::signing {
    namespace export load_password find_password
}

proc ::tclbuild::signing::load_systems {} {
    foreach sys $::SIGN_SYSTEMS {
        package require tbs::$sys
    }
}

proc ::tclbuild::signing::find_password {} {
    global KR_DEFAULTS

    msg -debug "checking for password file"
    if {[file exists $KR_DEFAULTS(pass_file)]} {
        return "file:$KR_DEFAULTS(pass_file)"
    }

    msg -debug "checking for environment variable $KR_DEFAULTS(pass_ev)"
    if {[info exists $::env($KR_DEFAULTS(pass_ev))]} {
        return "env:$KR_DEFAULTS(pass_ev)"
    }

    error -code {TCLBUILD SIGN NOPASSWORD} "could not find password source"
}

proc ::tclbuild::signing::load_password {pass} {
    # load a password from an OpenSSL-compatible spec
    if {[regexp {^([a-z]+):(.*)} $pass -> src spec]} {
        switch -- $src {
            file {
                set fp [open $spec r]
                set val [read $fp]
                close $fp
            }
            env {
                set val $::env($spec)
            }
            default {
                error "unsupported password source $src"
            }
        }
    } else {
        error "unexpected password format $pass"
    }
}

proc ::tclbuild::signing::act_generate_password {options} {
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

proc ::tclbuild::signing::act_generate_keys {options} {
    global KR_DEFAULTS
    set abort 0
    load_systems

    foreach sys $::SIGN_SYSTEMS {
        array set files [$sys files $KR_DEFAULTS(key_dir) tclbuild]
        foreach {type file} [array get files] {
            msg -debug "checking $type file $file"
            if {[file exists $file]} {
                if {[dict get $options force]} {
                    msg -warn "removing $type file $file"
                    file delete $file
                } else {
                    msg -error "$type file $file exists, aborting"
                    error "won't replace key files without --force"
                }
            }
        }
    }

    set pass [find_password]
    foreach sys $::SIGN_SYSTEMS {
        $sys gen_keys $KR_DEFAULTS(key_dir) tclbuild $pass
    }
}
