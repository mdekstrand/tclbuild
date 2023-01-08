# procedures for working with the distribution area
package provide tclbuild::distrepo 1.0
package require tclbuild::config

namespace eval ::tclbuild::dist {
    # list products that have been built.
    # it assumes each directory is a product, but doesn't actually check for artifacts.
    proc products {} {
        set dist [config::path distroot]
        msg -debug "scanning for products in $dist"
        set subdirs [glob -directory $dist -type d *]
        return [lmap dir $subdirs {
            file tail $dir
        }]
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
