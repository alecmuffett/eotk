#!/bin/sh -x

MAKE=make

CustomiseVars() {
    install_dir=$opt_dir/$tool.d
    tool_tarball=`basename "$tool_url"`
    tool_sig=`basename "$tool_sig_url"`
    tool_dir=`basename "$tool_tarball" .tar.gz`
    tool_checksum=`basename "$tool_checksum_url"`
}

SetupForBuild() {
    test -f "$tool_tarball" || curl -o "$tool_tarball" "$tool_url" || exit 1
    test -f "$tool_sig" || curl -o "$tool_sig" "$tool_sig_url" || exit 1
    if [ -n "$tool_checksum_url" ]; then
        test -f "$tool_checksum" || curl -o "$tool_checksum" "$tool_checksum_url" || exit 1
        gpg --verify "$tool_sig" "$tool_checksum" || exit 1
        sha256sum -c $tool_checksum || exit 1
    else
        gpg --verify "$tool_sig" || exit 1
    fi
    test -d "$tool_dir" || tar zxf "$tool_tarball" || exit 1
    cd $tool_dir || exit 1
}

BuildAndCleanup() {
    $MAKE || exit 1
    $MAKE install || exit 1
    cd $opt_dir || exit 1
    for x in $tool_link_paths ; do ln -sf "$install_dir/$x" || exit 1 ; done
    rm -rf "$tool_tarball" "$tool_sig" "$tool_dir" "$tool_checksum" "$tool_sig" || exit 1
}

# ------------------------------------------------------------------

SetupOpenSSLVars() {
    tool="openssl"
    tool_version="${OPENSSL_VERSION#OpenSSL_}"
    tool_version=$(printf '%s' "${tool_version}" | tr '_' '.')
    tool_url="https://www.openssl.org/source/$tool-$tool_version.tar.gz"
    tool_sig_url="https://www.openssl.org/source/$tool-$tool_version.tar.gz.asc"
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys DC7032662AF885E2F47F243F527466A21CA79E6D
}

SetupOpenRestyVars() {
    tool="openresty"
    tool_version="${OPENRESTY_VERSION#v}"
    tool_url="https://openresty.org/download/$tool-$tool_version.tar.gz"
    tool_sig_url="https://openresty.org/download/$tool-$tool_version.tar.gz.asc"
    tool_link_paths="nginx/sbin/nginx"
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 25451EB088460026195BD62CB550E09EA0E98066
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

ConfigureOpenRestyWithOpenSSL() { # this accepts arguments
    or_mods="https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git https://github.com/nginx-modules/ngx_http_json_log_module https://github.com/phuslu/nginx-ssl-fingerprint"
    or_opts="--with-http_sub_module --with-http_stub_status_module --with-http_v2_module " # someday, redo this in lua
    or_mod_list=""
    openssl_version="${OPENSSL_VERSION#OpenSSL_}"
    openssl_version=$(printf '%s' "${openssl_version}" | tr '_' '.')
    nginx_version=$(echo ${OPENRESTY_VERSION#v} | cut -d"." -f1-3)

    for mod_url in $or_mods ; do
        mod_dir=`basename $mod_url .git`
        if [ -d "$mod_dir" ] ; then
            ( cd "$mod_dir" ; exec git pull ; cd ..) || exit 1
        else
            git clone "$mod_url" || exit 1
        fi
        # Process special patches for JA3 fingerprinting
        if [ $mod_dir = "nginx-ssl-fingerprint" ] ; then
            cd "$mod_dir/patches" && git checkout $NGINX_SSL_FINGERPRINT_VERSION || exit 1
            (patch -p1 -t -d ../../../openssl-$openssl_version < openssl.1_1_1.patch; \
            patch -p1 -t -d ../../bundle/nginx-$nginx_version < nginx.patch ) || exit 1
            cd ../..
        fi
        or_mod_list="$or_mod_list --add-module=$mod_dir"
    done
    ./configure --prefix="$install_dir" --with-openssl=../openssl-$openssl_version $or_opts $or_mod_list "$@" || exit 1
}

# ------------------------------------------------------------------

SetupTorVars() {
    tool="tor"
    tool_version="tor-$TOR_VERSION"
    tool_url="https://dist.torproject.org/${tool_version}.tar.gz"
    tool_sig_url="https://dist.torproject.org/${tool_version}.tar.gz.sha256sum.asc"
    tool_checksum_url="https://dist.torproject.org/${tool_version}.tar.gz.sha256sum"
    tool_link_paths="bin/tor"
    gpg --keyserver hkps://keys.openpgp.org --recv-keys 514102454D0A87DB0767A1EBBE6A0531C18A9179
    gpg --keyserver hkps://keys.openpgp.org --recv-keys B74417EDDF22AC9F9E90F49142E86A2A11F48D36
    gpg --keyserver hkps://keys.openpgp.org --recv-keys 2133BC600AB133E1D826D173FE43009C4607B1FB
}

ConfigureTor() { # this accepts arguments
    ./configure --prefix="$install_dir" "$@" || exit 1
}

# ------------------------------------------------------------------
