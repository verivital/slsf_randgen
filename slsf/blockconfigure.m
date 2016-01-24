classdef blockconfigure < handle
    %BLOCKCONFIGURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data;
    end
    
    methods
        
        
        function obj = blockconfigure()
            % CONSTRUCTOR %
            obj.init();
        end
        
        
        function obj  = init(obj)
            obj.populate_data();
        end
        
        
        function found = get_block_configs(obj, blk_type)
            
            found = [];
            
            k = util.mvn(blk_type);
            
            if isfield(obj.data, k)
                found = obj.data.(k);
            end
        end
        
        
        function obj = populate_data(obj)
            d = struct();
            
            %   simulink/Math Operations/Add
            t = {
                bcprops('Inputs', char(['+' '-']), 2)
            };
           
            d.(util.mvn('simulink/Math Operations/Add')) = t;
            
            % Save All
            
            obj.data = d;
        end
        
        
    end
    
end

