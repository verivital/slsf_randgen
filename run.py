#!/usr/bin/env python3

import subprocess
import os
import shutil
from datetime import datetime

OPT_IGNORE_GCC_WARNING = True  # Discard the warning Matlab produces when using non-supported GCC
GCC_WARNING = 'Warning:'  # This message is produced by Matlab when using non-supported GCC


def run_tests():
    """
        This is the entry-point of running all sorts of test in our project.
    """
    try:
        while True:
            try:
                print('............................ Starting Matlab ............................')

                with open('testrun.m') as matlab_script:
                    with subprocess.Popen(['matlab', '-nodesktop', '-nosplash'], stdin=matlab_script, stdout=subprocess.PIPE, shell=False) as p_ml:
                
                        for line in p_ml.stdout:
                            line = line.decode("utf-8") 

                            if OPT_IGNORE_GCC_WARNING and line.startswith(GCC_WARNING): # Not working, weird
                                pass
                            else:
                                print (line)
                        
                        p_ml.wait()  # Call this to get the returncode correctly.
                        print('[Matlab Exit] return code: {}'.format(p_ml.returncode))

                        if p_ml.returncode != 0:
                            print('(!!!) Matlab crash detected (!!!)')
                            backup_crasher()

            except Exception as e:
                print('(!) Exception Occurred in main tester loop: {0}'.format(e))
    except KeyboardInterrupt as ke:
        print('(-/-) Interrupted by user, quiting.')


def backup_crasher():
    """ Back-up the generated codes responsible for the crash """

    dir_to_create = datetime.now().strftime("%Y-%m-%d-%H-%M-%S-%f")
    script_dir = os.path.dirname(os.path.realpath(__file__))

    dir_to_create_full_path = os.path.join(script_dir, 'crash', dir_to_create)

    try:
        if os.path.exists(dir_to_create_full_path):
            print('(!) Directory {} already exists!'.format(dir_to_create_full_path))
        else:
            os.mkdir(dir_to_create_full_path)
    except Exception as e:
        print('Failed creating dir: {0}'.format(dir_to_create_full_path))
        print('Exception: {}'.format(e))
        return False

    try:
        shutil.copy('randgen.c', dir_to_create_full_path)
        shutil.copy('staticsfun.c', dir_to_create_full_path)
        shutil.copy('ee_pre.c', dir_to_create_full_path)
        shutil.copy('ee_post.c', dir_to_create_full_path)
    except Exception as e:
        print('Error copying one or more files: {}'.format(e))
        return False

    return True


if __name__ == '__main__':
    run_tests()