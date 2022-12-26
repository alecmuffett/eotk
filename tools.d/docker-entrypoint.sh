#!/bin/sh
set -x

eotk=$EOTK_HOME/eotk
secrets_mnt="/var/local/secrets"

wait_for_secrets() {
    while true; do 
        for f in "$secrets_mnt"/*.key; do
            test -f $f && break 2
        done
        echo "Waiting for keys to populate..."
        sleep 1
    done 
}

convert_secrets() {
    onion_keys_secrets_out="$EOTK_HOME/secrets.d"
    onion_filetype="key"
    ssl_certs_secrets_out="$EOTK_HOME/projects.d/$project.d/ssl.d"

    mkdir -p $onion_keys_secrets_out
    mkdir -p $ssl_certs_secrets_out

    for file in $secrets_mnt/*; do
        if [ ${file##*.} = $onion_filetype ]; then
            base64 -d "$file" > $onion_keys_secrets_out/"$(basename "$file")"
        else
            cp $file $ssl_certs_secrets_out/"$(basename $file)"
        fi
    done
}

project="$PROJECT-$ENVIRONMENT"

# Non-development environments assume secrets are loaded via external mechanism via some file mount
if [ "$ENVIRONMENT" != "dev" ]; then
    wait_for_secrets
    convert_secrets
fi

template="$project".tconf
actualised="$project".conf
test -f $actualised && exit 1

$eotk configure $template && \
    $eotk start $project && \
    $eotk status $project && \
    # TODO: this is super hacky, should figure out process forking
    sleep infinity
