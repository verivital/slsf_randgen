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

from runcmd import RunCmd, CrashedWhileTerminationCheck
from pro_csmith import ProCSmith

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

        # In some Ubuntu (e.g. 16.04) there is problem when using Matlab's libstdc. As a workaround, we have to 
        # use the system's libstdc. Use command `locate libstdc++.so` to know the path. If not found, use
        # `sudo apt-get install libstdc++6` to install.
        # If not needed, set to None.
        self.path_to_libstd = '/usr/lib/x86_64-linux-gnu/libstdc++.so.6'

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
        # Use this function to generate multiple main functions
        self._generate_multi()
        copy_files()

    def go_pro(self):
        # Use this function to generate ONE main function that can be safely called over and over
        print('Inside Go_PRO....')
        current_file_name = 'current.c'
        
        while True:

            with open(current_file_name, 'w') as current_write:

                old_env = None

                if self.path_to_libstd is not None:
                    try:
                        old_env = os.environ['LD_LIBRARY_PATH']
                        print('Changing env LD_LIBRARY_PATH. OLD env: {}\nNEW env: {}'.format(old_env, self.path_to_libstd))
                        os.environ['LD_LIBRARY_PATH'] = self.path_to_libstd
                    except Exception:
                        pass
                # else:
                #     print('Not setting ld environment')
                    
                # with subprocess.Popen(('./mycsmith.sh'), stdout=current_write, shell=True) as c_p:
                with subprocess.Popen(('csmith', '--no-structs', '--no-unions', '--no-arrays', '--no-argc'), stdout=current_write) as c_p:
                    c_p.wait()

                if old_env is not None:
                    os.environ['LD_LIBRARY_PATH'] = old_env

            print('[!] current.c Generated! Now check for termination...') 
            
            # Check for termination

            try:

                if self._terminates(current_file_name):
                    print('Terminated!')
                    break
                else:
                    print('Not terminated, continue...')
            except CrashedWhileTerminationCheck:
                print('Fatal: Program crashed while checking termination')
                sys.exit(-2) 


        # processed_file = 'randgen.c'
        pc = ProCSmith(current_file_name, None)

        pc.parse()

        copy_files_pro(pc)



    def _append(self, big_file, little_file):
        with open(big_file, 'a') as outfile:
            with open(little_file, 'r') as infile:
                for line in infile:
                    outfile.write(line)

                outfile.write('\r\n')


p_randgen = None

def copy_files_pro(processor):
    """
        Used to concat multiple files into one single file
    """
    filenames = ['ee_post.c']
    with open('staticsfun.c', 'w') as outfile:

        outfile.write(processor.get_output())

        for fname in filenames:
            with open(fname) as infile:
                for line in infile:
                    outfile.write(line)

        outfile.write(processor.create_mdlOutputs())

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

try:
    Multi_RandC_Generator(1).go_pro()

    print('--DONE--')
except Exception as e:
    print('Exception in run_from_matlab.py: {}'.format(e));
    sys.exit(-1) 
