#!/bin/bash

# The user can set the following variables before including this file:
#
# Windows:
#    Set what visual studio compiler you want to use
#    vs="2010"  - For "Visual Studio 10 2010"
#    vs="2012"  - For "Visual Studio 11 2012"
#    vs="2013"  - For "Visual Studio 12 2013"
#
# 
# You can add the option `debug` if you want to have the `is_debug` set to y.
#

# Make sure the user passes the correct architecture.
if [ "${1}" = "" ] ; then
    echo ""
    echo "Usage: ${0} [32,64] [debug] [makefile,xcode,vs2010,vs2012,vs2013,vs2015]"
    echo ""
    echo "Example: compile 32bit version: ${0} 32 "
    echo "Example: compile 64bit version: ${0} 64 debug"
    echo "Example: compile 64bit version for VS 2015: ${0} 64 debug vs2015"
    echo ""
    exit
fi

# Detect if we're running on windows, mac, linux.
is_mac=n
is_linux=n
is_win=n
is_debug=n
is_64bit=""
is_32bit=""
in_arch=${1}
tri_arch=""
tri_compiler=""
tri_platform=""
tri_triplet=""
extra_cflags=""
extra_ldflags=""
cmake_osx_architectures=""
cmake_generator="" # is used with the win version
cmake_build_type="" # "Release" or "Debug", used for -DCMAKE_BUILD_TYPE 
cmake_build_config="" # "Release" or "Debug", used for `cmake --build . --config ${cmake_build_config}`
debug_flag="" # Set to _debug when building a debug version. You can add _debug to your debug build targets.
debugger="" # Set to the debugger, e.g. gdb or lldb
build_dir="" # Set to the build dir, e.g. build.release.xcode or build.debug.xcode, build.release.makefile, etc..
build_system="" # Set to makefile, xcode, vs2010, vs2012, vs2013, vs2015, used to create the build dir

for var in "$@" 
do
    if [ "${var}" = "debug" ] ; then
        is_debug=y
    elif [ "${var}" = "makefile" ] ; then
        cmake_generator="Unix Makefiles"
        build_system="makefile"
    elif [ "${var}" = "xcode" ] ; then
        cmake_generator="Xcode"
        build_system="xcode_project"
    elif [ "${var}" = "vs2010" ] ; then
        cmake_generator="Visual Studio 10 2010"
        build_system="vs2010_project"
        vs="${var#vs}"
    elif [ "${var}" = "vs2012" ] ; then
        cmake_generator="Visual Studio 11 2012"
        build_system="vs2012_project"
        vs="${var#vs}"
    elif [ "${var}" = "vs2013" ] ; then
        cmake_generator="Visual Studio 12 2014"
        build_system="vs2013_project"
        vs="${var#vs}"
    elif [ "${var}" = "vs2015" ] ; then
        cmake_generator="Visual Studio 14 2015"
        build_system="vs2015_project"
        vs="${var#vs}"
    elif [ "${var}" = "vs2017" ] ; then
        cmake_generator="Visual Studio 15 2017"
        build_system="vs2017_project"
        vs="${var#vs}"
    fi
done

if [ "${in_arch}" = "32" ] ; then
    tri_arch="i386"
    is_32bit="y"
    is_64bit="n"
elif [ "${in_arch}" = "64" ] ; then
    tri_arch="x86_64"
    is_32bit="n"
    is_64bit="y"
else
    echo ""
    echo "'${in_arch}' is an invalid architecture. Use 32 or 64."
    echo ""
    exit
fi

# Set platform and compiler
if [ "$(uname)" = "Darwin" ]; then
    is_mac=y
    tri_platform="mac"
    tri_compiler="clang"
    if [ "${cmake_generator}" = "" ] ; then
        cmake_generator="Unix Makefiles"
        build_system="makefile"
    fi
