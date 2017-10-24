function numCycle = getCountCycles(slb)
%             fprintf('Inside get cycles\n');
            
            %ret = mycell();
            
%            assert(numel(slb.nodes) == slb.NUM_BLOCKS);
            
			adjacentMatrix = zeros(slb.NUM_BLOCKS, slb.NUM_BLOCKS);
            pathCount = zeros(slb.NUM_BLOCKS, slb.NUM_BLOCKS);
			for out_i=1:slb.NUM_BLOCKS
				curNode = slb.nodes{out_i};
				    for j=1:numel(curNode.out_nodes)
						for k=1:numel(curNode.out_nodes{j})
							chld = curNode.out_nodes{j}{k};
							adjacentMatrix(out_i,chld.my_id) = 1 ;
                            pathCount(out_i,chld.my_id)= pathCount(out_i,chld.my_id)+1;
						end
					 
				end
            end
	numCycle = find_elem_circuits(adjacentMatrix);
            
    function numcycles = find_elem_circuits(A)

        if ~issparse(A)
            A = sparse(A);
        end
        n = size(A,1);

        Blist = cell(n,1);

        blocked = false(1,n);

        s = 1;
        cycles = {};
        stack=[];

        function unblock(u)
            blocked(u) = false;
            for w=Blist{u}
                if blocked(w)
                    unblock(w)
                end
            end
            Blist{u} = [];
        end

        function f = circuit(v, s, C)
            f = false;
            stack(end+1) = v;
            blocked(v) = true;
            for w=find(C(v,:))
                if w == s
                    cycles{end+1} = [stack s];
                    f = true;
                elseif ~blocked(w)
                    if circuit(w, s, C)
                        f = true;
                    end
                end
            end
        
            if f
                unblock(v)
            else
                for w = find(C(v,:))
                    if ~ismember(v, Blist{w})
                        Bnode = Blist{w};
                        Blist{w} = [Bnode v];
                    end
                end
            end
        
            stack(end) = [];
        end


        while s < n
    
    % Subgraph of G induced by {s, s+1, ..., n}
            F = A;
            F(1:s-1,:) = 0;
            F(:,1:s-1) = 0;
    
    % components computes the strongly connected components of 
    % a graph. This function is implemented in Matlab BGL 
    % http://dgleich.github.com/matlab-bgl/
            [ci, sizec] = components(F);
    
            if any(sizec >= 2)
        
                cycle_components = find(sizec >= 2);
                least_node = find(ismember(ci, cycle_components),1);
                comp_nodes = find(ci == ci(least_node));
        
                Ak = sparse(n,n);
                Ak(comp_nodes,comp_nodes) = F(comp_nodes,comp_nodes);        
    
                s = comp_nodes(1);
                blocked(comp_nodes) = false;
                Blist(comp_nodes) = cell(length(comp_nodes),1);
                circuit(s, s, Ak);
                s = s + 1;
    
            else
                break;        
            end
        end
        numcycles= 0;
        for i=1:length(cycles)
            curCycle = cycles{i};
            curCycleCount=1;
            for j = 1:length(curCycle)-1
                curCycleCount = curCycleCount*pathCount(curCycle(j),curCycle(j+1));
            end
            numcycles = numcycles+ curCycleCount;
        end                

    end
end

