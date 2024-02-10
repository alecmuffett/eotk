#!/bin/sh -x

MAKE=make
keyserver="keyserver.ubuntu.com" # standard

CustomiseVars() {
    install_dir=$opt_dir/$tool.d
    tool_tarball=`basename "$tool_url"`
    tool_checksum=`basename "$tool_checksum_url"`
    tool_sig=`basename "$tool_sig_url"`
    tool_dir=`basename "$tool_tarball" .tar.gz`
}

SetupForBuild() {
    test -f "$tool_tarball" || curl -o "$tool_tarball" "$tool_url" || exit 1
    test -f "$tool_sig" || curl -o "$tool_sig" "$tool_sig_url" || exit 1
    test -z "$tool_checksum" || test -f "$tool_checksum" || curl -o "$tool_checksum" "$tool_checksum_url" || exit 1
    test -z "$tool_checksum" || $tool_checksum_command "$tool_checksum" || exit 1
    gpg --keyserver "hkp://$keyserver:80" --recv-keys $tool_signing_keys || exit 1
    gpg --verify "$tool_sig" || exit 1
    test -d "$tool_dir" || tar zxf "$tool_tarball" || exit 1
    cd $tool_dir || exit 1
}

BuildAndCleanup() {
    $MAKE || exit 1
    $MAKE install || exit 1
    cd $opt_dir || exit 1
    for x in $tool_link_paths ; do ln -sf "$install_dir/$x" || exit 1 ; done
    rm -rf "$tool_tarball" "$tool_sig" "$tool_dir" "$tool_checksum" || exit 1
}

# ------------------------------------------------------------------

SetupOpenRestyVars() {
    tool="openresty"
    tool_version="1.15.8.3"
    tool_signing_keys="25451EB088460026195BD62CB550E09EA0E98066" # this is the full A0E98066 signature
    tool_url="https://openresty.org/download/$tool-$tool_version.tar.gz"
    tool_sig_url="https://openresty.org/download/$tool-$tool_version.tar.gz.asc"
    tool_link_paths="nginx/sbin/nginx"
}

ConfigureOpenResty() { # this accepts arguments
    or_mods="https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git"
    or_opts="--with-http_sub_module" # someday, redo this in lua
    or_mod_list=""

    for mod_url in $or_mods ; do
        mod_dir=`basename $mod_url .git`
        if [ -d "$mod_dir" ] ; then
            ( cd "$mod_dir" ; exec git pull ) || exit 1
        else
            git clone "$mod_url" || exit 1
        fi
        or_mod_list="$or_mod_list --add-module=$mod_dir"
    done

    ./configure --prefix="$install_dir" $or_opts $or_mod_list "$@" || exit 1
}

# ------------------------------------------------------------------

SetupTorVars() {
    tool="tor"
    tool_version="0.4.7.13"
    tool_signing_keys="514102454D0A87DB0767A1EBBE6A0531C18A9179 B74417EDDF22AC9F9E90F49142E86A2A11F48D36 2133BC600AB133E1D826D173FE43009C4607B1FB"
    tool_url="https://dist.torproject.org/$tool-$tool_version.tar.gz"
    tool_checksum_url="https://dist.torproject.org/$tool-$tool_version.tar.gz.sha256sum"
    tool_checksum_command="sha256sum -c"
    tool_sig_url="https://dist.torproject.org/$tool-$tool_version.tar.gz.sha256sum.asc"
    tool_link_paths="bin/$tool"
}

ConfigureTor() { # this accepts arguments
    ./configure --prefix="$install_dir" "$@" || exit 1
}

# ------------------------------------------------------------------
