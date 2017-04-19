classdef boxplotmanager < handle
    %BOXPLOTMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data = [];
        group = char.empty(0, 1);
        index = 1;
        group_len;
        
    end
    
    methods
        
        function obj = boxplotmanager(varargin)
            if nargin == 0
                obj.group_len = 1;
            else
                obj.group_len = varargin{1};
            end
            
            obj.group = char.empty(0, obj.group_len);
        end
        
        function add(obj, d, g)
            obj.data(obj.index, 1) = d;
            
            if numel(g) < obj.group_len
                g = pad(g, obj.group_len);
            elseif numel(g) > obj.group_len
                g = g(1:obj.group_len);
            end
            
            obj.group(obj.index, :) = g;
            obj.index = obj.index + 1;
        end
        
        function draw(obj, my_title, x_label, y_label)
            disp(['[DEBUG] Box Plot: ' my_title]);
%             obj.data
%             obj.group
            
            if isempty(obj.data)
                warning('No Data for BoxPlot! Not Drawing.');
                return;
            end
            
            figure;
            boxplot(obj.data, obj.group); % 'GroupOrder', {'1', '2', '3'}
            title(my_title);
            xlabel(x_label);
            ylabel(y_label);
        end
        
    end
    
end

