classdef slblocks < handle
    %SLBLOCKS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        NUM_BLOCKS;
        
        all;
        handles;
       
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