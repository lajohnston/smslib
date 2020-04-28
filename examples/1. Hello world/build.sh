#!/bin/bash

BUILD_DIR=../build
TEMP_DIR=$BUILD_DIR/tmp
PROJECT_NAME=helloWorld
ENTRY_POINT=main.asm

set -e # exit on errors

# Prepare build directory
rm -rf $TEMP_DIR/*
mkdir -p $TEMP_DIR

# Create simple linkfile
LINKFILE=$TEMP_DIR/linkfile
echo [objects] > $LINKFILE
echo $PROJECT_NAME.o >> $LINKFILE

# Assemble objects
wla-z80 -o $TEMP_DIR/$PROJECT_NAME.o $ENTRY_POINT

# Link objects
cd $TEMP_DIR
wlalink -d -v -S -A linkfile $PROJECT_NAME.sms
cd - # return to former directory

# Place output in build directory
mv $TEMP_DIR/$PROJECT_NAME.sms $BUILD_DIR
mv $TEMP_DIR/$PROJECT_NAME.sym $BUILD_DIR
