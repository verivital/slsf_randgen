#! /usr/bin/env python3

import subprocess
import sys
import os
import signal

TIMEOUT = 10

p_randgen = None

try:

    print('[x] Calling csmith')
    p_cs = subprocess.call('csmith --no-argc > randgen.c', shell=True)
    print('[x] End csmith');

    p_gcc = subprocess.call('gcc randgen.c -o randgen', shell=True)

    # Does the program terminate?

    p_randgen = subprocess.call('./randgen', timeout=TIMEOUT )
    #print('Randgen p id: {0}'.format(p_randgen.pid))
except Exception as e:
    print('Exception Occurred, returning error code: {0}'.format(e));
    sys.exit(100);
finally:
    #os.killpg(p_cs.pid, signal.SIGTERM) 
    #os.killpg(p_gcc.pid, signal.SIGTERM) 
    #os.killpg(p_randgen.pid, signal.SIGTERM) 
    pass
    

print('[x] Returning successfully from python script');
sys.exit(0)