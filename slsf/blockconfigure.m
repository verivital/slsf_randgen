classdef blockconfigure < handle
    %BLOCKCONFIGURE Specify how to choose Dialog Parameters of Blocks
    %randomly
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
            
            
            % simulink/Sources/Constant
            t = {
                bcprops('Value', char('0':'9'), 4)
            };
            d.(util.mvn('simulink/Sources/Constant')) = t;
            
            
            % simulink/Sources/Step
            t = {
                bcprops('After', char('1':'9'), 2)
            };
            d.(util.mvn('simulink/Sources/Step')) = t;
            
            
            % simulink/Sinks/To Workspace
            t = {
                bcprops('VariableName', char('a':'z'), 7)
            };
            d.(util.mvn('simulink/Sinks/To Workspace')) = t;
            
            
            % Save All
            
            obj.data = d;
        end
        
        
    end
    
end