elif [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
    is_linux=y
    tri_platform="linux"
    tri_compiler="gcc"
    if [ "${cmake_generator}" = "" ] ; then
        cmake_generator="Unix Makefiles"
        build_system="makefile"
    fi
elif [ "$(expr substr $(uname -s) 1 10)" = "MINGW32_NT" ] || [ "$(expr substr $(uname -s) 1 10)" = "MINGW64_NT" ]; then
    # @todo detect what compiler is used
    is_win="y"

    if [ "${vs}" = "2010" ] ; then
        tri_compiler="vs2010"
        build_system="vs2010_project"
        if [ "${cmake_generator}" = "" ] ; then
            cmake_generator="Visual Studio 10 2010"
            if [ "${is_64bit}" = "y" ] ; then
                cmake_generator="${cmake_generator} Win64"
            fi
        fi
    elif [ "${vs}" = "2012" ] ; then
        tri_compiler="vs2012"
        build_system="vs2012_project"
        if [ "${cmake_generator}" = "" ] ; then
            cmake_generator="Visual Studio 11 2012"
            if [ "${is_64bit}" = "y" ] ; then
                cmake_generator="${cmake_generator} Win64"
            fi
        fi
    elif [ "${vs}" = "2013" ] ; then
        tri_compiler="vs2013"
        build_system="vs2013_project"
        if [ "${cmake_generator}" = "" ] ; then
            cmake_generator="Visual Studio 12 2013"
            if [ "${is_64bit}" = "y" ] ; then
                cmake_generator="${cmake_generator} Win64"
            fi
        fi
    elif [ "${vs}" = "2017" ] ; then
        tri_compiler="vs2017"
        build_system="vs2017_project"
        if [ "${cmake_generator}" = "" ] ; then
            cmake_generator="Visual Studio 15 2017"
            if [ "${is_64bit}" = "y" ] ; then
                cmake_generator="${cmake_generator} Win64"
            fi
        fi
    else
        if [ "${cmake_generator}" = "" ] ; then
            cmake_generator="Visual Studio 12 2013"
            if [ "${is_64bit}" = "y" ] ; then
                cmake_generator="${cmake_generator} Win64"
            fi
        fi
        tri_compiler="vs2013"
    fi

    tri_platform="win"
fi

# Set CFLAGS / LDFLAGS
if [ "${architecture}" = "x86_64" ] || [ "${architecture}" = "" ] ; then
    if [ "${is_mac}" = "y" ] ; then
        extra_cflags=" -arch x86_64 "
        extra_ldflags=" -arch x86_64 "
    else
        extra_cflags=" -m64 "
        extra_ldflags=" -m64 "
    fi
else
    if [ "${is_mac}" = "y" ] ; then
        extra_cflags=" -arch i386 "
        extra_ldflags=" -arch i386 "
    else
        extra_cflags=" -m32  "
        extra_ldflags=" -m32 "
    fi
fi


if [ "${is_mac}" = "y" ] ; then
    if [ "${in_arch}" = "64" ] ; then
        cmake_osx_architectures="-DCMAKE_OSX_ARCHITECTURES=x86_64"
    else
        cmake_osx_architectures="-DCMAKE_OSX_ARCHITECTURES=i386"
    fi
fi

if [ "${is_debug}" = "y" ] ; then
    cmake_build_type="Debug"
    cmake_build_config="Debug"
    debug_flag="_debug"
    build_dir="build.debug.${build_system}"

    if [ "${is_mac}" = "y" ] ; then
        debugger="lldb"
    elif [ "${is_linux}" = "y" ] ; then
        debugger="gdb"
    fi
else
    cmake_build_type="Release"
    cmake_build_config="Release"
    build_dir="build.release.${build_system}"
fi

tri_triplet="${tri_platform}-${tri_compiler}-${tri_arch}"
d=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
sd=${d}/../sources
bd=${d}/../../extern/${tri_triplet}
id=${d}/../../extern/${tri_triplet}/include
extern_path=${d}/../../extern/${tri_triplet}
install_path=${d}/../../install/${tri_triplet}
sources_path=${d}/../sources

echo ""
echo "----------------------------------------------------------------------"
echo "Base directory:            \${d}:               ${d}"
echo "Build source directory:    \${sd}:              ${sd}"
echo "Extern base directory:     \${bd}:              ${bd}"
echo "Extern include directory:  \${id}:              ${id}"
echo "Install directory:         \${install_path}:    ${install_path}"
echo "Extern directory:          \${extern_path}:     ${extern_path}"
echo "Sources path:              \${sources_path}:    ${sources_path}"
echo "Build dir:                 \${build_dir}:       ${build_dir}"
echo "----------------------------------------------------------------------"

# Some extra helper functions.
# ------------------------------------------------------------------------
# Cross-platform symlink function. With one parameter, it will check
# whether the parameter is a symlink. With two parameters, it will create
# a symlink to a file or directory, with syntax: link $linkname $target
#
# NOTE: You first pass the name of the link (which doesn't need to exist)
#       The second parameter is the DIR/FILE to which you want to link
#       ln -s ./dir ./linkname   ----> link ./linkname ./dir
#
#       Example:
#
#           of=of_v0.8.4_vs_release
#           ofappdir=${d}/../${of}/apps/PROJECTNAME/
#           cd ${ofappdir}
#           link APPLICATION ./../../../src/of/
#
# Source: http://stackoverflow.com/questions/18641864/git-bash-shell-fails-to-create-symbolic-links
# ------------------------------------------------------------------------

link() {

    if [[ -z "$2" ]]; then

        # Link-checking mode.
        if [ "${is_win}" = "y" ] ; then
            echo "-----------------------------------------------------------"
            fsutil reparsepoint query "$1" > /dev/null
        else
            [[ -h "$1" ]]
        fi
    else

        # Link-creation mode.
        if [ "${is_win}" = "y" ] ;  then
            # Windows needs to be told if it's a directory or not. Infer that.
            # Also: note that we convert `/` to `\`. In this case it's necessary.
            echo "---------------------------------------------------------- ++++++++++-"
            if [[ -d "$2" ]]; then
#                runas /user:administrator "mklink args"
               # cmd <<< "runas /user:administrator \"mklink /J \"$1\" \"${2//\//\\}\" \"" > /dev/null
                echo "mklink /J \"${1//\//\\}\" \"${2//\//\\}\""
#                cmd <<< "runas /user:administrator \"mklink /J \"${1//\//\\}\" \"${2//\//\\}\" \""
#                cmd <<< "mklink /J \"$1\" \"${2//\//\\}\" " > /dev/null
                cmd <<< "mklink /J \"${1//\//\\}\" \"${2//\//\\}\" " > /dev/null
                echo "??"
            else
                cmd <<< "mklink \"$1\" \"${2//\//\\}\"" > /dev/null
            fi
        else
            # You know what? I think ln's parameters are backwards.
            ln -s "$2" "$1"
        fi
    fi
}

