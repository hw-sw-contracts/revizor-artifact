#!/usr/bin/env bash
set -e

SCRIPT=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT)

timestamp=$(date '+%y-%m-%d-%H-%M')
revizor_src='revizor/src'
instructions="$revizor_src/instruction_sets/x86/base.xml"

exp_dir="results/experiment_2/$timestamp"
mkdir $exp_dir

log="$exp_dir/experiment.log"
touch $log

# Violation of CT-SEQ
echo "------------------ Testing against CT-SEQ ---------------------------"
${revizor_src}/cli.py fuzz -s $instructions -n 10000 -i 100 -v -w $exp_dir -c $SCRIPT_DIR/v1-ct-seq.yaml 2>&1 | tee -a $log
mv $exp_dir/violation*.asm $exp_dir/ct-seq-violation.asm

# Violation of ARCH-SEQ
echo "------------------ Testing against ARCH-SEQ ---------------------------"
${revizor_src}/cli.py fuzz -s $instructions -n 10000 -i 100 -v -w $exp_dir -c $SCRIPT_DIR/v1-arch-seq.yaml 2>&1 | tee -a $log
mv $exp_dir/violation*.asm $exp_dir/arch-seq-violation.asm

cd - || exit