classdef simple_generator < handle
    %Main Random Generator Class
    %   Detailed explanation goes here
    
    properties(Constant = true)
       DEBUG = true;
       LIST_BLOCK_PARAMS = true;    % Will list all dialog parameters of a block which is chosen for current chart
       LIST_CONN = false;            % If true will print info when connecting blocks
       
    end
    
    properties
        NUM_BLOCKS;                 % These many blocks will be placed in chart
        
        slb;                        % Object of class slblocks
        
        sys;                        % Name of the chart
        
        candi_blocks;               % Will choose from these blocks
        
        diff_tester;                % Instance of comparator class
                
        simulate_models;            % Boolean: whether to simulate or not
        
        blkcfg;
        
        simul;                      % Instance of simulator class
        max_simul_attempt = 10;
        
        close_model = true;         % Close after simulation
        
        stop = false;               % Stop future steps from go() method
        
        last_exc = [];
        
        log_signals = true;
        simulation_mode = [];
        compare_results = true;
        
        
        simulation_mode_values = {'off' 'on'};
        
        is_simulation_successful = [];  % Boolean, whether the model can be simulated in Normal mode without any error.
        
        simulation_data = [];
        my_result = [];                 % Instance of Single result
        
        % Drawing related
        d_x;
        d_y;
        c_block;
        
        width = 60;
        height = 60;
        
        pos_x = 30;
        pos_y = 30;

        hz_space = 100;
        vt_space = 150;

        blk_in_line = 5;
        
        
    end
    
    methods
        function obj = simple_generator(num_blocks, model_name, simulate_models, close_model, log_signals, simulation_mode, compare_results)
            % Constructor %
            obj.NUM_BLOCKS = num_blocks;
            obj.sys = model_name;
            obj.simulate_models = simulate_models;
            obj.close_model = close_model;
            obj.log_signals = log_signals;
            obj.simulation_mode = simulation_mode;
            obj.compare_results = compare_results;
        end
        
        
        
        function ret = go(obj)
            % Call this function to start
            obj.p('--- Starting ---');
            
            ret = false;
            
            obj.init();
                        
            
            
            obj.get_candidate_blocks();
            
            
            
            if obj.stop
                return;
            end
            
            
            
            obj.draw_blocks();
            
            
            
            if obj.stop
                return;
            end
            
            
            
            
            
            obj.chk_compatibility();
            
            
            
            if obj.stop
                return;
            end
            
            
            
            
            obj.connect_blocks();
            
            
            
            
            fprintf('--Done Connecting!--\n');
            
            if obj.stop
                return;
            end
            
%             disp('Returning abruptly');
%             return;
            
            
            obj.is_simulation_successful = obj.simulate();
            ret = obj.is_simulation_successful;
            
            
%             fprintf('Done Simulating\n');
%             
%             disp('Returning abruptly');
%             return;
            
            
            
            % Signal Logging Setup and Compilation %
            
            if obj.simulate_models && obj.is_simulation_successful
                obj.my_result.set_ok_normal_mode();
                fprintf('[SIGNAL LOGGING] Now setting up...\n');
                
                obj.signal_logging_setup();
                
