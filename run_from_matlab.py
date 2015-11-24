#! /usr/bin/env python3
"""
    Do not execute this script directly. This script will be exceuted by Matlab.

    When called (executed) by Matlab, this script will:

    1. Call csmith to generated a C program
    2. Build the generated program using GCC and then run it to determine if it terminates.
    3. Based on terminaion/non-termination of the program, a value is returned to Matlab.
    4. If the program terminates (in step 2), we concate the files 'randgen.c' and 'ee_post.c'
        into one single file 'staticsfun.c'
"""

import subprocess
import sys
import os
import signal

TIMEOUT = 10  # The generated C program is allowed this much seconds to terminate.

p_randgen = None

def copy_files():
    """
        Used to concat multiple files into one single file
    """
    filenames = ['randgen.c', 'ee_post.c']
    with open('staticsfun.c', 'w') as outfile:
        for fname in filenames:
            with open(fname) as infile:
                for line in infile:
                    outfile.write(line)


try:

    print('[x] Calling csmith')
    p_cs = subprocess.call('csmith --easy-x --no-argc > randgen.c', shell=True)
    print('[x] End csmith')

    p_gcc = subprocess.call('gcc randgen.c -o randgen', shell=True)

    # Does the program terminate?

    p_randgen = subprocess.call('./randgen', timeout=TIMEOUT )
    #print('Randgen p id: {0}'.format(p_randgen.pid))

    # Copy randgen.c and ee_post.c together into one file

    copy_files()
except Exception as e:
    print('Exception Occurred, returning error code: {0}'.format(e))
    sys.exit(100)
finally:
    #os.killpg(p_cs.pid, signal.SIGTERM) 
    #os.killpg(p_gcc.pid, signal.SIGTERM) 
    #os.killpg(p_randgen.pid, signal.SIGTERM) 
    pass
    

print('[x] Returning successfully from python script');
sys.exit(0)