#!/usr/bin/env python3
import subprocess
import sys
import os
import signal
import shutil
from runcmd import RunCmd


class ProCSmith:
    """
        For post-processing Csmith generated C code
    """

    _my_input = None
    _my_output = ''
    _my_output_file = None

    _globals_initializer_body = ''

    _globals_started = False

    def __init__(self, csmith_output_file, my_output_file):
        self._my_input = csmith_output_file
        self._my_output_file = my_output_file


    def go(self):
        self._parse()
        self.write_op()


    def _parse(self):
        with open(self._my_input, 'r') as infile:
            for line in infile:
                if line.startswith('/* --- GLOBAL VARIABLES --- */'):
                    self._globals_started = True
                    self._my_output += line

                elif line.startswith('/* --- FORWARD DECLARATIONS --- */'):
                    self._globals_started = False
                    self._my_output += 'void init_globals(void){\n    printf("Initializing...\\n");\n' + self._globals_initializer_body + '    printf("End of init\\n");\n}\n'

                    self._my_output += line
                elif line.strip().startswith('int print_hash_value = 0;'):
                    self._my_output += '    init_globals();\n' + line
                else:
                    self._process_line(line)

    def _process_line(self, line):

        if not self._globals_started or line == '\n':
            self._my_output += line
            return

        # Handle Globals declaration

        tokens = line.split('=')
        left_side_tokens = tokens[0].split(' ')

        if 'const' in left_side_tokens:
            self._my_output += line
        else:
            # print('tokens...')
            # print((tokens[0].split(' '))[-2])
            self._globals_initializer_body += '    ' + left_side_tokens[-2].strip('*') + ' = ' + tokens[1]
            self._my_output += line.split('=')[0] + ';\n'



    def write_op(self):
        with open(self._my_output_file, 'w') as outfile:
            outfile.write(self._my_output)



if __name__ == '__main__':
    # print('---------- FROM PRO-CSMITH MAIN -------------')
    # ProCSmith('in.c', 'out.c').go()
    # print('DONE')
    # exit()



    NUM_TESTS  = 1

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