classdef boxplotmanager < handle
    %BOXPLOTMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data = [];
        group = char.empty(0, 1);
        index = 1;
        group_len;
        plotstyle = 'traditional';
        calc_stats = false;
        all_data;   % For collecting status explicitly
        my_title; % Will be populated when calling draw();
    end
    
    methods
        
        function obj = boxplotmanager(varargin)
            if nargin == 0
                obj.group_len = 1;
            else
                obj.group_len = varargin{1};
            end
            
            obj.group = char.empty(0, obj.group_len);
            
            obj.all_data = mymap();
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
            
            if obj.calc_stats
                data_for_this_key = obj.all_data.create_if_not_exists(g, 'mycell');
                data_for_this_key.add(d);
            end
            
%             if obj.sort_groups
%                 g_num = str2double(g);
%                 if g_num > obj.max_group
%                     obj.max_group = g_num;
%                 end
%             end
        end
        
        function draw(obj, my_title, x_label, y_label, sort_groups)
            
            obj.my_title = my_title;
            
            if nargin == 4
                sort_groups = false;
            end
            
            disp(['[DEBUG] Box Plot: ' my_title]);
%             obj.data
%             obj.group
            
            if isempty(obj.data)
                warning('No Data for BoxPlot! Not Drawing.');
                return;
            end

            figure;
            
            if sort_groups
                group_order =   sort(categories(categorical(cellstr(obj.group))));
                boxplot(obj.data, obj.group, 'Colors', 'k', 'PlotStyle', obj.plotstyle, 'GroupOrder', group_order, 'Widths', 0.25); 
            else
                boxplot(obj.data, obj.group, 'Colors', 'k', 'PlotStyle', obj.plotstyle, 'Widths', 0.25); 
            end
            
            title(my_title);
            xlabel(x_label);
            ylabel(y_label);
        end
        
        function get_stat(obj)
            fprintf('#### Stats for %s ###\n', obj.my_title);
            for i=1:obj.all_data.len_keys()
                k = obj.all_data.key(i);
                d = obj.all_data.get(k);
                d = cell2mat(d.data);
                fprintf('\t\t %s | \t\t Min: %.2f | \t\t Max: %.2f | \t\t Med: %.2f \n',k, min(d), max(d), median(d));
            end
        end
        
    end
    
end

