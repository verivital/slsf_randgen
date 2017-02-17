classdef simulator < handle
    %SIMULATOR Try to simulate a constructed model
    %   Detailed explanation goes here
    
    properties
        generator;
        max_try;
        
        sim_status = [];
        
        fixed_blocks;
        
        
        % Data type fixer related
        last_handle = [];
        last_at_output = [];
    end
    
    
    
    methods
        
        
        function obj = simulator(generator, max_try)
            % CONSTRUCTOR %
            obj.generator = generator;
            obj.max_try = max_try;
            obj.fixed_blocks = mymap();
        end
        
        
        function found = is_block_fixed_before(obj, exc, blk, add)
            found = false;
            d = obj.fixed_blocks.get(exc);
    
            if isempty(d) && add
                % Not Found
                d = mymap.create_from_cell({blk});
                obj.fixed_blocks.put(exc, d);
            else
                if d.contains(blk)
                    found = true;
                    % No need to add!
                elseif add
                    d.put(blk, 1);
                    obj.fixed_blocks.put(exc, d);
                end
            end
            
        end
        
        
        
        
        function obj = sim(obj)
            % A wrapper to the built in `sim` command - which is used to
            % start the simulation.
            obj.sim_status = [];
            myTimer = timer('StartDelay',cfg.SL_SIM_TIMEOUT, 'TimerFcn', {@sim_timeout_callback, obj});
