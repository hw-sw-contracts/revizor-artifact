#!/usr/bin/env bash
set -e

SCRIPT=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT)
#TIMEOUT=$(( 24 * 3600 ))
TIMEOUT=$(( 1200 ))

timestamp=$(date '+%y-%m-%d-%H-%M')
revizor_src='./revizor/src'
instructions="$revizor_src/instruction_sets/x86/base.xml"

exp_dir="results/experiment_1/$timestamp"
mkdir $exp_dir

log="$exp_dir/experiment.log"
touch $log

violations=()

for target in target1 target2 target3 target4 target5 target6 target7-8; do
    echo ""
    echo "------------------ Testing $target ---------------------------"
    echo ""
    for contract in seq bpas cond cond-bpas; do
        echo "***** Contract ct-$contract *****"
        echo ""
        name="$target-$contract"
        conf="$exp_dir/$name.yaml"

        # patch the config to set the correct contract
        cp "$SCRIPT_DIR/$target.yaml" $conf
        echo "prng_entropy_bits: 2
feedback_driven_generator: true
contract_observation_mode: ct
contract_execution_mode:" >> $conf
        if [ $contract == "seq" ]; then
            echo "- seq" >> $conf
        elif [ $contract == "cond" ]; then
            echo "- cond" >> $conf
        elif [ $contract == "bpas" ]; then
            echo "- bpas" >> $conf
        elif [ $contract == "cond-bpas" ]; then
            echo "- cond
- bpas" >> $conf
        fi

        # fuzz the target
        ${revizor_src}/cli.py fuzz -s $instructions -n 100000 -i 50 -v --timeout $TIMEOUT -w $exp_dir -c $conf 2>&1 | tee -a $log

        # if there was a violation, save it under an understandable name
        if ls $exp_dir/violation*.asm 1> /dev/null 2>&1; then
            mv $exp_dir/violation*.asm "$exp_dir/$name-violation.asm"
            violations+=("$target violates ct-$contract")
        elif [  $contract == "seq" ] || [  $contract == "cond" ]; then
            echo ""
            echo "  No violations of CT-SEQ found, hence there is no point in testing the other contracts."
            echo "  Moving on to the next target."
            break
        fi
    done
done

echo ""
echo ""
echo "======================== Summary =============================="
echo "Detected Violations:"
for value in "${violations[@]}"; do
    echo "- $value"
done
