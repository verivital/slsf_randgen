#! /usr/bin/env python3

import subprocess
import sys

TIMEOUT = 10

try:

    print('[x] Calling csmith')
    subprocess.call('csmith --no-argc > randgen.c', shell=True)
    print('[x] End csmith');

    subprocess.call('gcc randgen.c -o randgen', shell=True)

    # Does the program terminate?

    subprocess.call('./randgen', shell=True, timeout=TIMEOUT )
except Exception as e:
    #print('Exception Occurred {0}'.format(e));
    print('Exception Occurred, returning error code.');
    sys.exit(100);

print('[x] Returning from python script');
sys.exit(0)