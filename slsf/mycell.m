classdef mycell < handle
    %MYCELL Wrapper to `cell` for easy dynamic list usage
    %   Detailed explanation goes here
    
    properties
        data;
        capacity;
        len;
    end
    
    methods
        
        function obj = mycell(capacity)
            obj.capacity = capacity;
            
            if capacity == -1
                obj.data = {};
            else
                obj.data = cell(obj.capacity);
            end
            
            obj.len = 0;
        end
        
        
        function obj = add(obj, elem)
            obj.len = obj.len + 1;
            obj.data{obj.len} = elem;
        end
        
        
        function ret = get(obj, indx)
            ret = obj.data{indx};
        end
        
        
        function obj = print_all(obj)
            for i=1:obj.len
                fprintf('%s\t', obj.data{i});
            end
            
            fprintf('\n');
        end
        
    end
    
end

