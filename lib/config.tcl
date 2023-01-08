package provide tclbuild::config 1.0
package require platinfo

namespace eval config {
    variable arch
    variable os
    variable stack jim
    variable profile custom
    variable layout {
        root {}
        dist {[repopath dist]}
    }

    namespace export tag finalize

    proc tag {} {
        variable arch
        variable os

        return "$os-$arch"
    }

    proc product {} {
        variable stack
        variable profile
        return "$stack-$profile"
    }

    proc finalize {} {
        variable arch
        variable os

        if {![info exists arch]} {
            set arch [plat::arch]
        }
        if {![info exists os]} {
            set os [plat::os]
        }

        msg "configured to build for [tag]"
    }

    # Resolve a path relative to the root directory.
    proc repopath {path} {
        variable layout
        return [file join [dict get $layout root] $path]
    }

    proc set_path {name path} {
        variable layout
        dict set layout $name $path
    }

    proc path {req {arg {}}} {
        variable layout
        switch -- $req {
            root {
                return [dict get $layout root]
            }
            distroot {
                return [dict with layout {subst [dict get $layout dist]}]
            }
            distdir {
                set path [path distroot]
                if {[string equal arg {}]} {
                    set product [product]
                } else {
                    set product $arg
                }
                return [file join $path $product]
            }
            default {
                error "unknown path name $req"
            }
        }
    }
}

proc try_require {pkg onfail} {
    set failed [catch [subst {
        uplevel 1 package require $pkg
    }] res opts]
    if {$failed} {
        set code [dict get $opts -errorcode]
        if {[string equal $code "TCL PACKAGE UNFOUND"]} {
            uplevel 1 $onfail
        } else {
            msg -err "unexpected package import error: $msg"
            error "import failure"
        }
    }
}
