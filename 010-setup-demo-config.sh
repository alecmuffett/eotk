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
echo "  $" eotk start default
echo ""

echo Those projects which are listed as "'softmap'" will require
echo the following additional steps AFTER being started:
echo ""
echo "  1)" eotk ob-config
echo "  2)" eotk ob-start
echo "  3)" eotk maps -a "#" to see what is happening
echo ""

echo Done.
exit 0
