# Random Generation and Comparison of Simulink models

This directory contains scripts regarding *Csmith* integration. The 
actual Simulink random generator (aka *CyFuzz*) is located under `slsf` 
folder. Check out the [slsf/Readme.md](slsf/Readme.md) file to learn how to 
run the tool.

Rest of the contents in this file is related to *Csmith* integration

## Git Branches

 - *(CyFuzz implementation)* Development branch is `random-generation` where you can find latest code. Stable code can be found in `master`.
 - *(Csmith related)* Code without "multiple main functions" feature can be found in `csmith-integration` branch
 - *(Csmith related)* Code with the feature of generating multiple `main` functions can be found in `multi-main` branch

## Structure

 - All random genration and comparison code is located under `slsf` directory.
 - This folder contains scripts for experimenting with *Csmith*

# Experiments with Csmith

## Issues/TODO (warning: this section may be outdated)

 - Try out different *compilers* (not just different optimization flags) 
and optimization flags to eventually check "Wrong Code" (as mentioned by 
csmith work - when run time output of same source 
file is different changing compilers and optimization levels due to 
compiler bug).
 - Figure out how to calculate "checksum" (this is how csmith checks "wrong
code") for our case. This will incorporate both Simulink/Matlab variables and 
C-variables in the checksum generation procedure.

## How to run

 - Call `run.py` from your shell.
 - We can tune some options (number of loops to run, whether to call csmith etc) by changing the options located at the top of `testrun.m` file.

## Set-up

 - Python3 (for running the scripts I've written)
 - csmith (see below for instructions)
 - Matlab with Simulink 

### Building and installing csmith

 - First clone source from https://github.com/shafiul/csmith
 - To build csmith, follow official doc at https://embed.cs.utah.edu/csmith/
 - You need `m4` library in Ubuntu
 - Once built, the csmith binary is located inside `src` directory.
 - We have to ensure csmith executable and `include` directory is in OS path (see below). 

### Set up environment variables

In linux, we can set up this way. Please note that we need both `csmith` and `matlab` executables in our path.

    export CSMITH_PATH=/path/to/csmith
    export PATH=$PATH:/$CSMITH_PATH/src:path/to/matlab/binary
    export C_INCLUDE_PATH=$CSMITH_PATH/runtime
    export CSMITH_HOME=$CSMITH_PATH # Needed for running csmith test driver

Thank You :-)
