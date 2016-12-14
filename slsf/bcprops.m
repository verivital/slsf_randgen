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
                case {'m'}
                    ret = ['['];
                    ret_len = 2;
                    if strcmp(obj.chars{1}, 'int')
                        randmat = randi(obj.chars{2}, obj.len(1), obj.len(2));
                        for i=1:obj.len(1)
                            for j = 1:obj.len(2)
                                ret(ret_len) = int2str(randmat(i, j));
                                ret(ret_len + 1) = ' ';
                                ret_len = ret_len + 2;
                            end
                            ret(ret_len) = ';';
                            ret_len = ret_len + 1;
                        end
                        ret(ret_len) = ']';
                        ret = char(ret);
                        fprintf('This is random matrix: %s\n', ret);
                    else
                        throw(MException('RandGen:SL:InvalidMatrixConfiguration'));
                    end
                otherwise
                    throw(MException('RandGen:SL:BlkConfUnknwnKind'));
            end
        end
        
        
        function ret=p(obj)
            ret = obj.param_name;
        end
        
    end
    
end

