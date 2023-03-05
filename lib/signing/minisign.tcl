package provide tbs::minisign 1.0
package require oscmd

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

    proc sigext {} {
        return "minisig"
    }

    proc available {} {
        catch {
            exec which minisign
        } out options
        if {[dict get options -code]} {
            return 0
        } else {
            msg -debug "minisign: [string trim $out]"
            return 1
        }
    }

    proc gen_keys {pass} {
        variable key_name
        array set files [files]

        msg "minisign: generating private key"
        oscmd run expect -f drive-signer.tcl $pass minisign -G -c $key_name -s $files(secret) -p $files(public)
    }

    proc sign_file {pass file} {
        array set files [files]

        msg "minisign: signing $file"
        oscmd run expect -f drive-signer.tcl $pass minisign -S -s $files(secret) -m $file
    }

    proc verify_file {file} {
        array set files [files]

        msg -debug "minisign: verifying $file"
        set rc [oscmd run -noout -retfail minisign -V -p $files(public) -m $file]
        if {$rc} {
            msg -err "minisign: $file VERIFICATION FAILED"
            return 0
        } else {
            msg -success "minisign: $file OK"
            return 1
        }
    }

    namespace export init files sigext available gen_keys sign_file verify_file
    namespace ensemble create -command ::tclbuild::signing::minisign
}
