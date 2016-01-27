# Simulink Random generator

## How to use
Run sgtest.m file

## Issues
General Issues

 - Algebraic Loop

### Block connecting
Connect ports randomly till all ports are connected

 - Throwing away chart if number of output ports > number of input ports
 - Block connection bug: Already used input port chosen (no more inputs?)
then do not use this output port, mark as used maybe

### Block Parameters
Randomly choose parameter values

 - Block parameters may result in invalid chart

### Simulation Warnings
These warnings were produced while simulating the chart

 - 'sampleModel1/bl4/LimitedCounter/Output' is discrete, yet is inheriting a continuous sample time