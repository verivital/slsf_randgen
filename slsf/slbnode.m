classdef slbnode < handle
    %SLBNODE Represents a SL block in the generated model
    %   Detailed explanation goes here
    
    properties(Constant=true)
        ACTION_PORT = -1;
    end
    
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
        
        is_source = false;
        is_sink = false;
        
        dft_status = [];
        
        is_outports_actionports = false;    % Whether the output ports of this blocks are always connected to action ports (e.g. If blocks)
        
        dfmutex_blocks = [];      % list. Data-flow mutually exclusive blocks. Other nodes which are related to this node and can not be in some data-flow path without a Delay . E.g. If-else action subsystems 
%         is_delay_block = false;     % Whether the block is a delay block
    end
    
    methods
        function obj = slbnode(handle, search_name, my_id)
            obj.handle = handle;
            obj.search_name = search_name;
            obj.my_id = my_id;
            
            obj.is_visited = false;
%             obj.dfmutex_blocks = mycell();
        end
        
        function obj = replace_child(obj, chld_position, new_chld, child_p)
            % chld_position is 2-element array. 1st element: at which port
            % of obj this chld is connected. 2nd element is the serial
            % number of the chld, as there are (possibly) other blocks
            % connected at this output port of the obj.
            obj.out_nodes{chld_position(1)}{chld_position(2)} = new_chld;
            obj.out_nodes_otherport{chld_position(1)}{chld_position(2)} = child_p;
            
            if child_p == 1
                new_chld.in_node_first = obj;
            end
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
%                     fprintf('Not empty! %d\n', obj.docref.in_dtypes.len);
%                     disp(obj.docref.in_dtypes)
                    ret = obj.docref.in_dtypes;
                    return;
                else
                    disp('empty input type!');

                end
                
            end
            
            ret = mycell({'double'}); % double is the default type
        end
        
        function [ret, in] = is_out_in_types_compatible(obj, out)
            ret = false;
            
            in = obj.get_input_type();
            
            fprintf('------ out-------\t');
            disp(out.get_cell());
            fprintf('------- in --------\t');
            disp(in.get_cell());
            
            % Warning: Following logic is flawed if there are multiple out
            % types. E.g. let out type = {int, double} and in_type =
            % {double}. Following logic will consider the types
            % "compatible" since we found one match. However, if the
            % out_type is int in concrete run, then we will need extra converter.
            
            for i=1:out.len
                for j = 1:in.len
                    if strcmp(out.get(i), in.get(j))
                        ret = true;
                        return;
                    end
                end
            end
            
            if ~ isempty(obj.docref)
                for i=1:out.len
                    for j = 1:in.len
                        ret = util.is_type_equivalent(out.get(i), in.get(j), obj.docref.is_signed_only);
                        if ret
                            return;
                        end
                    end
                end
            else
                fprintf('No docref found\n');
            end
            
            
            fprintf('*** Outs Ins Not Compatible! ***\n');
            
        end
        
        function ret = get_output_type(obj, fxd)
            ret = [];

            if fxd.source_dtypes.contains(obj.search_name)
                ret = fxd.source_dtypes.get(obj.search_name);
                fprintf('Got return data type from FIXED source\n');
                return;
            end
            
            if obj.is_source
                ret = mycell({'double'}); % TODO
                fprintf('Got DEFAULT return data type for SOURCE\n');
                return;
            end
            
            % If output types for this block are explicitly specified, use
            % them. For now only use the default output param.
            
            if ~isempty(obj.docref) && ~isempty(obj.docref.default_out_param) && util.is_nativelike_type(obj.docref.default_out_param)
                ret = mycell({obj.docref.default_out_param});
                if cfg.PRINT_TYPESMART
                    fprintf('Got parsed O/P data type; using default one: %s\n', obj.docref.default_out_param);
                end
                return;
            end
            
            if isempty(obj.in_type)
                fprintf('Input type fed by driving block is empty\n');
                if ~isempty(obj.dft_status)
                    if ~isempty(obj.docref) && obj.docref.out_dtypes.len > 0
                        ret = obj.docref.out_dtypes;
                        fprintf('Got return data type from parsing SL docs\n');
                        return;
                    end
                    
                    ret = mycell({'double'});
                    fprintf('Got DEFAULT return data type for NON-DFT\n');
                    return;

                else
                    throw(MException('SL:RandGen:NODT', 'No Out Data Type Found'));
                end
            else
                ret = obj.in_type;
                fprintf('Got FED  data-type from input port\n');
                return;
            end
            
            
            
