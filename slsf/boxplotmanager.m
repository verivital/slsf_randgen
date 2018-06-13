classdef boxplotmanager < handle
    %BOXPLOTMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data = [];
        group = char.empty(0, 1);
        index = 1;
        group_len;
        plotstyle = 'traditional';
%         plotstyle = 'compact';
        calc_stats = false;
        all_data;   % For collecting status explicitly
        my_title; % Will be populated when calling draw();
        is_y_log = true; % log scale for Y axis
        add_eps = true;
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
            if obj.add_eps
                obj.data(obj.index, 1) = d + eps;
            else
                obj.data(obj.index, 1) = d;
            end
%             obj.data(obj.index, 1) = d;
            
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

            f = figure;
            set(f,'name',my_title);
            
            whisker = Inf;
            
            if sort_groups
                group_order =   sort(categories(categorical(cellstr(obj.group))));
                boxplot(obj.data, obj.group, 'Colors', 'k', 'PlotStyle', obj.plotstyle, 'GroupOrder', group_order, 'Widths', 0.2,...
                    'MedianStyle', 'target', 'whisker', whisker); 
            else
                boxplot(obj.data, obj.group, 'Colors', 'k', 'PlotStyle', obj.plotstyle, 'Widths', 0.2,...
                    'MedianStyle', 'target', 'whisker', whisker); 
            end
            
%             title(my_title);
            if ~isempty(x_label)
                xlabel(x_label);
            end
            ylabel(y_label);
            
            if obj.is_y_log
                set(gca, 'YScale', 'log');
            end
        end
        
        function get_stat(obj)
            fprintf('#### Stats for %s ###\n', obj.my_title);
            for i=1:obj.all_data.len_keys()
                k = obj.all_data.key(i);
                d = obj.all_data.get(k);
                d = cell2mat(d.get_cell());
%                 fprintf('\t\t %s | \t\t Min: %.2f | \t\t Max: %.2f | \t\t Med: %.2f \n',k, min(d), max(d), median(d));
                
                if util.starts_with(obj.my_title, 'Compile Time')
                    fprintf('\t\t %s | \t\t \\idt{%.2f}{%.2f}{%.2f}{%.2f}{%.2f} \n',k, min(d), max(d), median(d), mean(d), std(d));
                else
                    fprintf('\t\t %s | \t\t \\idt{%d}{%d}{%d}{%d}{%d} \n',k, min(d), max(d), round(median(d)), round(mean(d)), round(std(d)));
                end
                
            end
        end
        
    end
    
end

