classdef bcprops < handle
    %BCPROPS Data Structure for configuring blocks
    %   Detailed explanation goes here
    
    properties
        chars;      % Allowed Characters
        len;        % How many random characters we need in a string
        len_chars;
        kind;       % Type e.g. Enum vs. random chars etc.
        
        param_name; % Name of the parameter
    end
    
    methods
        
        function obj = bcprops(param_name, chars, len, kind)
            % CONSTRUCTOR %
            % Values of kind: r, e
            obj.param_name = param_name;
            obj.chars = chars;
            obj.len = len;
            obj.kind = kind;
            
            obj.len_chars = length(chars);
        end
        
        function ret = get(obj)
            switch obj.kind
                case {'r'}
                    i = ceil(obj.len_chars * rand(1, obj.len));
                    ret = obj.chars(i);
                case {'e'}
                    ret = obj.chars{util.rand_int(1, obj.len_chars, 1)};
                otherwise
                    throw(MException('RandGen:SL:BlkConfUnknwnKind'));
            end
        end
        
        
        function ret=p(obj)
            ret = obj.param_name;
        end
        
    end
    
end

