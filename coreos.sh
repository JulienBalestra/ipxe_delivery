#!/usr/bin/env bash

set -xe

USB=ipxe.usb
USB_RULE=bin/${USB}
USB_BIN=ipxe/src/${USB_RULE}

ISO=ipxe.iso
ISO_RULE=bin/${ISO}
ISO_BIN=ipxe/src/${ISO_RULE}

SCRIPT_NAME=coreos.ipxe

PACKAGE=coreos_ipxe.tar.gz

function go_to_dirname
{
    echo "Go to working directory..."
    cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    if [ $? -ne 0 ]
    then
        echo "go_to_dirname failed";
        exit 1
    fi
    echo "-> Current directory is" $(pwd)
}

function setup_submodules
{
    echo "Setup git submodules..."
    for module in ipxe
    do
        git submodule init ${module}
        git submodule update --remote ${module}
    done
}

function builder
{
    echo "Starting build..."
    SCRIPT_PATH="$(pwd)/${SCRIPT_NAME}"
    file ${SCRIPT_PATH}

    echo -n "date: " >> output/metadata
    date >> output/metadata
    echo -n "git rev-parse: " >> output/metadata
    git rev-parse HEAD >> output/metadata

    for RULE in ${ISO_RULE} ${USB_RULE} 
    do
        make -C ipxe/src -j ${RULE} EMBED=${SCRIPT_PATH}
        echo -n "file: " >> output/metadata
        file "ipxe/src/${RULE}" >> output/metadata
	ls -l "ipxe/src/${RULE}"
        echo -n "sha1sum: " >> output/metadata
        sha1sum  "ipxe/src/${RULE}" >> output/metadata
        mv "ipxe/src/${RULE}" output/
    done
}

function package
{
    echo "Starting package..."
    mkdir delivery || rm -Rf delivery/*
    cd output
    cat metadata
    tar -czvf ${PACKAGE} *
    file ${PACKAGE}
    mv ${PACKAGE} ../delivery/
}

go_to_dirname
setup_submodules
builder
package
