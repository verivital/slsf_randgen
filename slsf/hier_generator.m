classdef hier_generator < simple_generator
    %HIER_GENERATOR Generates child models
    %   These models can be used in a parent model using the
    %   Model_Reference block.
    
    properties
        root_result = [];     % To hold instance of the `singleresult` class of top-most model
        root_generator = []; % The topmost model's generator 
    end
    
    methods
        function obj = hier_generator(varargin)
            obj = obj@simple_generator(varargin{:});
        end
    end
    
end

