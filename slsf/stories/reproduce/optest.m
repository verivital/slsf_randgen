disp('-- starting OPTEST script --');

sys = 'triggered';

modes = {'normal', 'rapid'};
% modes = {'normal', 'accelerator', 'rapid'};

last_run_time = [];
last_run_data = [];

num_run = 1;
num_time_mismatch = 0;
num_data_mismatch = 0;

for i = 1:num_run
    fprintf('Loop number %d', i);
    for j=1:numel(modes)

        disp(['[>>>] Mode: ' modes{j}]);

        open_system(sys);

        simOut = sim(sys, 'SimulationMode', modes{j});
        out_data = simOut.get('yout');

    %     out_data.signals.values
    %     out_data.signals.dimensions
    %     out_data.signals.label
    %     out_data.signals.blockName

        % Compare
        if j ~= 1
            fprintf('Comparing mode %s...\n', modes{j});
            if last_run_time ~= out_data.time
                fprintf('Time mismatch in mode %s.\n', modes{j});
                num_time_mismatch = num_time_mismatch + 1;
                
                disp('---------------- Previous Time ------------------');
                last_run_time
                disp('---------------- Current Time ------------------');
                out_data.time
            else
                fprintf(' time matched!\n');
            end



            if ~ outcompare(last_run_data, out_data.signals)
                fprintf('Data mismatch in mode %s.\n', modes{j});
                num_data_mismatch = num_data_mismatch + 1;
            else
                fprintf(' data matched!\n');
            end


        end

        % Store for next run

        last_run_time = out_data.time;
        last_run_data = out_data.signals;

        close_system(sys);

        % Cleanup
        delete([sys '_acc*']);
        try
            rmdir('slprj', 's');
        catch e
        end

    end
end

num_run
num_time_mismatch
num_data_mismatch

disp('--- end of script---');
