#!/usr/bin/env tclsh
# Build TCL executables.

set tbroot [file dirname [info script]]
set tbroot [file normalize $tbroot]
set auto_path [linsert $auto_path 0 [file join $tbroot lib]]
set auto_path [linsert $auto_path 0 [file join $tbroot common lib]]

package require logging
package require platinfo
package require missing
package require getopt
package require tagline
package require tclbuild::config
package require tclbuild::profiledb

set options {
    if-missing 0
    fresh-build 1
}

if {![string equal [file normalize .] $tbroot]} {
    msg -err "must be run from tclbuild root directory"
    exit 1
}

getopt arg $argv {
    -v - --verbose {
        # increase logging verbosity
        logging::configure -verbose
    }
    -q - --quiet {
        # only log warnings and errors
        logging::configure -quiet
    }

    --no-clean {
        # don't clean brefore building
        dict set options fresh-build 0
    }

    -a: - --arch:ARCH {
        # build for architecture ARCH
        set config::arch $arg
        msg -debug "cli: architecture $config::arch"
    }
    --os:OS {
        # override autodetected os to OS
        set config::os $arg
        msg -debug "cli: OS $config::os"
    }

    -S: - --system:NAME {
        # build system NAME (default jim)
        set config::stack $arg
    }

    -p: - --profile:NAME {
        # use build profile NAME
        set config::profile $arg
        msg -debug "cli: profile $arg"
    }

    --if-missing {
        # only build if the distribution is missing
        dict set options if-missing 1
    }

    -h - --help {
        # print this help and exit
        help
    }

    arglist {
        if {![lempty $arg]} {
            msg -err "unrecognized arguments: $arg"
            exit 2
        }
    }
}

config::finalize

try_require "tclbuild::build::$config::stack" {
    msg -err "unknown stack $config::stack"
    exit 3
}
msg "setting up to build $config::stack"

try_require "tclbuild::os::$config::os" {
    msg -err "unsupported operating system $config::os"
    exit 3
}

profiledb::load "profiles.tcl"
msg "$config::stack: building with profile $config::profile"
build::use_profile $config::profile
set product [config::product]
set distdir [config::path distdir $product]

# find out the output directory
set result [build::executable -path]
msg "built $result"

set exename [file tail $result]
if {![plat::is windows]} {
    if {![string equal $buildenv::exesuffix ""]} {
        msg -err "non-windows platform has exe suffix $buildenv::exesuffix, que pasa?"
        error "unexpected platform configuration"
    }

    set exename "$exename-[config::tag]"
}

set distfile [file join $distdir $exename]

if {[dict get $options if-missing] && [file exists $distfile]} {
    msg "$distfile already exists, skipping build"
    exit 0
}

# now we are ready to go
buildenv::configure
build::init $options
msg "$product: version [build::full_version]"

if {[dict get $options fresh-build]} {
    build::clean
}
build::configure
build::make
build::postprocess
build::finish

msg "preparing distribution $distfile"
file mkdir $distdir
file copy -force $result $distfile

msg "saving build info"
set mfh [open "$distfile.descr" w]
dict for {key val} [::build::buildinfo] {
    set line [tagline unparse $exename $key $val]
    msg -debug $line
    puts $mfh $line
}
set hash [tagline parse [exec openssl dgst -sha256 $distfile]]
lset hash 0 $exename
# make it consistent
set line [tagline unparse $hash]
msg -debug $line
puts $mfh $line
close $mfh

msg -success "built $distfile"

if {[info exists env(GITHUB_OUTPUT)]} {
    msg "writing build information to GitHub Actions"
    set gho [open $env(GITHUB_OUTPUT) w]
    puts $gho "build-tag=[config::tag]"
    puts $gho "build-product=$product"
    puts $gho "distdir=$distdir"
    puts $gho "distfile=$distfile"
    close $gho
}
