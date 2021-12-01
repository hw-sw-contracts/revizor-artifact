# Artifact Evaluation Submission for Revizor [ASPLOS'22]

**Paper**: "Revizor: Testing Black-box CPUs against Speculation Contracts"

## Table of Contents

TODO

- [Requirements & Dependencies](#requirements--dependencies)
    - [Hardware Requirements](#inputsoutputs)
    - [Software Requirements](#software-requirements)
    - [(Optional) System Configuration](#optional-system-configuration)
    
## Requirements & Dependencies

**Warning**: Revizor executes randomly generated code in kernel space.
As you can imagine, things could go wrong.
We did our best to avoid it and to make Revizor stable, but still, no software is perfect.
Make sure you're not running these experiments on an important machine.

### Hardware Requirements

The artifact requires at least one physical machine with an Intel CPU and with root access. Preferably, there should be two machines, one with an 8th generation (or earlier) Intel CPU and another with a 9th gen (or later) Intel CPU. In the paper, we used Intel Core i7-6700 and i7-9700.

To have stable results, the machine(s) should not be actively used by any other software.

### Software Requirements

* Linux v5.6+ (tested on Linux v5.6.6-300 and v5.6.13-100; there is a good chance it will work on other versions as well, but it's not guaranteed).
* Linux Kernel Headers
* Python 3.7+
* [Unicorn 1.0.2+](https://www.unicorn-engine.org/docs/)
* Python bindings to Unicorn:
```shell
pip3 install --user unicorn

# OR, if installed from sources
cd bindings/python
sudo make install
```
* Python packages `pyyaml`, `types-pyyaml`, `numpy`, `iced-x86`:
```shell
pip3 install --user pyyaml types-pyyaml numpy iced-x86
```
For tests, also [Bash Automated Testing System](https://bats-core.readthedocs.io/en/latest/index.html) and [mypy](https://mypy.readthedocs.io/en/latest/getting_started.html#installing-and-running-mypy)

### (Optional) System Configuration

For more stable results, disable hyperthreading (there's usually a BIOS option for it).
If you do not disable hyperthreading, you will see a warning every time you invoke Revizor; you can ignore it.

Optionally (and it *really* is optional), you can boot the kernel on a single core by adding `-maxcpus=1` to the boot parameters ([how to add a boot parameter](https://wiki.ubuntu.com/Kernel/KernelBootParameters)). 

## Installing the Artifact (5 human-minutes + 10 compute-minutes)

1. Get submodules:
```bash
# from the root directory of this project
git submodule update --init --recursive
```

2. Copy the ISA description:
```bash
cp revizor/src/executor/x86/base.xml revizor/src/instruction_sets/x86
cp revizor/src/executor/x86/base.xml x86.xml
```

3. Install the executor:
```bash
cd revizor/src/executor/x86 
sudo rmmod x86-executor  # the command will give an error message, but it's ok!
make clean
make
sudo insmod x86-executor.ko
```

## Command line interface to Revizor

The fuzzer is controlled via a single command line interface `cli.py` (located in `revizor/src/cli.py`). It accepts the following arguments:

* `-s, --instruction-set PATH` - path to the ISA description file
* `-c, --config PATH` - path to the fuzzing configuration file
* `-n , --num-test-cases N` - number of test cases to be tested
* `-i , --num-inputs N` - number of inputs per test case
* `-t , --testcase PATH` - use an existing test case instead of generating random test cases
* `--timeout TIMEOUT` - run fuzzing with a time limit [seconds]
* `--nonstop` - don't stop after detecting a contract violation

## Basic Usability Test: Detecting Spectre V1 (5 human-minutes + 20 compute-minutes)

1. Run acceptance tests:
```bash
cd revizor/src/tests
./runtests.sh
```

If a few (up to 3) "Detection" tests fail, it's fine, you might just have a slightly different microarchitecture. But if other tests fail - something is broken. Let us know.

2. Fuzz in a configuration with a known contract violation (Spectre V1):
```bash
./revizor/src/cli.py fuzz -s x86.xml -i 50 -n 1000 -v -c test-detection.yaml
```

A violation should be detected within a few minutes, with a message similar to this:

```
================================ Violations detected ==========================
  Contract trace (hash):

    0111010000011100111000001010010011110101110011110100000111010110
  Hardware traces:
   Inputs [907599882]:
    _____^______^______^___________________________________________^
   Inputs [2282448906]:
    ___________________^_____^___________________________________^_^

```

You can find the test case that triggered this violation in `generated.asm`.

3. Fuzz in a violation-free configuration:
```bash
./revizor/src/cli.py fuzz -s x86.xml -i 50 -n 100 -v -c test-nondetection.yaml
```

No violations should be detected.

## Results of experiments

The results of all next experiments will be stored in a corresponding subdirectory of `results/` with a timestamp. For example, if you run Experiment 1 on 01.01.2022 at 13:00, the result will be stored in `results/experiment_1/22-01-01-13:00`.

This directory will contain the experiment logs, detected violations, and aggregated results (when applicable). 


## Experiment 1: Reproducing fuzzing results (20 human-minutes + 5 compute-days)

### Claims

* Abstract

```text
Revizor automatically detects violations of a rich set of contracts,
or indicates their absence. A highlight of our findings is that Revizor 
managed to automatically surface Spectre, MDS, and LVI.
```

* Introduction

```text
1. When testing a patched Skylake against a restrictive contract that 
states that speculation exposes no information, Revizor detects a violation
within a few minutes. Inspection shows the violation stems from the leakage
during branch prediction, i.e. a representative of Spectre V1.
2. When testing Skylake with V4 patch disabled against a contract that
permits leakage during branch prediction (and is hence not violated by V1),
Revizor detects a violation due to address prediction, i.e., a representative
of Spectre V4.
3. When further weakening the contract to permit leaks during both types 
of speculation, Revizor still detects a violation. This violation is a novel
(minor) variant of Spectre where the timing of variable-latency instructions
(which is not permitted to leak according to the contract) leaks into L1D
through a race condition induced by speculation.
4. When making microcode assists possible during collection of the hardware
traces, Revizor surfaces MDS [40, 5] on the same CPU and LVI-Null [39] on 
a CPU with microcode patch against MDS.
```

```text
The analysis is robust and did not produce false positives
```

* Evaluation: Table 3 and Section 6.2

* Conclusion

```text
The detected violations include known vulnerabilities such Spectre, MDS, 
and LVI, as well as novel variants.
```

### Validating the Claims

Execute:
```shell
./experiment_1_main/run.sh
```

This script will test each of the target-contract combinations in Table 3.
Note that the last target (called here target7-8) is dependent on the machine.
If you execute the script on an 8th gen (or earlier) CPU, it will correspond to Target 7 in the table.
Otherwise, it will correspond to Target 8.

The expected result is that the final summary will match the following:
```text
Detected Violations:
- target2 violates ct-seq
- target2 violates ct-cond
- target3 violates ct-seq
- target3 violates ct-bpas  # low likelihood
- target3 violates ct-cond
- target3 violates ct-cond-bpas  # low likelihood
- target5 violates ct-seq
- target5 violates ct-bpas
- target6 violates ct-seq
- target6 violates ct-bpas
- target6 violates ct-cond   # low likelihood
- target6 violates ct-cond-bpas  # low likelihood
- target7-8 violates ct-seq
- target7-8 violates ct-bpas
- target7-8 violates ct-cond
- target7-8 violates ct-cond-bpas
```

*NOTE*: The violations of Targets 3 and 6 (called V1-var and V4-var in the paper) are very rare, and there is only a low chance that you will be able to reproduce them.
Unfortunately, such unpredictability of the results is an unavoidable consequence of random testing.


## Experiment 2: Reproducing speculative store eviction (10 human-minutes + 60 compute-minutes)

### Claims

* Abstract
```text
A highlight of our findings is that Revizor managed to automatically 
surface [...] several previously unknown variants.
```

* Introduction
```text
When used to validate an assumption that stores do not modify the cache
state until they retire, made in recent defence proposals, Revizor 
discovered that this assumption does not hold in Coffee Lake.
```

* Evaluation: Section 6.4

### Validating the Claims

To reproduce this result, you will need a 9th gen Intel CPU or later (in the paper, we tested i7-9700).

Execute:
```shell
./experiment_2_speculative_store_eviction/run.sh
```

It will test the CPU against a version of CT-COND that does not permit cache eviction by speculative stores.

The expected result is that the execution detects a violation within an hour. The script should finish with a message ```===== Violations detected ====``` followed by the description of the violation and some statistics. (If you run this command on an earlier Intel CPU, the expected result is no violations.)

You can find the counterexample test case in the results' directory, named `violation-TIMESTAMP.asm`. To verify that it is indeed the speculative store eviction, execute:
```shell
./experiment_2_speculative_store_eviction/validate.sh RESULTS_DIRECTORY/violation-TIMESTAMP.asm
```

This will fuzz the test case against CT-COND, which permits speculative store eviction. The fuzzing is expected to complete with no violations.

## Experiment 3: Fuzzing speed and detection time (30 human-minutes + 2 compute-days)

### Claims

* Introduction
```text
In terms of speed, Revizor processes over 200 test cases per hour for complex
contracts, and with several hundreds of inputs per test case,
```

* Evaluation: Section 6.5, Table 4 and Table 5

### Validating the Claims

1. To measure the fuzzing speed, simply run Revizor for an hour in a configuration that does not find violations:
```bash
./revizor/src/cli.py fuzz -s x86.xml -i 200 -n 100000 --timeout 3600 -v -c test-nondetection.yaml
```

It should complete with a line `=== Statistics ===` followed by some statistics on the fuzzing run. The line "Test Cases: ..." is the total number of executed test cases, and "Inputs per test case: ..." is the number of inputs.

2. To measure the detection speed (Table 4), execute:
```bash
./experiment_3a_detection_speed/run.sh
```

The results are expected to be close to the following:
```text
v4,4405
v4-with-v4,8442
v1,291
v1-with-v4,228
mds,335
mds-with-v1,397
mds-with-v4,423
```

The numbers are the mean values of the amount of time to detect each of the violations.

The exact numbers may differ with each execution of this experiment because the test cases are generated randomly.

The meaning of the rows called "mds-*" depends on the target machine:
If the experiment is executed on an 8th gen (or earlier) CPU, they represent MDS-type vulnerabilities.
Otherwise, they represent LVI-type.

3. To measure the detection speed on handwritten test cases (Table 5), execute:
```bash
./experiment_3b_handwritten_test_cases/run.sh
```

The results are expected to approximately match the following:
```text
Test Case, Average, Median, Min, Max
spectre_v1.asm      7.5     7       4       12
spectre_v1.1.asm    6       5       4       10
spectre_v2.asm      12      11      6       20
spectre_v4.asm      14.5    14      12      18
spectre_v5.asm      2       2       2       4
mds-lfb.asm         2       2       2       2
mds-sb.asm          11.5    12      4       20
```

The numbers are the average, median, minimum, and maximum number of inputs that was required to detect each of the violations with the given test case.
If number of inputs is 4096 it means that the vulnerability was not detected (this script gives up testing after 4069 inputs).

The exact numbers will differ slightly with each execution of this experiment, because the input generation seeds are generated randomly.

*NOTE*: The last two test cases (MDS-SB and MDS-LFB) work only on an 8th gen (or earlier) Intel CPU, because the later generations are patched against MDS.

## Experiment 4: Reproducing ARCH-SEQ violation (30 human-minutes + 10 compute-hours)

### Claims

* Evaluation: Section 6.6 and Figure 6

### Validating the Claims

Execute:
```shell
./experiment_4_arch_vs_ct/run.sh
```

It will test the CPU against CT-SEQ and ARCH-SEQ.

The expected result is that both contracts are violated (i.e., you will see `=== Violations detected ====` twice).

You can find the counterexamples for both contracts in the results' directory, named `ct-seq-violation.asm` and `arch-seq-violation.asm`.

Verification of the violations requires manual analysis: `ct-seq-violation.asm` should match Fig. 6a and `arch-seq-violation.asm` Fig. 6b. As the test cases are randomly generated, it may be hard to analyse them; if you need help, send them to us.