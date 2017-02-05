#!/bin/sh
# eotk (c) 2017 Alec Muffett

cd `dirname $0`

INPUT=templates.d/demo.txt
OUTPUT=demo.conf

echo "Generating: $OUTPUT"
echo "Patience, please - this may take a minute or so..."

while read line ; do
    case "$line" in
        *%NEW_ONION%*)
            onion=`./eotk genkey`
            onion=`basename $onion .key`
            echo "$line" | sed -e "s/%NEW_ONION%/$onion/"
            ;;
        *)
            echo "$line"
            ;;
    esac
    echo ".\c" 1>&2
done < $INPUT > $OUTPUT

echo ""
echo "done"

echo "The demo configuration file is $OUTPUT"
echo "Take a look, and then run: eotk config $OUTPUT"
exit 0
