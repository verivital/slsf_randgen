classdef slblocks < handle
    %SLBLOCKS Information about blocks in the generated model
    %   Detailed explanation goes here
    
    properties
        NUM_BLOCKS;
        
        all;
        handles;
        nodes;
        sources;
       
        inp = struct('len', 0);
        inp_ports;
        
        oup = struct('len', 0);
        oup_ports;
        
        num_inp_ports = 0;
        num_oup_ports = 0;
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
            
        end
        
        function obj = create_node(obj, cur_blk, ports, search_name, handle)
            search_names = strsplit(search_name, 'simulink/');
            n = slbnode(handle, search_names{2}, cur_blk);
            
            obj.nodes{cur_blk} = n;
            
            sldoc = slblockdocparser.getInstance();
            docref = sldoc.get(search_names{2});
                        
            n.docref = docref;
            
            if ~isempty(docref)
                if docref.is_source
                    obj.sources.add(n);
                end
            else
%                 warning(['No Doc Ref found for ' search_names{2}]);
%                 throw(MException('SL:RandGen:NoDocRefFound', 'no doc ref found'));
            end
            
            n.out_nodes = cell(1, ports(2));
            n.out_nodes_otherport = cell(1, ports(2));
            
            
        end
        
        function obj = connect_nodes(obj, o_b, o_p, i_b, i_p)
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

            % Outputs

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