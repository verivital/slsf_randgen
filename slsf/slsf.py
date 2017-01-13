#!/usr/bin/env python3

import subprocess
import threading

import os
import shutil
from datetime import datetime
import time

# Options

OPT_NUM_RUN = 1

# You can configure more options in slsf/sgtest.m file.

model_count = 0
lock_model_count = threading.Lock()


class MyTimer(threading.Thread):

    prev_mdl_count = None
    p = None

    def __init__(self, p):
        threading.Thread.__init__(self)
        # try:
        global model_count
        self.prev_mdl_count = model_count
        self.p = p
        # except Exception as e:
        #     print('Exception in INIT: {}'.format(e))

        
    def run(self):
        # try:
        print('MyTimer: Starting...');
        time.sleep(20)
        print('MyTimer: End Timer....');

        global model_count

        if model_count == self.prev_mdl_count:
            print('Still running prev. Kill it');
            self.p.kill()
        else:
            print('Not running prev. Do nothing');
        # except Exception as e:
        #     print('Exception in RUN: {}'.format(e))


    # def go(self):
        
    #     self.start()
    #     self.join(self.timeout)
        

    #     if self.is_alive():
    #         # self.p.terminate()      #use self.p.kill() if process needs a kill -9
    #         self.p.kill()
    #         self.join()
    #         print('..Does not Terminate..')
    #         return False
        
    #     # print('..Terminates!..')

    #     if self.p is None or self.p.returncode != 0:
    #         raise CrashedWhileTerminationCheck();
        
    #     return True


def run_tests():
    """
        This is the entry-point of running all sorts of test in our project.
    """

    global model_count
    mt = None

    try:
        for _ in range(OPT_NUM_RUN):
            try:
                print('............................ Starting Matlab ............................')

                with open('sgtest.m') as matlab_script:
                    with subprocess.Popen(['matlab', '-nodesktop', '-nosplash'], stdin=matlab_script, stdout=subprocess.PIPE, shell=False) as p_ml:
                
                        for line in p_ml.stdout:
                            linez = line.decode("utf-8")
                            if linez.startswith('CyFuzz::NewRun'):

                                print('!!! New Run!!')

                                with lock_model_count:
                                    model_count = model_count + 1
                                
                                print('before calling timer....');
                                mt = MyTimer(p_ml)
                                mt.start()
                                # mt.join()

                            print (linez)
                        
                        p_ml.wait()  # Call this to get the returncode correctly.
                        print('[Matlab Exit] return code: {}'.format(p_ml.returncode))

                        if p_ml.returncode != 0:
                            print('(!!!) Matlab crash detected (!!!)')
                            # backup_crasher()

            except Exception as e:
                print('(!) Exception Occurred in main tester loop: {0}'.format(e))
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
