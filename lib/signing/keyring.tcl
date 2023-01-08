package provide tclbuild::signing 1.0

array set KR_DEFAULTS {
    key_dir keys
    pass_ev SIGNING_KEY_PASSWORD
    pass_file keys/keyprotect.pass
    pass_len 32
}
set SIGN_SYSTEMS {
    openssl
}

namespace eval ::tbs {}
namespace eval ::tclbuild::signing {
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
        if {[::tbs::${sys}::keyfiles_exist $KR_DEFAULTS(key_dir) tclbuild]} {
            msg -warn "key files for $sys exist"
            set abort 1
        }
    }
    if {$abort && ![dict get $options force]} {
        error "key files already exist, not regenerating"
    }

    set pass [find_password]
    foreach sys $::SIGN_SYSTEMS {
        ::tbs::${sys}::gen_keys $KR_DEFAULTS(key_dir) tclbuild $pass
    }
}
