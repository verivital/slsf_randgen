classdef simulator < handle
    %SIMULATOR Try to simulate a constructed model
    %   Performs the "Fix Error" Phase of CyFuzz
    
    properties
        generator;
        max_try;
        
        sim_status = [];
        
        fixed_blocks;
        
        
        % Data type fixer related
        last_handle = [];
        last_at_output = [];
        
        visited_nodes;
        num_visited;
        
        active_sys = [];    % Instead of using the top-most model, use this field to provide the child model's name 
        %when trying to fix child model from a parent model.
        
        fxd = [];      
    end
    
    
    
    methods
        
        
        function obj = simulator(generator, max_try)
            % CONSTRUCTOR %
            obj.generator = generator;
            obj.max_try = max_try;
            obj.fixed_blocks = mymap();
        end
        
        
        function found = is_block_fixed_before(obj, exc, blk, add)
            % Will also add the block if `add` is set to true.
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
        
%         function obj = df_analysis_all_nodes(obj, slb, fxd)
%             fprintf('DF Analysis for All Nodes\n');
%             
%             for i=1:numel(slb.nodes)
%                 n = slb.nodes{i};
%                 n.is_direct_feedthrough(fxd.df.get(n.search_name));
%             end
%             
%             fprintf('END F Analysis for All Nodes\n');
%         end
        
        function obj = do_data_type_analysis(obj, dfs, fxd)
            while true
                
                if dfs.isempty()
%                     if second_stack.isempty()
%                         fprintf('Both stacks empty. Done!\n');
                        break;
%                     else
%                         fprintf('--- Processing 2nd stack ---\n');
%                         temp_s = dfs;
%                         dfs = second_stack;
%                         second_stack = temp_s;
%                     end
                end

                c = dfs.pop();
                fprintf('\t\t\t\t\t\t\t\t\t\t\t\tPopped %d\n', c.n.my_id);

                if c.n.is_visited
                    fprintf('%d is already visited\n', c.n.my_id);
                    continue;
                end


                fprintf('\t\t\t\tVisiting %d\n', c.n.my_id);
                c.n.is_visited = true;
                obj.num_visited = obj.num_visited + 1;  
                obj.visited_nodes(c.n.my_id) = 1;

                % Get my output type
                my_out_type = c.n.get_output_type(fxd);


                for i=1:numel(c.n.out_nodes)
                    for j=1:numel(c.n.out_nodes{i})
                        chld = c.n.out_nodes{i}{j};

                        % Get In type

                        is_compatible = chld.is_out_in_types_compatible(my_out_type);

                        if ~ is_compatible
                            fprintf('Input Output not compatible! Out: %s ||| In: %s\n', c.n.search_name, chld.search_name);
%                             error('Input output types are not compatible');

                            obj.add_data_type_converter(c.n.handle);
                            obj.generator.my_result.dc_analysis = obj.generator.my_result.dc_analysis + 1;
                        end


                        if c.n.out_nodes_otherport{i}{j} == 1
                            chld_tagged = slbnodetags(chld);
                            fprintf('pushing %d\n', chld.my_id);
                            chld.in_type = my_out_type;
                            dfs.push(chld_tagged);
                        else
                            fprintf('Not Pushing %d; not pushed %d\n', chld.my_id, chld.in_node_first.my_id);
%                             second_stack.push(slbnodetags(chld.in_node_first));
                        end


                    end
                end
            end
        end


        function obj = ts_datatype_analysis(obj, slb)
            fprintf('@@@@@@@@@@@@@@@ PRE SIMULATION ANALYSIS @@@@@@@@@@@@@@@\n');
            
            
            
%             obj.df_analysis_all_nodes(slb, fxd);
            
            
            dfs = CStack();
