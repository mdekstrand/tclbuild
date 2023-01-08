# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

package ifneeded tbs::hmac 1.0 [list source [file join $dir signing/hmac.tcl]]
package ifneeded tbs::minisign 1.0 [list source [file join $dir signing/minisign.tcl]]
package ifneeded tbs::openssl 1.0 [list source [file join $dir signing/openssl.tcl]]
package ifneeded tbs::signify 1.0 [list source [file join $dir signing/signify.tcl]]
package ifneeded tclbuild::build::jim 1.0 [list source [file join $dir build-jim.tcl]]
package ifneeded tclbuild::buildenv 1.0 [list source [file join $dir buildenv.tcl]]
package ifneeded tclbuild::config 1.0 [list source [file join $dir config.tcl]]
package ifneeded tclbuild::distrepo 1.0 [list source [file join $dir dist.tcl]]
package ifneeded tclbuild::os::darwin 1.0 [list source [file join $dir os/darwin.tcl]]
package ifneeded tclbuild::os::linux 1.0 [list source [file join $dir os/linux.tcl]]
package ifneeded tclbuild::os::windows 1.0 [list source [file join $dir os/windows.tcl]]
package ifneeded tclbuild::profile::jim::custom 1.0 [list source [file join $dir profiles/jim-custom.tcl]]
package ifneeded tclbuild::profile::jim::default 1.0 [list source [file join $dir profiles/jim-default.tcl]]
package ifneeded tclbuild::profile::jim::full 1.0 [list source [file join $dir profiles/jim-full.tcl]]
package ifneeded tclbuild::signing 1.0 [list source [file join $dir signing/signing.tcl]]