%                 disp('Returning abruptly');
%                 return;
                
      
                
                % Run simulation again for comparing results
                max_try = 2;
                
                for i=1:max_try
                    
                    obj.simulate_for_data_logging();
                
                    if ~ obj.my_result.is_acc_sim_ok
                        ret = false;
                        return;
                    end
                    
                    ret = obj.compare_sim_results(i);
                    
                    if ~ obj.my_result.is_log_len_mismatch
                        break; % No need to run all those simulations again
                    end
                    
                end
                
            else
                obj.my_result.set_error_normal_mode(obj.last_exc);
                % Don't need to record timed_out, it is already logged
                % inside Simulator.m class
            end
            
            
            
            fprintf('------------------- END of One Generator Call -------------------\n');
        end
        
        
        
        function obj = init(obj)
            % Perform Initialization
                                    
            obj.slb = slblocks(obj.NUM_BLOCKS);
            obj.blkcfg = blockconfigure();
            obj.simul = simulator(obj, obj.max_simul_attempt);
            obj.my_result = singleresult(obj.sys);
            
            new_system(obj.sys);
            open_system(obj.sys);
        end
        
        
        
        
        function ret = compare_sim_results(obj, try_count)
            if ~ obj.compare_results
                fprintf('Will not compare simulation results, returning...');
            end
            
            obj.diff_tester = comparator(obj, obj.simulation_data, try_count);
            ret = obj.diff_tester.compare();
        end
        
        
        
        
        
        function obj = signal_logging_setup(obj)
            if ~ obj.log_signals
                fprintf('Returning from signal logging setup');
                return;
            end
            
            for i = obj.slb.handles
                port_handles = get_param(i{1}, 'PortHandles');
                out_ports = port_handles.Outport;
                
                for j = 1: numel(out_ports)
                    set_param(out_ports(j), 'DataLogging', 'On');
                end
                
            end
            
        end
        
        
        function obj = simulate_for_data_logging(obj)
            if isempty(obj.simulation_mode)
                fprintf('No simulation mode provided. returning...\n');
            end
            
            obj.my_result.set_ok_acc_mode();    % Will be over-written if not ok
            
            obj.simulation_data = cell(1, numel(obj.simulation_mode_values));
            
%             Simulink.sdi.changeLoggedToStreamed(obj.sys);   % Stream
%             logged signals in Simulink Data Inspector:
%             http://bit.ly/1RK6wTn - Only available from R2016
            

            for i = 1:numel(obj.simulation_mode_values)
                
                % Open the model first
                if i > 1
                    fprintf('Opening Model...\n');
                    open_system(obj.sys);
                end
                
                mode_val = obj.simulation_mode_values{i};
                fprintf('[!] Simulating in mode %s for value %s...\n', obj.simulation_mode, mode_val);
                try
                    simOut = sim(obj.sys, 'SimulationMode', obj.simulation_mode, 'SimCompilerOptimization', mode_val, 'SignalLogging','on');
                catch e
                    fprintf('ERROR SIMULATION in advanced modes');
                    e
                    obj.my_result.set_error_acc_mode(e, mode_val);
                    obj.last_exc = MException('RandGen:SL:ErrAfterNormalSimulation', e.identifier);
                    return;
                end
                obj.simulation_data{i} = simOut.get('logsout');
                
                % Delete generated stuffs
                fprintf('Deleting generated stuffs...\n');
                delete([obj.sys '_acc*']);
                rmdir('slprj', 's');
                
                % Save and close the system
                if i ~= numel(obj.simulation_mode_values)
                    fprintf('Saving Model...\n');
                    save_system(obj.sys);
                    obj.close();
                end
                
            end
            
            % Delete the saved model
            fprintf('Deleting model...\n');
            delete([obj.sys '.slx']);
            
%             obj.simulation_data{1}
%             obj.simulation_data{2}
            
        end
        
        
        
        
        
        function ret = chk_compatibility(obj)
            return;         % NOT DOING ANYTHING IN THIS FUNCTION
            done = false;
            while ~done
                try
                    disp('-- START COMPILING');
                    cpl_cmd = [obj.sys '([],[],[],''compile'');']
                    eval(cpl_cmd);
                    disp('-- END COMPILING');
                catch e
                    e
                    e.message
                    done = true;
                    obj.stop = true;
                    return;
                end
            end
            
            
            for i=1:numel(obj.slb.handles)
                h = obj.slb.handles{i};
                display(['CompiledPortConnectivity for block ' int2str(i) obj.candi_blocks{i}]);
                
                cpdt = get_param(h, 'CompiledPortDataTypes')
