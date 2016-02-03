classdef bcprops < handle
    %BCPROPS Data Structure for configuring blocks
    %   Detailed explanation goes here
    
    properties
        chars;      % Allowed Characters
        len;        % How many random characters we need in a string
        len_chars;
        
        param_name; % Name of the parameter
    end
    
    methods
        
        function obj = bcprops(param_name, chars, len)
            % CONSTRUCTOR %
            obj.param_name = param_name;
            obj.chars = chars;
            obj.len = len;
            
            obj.len_chars = length(chars);
        end
        
        function ret = get(obj)
            i = ceil(obj.len_chars * rand(1, obj.len));
            ret = obj.chars(i);
        end
        
        
        function ret=p(obj)
            ret = obj.param_name;
        end
        
    end
    
end

