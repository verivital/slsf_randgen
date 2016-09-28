#!/usr/bin/env python3
import random
import re

class Var:
    """docstring for Var
    """
    def __init__(self, v_name):
        self.v_name = v_name

    def __repr__(self):
        return '{}'.format(self.v_name)



class ProCSmith:
    """
        For post-processing Csmith generated C code
    """

    candidate_inputs = []
    candidate_outputs = []

    num_s_inputs = 1
    num_s_outputs = 1

    _my_input = None
    _my_output = ''
    _my_output_file = None

    _globals_initializer_body = ''

    _globals_started = False

    initialize_globals_in_main = False

    _main_started = False

    _p = re.compile(r'    transparent_crc\(([^,]*),')

    def __init__(self, csmith_output_file, my_output_file):
        self._my_input = csmith_output_file
        self._my_output_file = my_output_file


    def go(self):
        self.parse()
        self.write_op()


    def parse(self):
        with open(self._my_input, 'r') as infile:
            for line in infile:
                if line.startswith('/* --- GLOBAL VARIABLES --- */'):
                    self._globals_started = True
                    self._my_output += line

                elif line.startswith('/* --- FORWARD DECLARATIONS --- */'):
                    self._globals_started = False
                    self._my_output += 'void init_globals(void){\n    printf("Initializing...\\n");\n' + self._globals_initializer_body + '    printf("End of init\\n");\n}\n'

                    self._my_output += line
                elif self.initialize_globals_in_main and line.strip().startswith('int print_hash_value = 0;'):
                    self._my_output += '    init_globals();\n' + line
                else:
                    self._process_line(line)

    def _process_line_for_candidate_outputs(self, line):
        

        if not self._main_started:
            if line.startswith('int main (void)'):
                self._main_started = True

            return

        m = self._p.match(line)

        if m is None:
            return

        self.candidate_outputs.append(Var(m.group(1)))



    def _process_line(self, line):

        if line == '\n':
            self._my_output += line
            return
        elif not self._globals_started:
            self._my_output += line
            self._process_line_for_candidate_outputs(line)
            return

        # Handle Globals declaration

        tokens = line.split('=')
        left_side_tokens = tokens[0].split(' ')

        if 'const' in left_side_tokens:
            self._my_output += line
            return
        
        # print('tokens...')
        # print((tokens[0].split(' '))[-2])

        # The variable's name is in left_side_tokens[-2]

        this_var_name = left_side_tokens[-2].strip('*')

        self._globals_initializer_body += '    ' + this_var_name + ' = ' + tokens[1]
        self._my_output += tokens[0] + ';\n'

        # Add in candidate list for S-function's inputs

        # Avoid pointers - check if we have '*' in the characters till the variable's name
        line_till_varname = ' '.join(left_side_tokens[:-2])
        to_avoid = ('*', 'int64')

        if any(_ in line_till_varname for _ in to_avoid):
            print('Avoiding {} for candidate input'.format(left_side_tokens))
            return

        self.candidate_inputs.append(Var(this_var_name))

    def _get_random_var(self, var_list):
        return var_list[random.randint(0, len(var_list) - 1)].v_name   


    def create_mdlOutputs(self):
        ret = """
static void mdlOutputs(SimStruct *S, int_T tid)
{
    int_T             i;
    InputRealPtrsType uPtrs = ssGetInputPortRealSignalPtrs(S,0);
    real_T            *y    = ssGetOutputPortRealSignal(S,0);
    int_T             width = ssGetOutputPortWidth(S,0);
"""

        ret += '  init_globals();\n'

        # We don't support multi width yet.

        # Input

        ret += '  ' + self._get_random_var(self.candidate_outputs) + ' = (int) *uPtrs[0];\n'

        # Call main

        ret += '  main();\n'

        # Get Output

        ret += '  *y = ' + self._get_random_var(self.candidate_outputs) + '; \n'

        # Closing boilerplate

        ret += """
} /* closing mdlOutputs */

#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
"""


        return ret

    def get_output(self):
        return self._my_output

    def write_op(self):
        with open(self._my_output_file, 'w') as outfile:
            outfile.write(self._my_output)



if __name__ == '__main__':
    print('---------- FROM PRO-CSMITH MAIN -------------')
    pc = ProCSmith('in.c', 'out.c')
    pc.go()
    print(pc.candidate_inputs)
    print('-- Outputs --')
    print(pc.candidate_outputs)
    print(pc.create_mdlOutputs())
    print('DONE')
    exit()

    import subprocess
    import sys
    import os
    import signal
    import shutil
    from runcmd import RunCmd



    NUM_TESTS  = 0

    current_file_name = 'temptestprocsmith.c'
    pro_file_name = 'pro_output.c'
    executable = 'temptestprocsmith.out'
    TIMEOUT = 10

    for i in range(NUM_TESTS):
        print('Test {}'.format(i))

        checksum = None
        checksum2 = None

        # Run Csmith

        with open(current_file_name, 'w') as current_write:
            with subprocess.Popen(('csmith', '--no-structs', '--no-unions', '--no-arrays', '--no-argc'), stdout=current_write) as c_pp:
                # pass
                c_pp.wait()
        
        # Compile. Terminates?

        with subprocess.Popen(('gcc', '-w', '-o', executable, current_file_name)) as pr:
            pr.wait()

            print('Termination test...')
            if not RunCmd(('./{}'.format(executable),), TIMEOUT).go():
                print('...DOES NOT TERMINATE! CONTINUE...')
                continue 

        # Get output value

        with subprocess.Popen('./' + executable, stdout=subprocess.PIPE, shell=True) as c_p:
            for lines in c_p.stdout:
                line = lines.decode("utf-8")
                # print('[x]>' + line)
                checksum = line
            c_p.wait()

        # Run ProCsmith
        ProCSmith(current_file_name, pro_file_name).go()

        # Compile. Terminates?


        with subprocess.Popen(('gcc', '-w', '-o', executable, pro_file_name)) as pr:
            pr.wait()

            print('Termination test (2)...')
            if not RunCmd(('./{}'.format(executable),), TIMEOUT).go():
                print('...DOES NOT TERMINATE! Error!!...')
                exit(-1)

        # Get output value

        with subprocess.Popen('./' + executable, stdout=subprocess.PIPE, shell=True) as c_p:
            for lines in c_p.stdout:
                line = lines.decode("utf-8")
                # print('[x]>' + line)
                checksum2 = line
            c_p.wait()

        if checksum != checksum2:
            print('Error!!! Checksums not equal: {} vs {}'.format(checksum, checksum2))
            break
        else:
            print('Checksums equal: {} vs {}'.format(checksum, checksum2))




    print('End Test')