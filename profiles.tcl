# Specification of build profiles

profile -n 2 -stack jim custom {
    -config-arg --without-ext=default
    -config-arg --with-ext=aio,array,exec,file,glob,namespace,package,readdir,regexp,tclcompat
    -post strip
}

profile -n 2 -stack jim default {}

profile -n 2 -stack jim full {
    -config-arg --full
}
 profile -n 2 -stack tclkit default {}
