# TCL Build Tools

This repository contains tools for building TCL binaries.  I don't really expect
this to be useful for anyone other than me, although it does provide a set of static
binaries for [Jim Tcl][jim].   The binaries themselves are distributed at
<https://tcl.ekstrandom.net>, and the scripts may be useful for others.

[jim]: https://jim.tcl.tk

Builds supported and planned:

- [x] Jim Tcl — default options
- [x] Jim Tcl — custom small profile
- [ ] Jim Tcl — full build
- [ ] TclKit

Supported platforms:

- [x] Windows (32-bit — for the purposes of this project, 64-bit doesn't seem useful)
- [x] macOS
  - [x] x86_64
  - [x] arm64
  - [ ] notarized executables
- [x] Linux (statically linked with musl)
  - [x] x86_64
  - [x] aarch64
  - [x] armv7
  - [x] armhf

It is relatively easy to add Linux builds for any architecture supported by
Alpine Linux.  I'm also interested in adding support for BSDs and other
platforms, but have not yet done so.
