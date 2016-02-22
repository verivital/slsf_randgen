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


### Simulation Errors

 - Simulink:Engine:DerivNotFinite: An error occurred while running the simulation and the simulation was terminated

Derivative of state '1' in block 'sampleModel2/bl15' at time 0.0 is not finite. The simulation will be stopped. There may be a singularity in the solution.  If not, try reducing the step size (either by reducing the fixed step size or by tightening the error tolerances)

 - Simulink:Engine:DerivNotFinite: Problem is, script and simulation window becomes unresponsive and does not terminate
even after timeout.

An error occurred while running the simulation and the simulation was terminated
Derivative of state '1' in block 'sampleModel3/bl16/Integrator' at time 4.4501477170144E-309 is not finite. The simulation will be stopped. There may be a singularity in the solution.  If not, try reducing the step size (either by reducing the fixed step size or by tightening the error tolerances)


 - Simulink:Engine:SolverConsecutiveZCNum: At time 3.1592930568844847E-27, simulation hits (1000) consecutive zero crossings. Consecutive zero crossings will slow down the simulation or cause the simulation to hang. To continue the simulation, you may 1) Try using Adaptive zero-crossing detection algorithm or 2) Disable the zero crossing of the blocks shown in the following table. 
for block SecondOrderIntegrator

 - MATLAB:MException:MultipleErrors - Data Type Mismatch: Only 'single' or 'double' signals are accepted by block type DiscreteZeroPole.  The signals at the ports of 'sampleModel2/bl7' are of data type 'SlDemoSign'.

 - Simulink:Engine:InvCompDiscSampleTime: 'The sample time after propagation is [0, 0]. 
Enter a discrete sample time in 'sampleModel1/bl12'.

### Simulation Warnings
These warnings were produced while simulating the chart

 - 'sampleModel1/bl4/LimitedCounter/Output' is discrete, yet is inheriting a continuous sample time

 - Warning: Overriding parameters of 'sampleModel1/bl1/Delay Input' which is inside a library link. These changes can be
changed, propagated, or viewed using the 'Library Link' menu item 