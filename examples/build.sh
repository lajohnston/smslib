#!/bin/bash

set -e # exit on errors

# cd to script directory
DIRECTORY=$(cd `dirname $0` && pwd)
cd $DIRECTORY

# Prep build directory
mkdir -p ./build/tmp

EXAMPLES=( $(ls -d [0-9][0-9]-*) )
for i in "${EXAMPLES[@]}"
do
    BUILD_DIR=../build
    TEMP_DIR=$BUILD_DIR/tmp

    cd ./$i
    PROJECT_NAME=$i

    printf "\nBuilding example ${PROJECT_NAME}:\n\n"

    # Create simple linkfile
    LINKFILE=$TEMP_DIR/linkfile
    echo [objects] > $LINKFILE
    echo $PROJECT_NAME.o >> $LINKFILE

    # Assemble objects
    wla-z80 -o $TEMP_DIR/$PROJECT_NAME.o main.asm

    # Link objects
    cd $TEMP_DIR
    wlalink -d -v -S -A linkfile $PROJECT_NAME.sms
    cd - # return to former directory

    # Place output in build directory
    mv $TEMP_DIR/$PROJECT_NAME.sms $BUILD_DIR
    mv $TEMP_DIR/$PROJECT_NAME.sym $BUILD_DIR

    cd ../
done
