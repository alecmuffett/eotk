#!/bin/sh
# Enterprise Onion Toolkit

cd `dirname $0` || exit 1

export EOTK_HOME=`pwd` # expected by tools

cmd=`basename $0`
version=1.0

case "$1" in
    version)
        echo $cmd $version $EOTK_HOME
        if [ -f .gitignore ] ; then
            git show -s --oneline
        fi
        ;;

    conf|config|configure)
        log=configure$$.log
        if ! $EOTK_HOME/tools/do-configure.pl 2>$log ; then
            echo $cmd: failure: see $log
            exit 1
        else
            echo $cmd: success
        fi
        ;;

    start) # project
        echo tbd
        ;;

    stop) # project
        echo tbd
        ;;

    restart|reload|bounce) # project
        echo tbd
        ;;

    debugon) # project
        echo tbd
        ;;

    debugoff) # project
        echo tbd
        ;;

    harvest) # project
        echo tbd
        ;;

    delete) # project
        echo tbd
        ;;

    *)
        echo "usage: $cmd args ... # see README.md for docs" 1>&2
        exit 1
        ;;
esac

exit 0
