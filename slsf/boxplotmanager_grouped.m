classdef boxplotmanager_grouped < handle
    %BOXPLOTMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data;
        group = char.empty(0, 1);
        index;
        group_len;
        plotstyle = 'traditional';
        calc_stats = false;
        all_data;   % For collecting status explicitly
        my_title; % Will be populated when calling draw();
        
        subgroup_data;
        subgroup_names;
        
        label_orientation = 'horizontal';
        
        add_eps = true; % For log(0)
        is_y_log = true; % log scale for Y axis
        
    end
    
    methods
        
        function obj = boxplotmanager_grouped(varargin)
            if nargin == 0
                obj.group_len = 1;
            else
                obj.group_len = varargin{1};
            end
            
            obj.subgroup_names = mycell();
            obj.subgroup_data = mycell();
        end
        
        function obj = init_sg(obj, sg_name)
            % Manually call for all model classes,
            
            if obj.subgroup_names.len > 0
                % This is not the first experiment... back up data for
                % previous experiment
                obj.backup_last_sg();
            end
            
            obj.subgroup_names.add(sg_name);
            obj.data = [];
            obj.group = char.empty(0, obj.group_len);
            obj.index = 1;
            obj.all_data = mymap();
        end
        
        function obj = backup_last_sg(obj)
            pckt = {obj.data, obj.group, obj.all_data};
            obj.subgroup_data.add(pckt);
        end
        
        function add(obj, d, g)
            if obj.add_eps
                obj.data(obj.index, 1) = d + eps;
            else
                obj.data(obj.index, 1) = d;
            end
            
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
        
        function group_draw(obj, my_title, x_label, y_label, sort_groups)
            
            obj.backup_last_sg();
            
            obj.my_title = my_title;
            
            if nargin == 4
                sort_groups = false;
            end
            
            disp(['[DEBUG] Box Plot: ' my_title]);
            
            width = 0.20;
            x_diff = 0.4;
            inc = 2.5;

            f = figure;
            set(f,'name',my_title);
            
            box_colors = {'k', 'm', 'r', 'b', [0 .5 0], 'c', 'y'};
            
            whisker = Inf;
            
            for i=1:obj.subgroup_data.len
                sg_name = obj.subgroup_names.get(i);
                fprintf('\t -=-=-=-=-=-= Subgroup: %s -=-=-=-=-\n', sg_name);
                pckt = obj.subgroup_data.get(i);
                sg_data = pckt{1};
                sg_group = pckt{2};
                
                if isempty(sg_data)
                    warning('No Data for BoxPlot! Not Drawing.');
                    continue;
                end
                
                group_order =   sort(categories(categorical(cellstr(sg_group))));
                
                offst = (i-1)*x_diff;
                start = 1+offst;
                final = (numel(group_order) * inc) + offst;
                
                
                position = start :inc: final;
                
                boxplot(sg_data, sg_group, 'Colors', box_colors{i}, 'PlotStyle', obj.plotstyle, 'Positions', position,...
                    'GroupOrder', group_order, 'Widths', width, 'Symbol', [box_colors{i} '+'], 'LabelOrientation', obj.label_orientation,...
                    'MedianStyle', 'target', 'whisker', whisker);
                hold on;
%                 set(gca,'XTickLabel',{' '})  % Erase xlabels   
                
%                 pause;
            end
            
            hold off;
            
            xlim('auto');
            ylim('auto');
            
%             title(my_title);
            xlabel(x_label);
            ylabel(y_label);
            
            if obj.is_y_log
                set(gca, 'YScale', 'log');
            end
        end
        
%         function draw(obj, my_title, x_label, y_label, sort_groups)
%             
%             obj.my_title = my_title;
%             
%             if nargin == 4
%                 sort_groups = false;
%             end
%             
%             disp(['[DEBUG] Box Plot: ' my_title]);
% %             obj.data
% %             obj.group
%             
%             if isempty(obj.data)
%                 warning('No Data for BoxPlot! Not Drawing.');
%                 return;
%             end
% 
%             figure;
%             
%             if sort_groups
%                 group_order =   sort(categories(categorical(cellstr(obj.group))));
%                 boxplot(obj.data, obj.group, 'Colors', 'k', 'PlotStyle', obj.plotstyle, 'GroupOrder', group_order, 'Widths', 0.25); 
%             else
%                 boxplot(obj.data, obj.group, 'Colors', 'k', 'PlotStyle', obj.plotstyle, 'Widths', 0.25); 
%             end
%             
%             title(my_title);
%             xlabel(x_label);
%             ylabel(y_label);
%         end
        
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
    
    methods(Static)
        function ret = get_test()
            ret = boxplotmanager_grouped();
            
            ret.init_sg('examples');
            
            ret.add(1, '1');
            ret.add(3, '1');
            ret.add(4, '2');
            
            ret.add(2, '1');
            ret.add(5, '2');
            ret.add(6, '2');
            
            
            ret.init_sg('GitHub');
            
            ret.add(9, '1');
            ret.add(7, '1');
            ret.add(12, '2');
            
            ret.add(8, '1');
            ret.add(10, '2');
            ret.add(11, '2');
            
            ret.init_sg('Other');
            
            ret.add(9, '1');
            ret.add(7, '1');
            ret.add(12, '2');
            
            ret.add(8, '1');
            ret.add(10, '2');
            ret.add(11, '2');
            
            ret.init_sg('Matlab Central');
            
            ret.add(9, '1');
            ret.add(7, '1');
            ret.add(12, '2');
            
            ret.add(8, '1');
            ret.add(10, '2');
            ret.add(11, '2');
            
            ret.group_draw('Level wise block connection count', 'Levels', 'Block count');
        end
    end
    
end

