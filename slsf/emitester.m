classdef emitester < handle
    %EMITESTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sys;    % Name of the random model
        simulation_data = [];
        my; % Instance of `singleresult`
    end
    
    methods(Static)
        function ret=get_total_emi_variant()
            % Return how many EMI variants would be created
            if cfg.EMI_TESTING
                ret =  cfg.NUM_STATIC_EMI_VARS;
            else
                ret = 0;
            end
            
        end
    end
    
    methods
        
        function obj = emitester(sys, my)
            % Constructor
            obj.sys =sys;
            obj.my = my;
            
            obj.simulation_data = mycell(obj.get_total_emi_variant);
            
        end
        
        
        function ret = go(obj, diff_tester)
            obj.create_static_emi_vars(diff_tester);
            ret = obj.simulation_data;
        end
        
        
        function obj = create_static_emi_vars(obj, diff_tester)
            emi_creator = static_emigen(obj.sys);
            
            for i=1:cfg.NUM_STATIC_EMI_VARS
                single_emi_var = emi_creator.create_single();
                try
                    obj.simulation_data.add(obj.get_simulation_data_for_single_var(single_emi_var, diff_tester));
                catch e
                    fatal('Error in simulation data retrieval for EMI variant');
                    e
                end
            end
        end
        
        function ret = get_simulation_data_for_single_var(obj, sys, diff_tester)
            ret = diff_tester.get_logged_simulation_data(sys, 'normal', 'off');
            ret = diff_tester.retrieve_sim_data(ret);
        end
        
    end
    
end

