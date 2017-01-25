#!/usr/bin/env python3
import random
import re
import unittest

OPT_NUM_MANY_MAINS = 500

class Var:
    """docstring for Var
    """
    def __init__(self, v_name):
        self.v_name = v_name

    def __repr__(self):
        return '{}'.format(self.v_name)



class ProCSmith:
    """
        A post-processor for Csmith-generated C code
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

    initialize_globals_in_main = False # Set to False if generating the mdlOutput function. We wish to initialize the globals explicitly in the mdlOutput function, before calling main.
    generate_many_mains = False  # If True, will generate many calls to main function -- use only for testing ProCsmith.

    _main_started = False

    _p = re.compile(r'    transparent_crc\(([^,]*),')

    def __init__(self, csmith_output_file, my_output_file):
        self._my_input = csmith_output_file
        self._my_output_file = my_output_file


    def go(self):
        # Note: currently we don't call this function. Only using it for testing ProCsmith.
        self.parse()
        self.write_op()


    def parse(self):
        with open(self._my_input, 'r') as infile:
            for line in infile:
                if line.startswith('/* --- GLOBAL VARIABLES --- */'):
                    # From this point we start handling the global variables.
                    self._globals_started = True
                    self._my_output += line

                elif line.startswith('/* --- FORWARD DECLARATIONS --- */'):
                    # End of global declarations in original Csmith-generated file.
                    self._globals_started = False
                    # We write the "init_globals" function now.
                    self._my_output += 'void init_globals(void){\n    /*printf("Initializing...\\n");*/\n' + self._globals_initializer_body + '    /*printf("End of init\\n");*/\n}\n'

                    self._my_output += line
                elif self.initialize_globals_in_main and line.strip().startswith('int print_hash_value = 0;'):
                    # CALL "init_globals" inside main() function [if instructed by setting initialize_globals_in_main to TRUE]
                    self._my_output += '    init_globals();\n' + line
                else:
                    self._process_line(line)

    def _process_line_for_candidate_outputs(self, line):
        """
            If this function has also written the line, then returns False.
            If this function returns True, then the caller has to write the line.
        """

        if not self._main_started:
            if line.startswith('int main (void)'):
                self._main_started = True

                if self.generate_many_mains:
                    self._my_output += 'int main1 (void)'
                    return False

            return True

        m = self._p.match(line)

        if m is None:
            return True

        self.candidate_outputs.append(Var(m.group(1)))

        return True



    def _process_line(self, line):

        if line == '\n':
            self._my_output += line
            return
        elif not self._globals_started:
            if self._process_line_for_candidate_outputs(line):
                self._my_output += line
            return

        # Handle Globals declaration

        tokens = line.split('=')
        left_side_tokens = tokens[0].split(' ')

        # Avoid pointers - check if we have '*' in the characters till the variable's name
        if '*' in tokens[0]:
            is_pointer = True
        else:
            is_pointer = False

        if 'const' in left_side_tokens:
            # Check whether this is a pointer
            # if is_pointer and left_side_tokens[-3] != 'const':
            # if is_pointer and left_side_tokens[1] == 'const':
            if is_pointer and (tokens[0].rfind('const') < tokens[0].rfind('*')):
                # Check whether this is an immutable pointer or just a pointer to an immutable (constant) variable
                # For the second case we need to initialize! 
                # http://stackoverflow.com/questions/10091825/constant-pointer-vs-pointer-on-a-constant-value
                # print('{} is not a true constant.'.format(line))
                pass
            else:
                self._my_output += line
                return
        
        # print('tokens...')

        # The variable's name is in left_side_tokens[-2]
        this_var_name = left_side_tokens[-2].strip('*')

        self._globals_initializer_body += '    ' + this_var_name + ' = ' + tokens[1]
        self._my_output += tokens[0] + ';\n'

        # Add in candidate list for S-function's inputs

        to_avoid = ('int64',) # Not sure why int64 is here?

        if is_pointer or any(_ in tokens[0] for _ in to_avoid):
            # print('Avoiding {} for candidate input. is_pointer: {}'.format(left_side_tokens, is_pointer))
            return

        self.candidate_inputs.append(Var(this_var_name))

    def _get_random_var(self, var_list):
        if len(var_list) == 0:
            return None

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
        rand_v = self._get_random_var(self.candidate_inputs)

        if rand_v is None:
            print('[[!]] NO Input variables available after processing!')
        else:
            ret += '  ' + rand_v + ' = (int) *uPtrs[0];\n'

        # Call main

        ret += '  main();\n'

        # Get Output

        rand_v = self._get_random_var(self.candidate_outputs);

        if rand_v is None:
            print('[[!]] NO Output variables available after processing! Assigning zero...')
            ret += '  *y = 0; \n'
        else:
            ret += '  *y = ' + rand_v + '; \n'

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

    def _get_many_mains(self):
        self._my_output += """
            int main (void){
                int i;
                for (i=0; i<""" + str(OPT_NUM_MANY_MAINS) + """; i++){
                    /*printf("Many Mains: %d\\n", i);*/
                    init_globals();
                    main1();
                }
            }
        """

    def write_op(self):

        if self.generate_many_mains:
            self._get_many_mains()

        with open(self._my_output_file, 'w') as outfile:
            outfile.write(self._my_output)


class TestPCSingle(unittest.TestCase):
    """
        Command to run this testcase: `python3 -m unittest pro_csmith.TestPCSingle`
    """
    
    def test_single(self):
        print('---------- FROM PRO-CSMITH SINGLE TEST -------------')
        pc = ProCSmith('current.c', 'out.c')
        pc.go()
        print('-- Inputs --')
        print(pc.candidate_inputs)
        print('-- Outputs --')
        print(pc.candidate_outputs)
        print('-- mdlOutputs --')
        print(pc.create_mdlOutputs())
        self.assertTrue(True)
    

class TestPCMany(unittest.TestCase):
    """
        Running automated tests for checking sanity of Csmith Post Processor.
    """

    def test_many(self):

        NUM_TESTS  = 1
        GENERATE_MANY_MAINS = True
        CREATE_NEW_C = False # To test existing file

        import subprocess
        import sys
        import os
        import signal
        import shutil
        from runcmd import RunCmd

        current_file_name = 'current.c'
        pro_file_name = 'pro_output.c'
        executable = 'temptestprocsmith.out'
        executable2 = 'temptestprocsmith2.out'
        
        TIMEOUT = 10

        num_nonterminate = 0

        for i in range(NUM_TESTS):
            print(' >>-- NEW TEST {} --<<'.format(i))

            checksum = None
            checksum2 = None

            # Run Csmith

            csmith_cmd = ('csmith', '--no-structs', '--no-unions', '--no-arrays', '--no-argc')

            # if GENERATE_MANY_MAINS:
            #     csmith_cmd = ('csmith', '--no-structs', '--no-unions', '--no-arrays', '--no-argc', '--easy-x', '--suffix-main', '1')

            
            if CREATE_NEW_C:
                with open(current_file_name, 'w') as current_write:
                    with subprocess.Popen(csmith_cmd, stdout=current_write) as c_pp:
                        c_pp.wait()
            else:
                print('CSMITH NOT CALLED!');            
            
            # Compile. Terminates?

            with subprocess.Popen(('gcc', '-std=gnu99', '-w', '-o', executable, current_file_name)) as pr:
                self.assertEqual(pr.wait(), 0)

                # print('Termination test...')
                if not RunCmd(('./{}'.format(executable),), TIMEOUT).go():
                    print('...DOES NOT TERMINATE! CONTINUE...')
                    num_nonterminate = num_nonterminate + 1
                    continue 

            # Get output value

            with subprocess.Popen('./' + executable, stdout=subprocess.PIPE, shell=True) as c_p:
                for lines in c_p.stdout:
                    line = lines.decode("utf-8")
                    # print('[x]>' + line)
                    checksum = line
                c_p.wait()

            # Run ProCsmith ################################################################################################

            pcs = ProCSmith(current_file_name, pro_file_name)
            pcs.initialize_globals_in_main = True

            if GENERATE_MANY_MAINS:
                pcs.initialize_globals_in_main = False;
                pcs.generate_many_mains = True;

            pcs.go()

            # Compile. Terminates?

            with subprocess.Popen(('gcc',  '-std=gnu99', '-w', '-o', executable2, pro_file_name)) as pr:
                self.assertEqual(pr.wait(), 0)

                # print('Termination test (2)...')
                if not RunCmd(('./{}'.format(executable2),), (TIMEOUT * (OPT_NUM_MANY_MAINS + 5) )).go():
                    print('...DOES NOT TERMINATE! Error!!...')
                    exit(-1)

            # Get output value

            with subprocess.Popen('./' + executable2, stdout=subprocess.PIPE, shell=True) as c_p:
                for lines in c_p.stdout:
                    line = lines.decode("utf-8")
                    # print('[x]>' + line)

                    if not line.startswith('checksum = '):
                        # print('no chksum');
                        continue
                    else:
                        # print('line with chksum. value: {}'.format(line));
                        pass

                    checksum2 = line

                    self.assertEqual(checksum, checksum2)

                c_p.wait()

            self.assertEqual(checksum, checksum2)

        print('--- End Test. Non-terminating: {} ---'.format(num_nonterminate))