%             second_stack = CStack();
            
            
            for i=1:slb.nondfts.len
                c_s = slb.nondfts.get(i);
                fprintf('pushing non-DFT %d\n', c_s.my_id);     % TODO handle conditionally DFTs
                dfs.push(slbnodetags(c_s));
            end
            
            
            for i=1:slb.sources.len
                c_s = slb.sources.get(i);
                fprintf('pushing source %d\n', c_s.my_id);
                dfs.push(slbnodetags(c_s));
            end
            
            obj.num_visited = 0;
            obj.visited_nodes = zeros(1, numel(slb.all));
            
            obj.do_data_type_analysis(dfs, fxd);
            
            % secondary analysis
            
            obj.secondary_analysis(slb, fxd);
            
            fprintf('@@@@@@@@@@@@@@@ END PRE SIMULATION ANALYSIS @@@@@@@@@@@@@@@\n');
        end
        
        function obj = secondary_analysis(obj, slb, fxd)
            fprintf('~~ Secondary Analysis ~~\n');
            if obj.num_visited ~= slb.num_reachable_nodes
              
                slb.num_reachable_nodes
                fprintf('Unvisited Nodes:\n');
                
                unvisited = mycell(numel(slb.all) - obj.num_visited);
                
                for vi = 1:numel(obj.visited_nodes)
                    if obj.visited_nodes(vi) == 0
                        fprintf('\t%d', vi);
                        unvisited.add(vi);
                    end
                end
                fprintf('\n');
                
                is_loop_found = false;
               
                for i = 1:unvisited.len
                    c = slb.nodes{unvisited.get(i)};
                    [is_loop_found, c_t] = c.check_loop(slb.NUM_BLOCKS);

                    if is_loop_found
                        
                        new_node = obj.pre_fix_loop(c_t, slb);
                        
                        dfs = CStack();
                        dfs.push(slbnodetags(new_node));
                        obj.do_data_type_analysis(dfs, fxd);
                        
                        break;
                    else
                        fprintf('\t No loop found!\n');
                    end
                end
                
                if ~ is_loop_found
                    error('Weird Behavior: no loop found.');
                end
                
            end
        end
        
        
        function new_block_node = pre_fix_loop(obj, tn, slb)
            % Add Delay block at a specific input port of tn. tn is the
            % Node (tagged node)
            
            new_block_type = 'simulink/Discrete/Delay';
            
            new_delay_blocks = obj.add_block_in_the_middle(tn.n.handle, new_block_type, false, true, int2str(tn.which_input_port));
            
            assert(new_delay_blocks.len == 1); % There will be only one such block
            
            h = new_delay_blocks.get(1);  
            set_param(h, 'SampleTime', '1');                  %       TODO sample time
            
            % Register new block
            new_block_node = slb.register_new_block(h, new_block_type, get_param(h, 'name'));
          
            old_parent = tn.which_parent_block;
            old_parent.replace_child(tn.which_parent_port, new_block_node);
            new_block_node.add_child(tn.n, 1, tn.which_input_port);
        end
        
        function obj = remove_cycles(obj, slb)
            % TODO only finds strongly connected components, not all
            % cycles. use Johnson's algo to find all cycles
            
            fprintf('-- Starting cycle remover--\n');
            cc = obj.get_connected_components(slb);
            
            for out_i = 1:cc.len
                
                c = cc.get(out_i);
                
%                 fprintf('\n-- CC %d --\n', out_i);
%                 for out_j = 1:c.len
%                     v = c.get(out_j);
%                     fprintf('bl%d ---> \t', v);
%                 end
                
                first = c.get(1);
                v = slb.nodes{first};
                
                 for i=1:numel(v.out_nodes)
                    for j=1:numel(v.out_nodes{i})
                        chld = v.out_nodes{i}{j};
                        if util.cell_in(c.data, chld.my_id)
                            tn = slbnodetags(chld);
                            tn.which_input_port = v.out_nodes_otherport{i}{j};
                            tn.which_parent_block = v;
                            tn.which_parent_port = [i, j];
                            obj.pre_fix_loop(tn, slb);
                            break;
                        end
                    end
                 end
                 
                 fprintf('-- End cycle remover. Found %d STRONGLY CONNECTED COMPONENTS --\n', cc.len);
                
            end
            
        end
        
        
        function ret = simulate(obj, slb, pre_analysis_only)
            % Returns true if simulation did not raise any error.
            
            done = false;
            ret = false;
            
            obj.fxd = slblockdocfixed.getInstance();
            
            obj.remove_cycles(slb);
            
            if cfg.GENERATE_TYPESMART_MODELS
                obj.ts_datatype_analysis(slb);
            else
                fprintf('TypeSmart generation analysis is turned off\n');
            end
            
            if pre_analysis_only
                fprintf('Returning from Fix Errors phase after pre_analysis only.\n');
                return;
            end
            
            
            
