classdef mycell < handle
    %MYCELL Wrapper to `cell` for easy dynamic list usage
    %   Detailed explanation goes here
    
    properties
        data;
        capacity = [];
        len;
    end
    
    methods
        
        function obj = mycell(capacity)
            
            if nargin < 1
                capacity = -1;
            end
            
            
            
            if iscell(capacity)
                obj.data = capacity;
                obj.len = numel(capacity);
                
            else
                obj.capacity = capacity;
                
                if capacity == -1
                    obj.data = {};
                else
                    obj.data = cell(1, obj.capacity);
                end

                obj.len = 0;
            end
        end
        
        
        function obj = add(obj, elem)
            obj.len = obj.len + 1;
            obj.data{obj.len} = elem;
        end
        
        
        function ret = get(obj, indx)
            ret = obj.data{indx};
        end
        
        function obj = extend(obj, other_cell)
            for i=1:other_cell.len
                obj.add(other_cell.get(i));
            end
        end
        
        
        function obj = print_all(obj, header)
            
            if ~ isempty(header)
                fprintf('%s\n', header);
            end
            
            for i=1:obj.len
                fprintf('%s\t', obj.data{i});
            end
            
            fprintf('\n');
        end
        
    end
    
end

