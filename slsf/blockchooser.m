classdef blockchooser < handle
    %BLOCKCHOOSER Choose which blocks to use in random generator
    %Can blocklist some blocks
    %   Detailed explanation goes here
    
    properties
        categories = {
%             struct('name', 'Discrete', 'num', 10)
%             struct('name', 'Continuous', 'num', 10)
%             struct('name', 'Math Operations', 'num', 10)
%             struct('name', 'Logic and Bit Operations', 'num', 10)
            struct('name', 'Sinks', 'num', 2)
            struct('name', 'Sources', 'num', 2)
        };
    
        allowlist = {
            struct('name', 'simulink/Ports & Subsystems/Model')
            struct('name', 'simulink/Ports & Subsystems/For Each Subsystem')
        };
%         allowlist = {};
    
        blocklist = struct;
        
        hierarchy_blocks = mymap();
        submodel_blocks = mymap();
    end
    
    methods
        
        
        function obj=blockchooser()
            % CONSTRUCTOR %
            
            % Blacklist some blocks
            obj.blocklist.(util.mvn('simulink/Sources/From File')) = 1;
            obj.blocklist.(util.mvn('simulink/Sources/FromWorkspace')) = 1;
            obj.blocklist.(util.mvn('simulink/Sources/EnumeratedConstant')) = 1;
            obj.blocklist.(util.mvn('simulink/Discrete/Discrete Derivative')) = 1;
            obj.blocklist.(util.mvn('simulink/Math Operations/FindNonzeroElements')) = 1;
            obj.blocklist.(util.mvn('simulink/Continuous/VariableTransport Delay')) = 1;
            obj.blocklist.(util.mvn('simulink/Sinks/StopSimulation')) = 1;
%             obj.blocklist.(util.mvn('simulink/Continuous/PID Controller (2DOF)')) = 1;

            % List the hierarchy blocks
            obj.hierarchy_blocks.put('simulink/Ports & Subsystems/Model', 1);

            % List the submodel-blocks
            obj.submodel_blocks.put('simulink/Ports & Subsystems/For Each Subsystem', 1);
        end
        
        
        function ret = is_hierarchy_block(obj, bname)
            ret = obj.hierarchy_blocks.contains(bname);
        end
        
        function ret = is_submodel_block(obj, bname)
            ret = obj.submodel_blocks.contains(bname);
        end
        
        
        
        function ret = get(obj, cur_hierarchy_level, max_hierarchy_level)
            % Selects block names randomly
            ret = {};
            can_not_choose_hierarchy_blocks = cur_hierarchy_level >= max_hierarchy_level;
            
            count = 0;
            
            % Chose from whitelisted Simulink Libraries
            
            for i=1:numel(obj.categories)
                c = obj.categories{i};
                
                disp(['(c) Choosing from: ' c.name]);
                
                all_blocks = find_system(['Simulink/' c.name]);
                num_all_blocks = numel(all_blocks) - 1; % Skip the first
                
                rand_vals = randi([2, num_all_blocks], 1, c.num); % Generates starting at 2
            
                for index = 1:c.num
                    now_blk = all_blocks{rand_vals(index)};
                    
%                     disp(now_blk);

%                     if isfield(obj.blocklist, util.mvn(now_blk))
%                         continue;
                    while isfield(obj.blocklist, util.mvn(now_blk))
                        i_rand = randi([2, num_all_blocks], 1, 1);
                        now_blk = all_blocks{i_rand};
                    end
%                     end

                    
%                     disp('BBBBBBBB ');
%                     get_param(now_blk, 'Tag')

                    count = count + 1;
                    ret{count} = now_blk;
                end
            end
            
            fprintf('Now including blocks from Allowlist...\n');
            
            for i=1:numel(obj.allowlist)
                
                cur = obj.allowlist{i}.name;
                
                fprintf('HIER BLOCK FROM ALLOWLIST: %s\n', cur);
                
                if can_not_choose_hierarchy_blocks && (obj.hierarchy_blocks.contains(cur) || obj.submodel_blocks.contains(cur))
                    fprintf('Can not add hierarchy block %s as max level reached.\n', cur);
                    continue;
                end
                
                count = count + 1;
                ret{count} = cur;
            end
            
        end
        
    end
    
end