%             if ~ isempty(obj.docref)
%                 if obj.docref.is_source
%                     ret = mycell({'double'});
%                     fprintf('Got DEFAULT return data type for SOURCE: %s\n', ret);
%                     return;
%                 elseif ~isempty(obj.dft_status)
%                     if obj.docref.out_dtypes.len > 0
%                         ret = obj.docref.out_dtypes;
%                         fprintf('Got return data type from parsing: %s\n', ret);
%                         return;
%                     end
%                 end
%             end
%             
%             ret = mycell({'double'});
        end
        
        
        function [ret, current] = check_loop(obj, num_blocks)
            fprintf('====== Checking loop for %d=====\n', obj.my_id);
            
            ret = false;
            
            dfs = CStack();
            
            dfs.push(slbnodetags(obj));
            
            visited = zeros(num_blocks);
            
            while ~ dfs.isempty()
                current = dfs.pop();
                
                fprintf('Popped %d\n', current.n.my_id);
                
                if visited(current.n.my_id)
                    if current.n.my_id == obj.my_id
                        fprintf('[x!x] Visiting self !! Alg Loop in node %d\n', obj.my_id);
                        
                        ret = true;
                        return;
                    else
                        fprintf('ID mismatch.\n');
                    end
                    
                    fprintf('continue...\n');
                    continue; % Cycle detected
                end
                
                visited(current.n.my_id) = 1;
                
                for i=1:numel(current.n.out_nodes)
                    for j=1:numel(current.n.out_nodes{i})
                        
                        chld = current.n.out_nodes{i}{j};
                        chld_tagged = slbnodetags(chld);
                        
                        chld_tagged.which_input_port = current.n.out_nodes_otherport{i}{j};
                        chld_tagged.which_parent_block = current.n;
                        chld_tagged.which_parent_port = [i, j];
                        
                        fprintf('Pushing %d\n', chld_tagged.n.my_id);
                        dfs.push(chld_tagged);
                    end
                end
                
            end
            
        end
        
        
%         function ret = is_direct_feedthrough(obj, dfports)
%             fprintf('====== Checking DirectFT for %d=====\n', obj.my_id);
%             ret = false;
%             
%             dfs = CStack();
%             
%             dfs.push(slbnodetags(obj));
%             
%             while ~ dfs.isempty()
%                 current = dfs.pop();
%                 
%                 fprintf('Popped %d\n', current.my_id);
%                 
%                 if current.is_visited % Won't work
%                     if current.n.id == obj.n.id
%                         fprintf('[x!x] Visiting self !!\n');
%                         
%                         if util.cell_in(dfports, current.which_input_port)
%                             warning('[x!x] Algebraic Loop detected!');
%                             ret = true;
%                             return;
%                         else
%                             fprintf('Not alg loop \n');
%                         end
%                     end
%                     
%                     continue; % Cycle detected
%                 end
%                 
%                 current.is_visited = true;
%                 
%                 for i=1:numel(c.n.out_nodes)
%                     for j=1:numel(c.n.out_nodes{i})
%                         chld = c.n.out_nodes{i}{j};
%                         chld_tagged = slbnodetags(chld);
%                         chld_tagged.which_input_port = c.n.out_nodes_otherport{i}{j};
%                         dfs.push(chld_tagged);
%                     end
%                 end
%                 
%             end
%         end
        
%         function ret = get_tagged_one(obj, inp_port, parent_blk, parent_port)
%             ret = slbnodetags(obj);
%         end
    end
    
end

