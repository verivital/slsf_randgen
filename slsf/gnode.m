classdef gnode < handle
    %GNODE A simple graph vertice
    %   Detailed explanation goes here
    
    properties
        my_id;
        children = [];
    end
    
    methods
        function obj = gnode(my_id)
            obj.my_id = my_id;
            obj.children = mycell();
        end
        
        function obj = add(obj, chld)
            obj.children.add(chld);
        end
        
        function ret = num_children(obj)
            ret = obj.children.len;
        end
        
        function ret = get_child(obj, i)
            ret = obj.children.get(i);
        end
    end
    
end

