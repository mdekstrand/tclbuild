# Specification of build profiles

profile -n 1 -stack jim custom {
    -config-arg --without-ext=default
    -config-arg --with-ext=aio,array,exec,file,glob,namespace,package,readdir,regexp,tclcompat
}

profile -n 1 -stack jim default {}
