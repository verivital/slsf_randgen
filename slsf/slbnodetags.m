classdef slbnodetags < handle
    %SLBNODETAGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        n;
        
        which_input_port = [];
        which_parent_block;
        which_parent_port;
        
        is_visited;
    end
    
    methods
        function obj = slbnodetags(n)
            obj.n = n;
            obj.is_visited = false;
        end
    end
    
end

