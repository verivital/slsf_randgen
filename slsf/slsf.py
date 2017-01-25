#!/usr/bin/env python3

import subprocess
import threading

import os
import shutil
from datetime import datetime
import time

# Options

OPT_NUM_RUN = 1
OPT_SINGLE_MODEL_TIMEOUT = 600

# You can configure more options in slsf/sgtest.m file.

is_killed = False
lock_is_killed = threading.Lock()

prev_run_crashed = False # Whether previous run of sgtest crashed


# class MyTimer(threading.Thread):

#     prev_mdl_count = None
#     p = None

#     def __init__(self, p):
#         threading.Thread.__init__(self)
#         # try:
#         global model_count
#         self.prev_mdl_count = model_count
#         self.p = p
#         # except Exception as e:
#         #     print('Exception in INIT: {}'.format(e))

        
def ml_timer(p):
    
    global is_killed, lock_is_killed

    print('MyTimer: Running!');
    # time.sleep(20)
    # print('MyTimer: End Timer....');

    if p.poll() is None:
        with lock_is_killed:
            is_killed = True

        print('ML TIMER: Still running prev model. Kill it')
        p.kill()
    else:
        print('WEIRD: Timer is running but process terminated!')





def run_tests():
    """
        This is the entry-point of running all sorts of test in our project.
    """

    global is_killed, lock_is_killed
    mt = None

    try:
        for _ in range(OPT_NUM_RUN):
            try:
                print('............................ Python Script: Starting Matlab ............................')

                matlab_skip_first = 'false'

                with lock_is_killed:
                    if is_killed:
                        print('Previous Matlab instance was killed. Skip the first run.')
                        matlab_skip_first = 'true'
                        is_killed = False



                # with open('sgtest.m') as matlab_script:
                with subprocess.Popen(['matlab', '-nodesktop', '-nosplash', "-r 'sgtest(" + matlab_skip_first + ");quit();'"], stdout=subprocess.PIPE, shell=False) as p_ml:
            
                    for line in p_ml.stdout:
                        linez = line.decode("utf-8")

                        if linez.startswith('CyFuzz::NewRun'):

                            print('!!! New Run!!')


                            # Stop previous timer
                            if mt is not None:
                                try:
                                    mt.cancel()
                                except Exception as e:
                                    print('Exception while trying to cancel trimer: {}'.format(e))

                            
                            print('Setting up timer....');
                            mt = threading.Timer(OPT_SINGLE_MODEL_TIMEOUT, ml_timer, (p_ml,))
                            mt.start()

                        print (linez)
                    
                    p_ml.wait()  # Call this to get the returncode correctly.


                    if mt is not None:
                        try:
                            mt.cancel()
                            mt = None
                        except Exception as e:
                            print('Exception while trying to cancel timer at the end: {}'.format(e))


                    print('[Matlab Exit] return code: {}'.format(p_ml.returncode))

                    if p_ml.returncode == 0:
                        prev_run_crashed = True
                    else:
                        with lock_is_killed:
                            if not is_killed:
                                print('(!!!) Matlab crash detected (!!!)')

                                if prev_run_crashed:
                                    print('CONSECUTIVE CRASHES!!!')
                                    # backup_crasher()

            except Exception as e:
                print('(!) Exception Occurred in slsf.py MAIN LOOP: {0}'.format(e))
            # print('python script: next run...')
            # time.sleep(5)
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
