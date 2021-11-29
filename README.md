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

## Experiment 1: Reproducing fuzzing results (XX human-minutes + XX compute-minutes)

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

## Experiment 2: Reproducing speculative store eviction (XX human-minutes + XX compute-minutes)

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


## Experiment 3: Fuzzing speed and detection time (XX human-minutes + XX compute-minutes)

### Claims

* Introduction
```text
In terms of speed, Revizor processes over 200 test cases per hour for complex
contracts, and with several hundreds of inputs per test case,
```

* Evaluation: Section 6.5, Table 4 and Table 5

### Validating the Claims


## Experiment 4: Reproducing ARCH-SEQ violation (XX human-minutes + XX compute-minutes)

### Claims

* Evaluation: Section 6.6 and Figure 6

### Validating the Claims
