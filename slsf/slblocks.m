classdef slblocks < handle
    %SLBLOCKS Aggregated information about blocks in the generated model
    %   Contains following information:
    
    
    properties
        NUM_BLOCKS;
        
        all;                            % A cell containing name (e.g. bl1, bl2) of all blocks
        handles;                   % Cell containing handles of all blocks
        nodes;                      % Cell contaiing slbnode instances for all blocks
        sources;                    % mycell containing all source nodes
        nondfts;                    % mycell containing all non-DFT or conditionally DFT nodes.
       
        inp = struct('len', 0);     
        inp_ports;              % Cell containing X for all blocks. 
        
        oup = struct('len', 0);
        oup_ports;
        
        num_inp_ports = 0;
        num_oup_ports = 0;
        
        fixed_doc;                     % Reference to Fixed SL doc.
        
        num_reachable_nodes = 0;        % Count of nodes (blocks) which can be visited by graph search. Some blocks don't have inputs and outputs.
    end
    
    methods
        
        function obj = slblocks(num_blocks)
            % CONSTRUCTOR
            obj.NUM_BLOCKS = num_blocks;
            
            obj.all = cell(1, num_blocks);
            obj.handles = cell(1, num_blocks);

            
            obj.inp_ports = cell(1, num_blocks);
            obj.oup_ports = cell(1, num_blocks);
            
            obj.inp.blocks = cell(1, num_blocks);
            obj.oup.blocks = cell(1, num_blocks);
            
            obj.nodes = cell(1, num_blocks);
            
            obj.sources = mycell();
            obj.nondfts = mycell();
            
            obj.fixed_doc = slblockdocfixed.getInstance();
            
        end
        
        function n = register_new_block(obj, h, search_name, blk_name)
            obj.NUM_BLOCKS = obj.NUM_BLOCKS + 1;
            n = obj.create_node(obj.NUM_BLOCKS, get_param(h, 'Ports'), search_name, h);
            obj.all{obj.NUM_BLOCKS} = blk_name;
            obj.handles{obj.NUM_BLOCKS} = h;
        end
        
        function n = create_node(obj, cur_blk, ports, search_name, handle)
            
%             if strcmp(search_name, 'simulink/Ports & Subsystems/If')
%                 is_outports_actionports = true;
%             else
%                 is_outports_actionports = false;
%             end
            
            search_names = util.strip_simulink_prefix(search_name);  % Stripping of the simulink tag
            n = slbnode(handle, search_names, cur_blk);
            
            obj.nodes{cur_blk} = n;
            
%             n.is_outports_actionports = is_outports_actionports;
            
            n.out_nodes = cell(1, ports(2));
            n.out_nodes_otherport = cell(1, ports(2));
            
            if ports(1) > 0 || ports(2) > 0
                obj.num_reachable_nodes = obj.num_reachable_nodes + 1;
            end
            
            if ~ cfg.GENERATE_TYPESMART_MODELS
                return;
            end
            
            sldoc = slblockdocparser.getInstance();
            docref = sldoc.get(search_names);
                        
            n.docref = docref;
            
            if ~isempty(docref)
                if docref.is_source
                    n.is_source = true;
                    obj.sources.add(n);
                end
                n.is_sink = docref.is_sink;
            else
%                 warning(['No Doc Ref found for ' search_names{2}]);
%                 throw(MException('SL:RandGen:NoDocRefFound', 'no doc ref found'));
            end
            
            dft_stat = obj.fixed_doc.get(search_names, slblockdocfixed.DFT);
            if ~isempty(dft_stat)
                fprintf('\tDFT status found for node %s\n', search_name);
                n.dft_status = dft_stat;
                obj.nondfts.add(n);
            else
                fprintf('\tDFT status NOT found for node %s\n', search_name);
            end
            
            
            
        end
        
        function obj = connect_nodes(obj, o_b, o_p, i_b, i_p)
            % Warning: In the implementation of this function, do not do
            % anything other than node-specific tasks.
            o_n = obj.nodes{o_b};
            i_n = obj.nodes{i_b};
            
            o_n.add_child(i_n, o_p, i_p);
        end
        
        
        function obj = new_block_added(obj, cur_blk, ports)
            num_inputs_cell = cell(1, ports(1));
            [num_inputs_cell{:}] = deal(0);

            obj.inp_ports{cur_blk} = num_inputs_cell;

            if ports(1) > 0
%                 num_inp_blocks = num_inp_blocks + 1;
%                 inp_blocks{num_inp_blocks} = cur_blk;
                
                obj.inp.len = obj.inp.len + 1;
                obj.inp.blocks{obj.inp.len} = cur_blk;
                
                obj.num_inp_ports = obj.num_inp_ports + ports(1);
            end

            % Outpgit uts

            outputs_cell = cell(1, ports(2));
            [outputs_cell{:}] = deal(0);

            obj.oup_ports{cur_blk} = outputs_cell;

            if ports(2) > 0
%                 num_oup_blocks = num_oup_blocks + 1;
%                 oup_blocks{num_oup_blocks} = cur_blk;
                
                obj.oup.len = obj.oup.len + 1;
                obj.oup.blocks{obj.oup.len} = cur_blk;
                
                
%                 num_oup_ports = num_oup_ports + ports(2);
                
                obj.num_oup_ports = obj.num_oup_ports + ports(2);
            end
        end
        
        
    end
    
end