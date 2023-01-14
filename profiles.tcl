# Specification of build profiles

profile -n 5 -stack jim custom {
    -config-arg --disable-lineedit
    -config-arg --without-ext=default
    -config-arg --with-ext=aio,array,exec,file,glob,interp,namespace,oo,package,readdir,regexp,tclcompat
    -post strip
}

profile -n 2 -stack jim default {}

profile -n 2 -stack jim full {
    -config-arg --full
}

profile -n 2 -stack tclkit client {
    -pkg tclcurl
    -pkg tcllib
}
