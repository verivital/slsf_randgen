classdef singleresult < handle
    %SINGLERESULT Result of simulating/compiling a single random Model
    %   Detailed explanation goes here
    
     properties(Constant = true)
       % Phases
         
       NORMAL = 1;
       NORMAL_SIGLOG = 2;
       ACC = 3;
       
       % States in various phases
       NA = 0;
       STARTED = -1;
       OK = 1;
       TO = -2;
       ER = -3;
       
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
        
        is_log_len_mismatch = false; % After signal logging, length of two simulation was not same.
        log_len_mismatch_count = 0;
        
        phases = {};
        timeout = [];
        exc = [];
        main_exc = [];
        
        logdata = [];
        
    end
    
    methods
         function obj = singleresult(model_name)
             obj.model_name = model_name;
             
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
    end
    
end

