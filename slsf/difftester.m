classdef difftester < handle
    % Run differential testing for a given model
    %   Detailed explanation goes here
    
    properties
        sys = [];
        my_result = [];
        num_log_len_mismatch = 1;
        simulation_data = [];
        
        simulation_mode = [];
        simulation_mode_values = [];
        
        compare_results = [];
        
        comp_tester = [];
        
        root_var_of_results = [];
        
        signal_logging_value = [];      % on or off, to be passed to sim command
        
        sim_mode_for_my_result = struct('accelerator', singleresult.ACC, 'rapid', singleresult.RACC);
        
        logging_method_siglog = true;       % If true, uses Signal Logging API. Otherwise adds Outport blocks to every block of top-level model.
        
    end
    
    methods
        
        function obj = difftester(sys, my_result, num_log_len_mismatch, sim_mode, sim_mode_vals, compare_results)
            obj.sys = sys;
            obj.my_result = my_result;
            obj.num_log_len_mismatch = num_log_len_mismatch;
            
            obj.simulation_mode = sim_mode;
            obj.simulation_mode_values = sim_mode_vals;
            obj.compare_results = compare_results;
        end
        
        
        function ret = go(obj)
            ret = true;
            
            if obj.logging_method_siglog
                obj.root_var_of_results = 'logsout';
                obj.signal_logging_value = 'on';
            else
                obj.root_var_of_results = 'yout';
                obj.signal_logging_value = 'off';
            end
            
            for i=1:obj.num_log_len_mismatch
                    
                obj.simulate_for_data_logging();
                
                obj.my_result.is_ok(singleresult.NORMAL_SIGLOG)

                if ~ obj.my_result.is_valid_and_ok(singleresult.NORMAL_SIGLOG) || ~ obj.my_result.is_valid_and_ok(singleresult.ACC) || ~ obj.my_result.is_valid_and_ok(singleresult.RACC)
                    ret = false;
                    return;
                end

                ret = obj.compare_sim_results(i);
%                 ret = true;
%                 obj.my_result.is_log_len_mismatch = false;
%                 % end of hard coding

                if ~ obj.my_result.is_log_len_mismatch
                    break; % No need to run again, since we are successful in the first attempt.
                end

            end
            
        end
        
        
        function ret = compare_sim_results(obj, try_count)
            if ~ obj.compare_results
                fprintf('Will not compare simulation results, returning...');
            end
            
            % TODO manually choosing which comparator to use
%             obj.comp_tester = outport_comparator(obj.my_result, obj.simulation_data, try_count);
            obj.comp_tester = comparator(obj.my_result, obj.simulation_data, try_count);
            
            ret = obj.comp_tester.compare();
        end
        
        
        function ret = simulate_log_signal_normal_mode(obj)
            fprintf('[!] Simulating in NORMAL SIGNAL LOGGING mode...\n');
            ret = true;
            
            obj.my_result.start(singleresult.NORMAL_SIGLOG);
            
            % TODO: Handle Timeout
            
            try
                simOut = sim(obj.sys, 'SimulationMode', 'normal', 'SignalLogging','on');
                obj.my_result.set_ok(singleresult.NORMAL_SIGLOG);
            catch e
                fprintf('ERROR SIMULATION (Logging) in Normal mode');
                e
                
                obj.my_result.set_err(singleresult.NORMAL_SIGLOG, MException('RandGen:SL:ErrAfterNormalSimulation', e.identifier))
                obj.my_result.main_exc = e;
                
%                 obj.my_result.set_error_acc_mode(e, 'NormalMode');
%                 obj.last_exc = MException('RandGen:SL:ErrAfterNormalSimulation', e.identifier);

                ret = false;
                return;
            end
            obj.simulation_data{1} = simOut.get(obj.root_var_of_results);

            % Save and close the system
            fprintf('Saving Model...\n');
            save_system(obj.sys);
            obj.close();
            
        end
        
        
        function obj = simulate_for_data_logging(obj)
            if isempty(obj.simulation_mode)
                fprintf('No simulation mode provided. returning...\n');
            end
            
%             obj.my_result.set_ok_acc_mode();    % Will be over-written if not ok
            
            obj.simulation_data = cell(1, (numel(obj.simulation_mode_values) * numel(obj.simulation_mode) + 1)); % 1 extra for normal mode
            

            if ~ obj.simulate_log_signal_normal_mode()
                % Return if normally simulating threw error.
                return
            end
            
            % Accelerated Modes
            for ti = 1:numel(obj.simulation_mode)
                for i = 1:numel(obj.simulation_mode_values)
                    inc_i = i + 1;
                    simu_mode = obj.simulation_mode{ti};

    %                 % Open the model first
    %                 if i > 1
    %                     fprintf('Opening Model...\n');
    %                     open_system(obj.sys);
    %                 end

                    mode_val = obj.simulation_mode_values{i};
                    fprintf('[!] Simulating in mode %s for value %s...\n', obj.simulation_mode{ti}, mode_val);

                    obj.my_result.start(obj.sim_mode_for_my_result.(simu_mode));

                    try
                        simOut = sim(obj.sys, 'SimulationMode', simu_mode, 'SimCompilerOptimization', mode_val, 'SignalLogging', obj.signal_logging_value);
                        obj.my_result.set_ok(obj.sim_mode_for_my_result.(simu_mode));
                    catch e
                        fprintf('ERROR SIMULATION in later modes'); % TODO Mode name hardcoded
                        e
                        obj.my_result.set_err(obj.sim_mode_for_my_result.(simu_mode), MException('RandGen:SL:ErrAfterNormalSimulation', e.identifier));
                        obj.my_result.main_exc = e;
                        return;
                    end

                    obj.simulation_data{inc_i} = simOut.get(obj.root_var_of_results);

                    % Delete generated stuffs
                    fprintf('Deleting generated stuffs...\n');
                    delete([obj.sys '_acc*']);
                    rmdir('slprj', 's');

                    % Save and close the system
                    
                    fprintf('Saving Model...\n');
                    save_system(obj.sys);
                    obj.close();
   
                end
            end
            
            % Delete the saved model
            fprintf('Deleting model...\n');
            delete([obj.sys '.slx']);  % TODO Warning: when running a pre-generated model this will delete it! So keep the model in a different directory and add that directory in Matlab path.
            
            
        end
        
        function close(obj)
            close_system(obj.sys, 0);
        end
        
    end
    
end

