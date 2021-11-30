#!/usr/bin/env bash
set -e

SCRIPT=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT)

timestamp=$(date '+%y-%m-%d-%H-%M')
revizor_src='revizor/src'
instructions="$revizor_src/instruction_sets/x86/base.xml"

exp_dir="results/experiment_2/$timestamp"
mkdir $exp_dir

log="$exp_dir/experiment.log.txt"

${revizor_src}/cli.py fuzz -s $instructions -n 1000 -i 100 -v -w $exp_dir -c $SCRIPT_DIR/full-ct-nonspec-cond.yaml 2>&1 | tee -a $log


cd - || exit