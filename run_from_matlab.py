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
import shutil
from runcmd import RunCmd

TIMEOUT = 10  # The generated C program is allowed this much seconds to terminate.

class Multi_RandC_Generator():
    """
        Generate multiple random c programs
    """

    def __init__(self, num_programs):
        self._num_programs = num_programs

        # options
        self.PREFIX = 'slsf'
        self.CSMITH_ARGS = [
            'csmith', '--no-unions', '--no-structs', '--suffix-main', '--no-argc'
        ]

        # Internal variables
        self._main_func = 'int main(void){\n  static int top=0;\n  switch (top){\n'

    def _generate_multi(self):

        shutil.copy('ee_pre.c', 'randgen.c') # Clears everything from randgen.c

        for i in range(self._num_programs):
            single_terminating_file = self._generate_single(i)
            self._append('randgen.c', single_terminating_file)

            self._main_func += '    case ' + str(i) + ':\n      printf("(c) Calling main %d\\n",top);\n      main_' + self.PREFIX + str(i) + '();\n      top++;\n      break;\n'

        self._finish_main('randgen.c')

    def _finish_main(self, big_file):
        self._main_func += '    default:\n      printf("(c) NOT CALLING ANY MAIN!\\n");\n      break;\n    }\n  return 0;\n}'

        with open(big_file, 'a') as outfile:
            outfile.write(self._main_func)

    def _generate_single(self, file_index):

        while True:

            current_args = list(self.CSMITH_ARGS)       # Shallow copy is sufficient
            main_prefix = '{0}{1}'.format(self.PREFIX, file_index)

            print('Trying with this main prefix: {}'.format(main_prefix))

            current_args.extend(('--globals-prefix', main_prefix))

            current_file_name = 'current.c'

            with open(current_file_name, 'w') as current_write:
                with subprocess.Popen(current_args, stdout=current_write) as c_p:
                    c_p.wait()

            print('[!] current.c Generated! Now check for termination...') 
            
            compilable = self._add_main(main_prefix, current_file_name)

            # Check for termination

            if self._terminates(compilable):
                print('Terminated!')
                break
            else:
                print('Not terminated, continue...')

        return current_file_name

    def _add_main(self, main_suffix, input_file):
        target_file = 'c_with_main.c'
        shutil.copy(input_file, target_file)

        with open(target_file, 'a') as f:
            f.write('\nint main(void){\n return main_' + main_suffix + '(); \n}');

        return target_file

    def _terminates(self, src_file_name):
        executable = 'c_with_main'
        with subprocess.Popen(('gcc', '-w', '-o', executable, src_file_name) ) as pr:
            pr.wait()

            print('Now running executable...')
            return RunCmd(('./{}'.format(executable),), TIMEOUT).go()

    def go(self):
        self._generate_multi()
        copy_files()

    def _append(self, big_file, little_file):
        with open(big_file, 'a') as outfile:
            with open(little_file, 'r') as infile:
                for line in infile:
                    outfile.write(line)

                outfile.write('\r\n')


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


# try:

    # print('[x] Calling csmith')
    # p_cs = subprocess.call('csmith --easy-x --no-argc > randgen.c', shell=True)
    # print('[x] End csmith')


#     p_gcc = subprocess.call('gcc randgen.c -o randgen', shell=True)

#     # Does the program terminate?

#     p_randgen = subprocess.call('./randgen', timeout=TIMEOUT )
#     #print('Randgen p id: {0}'.format(p_randgen.pid))

#     # Copy randgen.c and ee_post.c together into one file

#     copy_files()
# except Exception as e:
#     print('Exception Occurred, returning error code: {0}'.format(e))
#     sys.exit(100)
# finally:
#     #os.killpg(p_cs.pid, signal.SIGTERM) 
#     #os.killpg(p_gcc.pid, signal.SIGTERM) 
#     #os.killpg(p_randgen.pid, signal.SIGTERM) 
#     pass
    

# print('[x] Returning successfully from python script');
# sys.exit(0)

Multi_RandC_Generator(5).go()

print('--DONE--')
