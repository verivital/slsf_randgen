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
        
        
        
        function obj = simulate(obj)
            
            done = false;
            
            for i=1:obj.max_try
                disp(['(s) Simulation attempt ' int2str(i)]);
                
                try
                    sim(obj.generator.sys);  
                    disp('Success!');
                    done = true;
                catch e
                    disp(['[E] Error in simulation: ', e.identifier]);
                    
                    e
                    e.message
                    
                    if isa(e, 'MSLException')
                        
                        if util.starts_with(e.identifier, 'Simulink:Engine:AlgLoopTrouble')
                            obj.fix_alg_loop(e);
                        else
                            done = true;                                    % TODO
                            switch e.identifier
                                case {'Simulink:Parameters:InvParamSetting'}
                                    obj.fix_invParamSetting(e);
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
        
        
        
        function obj = fix_alg_loop(obj, e)
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

