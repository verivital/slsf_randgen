num_run = 100000;    % Number of times the loop will run
gen_random_c = true; % Will Call csmith if set to `true`

gcc_opt_flags = {'-O0', '-O1', '-O2', '-O3', '-Os'};

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
        disp('[!] Csmith was NOT called.');
    end
    
    previous_checksum = '';
    
    for i=gcc_opt_flags
        disp(i{1})
        
        eval(strcat('mex CFLAGS="\$CFLAGS -std=gnu99 -w" COPTIMFLAGS="', i{1}, '" staticsfun.c;'));
    
        disp('Now Calling our Model...');
        sim staticmodel

        % Read checksum from file
        try
            fileID = fopen('checksum.txt','r');
            ch_from_file = fscanf(fileID,'%s');
            fclose(fileID);

            %disp('This is checksum from file...');
            disp(ch_from_file);

            if ~ isempty(previous_checksum)
                if ~ strcmp(previous_checksum, ch_from_file)
                    disp(strcat('[!!!] CH Mismatch! Previous: ', previous_checksum, '; Current: ', ch_from_file));
                    
                    copyfile('randgen.c', strcat('errors/', previous_checksum, '.c'));
                    
                    % End for now. TODO: Save the error-causing file
                    num_run = 0;
                    break;
                end
            end
            previous_checksum = ch_from_file;
            
        catch e
            disp('[!!!] Exception while comparing checksum. Continue...');
            fclose(fileID);
            continue;
        end
            
    end
    
end

