classdef singleresult < handle
    %SINGLERESULT Result of simulating/compiling a single random Model
    %   Detailed explanation goes here
    
    properties
        model_name;
        is_normal_sim_ok = [];       % Boolean: whether the model runs in Normal simulation mode
        is_timed_out = [];           % Bool: Simulation did not complete in Normal mode
        timeout_value = [];          % Timeout value in seconds
        is_acc_sim_ok = [];          % Boolean: whether model runs in Accelerated simulation mode
        last_exc = [];               % Last exception the model threw
        mode_diff_val = [];          % Value used for differential testing
        last_action = [];            % Last action (Normal mode or Acc mode) performed 
    end
    
    methods
         function obj = singleresult(model_name)
             obj.model_name = model_name;
         end
         
         function obj = set_ok_normal_mode(obj)
             obj.is_normal_sim_ok = true;
             obj.is_timed_out = false;
             obj.last_action = 'Normal';
         end
         
         function obj = set_timed_out_normal_mode(obj, timeout)
             obj.is_normal_sim_ok = false;
             obj.is_timed_out = true;
             obj.timeout_value = timeout;
             obj.last_action = 'Normal';
         end
         
         function obj = set_error_normal_mode(obj, exc)
             obj.is_normal_sim_ok = false;
             obj.is_timed_out = false;
             obj.last_exc = exc;
             obj.last_action = 'Normal';
         end
         
         function obj = set_error_acc_mode(obj, exc, mode_diff_val)
             obj.is_normal_sim_ok = true;
             obj.is_timed_out = false;
             obj.last_exc = exc;
             obj.is_acc_sim_ok = false;
             obj.mode_diff_val = mode_diff_val;
             obj.last_action = 'Acc';
         end
         
         function obj = set_ok_acc_mode(obj)
             obj.is_acc_sim_ok = true;
             obj.last_action = 'Acc';
         end
    end
    
end

