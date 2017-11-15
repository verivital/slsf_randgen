classdef singleresult < handle
    %SINGLERESULT Result of experiment for a single random Model
    %   Detailed explanation goes here
    
     properties(Constant = true)
       % Comparison Framework Options
         
       NORMAL = 1;              % Normal mode
       NORMAL_SIGLOG = 2;       % Normal mode with signal logging
       ACC = 3;                 % Accelerator
       RACC = 4;                % Rapid Accelerator
       
       % States in various Comparison Framework Options
       NA = 0;
       STARTED = -1;
       OK = 1;
       TO = -2;
       ER = -3;
       
       % Index for runtime count of various phases of the diff. test.
       % framework
       
       BLOCK_SEL = 1;
       PORT_CONN = 2;
       FAS = 3;         % Fix and Simulate
       SIGNAL_LOGGING = 4;
       COMPARISON = 5;
       
       
       
    end
    
    properties
        model_name;
%         is_normal_sim_ok = [];       % Boolean: whether the model runs in Normal simulation mode
%         is_timed_out = [];           % Bool: Simulation did not complete in Normal mode
%         timeout_value = [];          % Timeout value in seconds
%         is_normal_siglog_ok = [];    % In Normal mode, did the simulation completed after enabling signal logging
%         is_acc_sim_ok = [];          % Boolean: whether model runs in Accelerated simulation mode
%         last_exc = [];               % Last exception the model threw
%         mode_diff_val = [];          % Value used for differential testing
%         last_action = [];            % Last action (Normal mode or Acc mode) performed 
        
        
        record_runtime = true;

        is_log_len_mismatch = false; % After signal logging, length of two simulation was not same.
        log_len_mismatch_count = 0;
        
        phases = {};
        timeout = [];
        exc = [];
        main_exc = [];
        
        logdata = [];
        
        hier_models = [];           % Names of the models generated as part of the hierarchy. Storing them here so that we can delete them later
        sfuns;                 % Names of s-function files. Storing them to here to save later.
        
        block_sel_stat = [];        % Count which library got selected how many times for statistics
        
        runtime = [];               % To count runtime of various phases of DT framework
        
        dc_analysis = 0;     % data-type conversions added during pre-simulation analysis phase
        dc_sim = 0;             % data-type conversions added during simulation (Fix Errors) phase
        num_fe_attempts = 0;    % Number of Fix Error attempts taken
        
        solvers_used;
                
    end
    
    methods
         function obj = singleresult(model_name, record_runtime)
             obj.model_name = model_name;
             obj.record_runtime = record_runtime;
             
             obj.hier_models = mycell(-1);
             obj.sfuns = mycell();
             obj.block_sel_stat = mymap();
             obj.solvers_used = mycell();
             
         end
         
         function sr = update_saved_result(obj, sr)
            sr.errors = obj.exc;
            sr.num_fe_attempts = obj.num_fe_attempts;
            sr.solvers_used = obj.solvers_used.get_cell();
         end
         
         function obj = set_mode(obj, p, m)
             obj.phases{p} = m;
         end
         
         function ret = get_mode(obj, p)
             ret = obj.phases{p};
         end
         
         function ret = check(obj, p, m)
             ret = (obj.phases{p} == m);
         end
         
         function obj = set_err(obj, p, exc)
             obj.phases{p} = obj.ER;
             obj.exc = exc;
         end
         
         function obj = set_to(obj, p, timeout)
             obj.phases{p} = obj.TO;
             obj.timeout = timeout;
         end
         
         function obj = set_ok(obj, p)
             obj.phases{p} = obj.OK;
         end
         
         function obj = start(obj, p)
             obj.phases{p} = obj.STARTED;
         end
         
         function ret = is_ok(obj, p)
             % Will return false if data is not available.
             if p > numel(obj.phases) || isempty(obj.phases{p})
                 ret = false;
                 return
             end
             ret = (obj.phases{p} == obj.OK);
         end
         
         function ret = is_valid_and_ok(obj, p)
             % Will not return false if data is not available.
%              fprintf('array index: %d\n', p);
%              disp(obj.phases);
             if p > numel(obj.phases) || isempty(obj.phases{p})
                 ret = true;
                 return
             end
             ret = (obj.phases{p} == obj.OK);
         end
         
         
%          function obj = set_started_normal_mode(obj)
%              obj.phases{obj.NORMAL} = obj.STARTED;
%          end
%          
%          function obj = set_ok_normal_mode(obj)
%              obj.phases{obj.NORMAL} = obj.OK;
% %              obj.is_normal_sim_ok = true;
% %              obj.is_timed_out = false;
%              obj.last_action = 'Normal';
%          end
%          
%          function obj = set_timed_out_normal_mode(obj, timeout)
%              obj.phases{obj.NORMAL} = obj.TO;
% %              obj.is_normal_sim_ok = false;
% %              obj.is_timed_out = true;
%              obj.timeout_value = timeout;
%              obj.last_action = 'Normal';
%          end
%          
%          function obj = set_error_normal_mode(obj, exc)
%              obj.phases{obj.NORMAL} = obj.ER;
% %              obj.is_normal_sim_ok = false;
% %              obj.is_timed_out = false;
%              obj.last_exc = exc;
%              obj.last_action = 'Normal';
%          end
%          
%          
%          function obj = set_timed_out_normal_siglog(obj, timeout)
%              obj.is_normal_siglog_ok = false;
%              obj.is_timed_out = true;
%              obj.timeout_value = timeout;
%              obj.last_action = 'NormalSiglog';
%          end
%          
%          function obj = set_ok_normal_siglog(obj)
%              obj.is_normal_siglog_ok = true;
%              obj.last_action = 'NormalSiglog';
%          end
%          
%          
%          function obj = set_err_normal_siglog(obj, exc)
%              obj.is_normal_siglog_ok = false;
%              obj.last_exc = exc;
%              obj.last_action = 'NormalSiglog';
%          end
%          
%          function obj = set_error_acc_mode(obj, exc, mode_diff_val)
%              obj.is_normal_sim_ok = true;
%              obj.is_timed_out = false;
%              obj.last_exc = exc;
%              obj.is_acc_sim_ok = false;
%              obj.mode_diff_val = mode_diff_val;
%              obj.last_action = 'Acc';
%          end
%          
%          function obj = set_ok_acc_mode(obj)
%              obj.is_acc_sim_ok = true;
%              obj.last_action = 'Acc';
%          end
    
    
        function obj = store_runtime(obj, phase)
            if ~ obj.record_runtime
                return;
            end
            obj.runtime(phase) = obj.runtime(phase) + toc();
            % Automatically start counting for next phase!
            tic();
        end
        
        
        function obj = init_runtime_recording(obj)
            if obj.record_runtime
                % Init all values to zero, necessary.
                obj.runtime = zeros(singleresult.COMPARISON, 1);
                tic();
            end
        end
    
    end
    
end