%             warning('Returning abruptly before simulating \n');
%             return;
            
            for i=1:obj.max_try
                disp(['(s) Simulation attempt ' int2str(i)]);
                
                if cfg.PAUSE_BETWEEN_FIX_ERROR_STEPS
                    disp('Pausing before next Fix Error iteration attempt! Press any key to resume.');
                    pause();
                end
                
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
                            [done, found] = obj.fix_inv_comp_disc_sample_time(e, is_multi_exception);
                            ret = done;                             
%                             found = true;
                        case{'Simulink:DataType:InputPortDataTypeMismatch', 'SimulinkBlock:Foundation:SignedOnlyPortDType', 'Simulink:DataType:InvDisagreeInternalRuleDType'}
                            [done, found] = obj.fix_data_type_mismatch(e, 'both');
%                             found = true;
                        case {'Simulink:DataType:PropForwardDataTypeError', 'Simulink:blocks:DiscreteFirHomogeneousDataType', 'Simulink:blocks:SumBlockOutputDataTypeIsBool'}
                            [done, found] = obj.fix_data_type_mismatch(e, 'both');
%                             found = true;
                        case {'Simulink:DataType:PropBackwardDataTypeError'}
                            [done, found] = obj.fix_data_type_mismatch(e, 'both');
%                             found = true;
                        case {'SimulinkFixedPoint:util:fxpBitOpUnsupportedFloatType'}
                            obj.fix_data_type_mismatch(e, 'input', {{'OutDataTypeStr', 'boolean'}});
                            [done, found] = obj.fix_data_type_mismatch(e, 'output');
                           
                            
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
                            
                        case {'Simulink:modelReference:RootInputTsError'}
                            done = obj.fix_model_ref_rate_transitions(e);
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
                blkFullName = getfullname(handles);
                blkType = get_param(handles, 'blocktype');
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
        
        
        function new_blocks = add_data_type_converter(obj, h)
           
            disp('Adding DATA TYPE conversion block...');
            new_blocks = obj.add_block_in_the_middle(h, 'Simulink/Signal Attributes/Data Type Conversion', true, false);
                 
        end
        
        
        function [done, found] = fix_data_type_mismatch(obj, e, loc, blk_params)
            found = false;
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
                
                if  obj.is_block_fixed_before(e.identifier, getfullname(h), true)
                    fprintf('%s was already fixed for %s, so not trying this block again.\n', getfullname(h), e.identifier);
                    done = true;
                    return;
                else
                    found = true;
                end
                
%                 if cfg.SUBSYSTEM_FIX
%                     full_name = getfullname(h);
%                     slash_pos = strfind(full_name, '/');
%                     
%                     obj.active_sys = full_name(1:(slash_pos(numel(slash_pos)) - 1));
%                     fprintf('Active sys: %s\n', obj.active_sys);
%                 end
                

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
            
%             obj.active_sys = [];
            
            if ~isempty(blk_params) 
                for i=1:new_blocks.len
                    for j=1:numel(blk_params)
                        set_param(new_blocks.get(i), blk_params{j}{1}, blk_params{j}{2});
                    end
                end
            end
            
            obj.generator.my_result.dc_sim = obj.generator.my_result.dc_sim + new_blocks.len;
                 
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
        
        function done = fix_model_ref_rate_transitions(obj, e)
            disp('FIXING Model reference rate transition errors...');
            done = false;
                        
            for i = 1:numel(e.handles)
                inner = e.handles{i};
                
                disp(numel(inner));
                assert(numel(inner) == 2);
                
                for j = 1:numel(inner)

                    h = util.select_me_or_parent(inner(j));
                    
                    m_names = strsplit(getfullname(h), '/');
                    if numel(m_names) > 1
                        obj.active_sys = m_names{1};
                    end
                    
