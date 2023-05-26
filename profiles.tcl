# Specification of build profiles

profile -n 1 -stack jim custom {
    -config-arg --disable-lineedit
    -config-arg --disable-ssl
    -config-arg --without-ext=default
    -config-arg --with-ext=aio,array,ensemble,exec,file,glob,interp,json,namespace,oo,package,readdir,regexp,tclcompat
    -post strip
}

profile -n 2 -stack jim default {
    -config-arg --disable-ssl
    -config-arg --without-ext=zlib
}

profile -n 1 -stack jim full {
    -config-arg --disable-ssl
    -config-arg --full
}

profile -n 2 -stack tclkit client {
    -pkg tclcurl
    -pkg tcllib
}
