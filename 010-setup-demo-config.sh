#!/bin/sh
# eotk (c) 2017 Alec Muffett

cd `dirname $0`

INPUT=templates.d/demo.conf.txt
TEMPLATE=demo.tconf
OUTPUT=demo.conf

cp $INPUT $TEMPLATE

./eotk configure $TEMPLATE || exit 1

echo "----"
echo ""

echo Demo setup is complete.
echo The template was $TEMPLATE
echo The resulting configuration file is $OUTPUT
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

echo Those projects which are listed as "'softmap'" will require
echo the following additional steps AFTER being started:
echo ""
echo "  4)" eotk ob-start wiki "#" wiki is a softmap project
echo "  5)" eotk ob-maps wiki "#" to see what soft onions point where
echo "  6)" eotk ob-status "#" to see what onionbalance is doing
echo ""

echo Done.
exit 0
