classdef simulator < handle
    %SIMULATOR Try to simulate a constructed model
    %   Detailed explanation goes here
    
    properties
        generator;
        max_try;
    end
    
    methods
        
        
        function obj = simulator(generator, max_try)
            % CONSTRUCTOR %
            obj.generator = generator;
            obj.max_try = max_try;
        end
        
        
        
        function ret = simulate(obj)
            % Returns true if simulation did not raise any error.
            
            done = false;
            ret = false;
            
            for i=1:obj.max_try
                disp(['(s) Simulation attempt ' int2str(i)]);
                
                try
                    sim(obj.generator.sys);  
                    disp('Success!');
                    done = true;
                    ret = true;
                catch e
                    disp(['[E] Error in simulation: ', e.identifier]);
                    obj.generator.last_exc = e;
                    
                    e
                    e.message
                    e.cause
                    e.stack
                    
                    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
                    
                    is_multi_exception = false;
                    
                    if(strcmp(e.identifier, 'MATLAB:MException:MultipleErrors'))
                        
                        for m_i = 1:numel(e.cause)
                            disp(['Multiple Errors. Solving ' int2str(m_i)]);
                            ei = e.cause{m_i}
                            obj.generator.last_exc = ei;

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
                
                if done
                    disp('(s) Exiting from simulation attempt loop');
                    break;
                end
                
                
            end

                    
        end
        
        
        
        function [done, ret, found] = look_for_solutions(obj, e, is_multi_exception, done, ret)
            found = false;          % Did the exception matched with any of our fixers
            
            if isa(e, 'MSLException')

                if util.starts_with(e.identifier, 'Simulink:Engine:AlgLoopTrouble')
                    obj.fix_alg_loop(e);
                    found = true;
                else

                    switch e.identifier
                        case {'Simulink:Parameters:InvParamSetting'}
                            obj.fix_invParamSetting(e);
                            done = true;                                    % TODO
                            found = true;
                        case {'Simulink:Engine:InvCompDiscSampleTime', 'Simulink:blocks:WSTimeContinuousSampleTime'}
                            done = obj.fix_inv_comp_disc_sample_time(e, is_multi_exception);
                            ret = done;                             % TODO suspicious logic
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
                            
                        otherwise
                            done = true;
                    end
                end

            else
                done = true;                                        % TODO
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
                    sim(obj.generator.sys);
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
            done = false;
           
            
            for i = 1:numel(e.handles)
%                 if fetch_parent
                    inner = e.handles{i};
                    parent = get_param(inner, 'parent');
                    
                    if strcmp(get_param(parent, 'Type'), 'block')
                        disp('WILL FETCH PARENT');
                        h = get_param(get_param(inner, 'parent'), 'Handle');
                    else
                         disp('NOT fetching PARENT');
                        h = inner;
                    end
                    
%                     my_name = get_param(inner, 'Name')
%                     if length(strfind(my_name, '/')) > 1
%                         disp('WILL FETCH PARENT');
%                         h = get_param(get_param(inner, 'parent'), 'Handle');
%                     else
%                         disp('NOT fetching PARENT');
%                         h = inner;
%                     end

%                 else
%                     h = e.handles{i};
%                 end
%                 break;
                
                % Assume only output ports are giving errors   TODO
                if at_output
                    obj.add_block_in_the_middle(h, 'Simulink/Signal Attributes/Data Type Conversion', true, false);
                else
                    obj.add_block_in_the_middle(h, 'Simulink/Signal Attributes/Data Type Conversion', false, true);
                end
                
            end
            
%             disp('Handle:');
%             
%             h = e.handles{1}
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
                    h = current(i);
                    new_delay_block = obj.add_block_in_the_middle(h, 'Simulink/Discrete/Delay', false, true);
                    set_param(new_delay_block, 'SampleTime', '1');                  %       TODO sample time
%                     disp(h);
                    
                    
                    
                end
                
                
            end
        end
        
        
        
        
        
        
        
        function d_h = add_block_in_the_middle(obj, h, replacement, ignore_in, ignore_out)
            
            my_name = get_param(h, 'Name');

            disp(['Add Block in the middle: For ' my_name '; handle ' num2str(h)]);

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
                
                my_b_p = [my_name '/' p.Type];
                
                if numel(other_port) > 1
                    disp('Multiple src/ports Here');
                    other_name
                    other_port
                    d_h = obj.add_block_in_middle_multi(my_b_p, other_name, other_port, replacement);
                    return;
                end

                disp(['Const. ' dir ' ' other_name ' ; port ' num2str(other_port) '; My type ' p.Type ]);

                other_b_p = [other_name '/' num2str(other_port)];
                

                % get a new block

                [d_name, d_h] = obj.generator.add_new_block(replacement);

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
        
        
        
    end
    
end

