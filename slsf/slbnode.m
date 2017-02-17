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
        
        function ret = get_input_type(obj)
            if ~ isempty(obj.docref)
                
    %           fprintf('Got return data type from source: %s\n', ret);
                
                if obj.docref.in_dtypes.len ~= 0
                    fprintf('Not empty! %d\n', obj.docref.in_dtypes.len);
                    disp(obj.docref.in_dtypes)
                    ret = obj.docref.in_dtypes;
                    return;
                else
                    disp('empty!');
                    
                end
                
            end
            
            ret = mycell({'double'});
        end
        
        function ret = is_out_in_types_compatible(obj, out, in)
            ret = false;
            for i=1:out.len
                for j = 1:in.len
                    if strcmp(out.get(i), out.get(j))
                        ret = true;
                        return;
                    end
                end
            end
            fprintf('*** Outs Ins Not Compatible! ***\n');
            disp('out')
            disp(out.data);
            disp('in')
            disp(in.data);
        end
        
        function ret = get_output_type(obj, fxd)
            ret = [];
            
            
            if fxd.source_dtypes.contains(obj.search_name)
                ret = fxd.source_dtypes.get(obj.search_name);
%                 fprintf('Got return data type from FIXED source: %s\n', ret);
                return;
            end
            
            if ~ isempty(obj.docref)
                if obj.docref.is_source
                    ret = mycell({'double'});
%                     fprintf('Got return data type from source: %s\n', ret);
                    return;
                else
%                     fprintf('Got return data type from source: %s\n', ret);
                    ret = obj.docref.out_dtypes;
                    return;
                end
            end
            
            ret = mycell({'double'});
        end
        
        function ret = is_direct_feedthrough(obj, dfports)
            fprintf('====== Checking DirectFT for %d=====\n', obj.my_id);
            ret = false;
            
            dfs = CStack();
            
            dfs.push(slbnodetags(obj));
            
            while ~ dfs.isempty()
                current = dfs.pop();
                
                if current.is_visited
                    if current.n.id == obj.n.id
                        fprintf('[x!x] Visiting self !!\n');
                        
                        if util.cell_in(dfports, current.which_input_port)
                            warning('[x!x] Algebraic Loop detected!');
                            ret = true;
                            return;
                        else
                            fprintf('Not alg loop \n');
                        end
                    end
                    
                    continue; % Cycle detected
                end
                
                current.is_visited = true;
                
                for i=1:numel(c.n.out_nodes)
                    for j=1:numel(c.n.out_nodes{i})
                        chld = c.n.out_nodes{i}{j};
                        chld_tagged = slbnodetags(chld);
                        chld_tagged.which_input_port = c.n.out_nodes_otherport{i}{j};
                        dfs.push(chld_tagged);
                    end
                end
                
            end
        end
        
%         function ret = get_tagged_one(obj, inp_port, parent_blk, parent_port)
%             ret = slbnodetags(obj);
%         end
    end
    
end

