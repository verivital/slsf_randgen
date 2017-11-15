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
        
        signal_logging_value = [];      % on or off, to be passed to sim command, will be determined by `logging_method_siglog`
        
        sim_mode_for_my_result = struct('accelerator', singleresult.ACC, 'rapid', singleresult.RACC);
        
        logging_method_siglog = cfg.USE_SIGNAL_LOGGING_API;       % If true, uses Signal Logging API. Otherwise adds Outport blocks to every block of top-level model.
        
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
                    
                obj.simulate_for_data_logging(); % Simulates the model variying SUT options and records signals
                
                obj.my_result.is_ok(singleresult.NORMAL_SIGLOG)

                if ~ obj.my_result.is_valid_and_ok(singleresult.NORMAL_SIGLOG) || ~ obj.my_result.is_valid_and_ok(singleresult.ACC) || ~ obj.my_result.is_valid_and_ok(singleresult.RACC)
                    ret = false;
                    return;
                end
                
                obj.my_result.store_runtime(singleresult.SIGNAL_LOGGING);
                
                if cfg.PRESENTATION_MODE
                    fprintf('---- CyFuzz: Signal Logging Phase Completed ---- \n');
                    pause();
                end
                
                obj.create_and_log_signal_for_emi(); % Create EMI-variants and log signals by simulating them

                ret = obj.compare_sim_results(i); % Compares the recorded signals

                if ret
                    break; % No need to run again, since we are successful in the first attempt.
                end

            end
            
        end
        
        function obj = create_and_log_signal_for_emi(obj)
            if ~ cfg.EMI_TESTING
                return;
            end
            
            emi_tester = emitester(obj.sys, obj.my_result);
            sim_data = emi_tester.go(obj);
            
            for i = 1:sim_data.len
                obj.simulation_data{obj.get_num_of_non_emi_simulations() + i} = sim_data.get(i);
            end
            
        end
        
        
        function ret = get_num_of_non_emi_simulations(obj)
            ret = numel(obj.simulation_mode_values) * numel(obj.simulation_mode) + 1;
        end
        
        
        function ret = compare_sim_results(obj, try_count)
            ret = false;
            
            if ~ obj.compare_results
                fprintf('Will not compare simulation results, returning...');
                return;
            end
            
            % TODO manually choosing which comparator to use
            if obj.logging_method_siglog
                obj.comp_tester = comparator(obj.my_result, obj.simulation_data, try_count);
                obj.comp_tester.max_log_len_mismatch_allowed = obj.num_log_len_mismatch;
            else
                obj.comp_tester = outport_comparator(obj.my_result, obj.simulation_data, try_count);
            end
            
            ret = obj.comp_tester.compare();
            
            obj.my_result.store_runtime(singleresult.COMPARISON);
        end
        
        
        function ret = simulate_log_signal_normal_mode(obj)
            % Simulates the model in Normal mode and records/logs signals
            
            fprintf('[!] Simulating in NORMAL SIGNAL LOGGING mode...\n');
            ret = true;
            
            obj.my_result.start(singleresult.NORMAL_SIGLOG);
            
            % TODO: Handle Timeout
            
            try
%                 sim_output = sim(obj.sys, 'SimulationMode', 'normal', 'SignalLogging','on');
                sim_output = obj.get_logged_simulation_data(obj.sys, 'normal', 'off');
                obj.my_result.set_ok(singleresult.NORMAL_SIGLOG);
            catch e
                fprintf('ERROR SIMULATION (Logging) in Normal mode');
                getReport(e)
                
                obj.my_result.set_err(singleresult.NORMAL_SIGLOG, MException('RandGen:SL:ErrAfterNormalSimulation', e.identifier))
                obj.my_result.main_exc = e;
                

                ret = false;
                return;
            end
            obj.simulation_data{1} = obj.retrieve_sim_data(sim_output);

            % Save and close the system
            fprintf('Saving Model...\n');
            save_system(obj.sys);
            obj.close();
            
        end
        
        
        function obj = simulate_for_data_logging(obj)
            % Simulates a model varying SUT options and EMI testing
            
            if isempty(obj.simulation_mode)
                fprintf('No simulation mode provided. returning...\n');
            end
                        
            obj.simulation_data = cell(1, (obj.get_num_of_non_emi_simulations + emitester.get_total_emi_variant())); 

            if ~ obj.simulate_log_signal_normal_mode()
                % Return if normally simulating threw error.
                return
            end
            
            % Vary simulation modes
            for ti = 1:numel(obj.simulation_mode)
                for i = 1:numel(obj.simulation_mode_values)
                    inc_i = i + 1;
                    simu_mode = obj.simulation_mode{ti};

                    % Open the model first
%                     if i > 1  % Logic got flawed after introducing outer
%                     loop
                        fprintf('Opening Model...\n');
                        open_system(obj.sys);
%                     end

                    mode_val = obj.simulation_mode_values{i};
                    fprintf('[!] Simulating in mode %s for value %s...\n', obj.simulation_mode{ti}, mode_val);

                    obj.my_result.start(obj.sim_mode_for_my_result.(simu_mode));

                    try
%                         sim_data = sim(obj.sys, 'SimulationMode', simu_mode, 'SimCompilerOptimization', mode_val, 'SignalLogging', obj.signal_logging_value);
                        sim_data = obj.get_logged_simulation_data(obj.sys, simu_mode, mode_val);
                        obj.my_result.set_ok(obj.sim_mode_for_my_result.(simu_mode));
                    catch e
                        fprintf('ERROR SIMULATION in later modes'); % TODO Mode name hardcoded
                        e
                        obj.my_result.set_err(obj.sim_mode_for_my_result.(simu_mode), MException('RandGen:SL:ErrAfterNormalSimulation', e.identifier));
                        obj.my_result.main_exc = e;
                        return;
                    end

                    obj.simulation_data{inc_i} = obj.retrieve_sim_data(sim_data);

                    % Delete generated stuffs
                    fprintf('Deleting generated stuffs...\n');
                    delete([obj.sys '_acc*']);
                    
                    try
                        rmdir('slprj', 's');
                    catch me
                        fprintf('rmdir failure: directory not removed: %s\n', me.identifier);
                    end

                    % Save and close the system
                    
                    if ti ~= numel(obj.simulation_mode) || i ~= numel(obj.simulation_mode_values)
                        fprintf('Saving and closing Model...\n');
                        save_system(obj.sys);
                        obj.close();
                    else
                        fprintf('Will NOT save or close model\n');
                    end
   
                end
            end
           
            
            % Delete the saved model
%             fprintf('Deleting model...\n');
%             delete([obj.sys '.slx']);  % TODO Warning: when running a pre-generated model this will delete it! So keep the model in a different directory and add that directory in Matlab path.
            
            
        end
        
         function ret  = get_logged_simulation_data(obj, sys, simulation_mode, optimization_value)
             fprintf('[-->] Simulating %s, Mode: %s \n', sys, simulation_mode);
             if cfg.LOG_SOLVERS_USED
                obj.my_result.solvers_used.add([get_param(sys,'SolverType') '; ' simulation_mode]);
             end
            ret = sim(sys, 'SimulationMode', simulation_mode, 'SimCompilerOptimization', optimization_value, 'SignalLogging', obj.signal_logging_value);
         end
        
         function ret = retrieve_sim_data(obj, simOut)
             ret =  simOut.get(obj.root_var_of_results);
         end
        
        
        function close(obj)
            close_system(obj.sys, 0);
        end
        
    end
    
end

