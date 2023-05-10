#!/bin/bash

###
# Build examples on Linux
###

set -e # exit on errors

# cd to script directory
EXAMPLES_DIRECTORY=$(cd `dirname $0` && pwd)
cd $EXAMPLES_DIRECTORY

# Prep build directory
BUILD_DIR=$(realpath build)
TEMP_DIR=$BUILD_DIR/tmp

rm -rf $BUILD_DIR
mkdir $BUILD_DIR
mkdir $TEMP_DIR

# Build examples

EXAMPLES=( $(ls -d [0-9][0-9]-*) )

for EXAMPLE in "${EXAMPLES[@]}"
do
    cd $EXAMPLES_DIRECTORY/$EXAMPLE

    echo "Building example ${EXAMPLE}"

    # Create simple linkfile
    LINKFILE=$TEMP_DIR/linkfile
    echo [objects] > $LINKFILE
    echo $EXAMPLE.o >> $LINKFILE

    # Assemble objects
    wla-z80 -o $TEMP_DIR/$EXAMPLE.o main.asm

    # Link objects
    cd $TEMP_DIR
    wlalink -d -S -A linkfile $EXAMPLE.sms
    cd - > /dev/null # return to former directory

    # Place output in build directory
    mv $TEMP_DIR/$EXAMPLE.sms $BUILD_DIR
    mv $TEMP_DIR/$EXAMPLE.sym $BUILD_DIR

    cd $EXAMPLES_DIRECTORY
done
