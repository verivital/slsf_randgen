classdef graphutils < handle
    %GRAPHUTILS Handy Graph Algorithms
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        
        function [merged, num_nodes, sinks] = reverse_with_outports_merged(slb)
            num_nodes = slb.NUM_BLOCKS + 1;
            sinks = mycell();
            gnodes = cell(1, num_nodes);
            merged = gnode(num_nodes);
            
            for ii = 1:slb.NUM_BLOCKS
                c = slb.nodes{ii};
                if c.is_sink
                   c_n = merged;
                   sinks.add(c.my_id);
                else
                    c_n = gnode(c.my_id);
                end
                
                gnodes{ii} = c_n;
            end
            
            
            for ii = 1:slb.NUM_BLOCKS
                c = slb.nodes{ii};
                c_g = gnodes{ii};
                
                for i=1:numel(c.out_nodes)
                    for j=1:numel(c.out_nodes{i})
                        chld = c.out_nodes{i}{j};
                        chld_g = gnodes{chld.my_id};
                        
                        chld_g.add(c_g);
                    end
                end 
            end
        end
        
        function colors = dfs(start, num_nodes)
            fprintf('-- Starting DFS \n');
           
            WHITE = 0; % Unvisited
            GRAY = 1;   % Visited, in current DFS path
%             BLACK = 2; % Visited, but not in current DFS path

            colors = zeros(1, num_nodes);
           
            dfs_visit(start);
           
            fprintf('--- End DFS -- \n');
           
            function dfs_visit(v)
                fprintf('\t[DFS-GRAY] %d\n', v.my_id)
                colors(v.my_id) = GRAY;
                
                for i=1: v.num_children
                        chld = v.get_child(i);
                       
                        fprintf('\t\t\t[Child] %d ---> ** %d ** , color %d\n',v.my_id, chld.my_id, colors(chld.my_id));
                        
                        if colors(chld.my_id) == WHITE
                            fprintf('Will visit white child.\n');
                            dfs_visit(chld);
                        end
                    
                end
               
                fprintf('\t[DFS-BLACK] %d\n', v.my_id);
%                 colors(v.n.my_id) = BLACK;
            end
        end
        
        function ret = get_nodes_not_connected_to_outports(slb)
            [sink, num_nodes, sinks] = graphutils.reverse_with_outports_merged(slb);
            visited = graphutils.dfs(sink, num_nodes);
            
            for i=1:sinks.len
                
            end
            
        end
    end
    
end

