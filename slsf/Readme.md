# Simulink Random generator

## How to use
Run sgtest.m file

## Issues

Please note that this file is not updated, latest status can be found in our Github repo.

General Issues

 - Algebraic Loop: mostly handled.

### Block connecting
Connect ports randomly till all ports are connected

 - If number of output ports > number of input ports, then we can not 
connect any more. Stopping there. Shall we choose blocks will more input 
ports?
 - Block connection bug: Already used input port chosen (previous issue) - fixed.

### Block Parameters
Randomly choose parameter values. Using a database of chosen blocks,
can not infer parameter type yet.

 - Randomly chosen block parameters values may result in invalid chart
 - Manual process, only 2/3 parameters (blocks) are chosen now.


### Simulation Errors

 - Simulink:Engine:DerivNotFinite: An error occurred while running the simulation and the simulation was terminated

Derivative of state '1' in block 'sampleModel2/bl15' at time 0.0 is not finite. The simulation will be stopped. There may be a singularity in the solution.  If not, try reducing the step size (either by reducing the fixed step size or by tightening the error tolerances)

 - Simulink:Engine:DerivNotFinite: Problem is, script and simulation window becomes unresponsive and does not terminate
even after setting timeout function.

An error occurred while running the simulation and the simulation was terminated
Derivative of state '1' in block 'sampleModel3/bl16/Integrator' at time 4.4501477170144E-309 is not finite. The simulation will be stopped. There may be a singularity in the solution.  If not, try reducing the step size (either by reducing the fixed step size or by tightening the error tolerances)


 - Simulink:Engine:SolverConsecutiveZCNum: At time 3.1592930568844847E-27, simulation hits (1000) consecutive zero crossings. Consecutive zero crossings will slow down the simulation or cause the simulation to hang. To continue the simulation, you may 1) Try using Adaptive zero-crossing detection algorithm or 2) Disable the zero crossing of the blocks shown in the following table. 
for block SecondOrderIntegrator

 - Simulink:Engine:AlgStateNotFinite: Algebraic state in algebraic loop containing 'sampleModel1/bl29/Sum3' computed at time 6.9084165788892849E-17 is Inf or NaN.  There may be a singularity in the solution.  If the model is correct, try reducing the step size (either by reducing the fixed step size or by tightening the error tolerances)
SOLVABLE after adding delay block at output


### Simulation Warnings
These warnings were produced while simulating models

 - Unable to reduce the step size without violating minimum step size of 2.2250738585072014E-308 for 1 consecutive times at time 2.2250738585072014E-308.  Continuing simulation with the step size restricted to 2.2250738585072014E-308 and using an effective relative error tolerance of 0.0013562559694364864, which is greater than the specified relative error tolerance of 0.001. This usually may be caused by the high stiffness of the system. Please check the model 'sampleModel1' or increase the Max consecutive min step size violation parameter in the solver configuration panel

 - 'sampleModel1/bl4/LimitedCounter/Output' is discrete, yet is inheriting a continuous sample time

 - Warning: Overriding parameters of 'sampleModel1/bl1/Delay Input' which is inside a library link. These changes can be
changed, propagated, or viewed using the 'Library Link' menu item 