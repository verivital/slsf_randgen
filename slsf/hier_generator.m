classdef hier_generator < simple_generator
    %HIER_GENERATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        root_result = [];     % To hold instance of the `singleresult` class of top-most model
    end
    
    methods
        function obj = hier_generator(varargin)
            obj = obj@simple_generator(varargin{:});
        end
    end
    
end

