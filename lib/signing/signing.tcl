package provide tclbuild::signing 1.0

array set KR_DEFAULTS {
    key_dir keys
    pass_ev SIGNING_KEY_PASSWORD
    pass_file keys/keyprotect.pass
    pass_len 32
}
set DEFAULT_SYSTEMS {
    openssl
    minisign
    signify
}

namespace eval ::tbs {}
namespace eval ::tclbuild::signing {
    namespace export load_password find_password
}

proc ::tclbuild::signing::load_systems {options} {
    global KR_DEFAULTS
    set systems [wanted_systems $options]
    foreach sys $systems {
        package require tbs::$sys
        $sys init $KR_DEFAULTS(key_dir) tclbuild
    }
    return $systems
}

proc ::tclbuild::signing::find_password {} {
    global KR_DEFAULTS

    msg -debug "checking for password file"
    if {[file exists $KR_DEFAULTS(pass_file)]} {
        return "file:$KR_DEFAULTS(pass_file)"
    }

    msg -debug "checking for environment variable $KR_DEFAULTS(pass_ev)"
    if {[info exists ::env($KR_DEFAULTS(pass_ev))]} {
        return "env:$KR_DEFAULTS(pass_ev)"
    }

    error "could not find password source"
}

proc ::tclbuild::signing::load_password {pass} {
    # load a password from an OpenSSL-compatible spec
    if {[regexp {^([a-z]+):(.*)} $pass -> src spec]} {
        switch -- $src {
            file {
                msg -debug "reading password file $spec"
                set fp [open $spec r]
                set val [read $fp]
                close $fp
                return $val
            }
            env {
                msg -debug "reading password env $spec"
                return $::env($spec)
            }
            default {
                error "unsupported password source $src"
            }
        }
    } else {
        error "unexpected password format $pass"
    }
}

# fetch the list of wanted systems
proc ::tclbuild::signing::wanted_systems {options} {
    set wanted [dict get $options signers]
    if {[lempty $wanted] || [string equal $wanted all]} {
        msg -debug "want all signers"
        return $::DEFAULT_SYSTEMS
    } elseif {[string equal $wanted available]} {
        set systems {}
        foreach sys $::DEFAULT_SYSTEMS {
            if {[$sys available]} {
                msg -debug "$sys is available"
                lappend systems $sys
            } else {
                msg -debug "$sys is not available"
            }
        }
    } else {
        return $wanted
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
    set signers [load_systems $options]

    foreach sys $signers {
        array set files [$sys files]
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
    foreach sys $signers {
        $sys gen_keys $pass
    }
}

proc ::tclbuild::signing::act_sign_files {options args} {
    global KR_DEFAULTS
    load_systems $options

    set pass [find_password]
    foreach file $args {
        foreach sys [wanted_systems $options] {
            $sys sign_file $pass $file
        }
    }
}

proc ::tclbuild::signing::act_verify_files {options args} {
    global KR_DEFAULTS
    load_systems $options

    array set bad {}
    foreach file $args {
        foreach sys [wanted_systems $options] {
            set sigfile "$file.[$sys sigext]"
            if {[file exists $sigfile]} {
                if {![$sys verify_file $file]} {
                    set bad($file) bad-sig
                }
            } elseif {[dict get $options require]} {
                msg -err "$sys: signature $sigfile not found"
                set bad($file) no-sig
            } else {
                msg -warn "$sys: signature $sigfile not found"
            }
        }
    }

    set nbad [llength [array names bad]]
    if {$nbad > 0} {
        error "$nbad files failed"
    } else {
        msg -success "all files OK"
    }
}