%         
%                 try
%                     get_param(h,'OutDataTypeStr')
%                 catch mye
%                     disp('NO OUT PARAM');
%                 end
%                 
%                 if isfield('Inport', cpdt)
%                     cpdt.Inport
%                 else
%                     disp('empty');
%                 end
%                 
%                 if isfield('Outport', cpdt)
%                     cpdt.Outport
%                 else
%                     disp('Empty');
%                 end
                
                get_param(h, 'InputSignalNames')
                get_param(h, 'OutputSignalNames')
            end
            
            obj.stop = true;
        end
        
        
        
        
        function ret = simulate(obj)
            % Returns false ONLY if we asked to simulate and it raised error.
            
            if ~ obj.simulate_models
                ret = true;
                return;
            end
            
            fprintf('[~] Simulating...\n');
            
            ret =  obj.simul.simulate();
                
        end
        
        
        
        
        function close(obj)
            close_system(obj.sys, 0);
        end
        
        
        
        
        function obj = p(obj, str)
            % Prints str if Debug Mode.
            if obj.DEBUG
                display(str);
            end
        end
        
        
        
        function obj = get_candidate_blocks(obj)
            % Randomly choose which blocks will be used to populate the
            % chart
            all = obj.get_all_simulink_blocks();  
            obj.candi_blocks = cell(1, obj.NUM_BLOCKS);
            rand_vals = randi([1, numel(all)], 1, obj.NUM_BLOCKS);
            
            for index = 1:obj.NUM_BLOCKS
                obj.candi_blocks{index} = all{rand_vals(index)};
            end
        end
        
        
        
        function ret = get_all_simulink_blocks(obj)
%             ret = {'simulink/Sources/Constant', 'simulink/Sinks/Scope', 'simulink/Sources/Constant', 'simulink/Sinks/Display', 'simulink/Math Operations/Add'};
            ret = blockchooser().get();
        end
        
        
        
        function c_p(obj, str, condition)
            % Will print str if conditionis true
            if condition && obj.DEBUG
                disp(str);
            end
        end
        
        
        
        function obj = connect_blocks(obj)
            % CONNECT BLOCKS
            
            num_inp_ports = obj.slb.num_inp_ports;
            num_oup_ports = obj.slb.num_oup_ports;
            
            inp_blocks = obj.slb.inp.blocks;
            num_inp_blocks = obj.slb.inp.len;
            
            oup_blocks = obj.slb.oup.blocks;
            num_oup_blocks = obj.slb.oup.len;
            
            while_it = 0;
            
            while num_inp_ports > 0 || num_oup_ports > 0
                
                fprintf('-----\n');
                
                while_it = while_it + 1;
    
                fprintf('Num Input port: %d; num output port: %d\n', num_inp_ports, num_oup_ports);
                
                r_i_blk = 0;
                r_i_port = 0;
                
                r_o_blk = 0;
                r_o_port = 0;
                
                new_inp_used = false;
                new_oup_used = false;

                if num_inp_ports > 0
                   % choose an input port
                   if obj.LIST_CONN
                    fprintf('(d) num_inp_blk: %d\n', num_inp_blocks);
                   end
                   [r_i_blk, r_i_port] = obj.choose_bp(num_inp_blocks, inp_blocks, obj.slb.inp_ports);
                   
                   new_inp_used = true;
                
                end

                if num_oup_ports > 0
                    % Choose output port
                    
                    % Choose block not already taken for input.
                    
                    if obj.LIST_CONN
                        fprintf('(d) num_oup_blk: %d\n', num_oup_blocks);  
                    end

                    try
                        [r_o_blk, r_o_port] = obj.choose_bp_without_chosen(num_oup_blocks, oup_blocks, obj.slb.oup_ports, r_i_blk);
                    catch e
                        % Possible clause: only one output block available
                        % and it's same as the chosen input block for this
                        % iteration.
                        
                        if num_inp_blocks > 1
                            fprintf('SKIPPING THIS ITERATION...\n');
                            continue;
                        else
                            % Can not use this output block. pick another
                            % in later code
                            
                        end
                    end
                        
                    new_oup_used = true;


                end
                
                if r_i_port == 0 || r_i_blk == 0
                   
                    obj.c_p('No new inputs available!', obj.LIST_CONN);
                    
                    [r_i_blk, r_i_port] = obj.choose_bp(obj.slb.inp.len, obj.slb.inp.blocks, obj.slb.inp_ports);
                end
                
                if r_o_port == 0 || r_o_blk == 0
                    obj.c_p('No new outputs available!', obj.LIST_CONN);
                    [r_o_blk, r_o_port] = obj.choose_bp_without_chosen(obj.slb.oup.len, obj.slb.oup.blocks, obj.slb.oup_ports, r_i_blk);
                end
                
                if obj.LIST_CONN
                    fprintf('Input: Blk %d Port %d chosen.\n', r_i_blk, r_i_port);
                    fprintf('Output: Blk %d Port %d chosen.\n', r_o_blk, r_o_port);
                end

                % Add line
                t_i = strcat(obj.slb.all{r_i_blk}, '/', int2str(r_i_port));
                t_o = strcat(obj.slb.all{r_o_blk}, '/', int2str(r_o_port));
