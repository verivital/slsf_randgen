classdef submodel_block_chooser < blockchooser
    % Chooses blocks for submodels
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function obj = submodel_block_chooser()
            obj = obj@blockchooser();
            
            % Handle obj.categories property
            
%             new_cats = cell(1, numel(obj.categories));
%             
%             for i=1:numel(obj.categories)
%                 c = obj.categories{i};
%                 if strcmpi(c.name, 'Sinks') || strcmpi(c.name, 'Sources')
%                     new_s = c;
% %                     new_s.num = c.num / 4;
%                     new_s.num = c.num / 0;
%                     
%                     new_cats{i} = new_s;
%                 else
%                     new_cats{i} = c;
%                 end
%             end
%             
%             obj.categories = new_cats;
%             
% %             % Handle obj.allowlist
% %             
% %             len_allowlist = numel(obj.allowlist);
% %             
% %             obj.allowlist{len_allowlist + 1} = struct('name', 'simulink/Sources/In1');
% %             obj.allowlist{len_allowlist + 2} = struct('name', 'simulink/Sinks/Out1');


            obj.categories = {
                    struct('name', 'Discrete', 'num', 0)
        %             struct('name', 'Continuous', 'num', 0.3)
        %             struct('name', 'Math Operations', 'num', 10)
        %             struct('name', 'Logic and Bit Operations', 'num', 10)
                    struct('name', 'Sinks', 'num', 0)
                    struct('name', 'Sources', 'num', 0)
                };
            
            obj.allowlist = {
                struct('name', 'simulink/Ports & Subsystems/Model', 'num', 0.1)
                struct('name', 'simulink/Ports & Subsystems/For Each Subsystem', 'num', 0)
            };

            % Black List
            obj.blocklist.(util.mvn('simulink/Sinks/XY Graph')) = 1;
            obj.blocklist.(util.mvn('simulink/Sinks/To Workspace')) = 1;
            obj.blocklist.(util.mvn('simulink/Sinks/To File')) = 1;
            obj.blocklist.(util.mvn('simulink/Sinks/Scope')) = 1;
            obj.blocklist.(util.mvn('simulink/Sinks/FloatingScope')) = 1;
        end
        
    end
    
end

