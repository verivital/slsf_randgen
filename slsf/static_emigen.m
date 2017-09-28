classdef static_emigen < handle
    %STATIC_EMIGEN Generate EMI-Variants statically
    %   Detailed explanation goes here
    
    properties
        sys;
    end
    
    methods
        function obj = static_emigen(sys)
            obj.sys = sys;
        end
        
        
        function ret = create_single(obj)
            % Should create a single EMI variant and return it's name
            ret = obj.sys; %TODO: right now just passes itself. Not creating any different model
        end
        
    end
    
end

