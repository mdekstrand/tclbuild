# procedures for working with the distribution area
package provide tclbuild::distrepo 1.0
package require tclbuild::config
package require runprog

namespace eval ::tclbuild::dist {
    # list products that have been built.
    # it assumes each directory is a product, but doesn't actually check for artifacts.
    proc products {} {
        set dist [config::path distroot]
        msg -debug "scanning for products in $dist"
        set subdirs [glob -directory $dist -type d *]
        set results [list]
        foreach dir $subdirs {
            lappend results [file tail $dir]
        }
        return $results
    }

    # list results that have been built.
    proc build_outputs {{product -all}} {
        set dist [config::path distroot]
        msg -debug "scanning for products in $dist"
        if {[string equal $product -all]} {
            msg -debug "scanning for all produced files"
            set files [glob -directory $dist -type f */*]
        } else {
            msg -debug "scanning for all files in product $product"
            set files [glob -directory [file join $dist $product] -type f *]
        }
        set products [list]
        foreach f $files {
            set name [file tail $f]
            switch -glob -- $name {
                shasums -
                *.txt -
                *.md -
                *.mac -
                *.*sig {
                    msg -debug "skipping $name"
                }
                default {
                    # assume everything else is a build output
                    msg -debug "found output $f"
                    lappend products $f
                }
            }
        }
        return $products
    }
}

proc ::tclbuild::dist::act_checksum {product} {
    set dist [config::path distdir $product]
    set shafile [file join $dist shasums]
    if {[file exists $shafile]} {
        msg -info "removing existing $shafile"
        file delete $shafile
    }
    set files [glob -directory $dist -tails *]
    msg -info "checksumming [llength $files] files for $product"
    run -cwd $dist -outfile shasums sha256sum --binary {*}$files
}

proc ::tclbuild::dist::build_groups {product} {
    set files [build_outputs $product]

    set groups [dict create]

    foreach file [lsort $files] {
        msg -debug "grouping file $file"
        set file [file tail $file]
        switch -regexp -matchvar match -- $file {
            ^.*\\.exe$ {
                dict lappend groups windows x86 $file
            }
            ^\\w+-(\\w+)-(.*) {
                set os [lindex $match 1]
                set arch [lindex $match 2]
                dict lappend groups $os $arch $file
            }
            default {
                msg -warn "unmatched prodcut $file"
            }
        }
    }

    return $groups
}

proc ::tclbuild::dist::act_manifest {product} {
    set dist [config::path distdir $product]
    set shafile [file join $dist shasums]
    set md_file [file join docs $dist manifest.md]
    set txt_file [file join $dist manifest.txt]

    set platforms [build_groups $product]
    set plat_labels {
        windows Windows
        darwin macOS
        linux Linux
    }

    set mdh [open $md_file w]
    dict for {os builds} $platforms {
        msg "building manifest for $os"
        if {[dict exists $plat_labels $os]} {
            set os [dict get $plat_labels $os]
        }

        puts $mdh "## $os\n"
        dict for {arch file} $builds {
            set sigs {}
            lappend sigs [subst -nocommands {[[minisign]($file.minisig)]}]
            lappend sigs [subst -nocommands {[[signify]($file.sig)]}]
            lappend sigs [subst -nocommands {[[RSA (openssl)]($file.rsasig)]}]

            puts $mdh "- \[`$file`\]($file) [join $sigs { }]"
        }
        puts $mdh ""
    }

    close $mdh
}
