# CyFuzz: A Differential Testing Framework for Cyber-Physical Systems Development Environments

Welcome to the CyFuzz project! Prototype implementation for *Simulink* is located under `slsf` 
directory. Check out the [slsf/Readme.md](slsf/Readme.md) file to learn how to 
run the tool.

# Recent News

 - We presented at the 6th Workshop on Design, Modeling, and Evaluation of Cyber Physical Systems (CyPhy'16)
 - [Reproduced bug](https://github.com/verivital/slsf_randgen/wiki/CyFuzz-Reproduced-Bug-in-Simulink)
 - [Sample Models](https://github.com/verivital/slsf_randgen/wiki/Sample-random-models-generated-by-CyFuzz) 

## Contribute

We welcome new contributors! We manage the project in GitHub; please be familiar with different git branches. Development branch is `random-generation` where you can find latest code. Stable code can be found in `master`.

Other temporary branches:

 - *(Csmith related)*  `csmith-integration` branch

## Running the prototype

Please check out the [slsf/Readme.md](slsf/Readme.md) file to learn how to 
run the tool.

### Requirements

Hard requirements:

- Matlab with Simulink. Matlab scripts can be run from either Windows or Linux (as tested so far).

Optional:

 - Python3: if you want to detect crash-bugs. Python2 might not work. Also require Linux (I've tested the scripts in Ubuntu 14.04+) to run the Python scripts, as I've not tested them in other platforms. 
 - [https://embed.cs.utah.edu/csmith/](Csmith): if you want to generate *custom* blocks (see below for instructions)
 

### Building and installing Csmith (required if you want to create custom models)

 - Please clone source code from (customized Csmith)[ttps://github.com/shafiul/csmith].
 - To build csmith, follow official doc at https://embed.cs.utah.edu/csmith/
 - If using Ubuntu: You need `m4` library (`apt-get` it)
 - Once built, the Csmith binary is located inside `src` directory.
 - We have to ensure csmith executable and `include` directory is in operating system path (see below). 

### Set up environment variables (in Linux) 

Adding following in your `bash.rc` will add `Csmith` and `Matlab` executables in OS path:

    export CSMITH_PATH=/path/to/csmith
    export PATH=$PATH:/$CSMITH_PATH/src:path/to/matlab/binary
    export C_INCLUDE_PATH=$CSMITH_PATH/runtime
    export CSMITH_HOME=$CSMITH_PATH # Needed for running csmith test driver

## Acknowledgement

This material is based upon work supported by the National Science Foundation under Grants No. 1117369, 1464311, and 1527398. Any opinions, findings, and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation.
