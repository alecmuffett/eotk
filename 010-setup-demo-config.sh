#!/bin/sh
# eotk (c) 2017 Alec Muffett

cd `dirname $0`

for INPUT in demo.d/*.tconf ; do
    CONF=`basename $INPUT .tconf`.conf
    echo Configuring $INPUT as $CONF
    echo ""
    ./eotk configure $INPUT || exit 1
    echo ""
done

echo "------------------------------------------------------------------"
echo "------------------------------------------------------------------"
echo "------------------------------------------------------------------"

echo ""
echo Demo configuration is complete.
echo ""

echo The following per-project mappings are set up:
echo ""

echo "----"
./eotk maps -a
echo "----"
echo ""

echo The projects cited in $OUTPUT may now be started, e.g.:
echo ""
echo "  1)" eotk start -a
echo "  2)" eotk maps -a
echo "  3)" eotk status -a
echo ""

echo "Demo projects which are listed as 'softmap' (eg: 'wikipedia')"
echo "require the following additional steps AFTER being started:"
echo ""
echo "  4)" eotk ob-start wikipedia "#" wikipedia is a softmap project
echo "  5)" eotk ob-maps wikipedia "#" to see the onion mappings
echo "  6)" eotk ob-status "#" to see what onionbalance is doing
echo ""

echo Done.
exit 0
