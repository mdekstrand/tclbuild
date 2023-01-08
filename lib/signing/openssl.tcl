package provide tbs::openssl 1.0
package require runprog

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

    proc gen_keys {pass} {
        array set files [files]

        msg "openssl: generating private key"
        run openssl req -newkey rsa -subj /CN=tclbuild.ekstrandom.net \
            -passout $pass -keyout $files(secret) \
            -x509 -out $files(public)
    }

    proc sign_file {pass file} {
        array set files [files]

        msg "openssl: signing $file"
        run openssl dgst -sign $files(secret) -passin $pass -sha256 -out "$file.rsasig" $file
    }

    namespace export init files gen_keys sign_file
    namespace ensemble create -command ::tclbuild::signing::openssl
}
