package provide tbs::minisign 1.0
package require runprog

namespace eval ::tbs::minisign {} {
    proc files {dir name} {
        return [subst {
            secret [file join $dir "$name.minisign.sec"]
            public [file join $dir "$name.minisign.pub"]
        }]
    }

    proc gen_keys {dir name pass} {
        array set files [files $dir $name]

        msg "minisign: generating private key"
        run expect -f drive-signer.tcl $pass minisign -G -s $files(secret) -p $files(public)
    }

    namespace export files gen_keys
    namespace ensemble create -command ::tclbuild::signing::minisign
}
