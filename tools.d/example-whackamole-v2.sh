#!/bin/sh
DELAY=1
CLEARWEB=/tmp/clearweb.$$
CONVERT=/tmp/onionsed.$$

# these are hostnames for which we must visit onion, accept certificates
cat > $CLEARWEB <<EOF
www.wikipedia.org
en.wikipedia.org
en.m.wikipedia.org

commons.wikimedia.org
login.wikimedia.org
meta.wikimedia.org
upload.wikimedia.org
EOF

# ceb.wikipedia.org
# sv.wikipedia.org
# de.wikipedia.org
# fr.wikipedia.org
# nl.wikipedia.org
# ru.wikipedia.org
# it.wikipedia.org
# es.wikipedia.org

# generate a sed script
./eotk ob-maps -a | awk '{print "s/" $2 "/" $1 "/g"}' >$CONVERT

# convert and print to stdout
sed -f $CONVERT <$CLEARWEB |
while read onion_url ; do
    test x$onion_url = x && continue
    url="https://$onion_url/hello-onion/"
    echo "open -a "TorBrowser" $url && sleep $DELAY"
done

# done
rm $CONVERT $CLEARWEB
echo done. please inspect output to check everything was onionified. 1>&2
exit 0
