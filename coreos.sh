#!/usr/bin/env bash

set -xe

USB=ipxe.usb
USB_RULE=bin/${USB}
USB_BIN=ipxe/src/${USB_RULE}

ISO=ipxe.iso
ISE_RULE=bin/${ISO}
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

    date >> output/sha1
    git rev-parse HEAD >> output/sha1

    for RULE in ${USB_RULE} ${ISO_RULE}
    do
        make -C ipxe/src -j ${RULE} EMBED=${SCRIPT_PATH}
        file "ipxe/src/${RULE}"
        if [ $? -ne 0 ]
        then
            cat make_stdout
            exit 2
        fi
        sha1sum  "ipxe/src/${RULE}" >> output/sha1
        mv "ipxe/src/${RULE}" output/
    done
}

function package
{
    echo "Starting package..."
    mkdir delivery || rm -Rf delivery/*
    cd output
    tar -czvf ${PACKAGE} *
    file ${PACKAGE}
    mv ${PACKAGE} ../delivery/
}

go_to_dirname
setup_submodules
builder
package