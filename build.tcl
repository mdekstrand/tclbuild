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
package require tclbuild::config

set fresh_build 1

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
        set fresh_build 0
    }

    -a: - --arch:ARCH {
        # build for architecture ARCH
        set config::arch $arg
        msg -debug "cli: architecture $config::arch"
    }
    -s: - --os:OS {
        # override autodetected os to OS
        set config::os $arg
        msg -debug "cli: OS $config::os"
    }

    -p: - --profile:NAME {
        # use build profile NAME
        set config::profile $arg
        msg -debug "cli: profile $arg"
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

try_require "tclbuild::profile::${config::stack}::${config::profile}" {
    msg -err "$config::stack: unknown profile $config::profile"
    exit 3
}
msg "$config::stack: building with profile $config::profile"
set product "$config::stack-$config::profile"

if {![info exists distdir]} {
    set distdir "dist/$product"
}

# now we are ready to go
buildenv::configure
build::init
if {$fresh_build} {
    build::clean
}
build::configure
build::make
build::finish

set result [build::executable -path]
msg -success "built $result"

set exename [file tail $result]
if {![plat::is windows]} {
    if {![string equal $buildenv::exesuffix ""]} {
        msg -err "non-windows platform has exe suffix $buildenv::exesuffix, que pasa?"
        error "unexpected platform configuration"
    }

    set exename "$exename-[config::tag]"
}


set distfile [file join $distdir $exename]
msg "preparing distribution $distfile"
file mkdir $distdir
file copy -force $result $distfile

if {[info exists env(TCLBUILD_SIGN_KEY)]} {
    msg -debug "getting signing key from TCLBUILD_SIGN_KEY"
    set sign_key $env(TCLBUILD_SIGN_KEY)
} else {
    msg -warn "no sign key provided, using default key 'UNSAFE'"
    set sign_key UNSAFE
}

# msg "signing result file"
# set sigout [exec openssl dgst -hmac $sign_key -sha256 $distfile 2>@stderr]
# msg -debug $sigout
# if {[regexp {^HMAC-[A-Z0-9-]+\(([a-zA-Z0-9/_.-]+)\)=\s+([0-9a-f]+)} $sigout -> path digest]} {
#     set hfp [open "$distfile.mac" w]
#     puts $hfp $digest
#     close $hfp
# } else {
#     msg -err "cannot parse hash: $sigout"
#     exit 5
# }

msg -success "$distfile: $digest"

if {[info exists env(GITHUB_OUTPUT)]} {
    msg "writing build information to GitHub Actions"
    set gho [open $env(GITHUB_OUTPUT) w]
    puts $gho "build-tag=[config::tag]"
    puts $gho "build-product=$product"
    puts $gho "distdir=$distdir"
    puts $gho "distfile=$distfile"
    close $gho
}
