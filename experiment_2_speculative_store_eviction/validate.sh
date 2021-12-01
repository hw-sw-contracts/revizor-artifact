#!/usr/bin/env bash
set -e

SCRIPT=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT)

if [ -z "${1}" ]; then
    echo "Usage: ./validate.sh <TESTCASE>"
    exit 1
fi
testcase=$1

revizor_src='revizor/src'
instructions="$revizor_src/instruction_sets/x86/base.xml"

${revizor_src}/cli.py fuzz -s $instructions -t $testcase -i 1000 -v -c $SCRIPT_DIR/full-ct-cond.yaml
