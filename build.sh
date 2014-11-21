#!/bin/sh

source ./dependencies/environment.sh

# Compile dependencies
if [ "${is_linux}" = "y" ] ; then
    source ./dependencies/build_unix_dependencies.sh
elif [ "${is_mac}" = "y" ] ; then
    source ./dependencies/build_unix_dependencies.sh
elif [ "${is_win}" = "y" ] ; then
    source ./dependencies/build_win_dependencies.sh
fi
