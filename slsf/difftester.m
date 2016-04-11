classdef difftester < handle
    %DIFFTESTER For a given model run differential testing
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
            
            for i=1:obj.num_log_len_mismatch
                    
                obj.simulate_for_data_logging();

                if ~ obj.my_result.is_ok(singleresult.NORMAL_SIGLOG) || ~ obj.my_result.is_ok(singleresult.ACC)
                    ret = false;
                    return;
                end

                ret = obj.compare_sim_results(i);

                if ~ obj.my_result.is_log_len_mismatch
                    break; % No need to run again, since we are successful in the first attempt.
                end

            end
            
        end
        
        
        function ret = compare_sim_results(obj, try_count)
            if ~ obj.compare_results
                fprintf('Will not compare simulation results, returning...');
            end
            
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
            obj.simulation_data{1} = simOut.get('logsout');

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
            
            obj.simulation_data = cell(1, (numel(obj.simulation_mode_values) + 1)); % 1 extra for normal mode
            

            if ~ obj.simulate_log_signal_normal_mode()
                return
            end
            
            % Accelerated Modes

            for i = 1:numel(obj.simulation_mode_values)
                inc_i = i + 1;
%                 % Open the model first
%                 if i > 1
%                     fprintf('Opening Model...\n');
%                     open_system(obj.sys);
%                 end
                
                mode_val = obj.simulation_mode_values{i};
                fprintf('[!] Simulating in mode %s for value %s...\n', obj.simulation_mode, mode_val);
                
                obj.my_result.start(singleresult.ACC);
                
                try
                    simOut = sim(obj.sys, 'SimulationMode', obj.simulation_mode, 'SimCompilerOptimization', mode_val, 'SignalLogging','on');
                    obj.my_result.set_ok(singleresult.ACC);
                catch e
                    fprintf('ERROR SIMULATION in accelerated modes'); % TODO Mode name hardcoded
                    e
                    obj.my_result.set_err(singleresult.ACC, MException('RandGen:SL:ErrAfterNormalSimulation', e.identifier));
                    obj.my_result.main_exc = e;
                    return;
                end
                
                obj.simulation_data{inc_i} = simOut.get('logsout');
                
                % Delete generated stuffs
                fprintf('Deleting generated stuffs...\n');
                delete([obj.sys '_acc*']);
                rmdir('slprj', 's');
                
                % Save and close the system
                if i ~= numel(obj.simulation_mode_values)
                    fprintf('Saving Model...\n');
                    save_system(obj.sys);
                    obj.close();
                end
                
            end
            
            % Delete the saved model
            fprintf('Deleting model...\n');
            delete([obj.sys '.slx']);
            
            
        end
        
        function close(obj)
            close_system(obj.sys, 0);
        end
        
    end
    
end

