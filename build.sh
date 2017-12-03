#!/bin/bash

# Directory of Erlang files to build.
dir=$1

# Creates a bin directory if doesn't exist.
mkdir -p bin

echo -e "\nCompiling $dir ...\n"

# Compile all Erlang files into the bin directory.
for filename in $(find $dir -name "*.erl"); do
  erlc -o bin $filename
done
