classdef slbnode < handle
    %SLBNODE Represents a SL block in the generated model
    %   Detailed explanation goes here
    
    properties
        out_type = [];   % Output type. Assumes all ports have same output type
        in_type = [];    % Input type of the signal at first input port
        
        in_node_first = []; % Node connected at my FIRST input port.
        out_nodes = {};     % Other slbnodes at each output port.
        out_nodes_otherport = {};   % At which input port of the other node this connection is made
        
        name;
        
        is_visited;
        
        handle;
        search_name;
        docref = [];
        
        my_id;
    end
    
    methods
        function obj = slbnode(handle, search_name, my_id)
            obj.handle = handle;
            obj.search_name = search_name;
            obj.my_id = my_id;
            
            obj.is_visited = false;
        end
        
        function obj = add_child(obj, child_node, my_p, child_p)
            if (numel(obj.out_nodes) < my_p) || isempty(obj.out_nodes{my_p})
                obj.out_nodes{my_p} = {};
                obj.out_nodes_otherport{my_p} = {};
            end
            
            obj.out_nodes{my_p}{numel(obj.out_nodes{my_p}) + 1} = child_node;
            obj.out_nodes_otherport{my_p}{numel(obj.out_nodes_otherport{my_p}) + 1} = child_p;
            
            if child_p == 1
                child_node.in_node_first = obj;
            end
        end
        
%         function ret = get_tagged_one(obj, inp_port, parent_blk, parent_port)
%             ret = slbnodetags(obj);
%         end
    end
    
end

