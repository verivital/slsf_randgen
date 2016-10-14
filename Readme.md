# CyFuzz: A Differential Testing Framework for Cyber-Physical Systems Development Environments

Welcome to the CyFuzz project! Prototype implementation for *Simulink* is located under `slsf` 
directory. Check out the [slsf/Readme.md](slsf/Readme.md) file to learn how to 
run the tool.

# Recent News

 - We presented at the 6th Workshop on Design, Modeling, and Evaluation of Cyber Physical Systems (CyPhy'16)
 - [Reproduced bug](https://github.com/verivital/slsf_randgen/wiki/CyFuzz-Reproduced-Bug-in-Simulink)
 - [Sample Models](https://github.com/verivital/slsf_randgen/wiki/Sample-random-models-generated-by-CyFuzz) 

## Git Branches

We welcome new contributors! Please be familiar with different git branches. Development branch is `random-generation` where you can find latest code. Stable code can be found in `master`.

Other temporary branches:

 - *(Csmith related)*  `csmith-integration` branch

## Running the prototype

Please check out the [slsf/Readme.md](slsf/Readme.md) file to learn how to 
run the tool.

### Requirements

 - Python3 (Python2 might not work). Also require Linux to run the Python scripts, as I've not tested them in other platforms. 
 - csmith (see below for instructions)
 - Matlab with Simulink. Matlab scripts can be run from either Windows or Linux (as tested so far).

### Building and installing csmith (required if you want to create custom models)

 - Please clone source code from (customized Csmith)[ttps://github.com/shafiul/csmith].
 - To build csmith, follow official doc at https://embed.cs.utah.edu/csmith/
 - You need `m4` library in Ubuntu
 - Once built, the csmith binary is located inside `src` directory.
 - We have to ensure csmith executable and `include` directory is in OS path (see below). 

### Set up environment variables (in Linux)

Please note that we need both `csmith` and `matlab` executables in our path.

    export CSMITH_PATH=/path/to/csmith
    export PATH=$PATH:/$CSMITH_PATH/src:path/to/matlab/binary
    export C_INCLUDE_PATH=$CSMITH_PATH/runtime
    export CSMITH_HOME=$CSMITH_PATH # Needed for running csmith test driver

## Acknowledgement

This material is based upon work supported by the National Science Foundation under Grants No. 1117369, 1464311, and 1527398. Any opinions, findings, and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation.
