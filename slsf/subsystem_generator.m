classdef subsystem_generator < hier_generator
    % Generates subsystems e.g. If-Action subsystems
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        function obj = subsystem_generator(varargin)
            obj = obj@hier_generator(varargin{:});
        end
        
        function create_and_open_system(obj)
            % Do not create a New subsystem.
            % Delete the pre-existing line between input and output port
            delete_line(obj.sys, 'In1/1', 'Out1/1');
        end
        
        function process_preadded_blocks(obj)
            fprintf('Inside process preadded blocks. sys: %s\n', obj.sys);
            
            my_children = find_system(obj.sys, 'SearchDepth', 1, 'type', 'block');
            
            obj.num_preadded_blocks = 0;
            
            obj.candi_blocks = cell(1, obj.NUM_BLOCKS); % Has less capacity, but that's fine.    
            
            for i=1:numel(my_children)
                c = my_children{i};
                
                if strcmp(c, obj.sys) || strcmp(get_param(c, 'blocktype'), 'ActionPort')
%                     fprintf('Skipping %s\n', c);
                    continue;
                end
                
                obj.num_preadded_blocks = obj.num_preadded_blocks + 1;
                
                portions = strsplit(c, [obj.sys '/']);
                
                assert(numel(portions) == 2);
%                 disp(portions{2});

                is_discrete = false; % Assuming they are not discrete blocks
                
                obj.candi_blocks{obj.num_preadded_blocks} = {portions{2}, is_discrete};
            end
            
%             assert(obj.num_preadded_blocks == (numel(my_children) - 1)); % 1 is for the system itself
            
%             obj.candi_blocks{1} = 'In1';
%             obj.candi_blocks{2} = 'Out1';
% %             obj.candi_blocks{3} = 'For Each';
        end
        
        
    end
    
end

