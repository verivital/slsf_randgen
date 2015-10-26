num_run = 1;    % Number of times the loop will run
gen_random_c = false;

while num_run > 0
    disp(num_run);
    num_run = num_run - 1;
    
    % Generate a csmith program and check whether it terminates
    if gen_random_c
        [status, cmdout] = system('./run_from_matlab.py');

        if status ~= 0
            disp('[!] Skipping this run as does not terminate.');
            continue;
        end
    else
        disp('Csmith was not called.');
    end
    
    eval('mex CFLAGS="\$CFLAGS -std=gnu99 -w -O2" staticsfun.c;');
    
    disp('Now Calling our Model...');
    sim staticmodel
    
    % Read checksum from file
    fileID = fopen('checksum.txt','r');
    ch_from_file = fscanf(fileID,'%s');

    disp('This is checksum from file...');
    disp(ch_from_file);

    % Code to compare checksum
    %pre_cz = '6B7EA765';
    %res = strcmp(pre_cz, ch_from_file);
    %disp('This is result...');
    %disp(res)
    
end

