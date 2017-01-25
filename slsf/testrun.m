num_run = 1;    % Number of times the outer loop will run
gen_random_c = false; % Will generate a random c code using csmith if set to `true`

% gcc_opt_flags = {'-O0', '-O1', '-O2', '-O3', '-Os'}; % We will build using these compiler opt flags
gcc_opt_flags = {'-O0'}; % We will build using these compiler opt flags


while num_run > 0
    disp(num_run);
    num_run = num_run - 1;
    
    % Generate a csmith program and check whether it terminates
    if gen_random_c
        disp('Calling csmith...');
        [status, cmdout] = system('./csmith_gen.py --sfname staticsfun.c');
        
        cmdout

        if status ~= 0
            disp('[!] Skipping this run as does not terminate.');
%             cmdout
%             continue;
            break; % Just for curiocity
        end

        disp('csmith returned terminating program.')
    else
        disp('[~] csmith was NOT called.');
    end
    
    previous_checksum = '';
    
    for i=gcc_opt_flags
        disp(i{1})
        
        eval(strcat('mex CFLAGS="\$CFLAGS -std=gnu99 -w" COPTIMFLAGS="', i{1}, '" staticsfun.c;'));
    
        disp('... Calling Simulink Model ...');
        sim staticmodel;
        fprintf('Returned from Simulink Model...\n');

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

% quit;