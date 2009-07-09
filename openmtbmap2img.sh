#!/bin/bash

E_CANNOT_CREATE_TMP_DIR=65
E_DOWNLOAD=66
E_MISSING_MAP_FILE=67
E_UNARCHIVE=68
E_CANNOT_FIND_MAPSET=69
E_CANNOT_FIND_TOOL=70
E_INTERRUPTED=71

ORIGIN=`pwd`

MAP_URL="http://openmtbmap.x-nation.de/maps/mtbgermany.7z.zip"

if [ "$1" != "" ]; then
    MAP_URL="$1"
fi

MAP_FILE=`basename ${MAP_URL}`
MAP_FILE_EXTENSION=".${MAP_FILE#*.}"
MAP_FILE_BASENAME=`basename -s ${MAP_FILE_EXTENSION} ${MAP_FILE}`

# functions

cleanup() {

    echo "Switching back to ${ORIGIN}; removing tmp directory (${TEMPDIR}) ..."
    cd ${ORIGIN}

    if [ -d ${TEMPDIR} ]; then
        rm -rf ${TEMPDIR}
    fi
    
}

# check for needed tools

echo "(0) Checking for needed tools ..."

CHECK_7ZA=`which -s 7za`

if [ $? -ne 0 ]; then
    echo "$0: Cannot find '7za' binary"
    echo "$0: You can install 7za from MacPorts (http://macports.org)"
    echo "$0: exiting ..."
    cleanup
    exit ${E_CANNOT_FIND_TOOL}
fi

echo "    > 7-Zip file archiver found"

CHECK_GMT=`which -s gmt`

if [ $? -ne 0 ]; then
    echo "$0: Cannot find 'gmt' binary"
    echo "$0: Download it from here: http://www.anpo.republika.pl/download.html"
    echo "$0: exiting ..."
    cleanup
    exit ${E_CANNOT_FIND_TOOL}
fi

echo "    > gmaptool found"

CHECK_WGET=`which -s wget`

if [ $? -ne 0 ]; then
    echo "$0: Cannot find 'wget' binary, exiting ..."
    cleanup
    exit ${E_CANNOT_FIND_TOOL}
fi

echo "    > wget found"

# creating tmp dir

TEMPDIR=`mktemp -q -d openmtbmap.XXXXXX`

if [ $? -ne 0 ]; then
    echo "$0: Cannot create tmp directory, exiting ..."
    cleanup
    exit ${E_CANNOT_CREATE_TMP_DIR}
fi

cd ${TEMPDIR}

echo "(1) Downloading Maps (${MAP_FILE}) ..."
echo "    > Download URL: ${MAP_URL}"

wget ${MAP_URL}

if [ $? -ne 0 ]; then
    echo "$0: Error while downloading map archive, exiting ..."
    cleanup
    exit ${E_DOWNLOAD}
fi

echo "(2) Unarchiving Maps ..."

if [ ! -f ${MAP_FILE} ]; then
    echo "$0: Cannot find map archive, exiting ..."
    exit ${E_MISSING_MAP_FILE}
fi

7za x -o${MAP_FILE_BASENAME} ${MAP_FILE}

if [ $? -ne 0 ]; then
    echo "$0: Error while unarchiving maps, exiting ..."
    cleanup
    exit ${E_UNARCHIVE}
fi

echo "(3) Building .img Mapset ..."

cd ${MAP_FILE_BASENAME}
cp white*.TYP 01002468.TYP
gmt -wy 6350 01002468.TYP
gmt -j -o ${MAP_FILE_BASENAME}.img -f 6350 -m "openmtbmap" 6*.img 01002468.TYP

if [ -f ${MAP_FILE_BASENAME}.img ]; then
    mv ${MAP_FILE_BASENAME}.img ${ORIGIN}
    cleanup
else
    echo "$0: Cannot find generated mapset, exiting ..."
    cleanup
    exit ${E_CANNOT_FIND_MAPSET}
fi

echo "Done."
