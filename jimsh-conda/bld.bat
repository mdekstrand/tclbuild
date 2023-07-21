set PKG_CONFIG=x86_64-pc-msys-pkg-config
set MAKE=mingw32-make
set INSTALL_WANTED=jimsh
set PREFIX=%PREFIX%\Library\mingw-w64\
bash build.sh --disable-ssl
if errorlevel 1 exit 1
