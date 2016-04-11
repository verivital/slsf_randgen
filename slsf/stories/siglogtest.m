disp('-- starting --');

sys = 'model1';
num_run = 10;

lens = cell(1, (num_run * 2));
modes = {'off', 'on'};

lens_index = 0;

for i = 1:num_run
    for j=modes
        
        disp(['NEW: i: ' int2str(i) '; optimization: ' j{1}]);
    
        open_system(sys);

        simOut = sim(sys, 'SimulationMode', 'accelerator', 'SimCompilerOptimization', j{1}, 'SignalLogging','on');

        s_dataset = simOut.get('logsout').getElement(1);
        fprintf('Block is: %s\n', char(s_dataset.BlockPath.convertToCell()));

        lens_index = lens_index + 1;
        lens{lens_index} = numel(s_dataset.Values.Time);
        
        lens

        close_system(sys);

        % Cleanup
        delete([sys '_acc*']);
        rmdir('slprj', 's');
    
    end
   
end

disp('Final Result:');
lens

disp('--- end ---');
