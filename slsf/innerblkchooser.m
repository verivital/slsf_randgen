classdef innerblkchooser < blockchooser
    %INNERBLKCHOOSER Block Chooser for models which are children models
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = innerblkchooser()
            obj = obj@blockchooser();
            
            % Handle obj.categories property
            
            new_cats = cell(1, numel(obj.categories));
            
            for i=1:numel(obj.categories)
                c = obj.categories{i};
                if strcmpi(c.name, 'Sinks') || strcmpi(c.name, 'Sources')
                    new_s = c;
                    new_s.num = c.num - 1;
                    
                    new_cats{i} = new_s;
                else
                    new_cats{i} = c;
                end
            end
            
            obj.categories = new_cats;
            
            % Handle obj.allowlist
            
            len_allowlist = numel(obj.allowlist);
            
            obj.allowlist{len_allowlist + 1} = struct('name', 'simulink/Sources/In1');
            obj.allowlist{len_allowlist + 2} = struct('name', 'simulink/Sinks/Out1');
            
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

