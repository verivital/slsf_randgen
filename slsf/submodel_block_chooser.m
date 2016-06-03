classdef submodel_block_chooser < blockchooser
    % Chooses blocks for submodels
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function obj = submodel_block_chooser()
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
            
%             % Handle obj.allowlist
%             
%             len_allowlist = numel(obj.allowlist);
%             
%             obj.allowlist{len_allowlist + 1} = struct('name', 'simulink/Sources/In1');
%             obj.allowlist{len_allowlist + 2} = struct('name', 'simulink/Sinks/Out1');
        end
        
    end
    
end

