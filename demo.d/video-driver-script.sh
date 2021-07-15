#!/bin/sh
Print() {
    echo ""
    echo :::::::: $@ ::::::::
}

project=tpo
template=demo.d/tpo.tconf
actualised=tpo.conf
test -f $actualised && exit 1

ls

Print CONFIGURATION FILE CONTENTS
egrep -v '^(#.*)?$' $template

Print COMMANDS TO RUN
tail -6 $0

Print PRESS RETURN TO CONTINUE
read return

set -x
date &&
    eotk config $template &&
    eotk start $project &&
    eotk status $project &&
    eotk scripts &&
    date
