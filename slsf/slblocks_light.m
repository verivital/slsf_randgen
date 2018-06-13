classdef slblocks_light < slblocks
    %SLBLOCKS_LIGHT To perform lightweight analysis required by complexity
    %analysis tool
    %   Detailed explanation goes here
    
    properties
        name_to_id;
    end
    
    methods
        function obj = slblocks_light(varargin)
            obj = obj@slblocks(varargin{:});
            
            obj.name_to_id = mymap();
        end
        
        function [h, my_id, n] = get_existing_or_new(obj, b)
            blk_name = char(b);
            h = get_param(blk_name, 'handle');
            
            if obj.name_to_id.contains(blk_name)
                my_id = obj.name_to_id.get(blk_name);
                n = obj.nodes{my_id};
            else
                n = obj.register_new_block(h, blk_name);
                obj.name_to_id.put(blk_name, obj.NUM_BLOCKS);
                my_id = obj.NUM_BLOCKS;
            end
        end
        
        function process_new_block(obj, b)
            
            blk_name = char(b);
            
%             fprintf('--- Processing new block %s ---\n', blk_name);
            
            [h, ~, n] = obj.get_existing_or_new(getfullname(blk_name));
            
            % Handle its outgoing ports
            
            try
                ports = get_param(h,'PortConnectivity');
            catch e
%                 disp('~ Skipping, not a block');
                error('Not a port!');
            end
            
            out_port_count = 0;

            for j = 1:numel(ports)
                p = ports(j);
                
                is_inp = [];
                
                % Detect if current port is Input or Output

                if isempty(p.SrcBlock) || p.SrcBlock == -1
                    is_inp = false;
                end
                
                if isempty(p.DstBlock)
                    is_inp = true;
                end
                
                if isempty(is_inp)
                    % Could not determine input or output port. Throw error
                    % for now
                    throw(MException('RandGen:SL:BlockReplace', 'Could not determine input or output port'));
                end
                
                
                if(is_inp)
                    continue;
                else
                    out_port_count = out_port_count + 1;
                    other_handles = get_param(p.DstBlock, 'handle');
                    other_port = p.DstPort + 1; 
                end 
                
                if isempty(other_handles)
%                     disp('Can not find other end of the port. No blocks there or port misidentified');
                    % For example if an OUTPUT port 'x' of a block is not
                    % connected, that port 'x' will be wrongly identified
                    % as an INPUT port, and at this point variable
                    % `other_name` is empty as there is no other blocks
                    % connected to this port.
                    continue;
                end
                
%                 disp('my_port');
%                 p.Type
               
                my_port = str2double(p.Type);
                
                if isnan(my_port)
                    my_port = out_port_count;
                else
                    assert(my_port <= j);
                end
                
                                
                if numel(other_port) > 1
                    for i = 1:numel(other_port)
                        ohc = other_handles(i);
                        assert(numel(ohc) == 1);
                        [~,~,other_node] = obj.get_existing_or_new(getfullname(ohc{1}));
                        
%                         fprintf('\t\t\t Adding: %s:%d ---> %s:%d \n', obj.all{n.my_id}, my_port, obj.all{other_node.my_id}, other_port(i) );
                        n.add_child(other_node, my_port, other_port(i));
                        
                    end
                    
                    return;
                end
                
                [~,~,other_node] = obj.get_existing_or_new(getfullname(other_handles));
                n.add_child(other_node, my_port, other_port);  
                
%                 fprintf('\t\t\t (Adding): %s:%d ---> %s:%d \n', obj.all{n.my_id}, my_port, obj.all{other_node.my_id}, other_port );

            end
            
        end
        
        function n = register_new_block(obj, h, blk_name)
            obj.NUM_BLOCKS = obj.NUM_BLOCKS + 1;
            n = obj.create_node(obj.NUM_BLOCKS, get_param(h, 'Ports'), [], h);
            obj.all{obj.NUM_BLOCKS} = blk_name;
            obj.handles{obj.NUM_BLOCKS} = h;
        end
        
        function n = create_node(obj, cur_blk, ports, search_names, handle)
%             search_names = strsplit(search_name, 'simulink/');  % Stripping of the simulink tag
            n = slbnode(handle, [], cur_blk);
            
            obj.nodes{cur_blk} = n;
            
            n.out_nodes = cell(1, ports(2));
            n.out_nodes_otherport = cell(1, ports(2));
            
%             if ports(1) > 0 || ports(2) > 0
%                 obj.num_reachable_nodes = obj.num_reachable_nodes + 1;
%             end
            
            
        end
    end
    
end

