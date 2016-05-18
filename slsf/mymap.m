classdef mymap < handle
    %UNTITLED2 HashMap
    %   Detailed explanation goes here
    
    properties
        data
    end
    
    methods
        function obj = mymap()
            obj.data = struct;
        end
        
        
        function put(obj, k, v)
            obj.data.(util.mvn(k)) = v;
        end
        
        function ret = contains(obj, k)
            ret = isfield(obj.data, util.mvn(k));
        end
        
        function ret = get(obj, k)
            if ~ isfield(obj.data, util.mvn(k))
                ret = [];
            else
                ret = obj.data.(util.mvn(k));
            end
        end
    end
    
end

