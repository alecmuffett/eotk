#!/bin/sh
# eotk (c) 2017 Alec Muffett

# This script is written for OSX Sierra, and a local Tor daemon
# running attached to a TorBrowser instance; feel free to copy this
# script and hack it to meet your requirements, eg: by amending the
# Speak() function to be platform-independent, and amending the
# "Connectivity Check" to look for a local tor daemon.

export PATH=/sbin:/usr/sbin:/bin:/usr/bin

OUTFILE=/tmp/owo$$
ERRFILE=/tmp/owe$$
DATESTAMP=`date "+%Y%m%d%H%M%S"`

# alert sound for Failure()
# ALERT=/path/to/somefile.wav

TorCurl() {
    curl -x socks5h://127.0.0.1:9150/ --progress-bar --max-time 60 "$@"
}

Speak() {
    echo "$@" at $DATESTAMP
    say "$@" # REPEAT ARGUMENTS USING OSX SPEECH SYNTH
}

Failure() {
    # afplay $ALERT # PLAY AUDIO ALERT. AWOOOGA!
    Speak outage detected: "$@"
}

Save() {
    echo saving content as "$2" and "$4"
    mv "$1" "$2"
    mv "$3" "$4"
}

# Connectivity Check
# IMPORTANT: pattern must not match itself, that's why we have [Tt]

if ! ps auxww | egrep '\b([Tt]orBrowser)\b' ; then
    Failure Tor Browser is not running.
    exit 0
fi

# Speak checking onion status.

while read site method value url  ; do

    # skip blank lines

    test "x$site" = x && continue

    osave=/tmp/osave.$site.$DATESTAMP.out.txt
    esave=/tmp/osave.$site.$DATESTAMP.err.txt

    echo checking $site # slightly quieter

    # $uri will automatically swallow all extra fields in the heredoc,
    # so this is kinda redundant EXCEPT that using `column -t` looks bad

    curlargs=`echo $url | tr , ' '`

    if ! TorCurl $curlargs >$OUTFILE 2>$ERRFILE; then
        # try a second time, in case transient error
        if ! TorCurl $curlargs >$OUTFILE 2>$ERRFILE; then
            Failure communications problem when fetching $site.
            Save "$OUTFILE" "$osave" "$ERRFILE" "$esave"
            continue
        fi
    fi

    case $method in
        grep)
            if ! grep $value $OUTFILE >/dev/null ; then
                Failure content mismatch when fetching $site.
                Save "$OUTFILE" "$osave" "$ERRFILE" "$esave"
                continue
            fi
            ;;

        md5)
            sig=`md5 -r <$OUTFILE`
            if ! echo $value | grep $sig >/dev/null ; then
                Failure content mismatch when fetching $site.
                Save "$OUTFILE" "$osave" "$ERRFILE" "$esave"
                continue
            fi
            ;;

        *)
            Failure this cannot happen.
            exit 1
            ;;
    esac

done <<EOF
facebook      grep  ^1-AM-ALIVE  https://www.facebook.com/status.php
f-b-onion     grep  ^1-AM-ALIVE  https://www.facebookcorewwwi.onion/status.php
duck-duck-go  grep  DuckDuckGo   https://3g2upl4pq6kufc4m.onion/
EOF

# SYNTAX:
# <sitename> grep <content-regexp> http://site/file.ext
# <sitename> md5 <content-hash> http://site/file.ext
# <sitename> md5 <hash1>,<hash2>,<hash3> http://site/multioutput.ext
# <sitename> grep <regexp> --insecure,https://skip-ssl-checks-site/file.ext

# eg:
# facebook md5 6da9c97ee7e0495379babf0a9d2ab96e https://www.facebook.com/status.php

rm -f $OUTFILE $ERRFILE

# Speak onion checks completed.

exit 0
