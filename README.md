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

The artifact requires at least one physical machine with an Intel CPU and with root access. Preferably, there should be two machines, one with an 8th generation (or earlier) Intel CPU and another with a 9th gen (or later) Intel CPU. To have stable results, the machine(s) should not be actively used by any other software.

### Software Requirements

* Linux v5.6+ (tested on Linux v5.6.6-300 and v5.6.13-100; there is a good chance it will work on other versions as well, but it's not guaranteed).
* Linux Kernel Headers
* [Unicorn 1.0.2+](https://www.unicorn-engine.org/docs/)
* Python 3.7+
* Python packages `pyyaml`, `types-pyyaml`, `numpy`, `iced-x86`:
```shell
pip3 install --user pyyaml types-pyyaml numpy iced-x86
```
For tests, also [Bash Automated Testing System](https://bats-core.readthedocs.io/en/latest/index.html) and [mypy](https://mypy.readthedocs.io/en/latest/getting_started.html#installing-and-running-mypy)

### (Optional) System Configuration

For more stable results, disable hyperthreading (there's usually a BIOS option for it).

Optionally (and it *really* is optional), you can boot the kernel on a single core by adding `-maxcpus=1` to the boot parameters ([how to add a boot parameter](https://wiki.ubuntu.com/Kernel/KernelBootParameters)). 

## Installing the Artifact (5 human-minutes + XX compute-minutes)

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
sudo rmmod x86-executor
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

## Basic Usability Test: Detecting Spectre V1 (5 human-minutes + XX compute-minutes)

1. Run acceptance tests:
```bash
cd revizor/src/tests
./runtests.sh
```

If a few (up to 3) "Detection" tests fail, it's fine, you might just have a slightly different microarchitecture. But if other tests fail - something is broken. Let us know.

2. Fuzz in a violation-free configuration:
```bash
./revizor/src/cli.py fuzz -s x86.xml -i 50 -n 100 -v -c evaluation/test-nondetection.yaml
```

No violations should be detected.

3. Fuzz in a configuration with a known contract violation (Spectre V1):
```bash
./revizor/src/cli.py fuzz -s x86.xml -i 50 -n 1000 -v -c ../evaluation/test-detection.yaml
```

A violation should be detected within a few minutes.

You can find the test case that triggered this violation in `generated.asm`.

## Experiment 1: Name (XX human-minutes + XX compute-minutes)

TODO

## Experiment 2: Name (XX human-minutes + XX compute-minutes)

TODO

## Experiment 3: Name (XX human-minutes + XX compute-minutes)

TODO