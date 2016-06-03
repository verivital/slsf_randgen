classdef submodel_generator < hier_generator
    % Generates submodels e.g. For Each Block
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        function obj = submodel_generator(varargin)
            obj = obj@hier_generator(varargin{:});
        end
        
        function create_and_open_system(obj)
            % Do not create a New subsystem.
            % Delete the pre-existing line between input and output port
            delete_line(obj.sys, 'In1/1', 'Out1/1')
        end
        
        
        
        
    end
    
end

