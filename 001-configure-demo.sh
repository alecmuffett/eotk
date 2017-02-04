#!/bin/sh
# eotk (c) 2017 Alec Muffett

cd `dirname $0`

INPUT=templates.d/onions.txt
OUTPUT=onions.conf

echo "patience, please - this may take a minute or so..."

while read line ; do
    case "$line" in
        *%NEW_ONION%*)
            onion=`./secrets.d/generate-onion-key.sh`
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
echo "done."

echo "the demo configuration is in $OUTPUT, go take a look :-)"
exit 0
