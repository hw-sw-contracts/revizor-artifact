#!/usr/bin/env bash
set -e

SCRIPT=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT)
numinputs=1000

if [ -z "${1}" ] ; then
    echo "Usage: ./validate.sh <TESTCASE>"
    exit 1
fi
testcase=$1

revizor_src='revizor/src'
instructions="$revizor_src/instruction_sets/x86/base.xml"

function runtest() {
  local entropy=$1
  local config=$2
  local logfile=$3

  cp $config tmp.yaml
  echo "prng_entropy_bits: $entropy" >> tmp.yaml

  ${revizor_src}/cli.py fuzz -s $instructions -t $testcase -i $numinputs -v -c tmp.yaml > $logfile 2>&1
  printf "."
}

printf "Analysing..."

# V1
for e in $(seq 2 5); do
  runtest $e ${SCRIPT_DIR}/validate-ct-seq-patch-noasist.yaml violation.txt
  runtest $e ${SCRIPT_DIR}/validate-ct-cond-patch-noasist.yaml noviolation.txt
  if grep "== Violations detected ==" violation.txt > /dev/null && ! grep "== Violations detected ==" noviolation.txt > /dev/null; then
      echo ""
      echo "Likely a V1-type violation"
      exit 0
  fi
done

# V4
for e in $(seq 2 5); do
  runtest $e ${SCRIPT_DIR}/validate-ct-seq-nopatch-noasist.yaml violation.txt
  runtest $e ${SCRIPT_DIR}/validate-ct-bpas-nopatch-noasist.yaml noviolation.txt
  if grep "== Violations detected ==" violation.txt > /dev/null && ! grep "== Violations detected ==" noviolation.txt > /dev/null; then
      echo ""
      echo "Likely a V4-type violation"
      exit 0
  fi
done

# MDS/LVI
for e in $(seq 2 5); do
  runtest $e ${SCRIPT_DIR}/validate-ct-seq-patch-asist.yaml violation.txt
  runtest $e ${SCRIPT_DIR}/validate-ct-seq-patch-noasist.yaml noviolation.txt
  if grep "== Violations detected ==" violation.txt > /dev/null && ! grep "== Violations detected ==" noviolation.txt > /dev/null; then
      echo ""
      if grep "mds" /proc/cpuinfo ; then
         echo "Likely a MDS-type violation"
      else
          echo "Likely a LVI-type violation"
      fi
      exit 0
  fi
done

echo ""
echo "Unknown type"