%                     disp(get_param(h, 'name'));
                    port_type = get_param(h, 'BlockType');
                    if strcmpi(port_type, 'Inport')
                        obj.add_block_in_the_middle(h, 'simulink/Signal Attributes/Rate Transition', true, false);
                        save_system(obj.active_sys);        % Otherwise Simulink opens up a GUI dialogue asking whether to save or not
                        obj.active_sys = [];
                        break;  % Adding to the other block may result in error
                    elseif strcmpi(port_type, 'Outport')
                        obj.add_block_in_the_middle(h, 'simulink/Signal Attributes/Rate Transition', false, true);
                        save_system(obj.active_sys);        % Otherwise Simulink opens up a GUI dialogue asking whether to save or not
                        obj.active_sys = [];
                        break;
                    end
                end
            end
        end
        
        
        
        function obj = fix_alg_loop(obj, e)
%             throw(MException('RandGen:SL:AlgebraicLoopDiscovered', 'By construction, there should be no algebraic loops!'));
            
            % Fix Algebraic Loop 
%             handles = e.handles{1}

%             handles(1)
%             handles(2)
%             
%             disp('here');
            
            for ii = 1:numel(e.handles)
                current = e.handles{ii};
                
%                 disp(numel(current));
%                 assert(numel(current) == 2);
                
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
        
        
        
        
        
        
        
        function ret = add_block_in_the_middle(obj, h, replacement, ignore_in, ignore_out, specific_port)
            
            if nargin == 5
                specific_port = [];
            else
%                 fprintf('Specific Port to use: %d\n', specific_port);
            end
  
            ret = mycell(-1);
            
            save_active_sys = false;
            
            if isempty(obj.active_sys) && cfg.SUBSYSTEM_FIX
                full_name = getfullname(h);
                slash_pos = strfind(full_name, '/');

                obj.active_sys = full_name(1:(slash_pos(numel(slash_pos)) - 1));
                fprintf('Active sys: %s\n', obj.active_sys);
            end
            
            if isempty(obj.active_sys) || strcmp(obj.active_sys, obj.generator.sys)
                sys = obj.generator.sys;
                g = obj.generator;
            else
                sys = obj.active_sys;
                g = obj.generator.get_root_generator().descendant_generators.get(sys);
                obj.generator.get_root_generator().descendant_generators.print_keys();
                assert(~isempty(g));
                
                if util.starts_with(sys, 'hier')
                    save_active_sys = true;
                end
            end
            
            my_name = get_param(h, 'Name');

            disp(['Add Block in the middle: For ' my_name '; handle ' num2str(h)]);
            
%             if ignore_in
%                 disp('INGORE INPUTS');
%             end
%             
%             if ignore_out
%                 disp('IGNORE OUTPUTS');
%             end

            try
                ports = get_param(h,'PortConnectivity');
            catch e
%                 disp('~ Skipping, not a block');
                if cfg.SUBSYSTEM_FIX
                    obj.active_sys = [];
                end
                return;
            end

            for j = 1:numel(ports)
                p = ports(j);
                
                if ~isempty(specific_port) && ~strcmp(specific_port, p.Type)
%                     fprintf('Skipping due to specific port. current: %s\n', p.Type);
                    continue;
                end
                
                is_inp = [];
                
                % Detect if current port is Input or Output

                if isempty(p.SrcBlock) || p.SrcBlock == -1
                    is_inp = false;
                end
                
                if isempty(p.DstBlock)
                    is_inp = true;
                end
                
                assesrt(~ isempty(is_inp));
                    
                
                
                
                if(is_inp)
                    if ignore_in
%                         disp(['Skipping input port ' int2str(j)]);
                        continue;
                    end
                    other_name = get_param(p.SrcBlock, 'Name');
                    other_port = p.SrcPort + 1; 
                    dir = 'from';
                else
                    if ignore_out
%                         disp(['Skipping output port ' int2str(j)]);
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
                    d_h = obj.add_block_in_middle_multi(my_b_p, other_name, other_port, replacement, g);
                    ret.add(d_h);
                    if cfg.SUBSYSTEM_FIX
                        obj.active_sys = [];
                    end
                    if save_active_sys
                        save_system(sys);
                    end
                    return;
                end

                disp(['Const. ' dir ' ' other_name ' ; port ' num2str(other_port) '; My type ' p.Type ]);

                other_b_p = [other_name '/' num2str(other_port)];
                

                % get a new block

                [d_name, d_h] = g.add_new_block(replacement);
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
                

