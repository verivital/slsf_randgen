# Simulink Random generator

## How to use
Run sgtest.m file

## Issues
General Issues

 - Algebraic Loop: not handled yet

### Block connecting
Connect ports randomly till all ports are connected

 - If number of output ports > number of input ports, then we can not 
connect any more. Stopping there. Shall we choose blocks will more input 
ports?
 - Block connection bug: Already used input port chosen (previous issue)

### Block Parameters
Randomly choose parameter values. Using a database of chosen blocks,
can not infer parameter type yet.

 - Randomly chosen block parameters values may result in invalid chart
 - Manual process, only 2/3 parameters (blocks) are chosen now.

### Simulation Warnings
These warnings were produced while simulating the chart

 - 'sampleModel1/bl4/LimitedCounter/Output' is discrete, yet is inheriting a continuous sample time