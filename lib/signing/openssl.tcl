package provide tbs::openssl 1.0
package require runprog

namespace eval ::tbs::openssl {} {
    proc files {dir name} {
        return [subst {
            secret [file join $dir "$name.openssl.sec"]
            public [file join $dir "$name.openssl.pub"]
        }]
    }

    proc gen_keys {dir name pass} {
        array set files [files $dir $name]

        msg "openssl: generating private key"
        run openssl req -newkey rsa -subj /CN=tclbuild.ekstrandom.net \
            -passout $pass -keyout $files(secret) \
            -x509 -out $files(public)
    }

    namespace export files gen_keys
    namespace ensemble create -command ::tclbuild::signing::openssl
}
