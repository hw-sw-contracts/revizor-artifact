#!/usr/bin/env bash
set -e

SCRIPT=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT)

timestamp=$(date '+%y-%m-%d-%H-%M')
revizor_src='./revizor/src'
instructions="$revizor_src/instruction_sets/x86/base.xml"

exp_dir="results/experiment_3b/$timestamp"
mkdir $exp_dir

log="$exp_dir/experiment.log"
touch $log
result="$exp_dir/result.txt"
touch $result

aggregated="$exp_dir/aggregated.txt"
echo 'Test Case, Average, Median, Min, Max' > $aggregated

config="$SCRIPT_DIR/config.yaml"

function runtest() {
    local name=$1
    local tmpl=$2

    case="$SCRIPT_DIR/$name"
    echo "Testing $name"
    echo "" > $result

    for i in $(seq 0 99); do
        sed -e "s:@seed@:$RANDOM:g" $SCRIPT_DIR/$tmpl > $config
        for j in $(seq 2 2 64) 128 256 512 1024 2048 4096 ; do
            ${revizor_src}/cli.py fuzz -s $instructions -t $case -i $j -c $config > tmp.log 2>&1
            if grep "Violations de" tmp.log -q ; then
                echo "$j" >> $result
                break
            fi
        done
    done

    cat $result | sort -n | awk '
          BEGIN {
            c = 0;
            sum = 0;
          }
          $1 ~ /^(\-)?[0-9]+(\.[0-9]*)?$/ {
            a[c++] = $1;
            sum += $1;
          }
          END {
            ave = sum / c;
            if( (c % 2) == 1 ) {
              median = a[ int(c/2) ];
            } else {
              median = ( a[c/2] + a[c/2-1] ) / 2;
            }
            OFS="\t";
            print name, ave, median, a[0], a[c-1];
          }
        ' name=$name >> $aggregated
}

for name in "spectre_v1.asm" "spectre_v1.1.asm" "spectre_v2.asm" "spectre_v4.asm" "spectre_v5.asm"; do
    runtest $name spectre.yaml.tmpl
done

for name in "mds-lfb.asm" "mds-sb.asm"; do
    runtest $name mds.yaml.tmpl
done

echo ""
echo "======================== Summary =============================="
cat $aggregated
