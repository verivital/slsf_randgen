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
                    
                    e
                    e.message
                    e.cause
                    e.stack
                    
%                     try
%                         disp('Testing...');
%                         
%                         if numel(e.cause) == 2
% 
%                             e.cause{1}.message
%                             e.cause{2}.message
%                         end
%                     catch e
%                     end
                    
                    if isa(e, 'MSLException')
                        
                        if util.starts_with(e.identifier, 'Simulink:Engine:AlgLoopTrouble')
                            obj.fix_alg_loop(e);
                        else
                            
                            switch e.identifier
                                case {'Simulink:Parameters:InvParamSetting'}
                                    obj.fix_invParamSetting(e);
                                    done = true;                                    % TODO
                                case {'Simulink:Engine:InvCompDiscSampleTime'}
                                    done = obj.fix_inv_comp_disc_sample_time(e);
                                    ret = done;
                                otherwise
                                    done = true;
                            end
                        end
                        
                    else
                        done = true;                                        % TODO
                    end
                    
                end
                
                if done
                    disp('(s) Exiting from simulation attempt loop');
                    break;
                end
                
                
            end
            
            
            
            
%             al = Simulink.BlockDiagram.getAlgebraicLoops(obj.sys);
%             disp(al);
            
            
        end
        
        
        
        function done = fix_inv_comp_disc_sample_time(obj, e)
            done = false;
            MAX_TRY = 10;
            
            for i=1:MAX_TRY
                disp(['Attempt ' int2str(i) ' - Fixing inv-disc-comp-sample-time']);
                try
                    
                    for j = 1:numel(e.handles)
                        handles = e.handles{j}
                        
                        for k = 1:numel(handles)
                            h = handles(k);
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
                    

%                     disp(h);
                    
                    my_name = get_param(h, 'Name');

                    disp(['Trying to fix Alg. loop for block ' my_name '; handle ' num2str(h)]);

                    try
                        ports = get_param(h,'PortConnectivity');
                    catch e
%                         if isa(e.identifier, 'Simulink:Commands:ParamUnknown')
%                             continue
%                         end
                        disp('~ Skipping, not a block');
                        continue
                    end

                    for j = 1:numel(ports)
                        p = ports(j);
                        
                        if isempty(p.SrcBlock) || p.SrcBlock == -1
                            continue
                        end
                        
                        src_name = get_param(p.SrcBlock, 'Name');
                        src_port = p.SrcPort + 1;                                               % TODO
                        
                        disp(['Con. from ' src_name ' port ' num2str(src_port) ' ;type ' p.Type ]);
                                                
                        src_b_p = [src_name '/' num2str(src_port)];
                        my_b_p = [my_name '/' p.Type];
                        
                        delete_line( obj.generator.sys, src_b_p , my_b_p);
                        
                        % get a new delay block
                        
                        [d_name, d_h] = obj.generator.add_new_block('Simulink/Discrete/Delay');
                        set_param(d_h, 'SampleTime', '1');                                         % TODO
                        
                        % Connect
                        
                        d_b_p = [d_name '/1'];
                        
                        add_line(obj.generator.sys, src_b_p, d_b_p , 'autorouting','on');
                        add_line(obj.generator.sys, d_b_p, my_b_p , 'autorouting','on');

                    end
                    
                end
                
                
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

