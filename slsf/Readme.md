# CyFuzz Implementation for Simulink

Simulink model random generator and compare. All code are in this directory
(slsf)

## Running from Matlab
Run `sgtest.m` script from Matlab (tested on `R2015a`). 
Works in Windows and Linux (Ubuntu 14.04, 15.04)

On the top of `sgtest.m` file you will see plenty of configuraiton options. 
Each option has a comment explaining what it does.

For configuring Simulink blocks and their weights, edit `blockchooser.m`

## Running from Shell (Linux only)

Run the Python3 script `slsf.py` which actually calls `sgtest.m` file. 
Sometimes, Matlab crashes when running `sgtest.m` directly from Matlab. If 
you run `slsf.py` instead, it detects such crashes and re-opens Matlab and 
run `sgtest.m` file.

There are some configuration options at the top of `slsf.py` script too.

This Python script does not run in Windows, I've not investigated why yet.

## Viewing Reports

After you've generated some models and run test, you can view statistics 
and reports using function `getreport`. Pass the date from which you want 
to generate reports. Example usage: `getreport('2016-01-13-00-00-00');`

After each run of `sgtest.m`, one Matlab data file containing reports is 
permanently stored in `reports` directory. You can also save all the 
randomly generated models in this directory.

