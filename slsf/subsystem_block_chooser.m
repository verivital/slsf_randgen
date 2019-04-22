classdef subsystem_block_chooser < blockchooser
    % Chooses blocks for subsystems
    %   Detailed explanation goes here
    
    properties
        source_proportion = 0.15;  % Will be updated later
        sink_proportion = 0.15;     % Will be updated later

    end
    
    methods
        
        function obj = subsystem_block_chooser()
            obj = obj@blockchooser();
            
            % Handle obj.categories property
            
            new_cats = cell(1, numel(obj.categories));
            new_cats_num = 0;
            
            for i=1:numel(obj.categories)
                c = obj.categories{i};
                
                if strcmpi(c.name, 'Sources')
                    % Uncomment the following code to use Sources. 
%                     new_s = c;
%                     new_s.num = c.num/2;
%                     obj.source_proportion = new_s.num;
%                     
%                     new_cats_num = new_cats_num + 1;
%                     new_cats{new_cats_num} = new_s;
                    obj.source_proportion = c.num/1.0;
                elseif strcmpi(c.name, 'Sinks') 
                    % Don't add any sink -- most of them are blacklisted
                    obj.sink_proportion = c.num/3;
                elseif strcmpi(c.name, 'simulink/Ports & Subsystems/If') 
                    new_s = c;
                    new_s.num = c.num/3;                    
                    new_cats_num = new_cats_num + 1;
                    new_cats{new_cats_num} = new_s;
                else
                    new_cats_num = new_cats_num + 1;
                    new_cats{new_cats_num} = c;
                end
            end

            obj.categories = new_cats;
            
            obj.categories{new_cats_num + 1} = ...
                struct('name', 'simulink/Sources/In1', 'is_blk', true, 'num', obj.source_proportion);
            obj.categories{new_cats_num + 2} = ...
                struct('name', 'simulink/Sinks/Out1', 'is_blk', true, 'num', obj.sink_proportion);
            
            % Handle obj.allowlist
            
%             len_allowlist = numel(obj.allowlist);
%             obj.allowlist{len_allowlist + 1} = struct('name', 'simulink/Sources/In1');
%             obj.allowlist{len_allowlist + 2} = struct('name', 'simulink/Sinks/Out1');
            
            % Blacklist
            
            % Mainly because of a For Each block appearing at parent level
            obj.blocklist.(util.mvn('simulink/Sinks/XY Graph')) = 1;
            obj.blocklist.(util.mvn('simulink/Sinks/To Workspace')) = 1;
            obj.blocklist.(util.mvn('simulink/Sinks/To File')) = 1;
            obj.blocklist.(util.mvn('simulink/Sinks/Scope')) = 1;
            obj.blocklist.(util.mvn('simulink/Sinks/FloatingScope')) = 1;
        end
        
    end
    
end

