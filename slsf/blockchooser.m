classdef blockchooser < handle
    %BLOCKCHOOSER Choose which blocks to use in random generator
    %Can blocklist some blocks
    %   Detailed explanation goes here
    
    properties
        categories = {
            struct('name', 'Discrete', 'num', 10)
            struct('name', 'Sinks', 'num', 5)
            struct('name', 'Sources', 'num', 5)
        };
    
        blocklist = struct;
    end
    
    methods
        
        
        function obj=blockchooser()
            % CONSTRUCTOR %
            
            % Blocklist some blocks
            obj.blocklist.(util.mvn('simulink/Sources/From File')) = 1;
            obj.blocklist.(util.mvn('simulink/Sources/FromWorkspace')) = 1;
            obj.blocklist.(util.mvn('simulink/Sources/EnumeratedConstant')) = 1;
            obj.blocklist.(util.mvn('simulink/Discrete/Discrete Derivative')) = 1;
            
        end
        
        
        
        function ret = get(obj)
            % Selects block names randomly
            ret = {};
            
            count = 0;
            
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
            
        end
        
    end
    
end

