import subprocess
import threading

class RunCmd(threading.Thread):

    p = None

    def __init__(self, cmd, timeout):
        threading.Thread.__init__(self)
        self.cmd = cmd
        self.timeout = timeout

    def run(self):
        self.p = subprocess.Popen(self.cmd)
        self.p.wait()

    def go(self):
        
        self.start()
        self.join(self.timeout)
        

        if self.is_alive():
            # self.p.terminate()      #use self.p.kill() if process needs a kill -9
            self.p.kill()
            self.join()
            print('..Does not Terminate..')
            return False
        
        # print('..Terminates!..')

        if self.p is None or self.p.returncode != 0:
            raise CrashedWhileTerminationCheck();
        
        return True



class CrashedWhileTerminationCheck(Exception):
    pass