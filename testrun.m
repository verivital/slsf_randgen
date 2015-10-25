num_run = 1000;    % Number of times the loop will run

% Some vars for our S-function "randsfun" 
s=5;
A = [1.5, 2, 9];

while num_run > 0
    disp(num_run);
    num_run = num_run - 1;
    
    % Generate a csmith program and check whether it terminates
    [status, cmdout] = system('./run_from_matlab.py');
    
    if status ~= 0
        disp('[!] Skipping this run.');
        continue;
    end
    
    mex CFLAGS="\$CFLAGS -std=gnu99" staticsfun.c;
    
    disp('Now Calling our Model...');
    sim staticmodel
end

