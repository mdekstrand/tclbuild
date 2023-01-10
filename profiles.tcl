# Specification of build profiles

profile -n 2 -stack jim custom {
    -config-arg --without-ext=default
    -config-arg --with-ext=aio,array,exec,file,glob,namespace,package,readdir,regexp,tclcompat
}

profile -n 2 -stack jim default {}