%             myTimer = timer('StartDelay',obj.simulation_timeout, 'TimerFcn',['set_param(''' obj.generator.sys ''',''SimulationCommand'',''stop'')']);
            start(myTimer);
            try
                sim(obj.generator.sys);
                disp(['RETURN FROM SIMULATION. STATUS: ' obj.sim_status ]);
                stop(myTimer);

                delete(myTimer);
            catch e
                throw(e);
            end
            
            if ~isempty(obj.sim_status) && ~strcmp(obj.sim_status, 'stopped')
                disp('xxxxxxxxxxxxxxxx SIMULATION TIMEOUT xxxxxxxxxxxxxxxxxxxx');
                throw(MException('RandGen:SL:SimTimeout', 'TimeOut'));
            end
            
        end
        
        function obj = df_analysis_all_nodes(obj, slb, fxd)
            fprintf('DF Analysis for All Nodes\n');
            
            for i=1:numel(slb.nodes)
                n = slb.nodes{i};
                n.is_direct_feedthrough(fxd.df.get(n.search_name));
            end
            
            fprintf('END F Analysis for All Nodes\n');
        end
        
        
        function obj = pre_sim_analysis(obj, slb)
            fprintf('@@@@@@@@@@@@@@@ PRE SIMULATION ANALYSIS @@@@@@@@@@@@@@@\n');
            
            fxd = slblockdocfixed.getInstance();
            
            obj.df_analysis_all_nodes(slb, fxd);
            
            
            dfs = CStack();
            second_stack = CStack();
            
            for i=1:slb.sources.len
                c_s = slb.sources.get(i);
                fprintf('pushing %d\n', c_s.my_id);
                dfs.push(slbnodetags(c_s));
            end
            
            num_visited = 0;
            
            
            
            while true
                
                if dfs.isempty()
                    if second_stack.isempty()
                        fprintf('Both stacks empty. Done!\n');
                        break;
                    else
                        fprintf('--- Processing 2nd stack ---\n');
                        temp_s = dfs;
                        dfs = second_stack;
                        second_stack = temp_s;
                    end
                end
                
                c = dfs.pop();
                fprintf('\t\t\t\t\t\t\t\t\t\t\t\tPopped %d\n', c.n.my_id);
                
                if c.n.is_visited
                    fprintf('%d is already visited\n', c.n.my_id);
                    continue;
                end
                
                
                fprintf('\t\t\t\tVisiting %d\n', c.n.my_id);
                c.n.is_visited = true;
                num_visited = num_visited + 1;                
                
                % Get my output type
                my_out_type = c.n.get_output_type(fxd);
                

                for i=1:numel(c.n.out_nodes)
                    for j=1:numel(c.n.out_nodes{i})
                        chld = c.n.out_nodes{i}{j};
                        
                        % Get In type
                        
                        chld_in_types = chld.get_input_type();
                        
                        is_compatible = chld.is_out_in_types_compatible(my_out_type, chld_in_types);
                        
                        if ~ is_compatible
                            fprintf('Out: %s ||| In: %s\n', c.n.search_name, chld.search_name);
                        end
                        
                        if c.n.out_nodes_otherport{i}{j} == 1
                            chld_tagged = slbnodetags(chld);
                            fprintf('pushing %d\n', chld.my_id);
                            dfs.push(chld_tagged);
                        else
                            fprintf('Not Pushing %d; pushed %d\n', chld.my_id, chld.in_node_first.my_id);
                            second_stack.push(slbnodetags(chld.in_node_first));
                        end
                        
                        
                    end
                end
            end
            
%             if num_visited ~= numel(slb.all)
%                 num_visited
%                 error('Num visited is not equal to all blocks.');
%             end
            
            fprintf('@@@@@@@@@@@@@@@ END PRE SIMULATION ANALYSIS @@@@@@@@@@@@@@@\n');
        end
        
        
        function ret = simulate(obj, slb)
            % Returns true if simulation did not raise any error.
            
            done = false;
            ret = false;
            
            if isempty(slb)
                throw(MException('SL:RandGen:Unexpected', 'SLB ref is empty!'));
            end
            
            if cfg.GENERATE_TYPESMART_MODELS
                obj.pre_sim_analysis(slb);
            else
                fprintf('TypeSmart generation analysis is turned off\n');
            end
            
%             warning('Returning abruptly before simulating \n');
%             return;
            
            for i=1:obj.max_try
                disp(['(s) Simulation attempt ' int2str(i)]);
                
                found = false;
                
                try
                    obj.sim();
                    disp('Success simulating in SIMULATOR.M module!');
                    done = true;
                    ret = true;
                    found = true; % So that we eliminate alg. loops
                catch e
                    disp(['[E] Error in simulation: ', e.identifier]);
                    obj.generator.my_result.exc = e;
                    
                    if(strcmp(e.identifier, 'RandGen:SL:SimTimeout'))
                        obj.generator.my_result.set_to(singleresult.NORMAL, cfg.SL_SIM_TIMEOUT);
                        return;
                    end
                    
                    e
                    e.message
                    e.cause
                    e.stack
                    
                    disp('-------------- Fixing Simulation --------------');
                    
                    is_multi_exception = false;
                    
                    if(strcmp(e.identifier, 'MATLAB:MException:MultipleErrors'))
                        
                        for m_i = 1:numel(e.cause)
                            disp(['Multiple Errors. Solving ' int2str(m_i)]);
                            ei = e.cause{m_i}
                            obj.generator.my_result.exc = ei;

                            ei.message
                            ei.cause
                            ei.stack

                            disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
                            
                            [done, ret, found] = obj.look_for_solutions(ei, true, done, ret);
                            
                            if found
                                disp('Found at least one exception fixer. Breaking.');
                                break;
                            end
                            
                        end

                    else
                        [done, ret, found] = obj.look_for_solutions(e, false, done, ret);
                    end

                end
                
                if done && found % Don't waste executing below block if simulation fixer was not done.
                    try
                        obj.alg_loop_eliminator();
                    catch e
                        done = false;
                        ret = false;
                        fprintf('Error in algebraic loop elimination: %s. Will try simulating again. \n', e.identifier);
                    end
                end
                
                if done
                    disp('(s) Exiting from simulation attempt loop');
                    break;
                end
                
                
            end         %       fix-and-simulate loop

                    
        end
        
        
        
        function [done, ret, found] = look_for_solutions(obj, e, is_multi_exception, done, ret)
            found = false;          % Did the exception matched with any of our fixers
            
            if isa(e, 'MSLException')

                if util.starts_with(e.identifier, 'Simulink:Engine:AlgLoopTrouble')
                    obj.fix_alg_loop(e);
                    found = true;
                elseif util.starts_with(e.identifier, 'Simulink:Engine:PortDimsMismatch')
                    [done, found] = obj.fix_port_dimensions_mismatch(e);
                else

                    switch e.identifier
                        case {'Simulink:Engine:AlgStateNotFinite', 'Simulink:Engine:UnableToSolveAlgLoop', 'Simulink:Engine:BlkInAlgLoopErr'}
                            obj.fix_alg_loop(e);
                            found = true;
%                         case {'Simulink:utility:GetAlgebraicLoopFailed'}
%                             % Will fix in next FAS attempt. This is the
%                             % case when sim() is successful, but algebraic
%                             % loop eliminator introduced a new problem and 
%                             % failed to simulate. In this case another
%                             % round of simulation is needed to fix the new
%                             % problem
%                             found = true;
                        case {'Simulink:Parameters:InvParamSetting'}
                            obj.fix_invParamSetting(e);
                            done = true;                                    % TODO
                            found = true;
                        case {'Simulink:Engine:InvCompDiscSampleTime', 'Simulink:blocks:WSTimeContinuousSampleTime'}
                            done = obj.fix_inv_comp_disc_sample_time(e, is_multi_exception);
                            ret = done;                             
                            found = true;
                        case{'Simulink:DataType:InputPortDataTypeMismatch', 'SimulinkBlock:Foundation:SignedOnlyPortDType', 'Simulink:DataType:InvDisagreeInternalRuleDType'}
                            done = obj.fix_data_type_mismatch(e, 'both');
                            found = true;
                        case {'Simulink:DataType:PropForwardDataTypeError', 'Simulink:blocks:DiscreteFirHomogeneousDataType', 'Simulink:blocks:SumBlockOutputDataTypeIsBool'}
                            done = obj.fix_data_type_mismatch(e, 'both');
                            found = true;
                        case {'Simulink:DataType:PropBackwardDataTypeError'}
                            done = obj.fix_data_type_mismatch(e, 'both');
                            found = true;
                        case {'SimulinkFixedPoint:util:fxpBitOpUnsupportedFloatType'}
                            done = false;
                            obj.fix_data_type_mismatch(e, 'input', {{'OutDataTypeStr', 'boolean'}});
                            obj.fix_data_type_mismatch(e, 'output');
                            found = true;
                            
                        case {'Simulink:SampleTime:BlkFastestTsNotGCDOfInTs'}
%                             disp('HEREEEEE');
                            done = obj.fix_st_gcd(e);
                            found = true;
                            
                        case {'Simulink:blocks:NormModelRefBlkNotSupported'}
                            done = obj.fix_normal_mode_ref_block(e);
                            found = true;
                            
                        case {'Simulink:Engine:SolverConsecutiveZCNum'}
                            done = obj.fix_solver_consecutive_zc(e);
                            found = true;
                            
                        otherwise
                            done = true;
                    end
                end

            else
                done = true;                                        % TODO
            end
        end  
        
        function done = fix_solver_consecutive_zc(obj, e)
            done = false;
            set_param(obj.generator.sys, 'ZeroCrossAlgorithm', 'Adaptive');
        end
        
        
        function done = fix_normal_mode_ref_block(obj, e)
            done = false;
            for j = 1:numel(e.handles)
%                 fprintf('XXXXXXXXXXXXXXXX \n' );
                handles = e.handles{j};
%                 get_param(handles, 'Name')
                set_param(handles, 'SimulationMode', 'Accelerator');
            end
            
        end
        
        
        function done = fix_inv_comp_disc_sample_time(obj, e, do_parent)
            done = false;
            MAX_TRY = 10;
            
            for i=1:MAX_TRY
                disp(['Attempt ' int2str(i) ' - Fixing inv-disc-comp-sample-time.']);
                try
                    
                    for j = 1:numel(e.handles)
                        handles = e.handles{j};
                        
                        for k = 1:numel(handles)
                            h = handles(k);
                            
                            if do_parent
                                h = get_param(get_param(h, 'Parent'), 'Handle');
                            end
                            
                            disp(['Current Block: ' get_param(h, 'Name')]);
                            set_param(h, 'SampleTime', num2str(rand));
                        end
                        
                    end
                    
                    % Try Simulating
                    obj.sim();
%                     sim(obj.generator.sys);
                    disp('Success in fixing inv-disc-comp-sample-time!');
                    done = true;
                    return;
                catch e
                    if ~ strcmp(e.identifier, 'Simulink:Engine:InvCompDiscSampleTime')
                        disp(['[E] Some other error occ. when fixing sample time: ']);
                        e
                        return;
                    end
                end
            end
            
        end
        
        
        function [done, found] = fix_port_dimensions_mismatch(obj, e)
            done = false;
            found = false;
            
            for j = 1:numel(e.handles)
                handles = e.handles{j};
                blkFullName = getfullname(handles)
                blkType = get_param(handles, 'blocktype')
                if strcmp(blkType, 'CombinatorialLogic')
                    
                    if obj.is_block_fixed_before(e.identifier, blkFullName, true)
                        % Block was previously addressed. Most likely is
                        % that there is another block with same exception,
                        % at subsequent positions of the Multiple Error. So
                        % try those blocks. found = false already.
                    else
                        obj.fix_combinatorial_logic_block(handles);
                        found = true;
                    end
                end
            end
            
        end
        
        function obj = fix_combinatorial_logic_block(obj, handle)
            % Creates One input port and One output port.
            disp('Fixing comb logic block...');
            rs = randi([0 1], 2, 1); % Two random integers from 0 and 1
            set_param(handle, 'TruthTable', sprintf('[%d;%d]', rs(1), rs(2)));
        end
        
        
        function done = fix_data_type_mismatch(obj, e, loc, blk_params)
            
            if nargin < 4
                blk_params = []; % Parameters for the new block
            end
            
            
            disp('FIXING DATA TYPE MISMATCH...');
            done = false;
            
%             if ~isempty(obj.last_handle) && strcmp(obj.generator.last_exc.identifier, e.identifier)
%                 disp('Same error as last one. Check for handle...');
%                 if obj.last_handle == 
%             end
            
            for i = 1:numel(e.handles)
                inner = e.handles{i};

                h = util.select_me_or_parent(inner);

%                 if at_output
                switch loc
                    case {'output'}
                        new_blocks = obj.add_block_in_the_middle(h, 'Simulink/Signal Attributes/Data Type Conversion', true, false);
                        break;
                    case {'input'}
                        new_blocks = obj.add_block_in_the_middle(h, 'Simulink/Signal Attributes/Data Type Conversion', false, true);
                        break;
                    case {'both'}
                        new_blocks = obj.add_block_in_the_middle(h, 'Simulink/Signal Attributes/Data Type Conversion', true, false);
                        more_new = obj.add_block_in_the_middle(h, 'Simulink/Signal Attributes/Data Type Conversion', false, true);
                        new_blocks.extend(more_new);
                        break;
                    otherwise
                        throw(MException('RandGen:FixDataType:InvalidValForParamLOC', 'Invalid value for parameter loc'));
                end
            end
            
            if ~isempty(blk_params) 
                for i=1:new_blocks.len
                    for j=1:numel(blk_params)
                        set_param(new_blocks.get(i), blk_params{j}{1}, blk_params{j}{2});
                    end
                end
            end
                 
        end
        
        function done = fix_st_gcd(obj, e)
            disp('FIXING Sample Time not GCD...');
            done = false;
                        
            for i = 1:numel(e.handles)
                inner = e.handles{i};

                h = util.select_me_or_parent(inner);
                obj.add_block_in_the_middle(h, sprintf('simulink/Discrete/Zero-Order\nHold'), false, true);
            end
        end
        
        
        
        function obj = fix_alg_loop(obj, e)
            % Fix Algebraic Loop 
%             handles = e.handles{1}

%             handles(1)
%             handles(2)
%             
%             disp('here');
            
            for ii = 1:numel(e.handles)
                current = e.handles{ii};
                
                for i=1:numel(current)
%                     disp('in loop');
                    if ~strcmp(get_param(current(i), 'Type'), 'block')
                        disp('Not a block! Skipping...');
                        continue;
                    end
                    h = util.select_me_or_parent(current(i));
                    new_delay_blocks = obj.add_block_in_the_middle(h, 'Simulink/Discrete/Delay', false, true);
                    for xc = 1:new_delay_blocks.len
                        set_param(new_delay_blocks.get(xc), 'SampleTime', '1');                  %       TODO sample time
    %                     disp(h);
                    end
                    
                    
                    
                end
                
                
            end
        end
        
        
        
        
        
        
        
        function ret = add_block_in_the_middle(obj, h, replacement, ignore_in, ignore_out)
  
            ret = mycell(-1);
            
            my_name = get_param(h, 'Name');

            disp(['Add Block in the middle: For ' my_name '; handle ' num2str(h)]);
            
            if ignore_in
                disp('INGORE INPUTS');
            end
            
            if ignore_out
                disp('IGNORE OUTPUTS');
            end

            try
                ports = get_param(h,'PortConnectivity');
            catch e
                disp('~ Skipping, not a block');
                return;
            end

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
                    if ignore_in
                        disp(['Skipping input port ' int2str(j)]);
                        continue;
                    end
                    other_name = get_param(p.SrcBlock, 'Name');
                    other_port = p.SrcPort + 1; 
                    dir = 'from';
                else
                    if ignore_out
                        disp(['Skipping output port ' int2str(j)]);
                        continue;
                    end
                    dir = 'to';
                    other_name = get_param(p.DstBlock, 'Name');
                    other_port = p.DstPort + 1; 
                end 
                
                if isempty(other_name)
                    disp('Can not find other end of the port. No blocks there or port misidentified');
                    % For example if an OUTPUT port 'x' of a block is not
                    % connected, that port 'x' will be wrongly identified
                    % as an INPUT port, and at this point variable
                    % `other_name` is empty as there is no other blocks
                    % connected to this port.
                    continue;
                end
                
                my_b_p = [my_name '/' p.Type];
                
                if numel(other_port) > 1
                    disp('Multiple src/ports Here');
                    other_name
                    other_port
                    d_h = obj.add_block_in_middle_multi(my_b_p, other_name, other_port, replacement);
                    ret.add(d_h);
                    return;
                end

                disp(['Const. ' dir ' ' other_name ' ; port ' num2str(other_port) '; My type ' p.Type ]);

                other_b_p = [other_name '/' num2str(other_port)];
                

                % get a new block

                [d_name, d_h] = obj.generator.add_new_block(replacement);
                ret.add(d_h);

                %  delete and Connect

                new_blk_port = [d_name '/1'];
                
                if is_inp
                    b_a = other_b_p;
                    b_b = my_b_p;
                    
                else
                    b_a = my_b_p;
                    b_b = other_b_p;
                end
                
                delete_line( obj.generator.sys, b_a , b_b);
                add_line(obj.generator.sys, b_a, new_blk_port , 'autorouting','on');
                add_line(obj.generator.sys, new_blk_port, b_b , 'autorouting','on');
                
                disp('Done adding block!');

               

            end
            
            
        end
        
        
        
        function d_h = add_block_in_middle_multi(obj,my_b_p, o_names, o_ports, replacement)
            
            % get a new block

            [d_name, d_h] = obj.generator.add_new_block(replacement);

            %  delete and Connect

            new_blk_port = [d_name '/1'];
            add_line(obj.generator.sys, my_b_p, new_blk_port , 'autorouting','on');
                        
            for i = 1:numel(o_ports)
                other_b_p = [char(o_names(i)), '/', num2str(o_ports(i))];
                
                delete_line( obj.generator.sys, my_b_p , other_b_p);
                add_line(obj.generator.sys, new_blk_port, other_b_p , 'autorouting','on');
            end
            
        end
        
        
        
        
        function obj = fix_invParamSetting(obj, e)
%             e
%             e.message
%             e.cause
%             e.stack
        end
        
        
        function obj = alg_loop_eliminator(obj)
      
            num_max_attempts = 3;
            
            for gc = 1:num_max_attempts
                
                fprintf('Starting alg. loop eliminator... attempt %d\n', gc);
                
                aloops = Simulink.BlockDiagram.getAlgebraicLoops(obj.generator.sys);
            
                if numel(aloops) == 0
                    fprintf('No Algebraic loop. Returning...\n');
                    return;
                end

                for i = 1:numel(aloops)
                    cur_loop = aloops(i);

                    visited_handles = mycell(-1);

                    for j = 1:numel(cur_loop.VariableBlockHandles)
                        j_block = cur_loop.VariableBlockHandles(1);
                        effective_j_blk = util.select_me_or_parent(j_block);

                        fprintf('j blk: %s \t effective blk: %s\n',get_param(j_block, 'name'), get_param(effective_j_blk, 'name'));

                        if util.cell_in(visited_handles.data, effective_j_blk)
                            fprintf('Blk already visited\n');
                        else

                            visited_handles.add(effective_j_blk);
                            
                            fprintf('[AlgLoopEliminator] Adding new block....\n');
                            new_delay_blocks = obj.add_block_in_the_middle(effective_j_blk, 'Simulink/Discrete/Delay', false, true);
                            for xc = 1:new_delay_blocks.len
                                new_delay_block = new_delay_blocks.get(xc);
                                fprintf('[AlgLoopEliminator] Done adding block %s\n', get_param(new_delay_block, 'Name'));
                                set_param(new_delay_block, 'SampleTime', '1'); 
                                fprintf('[AlgLoopEliminator] Handled sample time.\n');
                            end
                        end
                    end
                end
            end
        end
        
        
        
    end
    
end

