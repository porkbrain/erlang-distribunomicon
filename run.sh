#!/bin/bash

shell="-noshell"

main="client_main"

node=""

# Parses flags.
while getopts 'n:m:s' flag; do
  case "${flag}" in
    n) node="-name ${OPTARG} -setcookie \"12345\"" ;;
    m) main="${OPTARG}" ;;
    s) shell="" ;;
    *) error "Unknown flag ${flag}." ;;
  esac
done

./build.sh client
./build.sh load-balancer
./build.sh node

# Opens bin directory.
cd bin

echo -e "\nRunning $main module.\n"

# Calls the $main module's start/0 function.
erl $shell $node -s $main start -s init stop

echo -e "\n\nTerminating\n"
