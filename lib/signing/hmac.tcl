package provide tbs::hmac 1.0
package require runprog

namespace eval ::tbs::hmac {} {
    proc init {dir name} {}

    proc files {} {
        return {}
    }

    proc sigext {} {
        return "mac"
    }

    proc available {} {
        catch {
            exec which openssl
        } out options
        if {[dict get options -code]} {
            return 0
        } else {
            msg -debug "openssl: [string trim $out]"
            return 1
        }
    }

    proc gen_keys {pass} {
        msg "hmac: does not use keys"
    }

    proc sign_file {pass file} {
        set pass [::tclbuild::signing::load_password $pass]

        msg "hmac: signing $file"
        run openssl dgst -hmac $pass -sha256 -hex -out "$file.mac" $file
    }

    proc verify_file {file} {
        msg "hmac: locating password"
        set pass [::tclbuild::signing::find_password]
        set pass [::tclbuild::signing::load_password $pass]

        msg "hmac: loading hash file"
        set fh [open "$file.mac" r]
        set saved_out [read $fh]
        set saved_out [string trim $saved_out]
        close $fh
        msg -debug $saved_out
        if {![regexp {HMAC-SHA2(?:-2)?56\(.+\)= ([0-9a-f]+)} $saved_out -> saved_hash]} {
            msg -err "cannot parse saved MAC"
            error "invalid saved MAC"
        }

        msg "hmac: hashing $file"
        set file_out [exec openssl dgst -hmac $pass -sha256 -hex $file 2>@stderr]
        set file_out [string trim $file_out]
        msg -debug $file_out
        if {![regexp {HMAC-SHA2(?:-2)?56\(.+\)= ([0-9a-f]+)} $file_out -> file_hash]} {
            msg -err "cannot parse MAC"
            error "invalid live MAC"
        }
        if {[string equal $saved_hash $file_hash]} {
            msg "hmac: OK"
        } else {
            msg -err "hmac: INVALID MAC"
            error "MAC verification failed"
        }
    }

    namespace export init files sigext available gen_keys sign_file verify_file
    namespace ensemble create -command ::tclbuild::signing::hmac
}
