package provide tbs::openssl 1.0
package require oscmd

namespace eval ::tbs::openssl {} {
    proc init {dir name} {
        variable key_dir $dir
        variable key_name $name
    }

    proc files {} {
        variable key_dir
        variable key_name
        return [subst {
            secret [file join $key_dir "$key_name.openssl.sec"]
            public [file join $key_dir "$key_name.openssl.pub"]
        }]
    }

    proc sigext {} {
        return "rsasig"
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
        array set files [files]

        msg "openssl: generating private key"
        oscmd run openssl genrsa -passout $pass -out $files(secret)
        msg "openssl: extracting public key"
        oscmd run openssl pkey -in $files(secret) -passin $pass -pubout -out $files(public)
    }

    proc sign_file {pass file} {
        array set files [files]

        msg "openssl: signing $file"
        oscmd run openssl dgst -sign $files(secret) -passin $pass -sha256 -out "$file.rsasig" $file
    }

    proc verify_file {file} {
        array set files [files]

        msg -debug "openssl: verifying $file"
        set rc [oscmd run -noout -retfail openssl dgst -verify $files(public) -signature "$file.rsasig" $file]
        if {$rc} {
            msg -err "openssl: $file VERIFICATION FAILED"
            return 0
        } else {
            msg -success "openssl: $file OK"
            return 1
        }
    }

    namespace export init files sigext available gen_keys sign_file verify_file
    namespace ensemble create -command ::tclbuild::signing::openssl
}
