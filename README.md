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

2. Copy the x86 ISA description:
```bash
cp revizor/src/executor/x86/base.xml revizor/src/instruction_sets/x86
```

3. Install the x86 executor:
```bash
cd revizor/src/executor/x86 
sudo rmmod x86-executor
make clean
make
sudo insmod x86-executor.ko
```

4. (Optionally) Run test:
```bash
cd src/tests
./runtests.sh
```

If a few (up to 3) "Detection" tests fail, it's fine, you might just have a slightly different microarchitecture. But if other tests fail - something is broken. Let us know.

## Basic Usability Test: Detecting Spectre V1 (5 human-minutes + XX compute-minutes)

TODO

This fuzzing command will call the fuzzer and execute 10 fuzzing iterations in a configuration that is not expected to find any vulnerabilities.
```bash
cd revizor/src/
./cli.py fuzz -s instruction_sets/x86/base.xml -i 1000 -n 10 -v -c ../evaluation/1_fuzzing_main/bm-bpas.yaml
```

This one should detect a violations within several minutes.
The detected violation is most likely an instance of Spectre V1.

```bash
cd revizor/src/
./cli.py fuzz -s instruction_sets/x86/base.xml -i 50 -n 1000 -v -c ../evaluation/fast-spectre-v1.yaml
```

You can find the test case that triggered this violation in `src/generated.asm`.


## Experiment 1: Name (XX human-minutes + XX compute-minutes)

TODO

## Experiment 2: Name (XX human-minutes + XX compute-minutes)

TODO

## Experiment 3: Name (XX human-minutes + XX compute-minutes)

TODO