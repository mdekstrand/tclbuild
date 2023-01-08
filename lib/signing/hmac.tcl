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

    namespace export init files sigext available gen_keys sign_file
    namespace ensemble create -command ::tclbuild::signing::hmac
}
