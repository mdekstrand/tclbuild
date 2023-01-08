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
    proc built_outputs {{product -all}} {
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
            set ext [file extension $f]
            switch -- $ext {
                .exe - "" {
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
        file remove $shafile
    }
    set files [glob -directory $dist -tails *]
    msg -info "checksumming [llength $files] files for $product"
    run -cwd $dist -outfile shasums sha256sum --binary {*}$files
}
