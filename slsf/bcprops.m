classdef bcprops < handle
    %BCPROPS Data Structure for configuring blocks
    %   Detailed explanation goes here
    
    properties
        chars;      % Allowed Characters
        len;        % How many random characters we need in a string
        len_chars;
        kind;       % Type e.g. Enum (e)/ random chars (r) / number (n)
        
        param_name; % Name of the parameter
        
        % A function to apply on the generated value before creating
        % string. Currently only supported for `n` kind
        fn;          
    end
    
    methods
        
        function obj = bcprops(param_name, chars, len, kind, fn)
            % CONSTRUCTOR % Randomly choose block parameters
            % `param_name` the block parameter we want to configure.
            % Values of kind: 
            %r randomly choose `len` characters from `chars`
            %e
            %n Numeric - uniformly chosen random number. `chars`, if
            %present, denotes range.
            
            if nargin < 5
                fn = [];
            end
            
            obj.fn = fn;
            
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
                case {'n'}
                    % uniformly distributed fro -10E8 to 10E8
                    if isempty(obj.chars)
                        lr = [-10e8, 10e8];
                    else
                        lr = obj.chars;
                    end
                    
                    if isempty(obj.len)
                        obj.len = 1;
                    end
                    
                    ret = lr(1) + (lr(2) - lr(1)) * rand(1,obj.len);
                    
                    if ~isempty(obj.fn)
                        ret = obj.fn(ret);
                    end
                    
                    ret = arrayfun(...
                            @(p)sprintf('%.6f', p) , ...
                            ret, 'UniformOutput', false ...
                    );
                
                    ret = sprintf('[%s]', strjoin(ret, ', '));
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

