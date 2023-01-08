package provide tbs::signify 1.0
package require runprog

namespace eval ::tbs::signify {} {
    proc init {dir name} {
        variable key_dir $dir
        variable key_name $name
    }
    proc files {} {
        variable key_dir
        variable key_name
        return [subst {
            secret [file join $key_dir "$key_name.signify.sec"]
            public [file join $key_dir "$key_name.signify.pub"]
        }]
    }

    proc sigext {} {
        return "sig"
    }

    proc available {} {
        catch {
            exec which signify
        } out options
        if {[dict get options -code]} {
            return 0
        } else {
            msg -debug "signify: [string trim $out]"
            return 1
        }
    }

    proc gen_keys {pass} {
        variable key_name
        array set files [files]

        msg "signify: generating private key"
        run expect -f drive-signer.tcl $pass signify -G -c $key_name -s $files(secret) -p $files(public)
    }

    proc sign_file {pass file} {
        array set files [files]

        msg "signify: signing $file"
        run expect -f drive-signer.tcl $pass signify -S -s $files(secret) -m $file
    }

    proc verify_file {file} {
        array set files [files]

        msg "signify: verifying $file"
        run signify -V -p $files(public) -m $file
    }

    namespace export init files sigext available gen_keys sign_file verify_file
    namespace ensemble create -command ::tclbuild::signing::signify
}