%                 disp(t_i);

                try
                    add_line(obj.sys, t_o, t_i, 'autorouting','on')
                catch e
                    fprintf('Error while connecting: %s\n', e.identifier);
                    fprintf('[!] Giving up... RETURNGING FROM BLOCK CONNECTION...\n');
                    break;
                end
                
                % Mark used blocks/ports
                
                if new_inp_used
                    obj.slb.inp_ports{r_i_blk}{r_i_port} = 1;
                    
                    if obj.is_all_ports_used(obj.slb.inp_ports{r_i_blk})
                        fprintf('ALL inp PORTS OF BLOCK IS USED: %d\n', r_i_blk);
                        [num_inp_blocks, inp_blocks] = obj.del_from_cell(r_i_blk, num_inp_blocks, inp_blocks);
                    end
                    
                    num_inp_ports = num_inp_ports - 1;
                end
                
                if new_oup_used
                    obj.slb.oup_ports{r_o_blk}{r_o_port} = 1;
                    
                    if obj.is_all_ports_used(obj.slb.oup_ports{r_o_blk})
                        fprintf('ALL oup PORTS OF BLOCK IS USED: %d\n', r_o_blk);
                        [num_oup_blocks, oup_blocks] = obj.del_from_cell(r_o_blk, num_oup_blocks, oup_blocks);
                    end
                    
                    num_oup_ports = num_oup_ports - 1;
                end
                
              
