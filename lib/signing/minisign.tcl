package provide tbs::minisign 1.0
package require runprog

namespace eval ::tbs::minisign {} {
    proc init {dir name} {
        variable key_dir $dir
        variable key_name $name
    }
    proc files {} {
        variable key_dir
        variable key_name
        return [subst {
            secret [file join $key_dir "$key_name.minisign.sec"]
            public [file join $key_dir "$key_name.minisign.pub"]
        }]
    }

    proc gen_keys {pass} {
        array set files [files]

        msg "minisign: generating private key"
        run expect -f drive-signer.tcl $pass minisign -G -s $files(secret) -p $files(public)
    }

    proc sign_file {pass file} {
        array set files [files]

        msg "minisign: signing $file"
        run expect -f drive-signer.tcl $pass minisign -S -s $files(secret) -m $file
    }

    namespace export init files gen_keys sign_file
    namespace ensemble create -command ::tclbuild::signing::minisign
}
