classdef simulator < handle
    %SIMULATOR Try to simulate a constructed model
    %   Detailed explanation goes here
    
    properties
        generator;
        max_try;
        
        simulation_timeout = 1500;        % After this many seconds simulation will be killed. 
        sim_status = [];
        
        
        % Data type fixer related
        last_handle = [];
        last_at_output = [];
    end
    
    
    
    methods
        
        
        function obj = simulator(generator, max_try)
            % CONSTRUCTOR %
            obj.generator = generator;
            obj.max_try = max_try;
        end
        
        
        
        
        function obj = sim(obj)
            % A wrapper to the built in `sim` command - which is used to
            % start the simulation.
            obj.sim_status = [];
            myTimer = timer('StartDelay',obj.simulation_timeout, 'TimerFcn', {@sim_timeout_callback, obj});
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
        
        
        
        function ret = simulate(obj)
            % Returns true if simulation did not raise any error.
            
            done = false;
            ret = false;
            
            for i=1:obj.max_try
                disp(['(s) Simulation attempt ' int2str(i)]);
                
                found = false;
                
                try
                    obj.sim();
%                     sim(obj.generator.sys);  
                    disp('Success simulating in SIMULATOR.M module!');
                    done = true;
                    ret = true;
                    found = true; % So that we eliminate alg. loops
                catch e
                    disp(['[E] Error in simulation: ', e.identifier]);
                    obj.generator.my_result.exc = e;
                    
                    if(strcmp(e.identifier, 'RandGen:SL:SimTimeout'))
                        obj.generator.my_result.set_to(singleresult.NORMAL, obj.simulation_timeout);
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
                        case{'Simulink:DataType:InputPortDataTypeMismatch'}
                            done = obj.fix_data_type_mismatch(e, true, true);
                            found = true;
                        case {'Simulink:DataType:PropForwardDataTypeError'}
                            done = obj.fix_data_type_mismatch(e, false, true);
                            found = true;
                        case {'Simulink:DataType:PropBackwardDataTypeError'}
                            done = obj.fix_data_type_mismatch(e, false, false);
                            found = true;
                            
                        case {'Simulink:blocks:NormModelRefBlkNotSupported'}
                            done = obj.fix_normal_mode_ref_block(e);
                            found = true;
                            
                        otherwise
                            done = true;
                    end
                end

            else
                done = true;                                        % TODO
            end
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
        
        
        
        
        
        function done = fix_data_type_mismatch(obj, e, fetch_parent, at_output)
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
                    obj.add_block_in_the_middle(h, 'Simulink/Signal Attributes/Data Type Conversion', true, false);
%                 else
                    obj.add_block_in_the_middle(h, 'Simulink/Signal Attributes/Data Type Conversion', false, true);
%                 end
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

                
%                 delete_line( obj.generator.sys, src_b_p , my_b_p);
%                 add_line(obj.generator.sys, src_b_p, d_b_p , 'autorouting','on');
%                 add_line(obj.generator.sys, d_b_p, my_b_p , 'autorouting','on');

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