%                 disp('Active Sys:');
%                 sys
%                 b_a
%                 new_blk_port
%                 b_b
                
                delete_line( sys, b_a , b_b);
                add_line(sys, b_a, new_blk_port , 'autorouting','on');
                add_line(sys, new_blk_port, b_b , 'autorouting','on');
                
%                 disp('Done adding block!');

               

            end
            
            if cfg.SUBSYSTEM_FIX
                obj.active_sys = [];
            end
            if save_active_sys
                save_system(sys);
            end
            
        end
        
        
        
        function d_h = add_block_in_middle_multi(obj,my_b_p, o_names, o_ports, replacement, generator, o_port)
            
            if numel(nargin == 6)
                o_port = [];
            end
            
            % get a new block

            [d_name, d_h] = generator.add_new_block(replacement);

            %  delete and Connect

            new_blk_port = [d_name '/1'];
            add_line(generator.sys, my_b_p, new_blk_port , 'autorouting','on');
                        
            for i = 1:numel(o_ports)
                other_b_p = [char(o_names(i)), '/', num2str(o_ports(i))];
                
                delete_line( generator.sys, my_b_p , other_b_p);
                add_line(generator.sys, new_blk_port, other_b_p , 'autorouting','on');
            end
            
        end
        
        
        
        
        function obj = fix_invParamSetting(obj, e)
%             e
%             e.message
%             e.cause
%             e.stack
        end
        
        
        function obj = alg_loop_eliminator(obj)
            
%             if obj.generator.current_hierarchy_level == 1
%                 fprintf('Returning at top level\n');
%                 return;
%             end
      
            num_max_attempts = 3;
            
            for gc = 1:num_max_attempts
                
                fprintf('Starting alg. loop eliminator... attempt %d\n', gc);
                
                aloops = Simulink.BlockDiagram.getAlgebraicLoops(obj.generator.sys);
                
%                 assert(numel(aloops) == 0);
            
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
        
        
        function ret = get_connected_components(obj, slb)
            
            ret = mycell();
            
%             disp(numel(slb.nodes));
%             disp(slb.NUM_BLOCKS);
            
            assert(numel(slb.nodes) == slb.NUM_BLOCKS);
            
            visit_index = cell(1, slb.NUM_BLOCKS);
            low_link = cell(1, slb.NUM_BLOCKS);
            on_stack = zeros(1, slb.NUM_BLOCKS);
            
            index = 0;
            s = CStack();
            
            for out_i=1:slb.NUM_BLOCKS
                if isempty(visit_index{out_i})
                    strongconnect(slb.nodes{out_i});
                end
            end
            
            
            function strongconnect(v)
                visit_index{v.my_id} = index;
                low_link{v.my_id} = index;
                index = index + 1;
         
                s.push(v);
                on_stack(v.my_id) = true;
                
                % onsider successors of v
                
                for i=1:numel(v.out_nodes)
                    for j=1:numel(v.out_nodes{i})
                        chld = v.out_nodes{i}{j};
                        
                        if isempty(visit_index{chld.my_id})
                            strongconnect(chld);
                            low_link{v.my_id} = min(low_link{v.my_id} , low_link{chld.my_id});
                        elseif on_stack(chld.my_id)
                            low_link{v.my_id} = min(low_link{v.my_id} , low_link{chld.my_id});
                        end
                        
                    end
                end
                
                % If v is a root node, pop the stack and generate an SCC
                
                if low_link{v.my_id} == visit_index{v.my_id}
                    % start a new strongly connected component
                    cc = mycell();
                    while true
                        w = s.pop();
                        on_stack(w.my_id) = false;
                        cc.add(w.my_id);
                        
                        if w.my_id == v.my_id
                            break;
                        end
                    end
                    
                    if cc.len > 1
                        ret.add(cc);
                    end
                end
                
            end
            
            
        end
        
        
    end
    
end