%                 if while_it >= 2                
%                     break;  % After one iteration
%                 end


            end
           
        end
        
        
        
        function [ret_len, ret_cell] = del_from_cell(obj, sub, num_target, target)
            % If `sub` is one of the elements of the cell `target`, then
            % it is removed.
            
            is_found = false;
            
            for inx = 1 : num_target
                if target{inx} == sub
                    is_found = true;
                    target{inx} = [];
                    break;
                end
            end
            
            if is_found
                ret_cell = target(~cellfun(@isempty, target));    % Removes empty cell
                ret_len = num_target - 1;
            else
                ret_cell = target;
                ret_len = num_target;
            end
            
        end
        
        
        
        function ret = is_all_ports_used(obj, ports)
            ret = true;
            
            for i_p = ports
                if i_p{1} == 0
                    ret = false;
                    break;
                end
            end
        end
        
        
        
        function [r_blk, r_port] = choose_bp(obj, num_blocks, blocks, ports)
            % Choose a block and pointer
            
            % choose a block
           rand_num = randi([1, num_blocks], 1, 1);
           r_blk = blocks{rand_num(1)};

           % get a (unused prefered, else last) port of this block
           t_all_ports = ports{r_blk};

           r_port = 0;

           for t_i = t_all_ports
               r_port = r_port + 1;

               if t_i{1} == 0
                   break;
               end
           end
            
        end
        
        
        
        
        
        function [r_blk, r_port] = choose_bp_without_chosen(obj, num_blocks, blocks, ports, chosen)
            % Choose a block except `chosen`, then choose a port from it.
            
            if chosen > 0
                [blk_len, blk] = obj.del_from_cell(chosen, num_blocks, blocks);
            else
                blk_len = num_blocks;
                blk = blocks;
            end

            [r_blk, r_port] = obj.choose_bp(blk_len, blk, ports);
            
        end
        
        
        
        function ret=create_blk_name(obj, num)
            ret = strcat('bl', num2str(num));
        end
        
        
        
        function obj = draw_blocks(obj)
            % Draw blocks in the screen
            
            disp('DRAWING BLOCKS...');
            
            cur_blk = 0;

            x = obj.pos_x;
            y = obj.pos_y;
            
            disp('Candidate Blocks:');
            disp(obj.candi_blocks);

            for block_name = obj.candi_blocks
                cur_blk = cur_blk + 1;          % Create block name
                
                h_len = x + obj.width;

                pos = [x, y, h_len, y + obj.height];

                this_blk_name = obj.create_blk_name(cur_blk);

                % Add this block name to list of all added blocks
                obj.slb.all{cur_blk} = this_blk_name;

                this_blk_name = strcat('/', this_blk_name);

                h = add_block(block_name{1}, [obj.sys, this_blk_name], 'Position', pos);
                
                % Save the handle of this new block. Accessing a block by
                % its handle is faster than accessing by its name
                
                obj.slb.handles{cur_blk} = h;
                

                % Get its inputs and outputs
                ports = get_param(h, 'Ports');

                obj.slb.new_block_added(cur_blk, ports);
                
                % Configure block parameters
                
                obj.config_block(h, block_name{1}, this_blk_name);
                
                %%%%%%% Done configuring block %%%%%%%%%

                % Update x
                x = h_len;

                % Update y
                if rem(cur_blk, obj.blk_in_line) == 0
                    y = y + obj.vt_space;
                    x = obj.pos_x;
                else
                    x = x + obj.hz_space;
                end

            end
            
            % Store drawing properties
            obj.d_x = x;
            obj.d_y = y;
            obj.c_block = cur_blk;
            
        end
        
        
        
        
        function [this_blk_name, h] = add_new_block(obj, block_type)
            
            obj.c_block = obj.c_block + 1;
            
            h_len = obj.d_x + obj.width;

            pos = [obj.d_x, obj.d_y, h_len, obj.d_y + obj.height];
            
            this_blk_name = obj.create_blk_name(obj.c_block);
            
            h = add_block(block_type, [obj.sys '/' this_blk_name], 'Position', pos);
            
            % Update x
            obj.d_x = h_len;

            % Update y
            if rem(obj.c_block, obj.blk_in_line) == 0
                obj.d_y = obj.d_y + obj.vt_space;
                obj.d_x = obj.pos_x;
            else
                obj.d_x = obj.d_x + obj.hz_space;
            end
            
        end
        
        
        
        
        function obj=config_block(obj, h, blk_type, blk_name)
            
            disp(['(' blk_name ') Attempting to config block ', blk_type]);
            
            found = obj.blkcfg.get_block_configs(blk_type);
            
            if obj.LIST_BLOCK_PARAMS
                bp = get_param(h, 'DialogParameters');
                disp(bp);
            end
            
            if isempty(found)
                disp(['[!] Did not find config db for block ', blk_type]);
                return;
            end
            
            disp(['[i] Will config block type ', blk_type]);
            
            for i=found
                disp(['Configuring ', i{1}.p()]);
                set_param(h, i{1}.p(), i{1}.get());
            end
           
            
        end
        
        
        
        
        
    end
    
end



