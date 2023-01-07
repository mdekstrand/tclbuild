puts "TCL version $tcl_version"
puts "Platform info: [array get tcl_platform]"
puts "PATH=$env(PATH)"
puts [exec which make]
