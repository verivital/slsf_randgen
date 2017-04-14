classdef boxplotmanager < handle
    %BOXPLOTMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data = [];
        group = char.empty(0, 1);
        index = 1;
        
    end
    
    methods
        function add(obj, d, g)
            obj.data(obj.index, 1) = d;
            obj.group(obj.index, 1) = g;
            obj.index = obj.index + 1;
        end
        
        function draw(obj, my_title, x_label, y_label)
%             disp(['[DEBUG] Box Plot: ' my_title]);
%             obj.data
%             obj.group
            figure;
            boxplot(obj.data, obj.group);
            title(my_title);
            xlabel(x_label);
            ylabel(y_label);
        end
        
    end
    
end

