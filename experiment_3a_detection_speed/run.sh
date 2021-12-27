#!/usr/bin/env bash
set -e

SCRIPT=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT)
MAX_ROUNDS=10000

timestamp=$(date '+%y-%m-%d-%H-%M')
revizor_src='./revizor/src'
instructions="$revizor_src/instruction_sets/x86/base.xml"

exp_dir="results/experiment_3a/$timestamp"
mkdir $exp_dir

log="$exp_dir/experiment.log"
touch $log
result="$exp_dir/aggregated.txt"
touch $result

function time_to_violation() {
    local conf=$1
    local name=$2

    ${revizor_src}/cli.py fuzz -s $instructions -c $conf -n $MAX_ROUNDS -i 50 -w $exp_dir -v > "$exp_dir/tmp.txt"
    cat "$exp_dir/tmp.txt" >> $log
    cat "$exp_dir/tmp.txt" | awk '/Test Cases:/{tc=$3} /Duration:/{dur=$2} /Finished/{printf "%s, %d, %d\n", name, tc, dur}' name=$name >> $result
#    cat tmp.txt | awk '/Test Cases:/{tc=$3} /Patterns:/{p=$2} /Fully covered:/{fc=$3} /Longest uncovered:/{lu=$3} /Duration:/{dur=$2} /Finished/{printf "%s, %d, %d, %d, %d, %d\n", name, tc, p, fc, lu, dur}' name=$name >> $result

}

if [ "${1}" == "mds-only" ]; then
    for name in mds mds-with-v1 mds-with-v4; do
        echo ""
        echo "Running $name" | tee -a "$log"
        echo ""
        conf="$SCRIPT_DIR/$name.yaml"

        for i in $(seq 0 9); do
            time_to_violation $conf "$name,$i"
        done
    done
else
    for name in v4 v4-with-v1 v1 v1-with-v4 mds mds-with-v1 mds-with-v4; do
        echo ""
        echo "Running $name" | tee -a "$log"
        echo ""
        conf="$SCRIPT_DIR/$name.yaml"

        for i in $(seq 0 9); do
            time_to_violation $conf "$name,$i"
        done
    done
fi

echo ""
echo "======================== Summary =============================="
echo "Name, Mean, Standard Deviation"
datamash -t, groupby 1 mean 3 sstdev 3 < $result
