classdef simple_generator < handle
    %Main Random Generator Class
    %   Detailed explanation goes here
    
    properties(Constant = true)
       DEBUG = true;
       LIST_BLOCK_PARAMS = false;    % Will list all dialog parameters of a block which is chosen for current chart
       LIST_CONN = true;            % If true will print info when connecting blocks
       
       blk_construction = mymap('Simulink/User-Defined Functions/S-Function', 'bcsfunction');
       
    end
    
    properties
        NUM_BLOCKS;                 % These many blocks will be placed in chart
        record_runtime = true;
        num_log_len_mismatch_attempt = 5;
        skip_after_creation = false;    % Skip rest of the experiments with this model after creating it. Reason: it crashed before
        
        slb;                        % Object of class slblocks
        
        sys;                        % Name of the model
        
        candi_blocks;               % Will choose from these blocks
        num_preadded_blocks = 0;    % Blocks which are already added in the model. E.g. in a For-each block some blocks are already given
        
%         diff_tester;                % Instance of comparator class
                
        simulate_models;            % Boolean: whether to simulate or not
        
        blkcfg;
        blkchooser = [];                 
        
        max_hierarchy_level = [];
        current_hierarchy_level = [];
%         inner_model_num_blocks = 4;     % Number of blocks for models whose `current_hierarchy_level` is > 1 % TODO
        
%         simul;                      % Instance of simulator class
        max_simul_attempt = 15;
        
        close_model = true;         % Close after simulation
        
        stop = false;               % Stop future steps from go() method
        
%         last_exc = [];
        
        log_signals = true;
        simulation_mode = [];
        compare_results = true;
                
        
        simulation_mode_values = [];    % Actually these are compiler optimization on/off values
        use_signal_logging_api = true;
        
        is_simulation_successful = [];  % Boolean, whether the model can be simulated in Normal mode without any error.
        
        simulation_data = [];
        my_result = [];                 % Instance of Single result
        
        use_pre_generated_model = [];   % Instead of generating ranodm model use this pre-generated model
        
        % Drawing related
        d_x = 0;
        d_y = 0;
        c_block = 0;
        
        width = 60;
        height = 60;
        
        pos_x = 30;
        pos_y = 30;

        hz_space = 100;
        vt_space = 150;

        blk_in_line = 5;
        
        % hierarchy related
        hierarchy_new_old = []; % Ratio of new and old submodels
        hierarchy_new_count = 0;
        hierarchy_old_models;
        
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
            obj.hierarchy_old_models = mycell();
        end
        
        
        function ret = go(obj)
            % Call this function to start
            obj.p('--- Starting ---');
            fprintf('CyFuzz::NewRun\n');
            
            ret = false;
            
%             obj.init(); % NOTE: Client has to call init() explicityly!
                        
            if isempty(obj.use_pre_generated_model)
            
                obj.get_candidate_blocks();
                
                obj.draw_blocks();
               

                obj.chk_compatibility();
                
                obj.my_result.store_runtime(singleresult.BLOCK_SEL);

                obj.connect_blocks();
                obj.my_result.store_runtime(singleresult.PORT_CONN);
                
                fprintf('--Done Connecting!--\n');

%                 disp('Returning abruptly');
%                 ret = true;
%                 return;

            else
                % Use pre-generated model
%                 obj.my_result.store_runtime(singleresult.BLOCK_SEL);
%                 obj.my_result.store_runtime(singleresult.PORT_CONN);
                
                obj.sys = obj.use_pre_generated_model;
                open_system(obj.sys);
            end
            
            if obj.skip_after_creation
                fprintf('Skip_After_Creation: Skipping rest of the experiments after creating the model.\n');
                obj.my_result.exc = MException('RandGen:SL:SkippedAfterCreation', 'Skipped experiment after model creation.');
                ret = false;
                return;
            end
            
            % Set up signal logging even before the simulation
            
            fprintf('[SIGNAL LOGGING] PRE-simulation setting up...\n');
            if obj.log_signals
                if obj.use_signal_logging_api
                    obj.signal_logging_setup();
                else
                    obj.logging_using_outport_setup();
                end
                
                obj.my_result.store_runtime(singleresult.SIGNAL_LOGGING);
            else
                fprintf('Skipping signal logging...\n');
            end
            
            % Simulation %
            
            obj.is_simulation_successful = obj.simulate();
            
            obj.my_result.store_runtime(singleresult.FAS);
            
            ret = obj.is_simulation_successful;
            fprintf('Done Simulating\n');
            
%             disp('Returning abruptly');
%             return;
            
            
            
            % Signal Logging Setup and Compilation %
            
            if obj.simulate_models && obj.is_simulation_successful
%                 obj.my_result.set_ok_normal_mode();
                obj.my_result.set_ok(singleresult.NORMAL)
                
%                 fprintf('[SIGNAL LOGGING] Now setting up...\n');
%                 if obj.log_signals
%                     if obj.use_signal_logging_api
%                         obj.signal_logging_setup();
%                     else
%                         obj.logging_using_outport_setup();
%                     end
%                 else
%                     fprintf('Skipping signal logging...\n');
%                 end
                
                
%                 save_system(obj.sys);
%                 disp('Returning abruptly');
%                 return;

                % Eliminate new algebraic loops (e.g. due to signal logging)
%                 simul = simulator(obj, obj.max_simul_attempt);
%                 simul.alg_loop_eliminator();
                
           
                % Run simulation again for comparing results
                
                
                if ~ obj.compare_results
                    fprintf('Comparing results is turned off. Returning...\n');
                    return;
                end
                                
                diff_tester = difftester(obj.sys, obj.my_result, obj.num_log_len_mismatch_attempt, obj.simulation_mode, obj.simulation_mode_values, obj.compare_results);
                diff_tester.logging_method_siglog = obj.use_signal_logging_api;
                
                ret = diff_tester.go();
%                 for i=1:max_try
%                     
%                     obj.simulate_for_data_logging();
%                 
%                     if ~ obj.my_result.is_acc_sim_ok
%                         ret = false;
%                         return;
%                     end
%                     
%                     ret = obj.compare_sim_results(i);
%                     
%                     if ~ obj.my_result.is_log_len_mismatch
%                         break; % No need to run all those simulations again
%                     end
%                     
%                 end
                
            else
%                 obj.my_result.set_error_normal_mode(obj.last_exc);
                obj.my_result.set_mode(singleresult.NORMAL, singleresult.ER);
                % Don't need to record timed_out, it is already logged
                % inside Simulator.m class
            end
            
            
            
            fprintf('------------------- END of One Generator Call -------------------\n');
        end
        
        
        
        function obj = init(obj)
            % Perform Initialization
            
            % Choose number of blocks to use
            
            if ~ isscalar(obj.NUM_BLOCKS)
                obj.NUM_BLOCKS = util.rand_int(obj.NUM_BLOCKS(1), obj.NUM_BLOCKS(2), 1);
                fprintf('NUM_BLOCKS chosen to %d \n', obj.NUM_BLOCKS);
            end
                                    
            obj.slb = slblocks(obj.NUM_BLOCKS);
            obj.blkcfg = blockconfigure();
%             obj.simul = simulator(obj, obj.max_simul_attempt);
            obj.my_result = singleresult(obj.sys, obj.record_runtime);
            
            obj.my_result.init_runtime_recording();
            
            obj.create_and_open_system();
        end
        
        
        function create_and_open_system(obj)
            if isempty(obj.use_pre_generated_model)
                new_system(obj.sys);
                open_system(obj.sys);
            end
        end
        
        
        
        
%         function ret = compare_sim_results(obj, try_count)
%             if ~ obj.compare_results
%                 fprintf('Will not compare simulation results, returning...');
%             end
%             
%             obj.diff_tester = comparator(obj, obj.simulation_data, try_count);
%             ret = obj.diff_tester.compare();
%         end
        
        
        function logging_using_outport_setup(obj)
            
            set_param(obj.sys, 'SaveFormat', 'StructureWithTime');
            
            % Configure Model
%             set_param(obj.sys, 'EnhancedBackFolding', 'on');
            
%             return;                                                                 % TODO
            
            all_blocks = util.get_all_top_level_blocks(obj.sys);
            
            for i = 1:numel(all_blocks)
                cur_blk = all_blocks(i);
                [out_ports, other_end_ports] = util.get_other_blocks(cur_blk, true);
                
                for j = 1:numel(out_ports)
                    other_ports = other_end_ports{j};
                    
                    % Check if the port is already connected to an Outport
                    
                    already_outport_connected = false;
                    
                    for k = 1:numel(other_ports)
                        block_name = other_ports(k).Parent; % This gives the name of the block which contains the port
                        block_type = get_param(block_name, 'BlockType');
                        
                        if strcmpi(block_type, 'Outport')
                            % Do not need to connect an Output block here
                        	% because we already have one Outport connected.
                            already_outport_connected = true;
                            break;
                        end
                    end
                    
                    if already_outport_connected
                        fprintf('Already an outport connected, skipping this itereation\n');
                        continue;
                    end
                    
                    
                    % Connect an Outport block here
                    [d_name, d_h] = obj.add_new_block('simulink/Sinks/Out1');
                    
                    add_line(obj.sys, [get_param(cur_blk, 'Name') '/' int2str(j)], [d_name '/1'], 'autorouting', 'on');
                end
            end
        end
        
        
        function obj = signal_logging_setup(obj)
            
            all_blocks = util.get_all_top_level_blocks(obj.sys);
            
            for i = 1:numel(all_blocks)
                port_handles = get_param(all_blocks(i), 'PortHandles');
                out_ports = port_handles.Outport;
                
                for j = 1: numel(out_ports)
                    set_param(out_ports(j), 'DataLogging', 'On');
                end
            end
            
            % Following code uses our data structure. Cons: Can not work
            % with pre-generated models
            
%             for i = obj.slb.handles
%                 port_handles = get_param(i{1}, 'PortHandles');
%                 ... rest is same as upper code ...
%             end
            
        end
        
        
%         function ret = simulate_log_signal_normal_mode(obj)
%             fprintf('[!] Simulating in NORMAL mode...\n');
%             ret = true;
%             try
%                 simOut = sim(obj.sys, 'SimulationMode', 'normal', 'SignalLogging','on');
%             catch e
%                 fprintf('ERROR SIMULATION (Logging) in Normal mode');
%                 e
%                 obj.my_result.set_error_acc_mode(e, 'NormalMode');
%                 obj.last_exc = MException('RandGen:SL:ErrAfterNormalSimulation', e.identifier);
%                 ret = false;
%                 return;
%             end
%             obj.simulation_data{1} = simOut.get('logsout');
% 
%             % Save and close the system
%             fprintf('Saving Model...\n');
%             save_system(obj.sys);
%             obj.close();
%             
%         end
%         
%         
%         function obj = simulate_for_data_logging(obj)
%             if isempty(obj.simulation_mode)
%                 fprintf('No simulation mode provided. returning...\n');
%             end
%             
%             obj.my_result.set_ok_acc_mode();    % Will be over-written if not ok
%             
%             obj.simulation_data = cell(1, (numel(obj.simulation_mode_values) + 1)); % 1 extra for normal mode
%             
% %             Simulink.sdi.changeLoggedToStreamed(obj.sys);   % Stream
% %             logged signals in Simulink Data Inspector:
% %             http://bit.ly/1RK6wTn - Only available from R2016
% 
%             if ~ obj.simulate_log_signal_normal_mode()
%                 return
%             end
%             
% 
%             for i = 1:numel(obj.simulation_mode_values)
%                 inc_i = i + 1;
% %                 % Open the model first
% %                 if i > 1
% %                     fprintf('Opening Model...\n');
% %                     open_system(obj.sys);
% %                 end
%                 
%                 mode_val = obj.simulation_mode_values{i};
%                 fprintf('[!] Simulating in mode %s for value %s...\n', obj.simulation_mode, mode_val);
%                 try
%                     simOut = sim(obj.sys, 'SimulationMode', obj.simulation_mode, 'SimCompilerOptimization', mode_val, 'SignalLogging','on');
%                 catch e
%                     fprintf('ERROR SIMULATION in advanced modes');
%                     e
%                     obj.my_result.set_error_acc_mode(e, mode_val);
%                     obj.last_exc = MException('RandGen:SL:ErrAfterNormalSimulation', e.identifier);
%                     return;
%                 end
%                 obj.simulation_data{inc_i} = simOut.get('logsout');
%                 
%                 % Delete generated stuffs
%                 fprintf('Deleting generated stuffs...\n');
%                 delete([obj.sys '_acc*']);
%                 rmdir('slprj', 's');
%                 
%                 % Save and close the system
%                 if i ~= numel(obj.simulation_mode_values)
%                     fprintf('Saving Model...\n');
%                     save_system(obj.sys);
%                     obj.close();
%                 end
%                 
%             end
%             
%             % Delete the saved model
%             fprintf('Deleting model...\n');
%             delete([obj.sys '.slx']);
%             
% %             obj.simulation_data{1}
% %             obj.simulation_data{2}
%             
%         end
        
        
        
        
        
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
            simul = simulator(obj, obj.max_simul_attempt);
            ret =  simul.simulate(obj.slb);
            
%             simul.alg_loop_eliminator();
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
        
        function process_preadded_blocks(obj)
            % Manually overload for the time being.
        end
        
        
        
        function obj = get_candidate_blocks(obj)
            % Randomly choose which blocks will be used to populate the
            % model
            all = obj.get_all_simulink_blocks();  
            
            obj.process_preadded_blocks();
            
            if obj.num_preadded_blocks == 0
                obj.candi_blocks = cell(1, obj.NUM_BLOCKS);
            end
            
%             rand_vals = randi([1, numel(all)], 1, obj.NUM_BLOCKS);
            
            for index = 1:obj.NUM_BLOCKS
                obj.candi_blocks{index + obj.num_preadded_blocks} = all.get(index);
%                 obj.candi_blocks{index + obj.num_preadded_blocks} = all{rand_vals(index)};
            end
            
            obj.NUM_BLOCKS = obj.NUM_BLOCKS + obj.num_preadded_blocks;
            
            % Calculate new-old ratio for hierarchy models
            obj.hierarchy_new_old = util.roulette_wheel(cfg.HIERARCHY_NEW_OLD_RATIO, obj.blkchooser.hier_block_count);
            if obj.hierarchy_new_old(1) == 0
                % If choosing zero NEW blocks.
                obj.hierarchy_new_old = [ceil(obj.blkchooser.hier_block_count/2), floor(obj.blkchooser.hier_block_count/2)];
            end
            fprintf('Hierarchy blocks ratio: New %d; Old %d\n', obj.hierarchy_new_old(1), obj.hierarchy_new_old(2));
        end
        
        
        function ret = get_all_simulink_blocks(obj)
%             ret = {'simulink/Sources/Constant', 'simulink/Sinks/Scope', 'simulink/Sources/Constant', 'simulink/Sinks/Display', 'simulink/Math Operations/Add'};

            if isempty(obj.blkchooser)
                obj.blkchooser = blockchooser();
            end
            
            ret = obj.blkchooser.get(obj.current_hierarchy_level, obj.max_hierarchy_level, obj.NUM_BLOCKS);
            obj.my_result.block_sel_stat = obj.blkchooser.selection_stat;
        end
        
        
        
        function c_p(obj, str, condition)
            % Will print str if conditionis true
            if condition && obj.DEBUG
                disp(str);
            end
        end
        
        function obj = bcsfunction(obj, h)
            fprintf('BLOCK CONSTRUCTION S FUNCTION..... !!!!!\n');
            sfcreator = sfuncreator();
            sfname = sfcreator.go(obj.skip_after_creation);
            if obj.current_hierarchy_level == 1
                obj.my_result.sfuns.add(sfname);
            else
                obj.root_result.sfuns.add(sfname);
            end
            set_param(h, 'FunctionName', sfname)
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
            
            while num_inp_ports > 0
                
                if cfg.PRINT_BLOCK_CONNECTION
                fprintf('-----\n');
                end
                
                while_it = while_it + 1;
    
                if cfg.PRINT_BLOCK_CONNECTION
                fprintf('Num Input port: %d; num output port: %d\n', num_inp_ports, num_oup_ports);
                end
                
                r_i_blk = 0;
                r_i_port = 0;
                
                r_o_blk = 0;
                r_o_port = 0;
                
                new_inp_used = false;
                new_oup_used = false;

                if num_inp_ports > 0
                   % choose an input port
                   if cfg.PRINT_BLOCK_CONNECTION
                    fprintf('(d) num_inp_blk: %d\n', num_inp_blocks);
                   end
                   [r_i_blk, r_i_port] = obj.choose_bp(num_inp_blocks, inp_blocks, obj.slb.inp_ports);
                   
                   new_inp_used = true;
                
                end

                if num_oup_ports > 0
                    % Choose output port
                    
                    % Choose block not already taken for input.
                    
                    if cfg.PRINT_BLOCK_CONNECTION
                        fprintf('(d) num_oup_blk: %d\n', num_oup_blocks);  
                    end

                    try
                        [r_o_blk, r_o_port] = obj.choose_bp_without_chosen(num_oup_blocks, oup_blocks, obj.slb.oup_ports, r_i_blk);
                    catch e
                        % Possible clause: only one output block available
                        % and it's same as the chosen input block for this
                        % iteration.
                        
                        if num_inp_blocks > 1
%                             fprintf('SKIPPING THIS ITERATION...\n');
                            continue;
                        else
                            % Can not use this output block. pick another
                            % in later code
                        end
                    end
                        
                    new_oup_used = true;


                end
                
                if r_i_port == 0 || r_i_blk == 0
                   
                    obj.c_p('No new inputs available!', cfg.PRINT_BLOCK_CONNECTION);
                    
                    throw(MException('SL:RandGen:UnexpectedBehavior', 'No Inputs were chosen!'));
                    
                    [r_i_blk, r_i_port] = obj.choose_bp(obj.slb.inp.len, obj.slb.inp.blocks, obj.slb.inp_ports);
                end
                
                if r_o_port == 0 || r_o_blk == 0
                    obj.c_p('No new outputs available!', cfg.PRINT_BLOCK_CONNECTION);
                    [r_o_blk, r_o_port] = obj.choose_bp_without_chosen(obj.slb.oup.len, obj.slb.oup.blocks, obj.slb.oup_ports, r_i_blk);
                end
                
                if cfg.PRINT_BLOCK_CONNECTION
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
                    fprintf('Error while connecting. Exception: %s\n', e.identifier);
                    fprintf('add_line(''%s\'', ''%s'', ''%s'', ''autorouting'', ''on'')\n', obj.sys, t_o, t_i);
                    fprintf('[!] Giving up... RETURNGING FROM BLOCK CONNECTION...\n');
                    throw(MException('SL:RandGen:UnexpectedBehavior', 'Unexpected err while connecting line'));
%                     break;
                end
                
                obj.slb.connect_nodes(r_o_blk, r_o_port, r_i_blk, r_i_port);
                
                % Mark used blocks/ports
                
                if new_inp_used
                    obj.slb.inp_ports{r_i_blk}{r_i_port} = 1;
                    
                    if obj.is_all_ports_used(obj.slb.inp_ports{r_i_blk})
%                         fprintf('ALL inp PORTS OF BLOCK IS USED: %d\n', r_i_blk);
                        [num_inp_blocks, inp_blocks] = obj.del_from_cell(r_i_blk, num_inp_blocks, inp_blocks);
                    end
                    
                    num_inp_ports = num_inp_ports - 1;
                end
                
                if new_oup_used
                    obj.slb.oup_ports{r_o_blk}{r_o_port} = 1;
                    
                    if obj.is_all_ports_used(obj.slb.oup_ports{r_o_blk})
%                         fprintf('ALL oup PORTS OF BLOCK IS USED: %d\n', r_o_blk);
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
%            num_blocks
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
        
        
        function obj = set_sample_time_for_discrete_blk(obj, h, blk)
            if ~ blk{2}
%                 disp('NOT A DISCRETE BLOCK. RETURN');
                return;
            end
            
%             disp('DISCRETE BLK!');
            
            try
                set_param(h, 'SampleTime', '1');  % TODO random choose sample time?
            catch e
            end
                
        end
        
        
        function obj = draw_blocks(obj)
            % Draw blocks in the screen
            
            disp('DRAWING BLOCKS...');
            
            cur_blk = 0;

            x = obj.pos_x;
            y = obj.pos_y;
            
%             disp('Candidate Blocks:');
%             disp(obj.candi_blocks); % Doesn't work: only mentions that
%             elements are cell

            for block_name = obj.candi_blocks
                % Warning: block_name could be a string or a cell. This is
                % a string if the block is pre-added. Cell otherwise, where
                % first element of the cell is the block name and 2nd
                % element is boolean: whether the block is discrete.
                
                cur_blk = cur_blk + 1;          % Create block name
                
                is_preadded_block = cur_blk <= obj.num_preadded_blocks;
                
                h_len = x + obj.width;

                pos = [x, y, h_len, y + obj.height];
                
                if is_preadded_block
                    this_blk_name = block_name{1};
                else
                    this_blk_name = obj.create_blk_name(cur_blk);
                end


                % Add this block name to list of all added blocks
                obj.slb.all{cur_blk} = this_blk_name;

                this_blk_name = strcat('/', this_blk_name);
%                 disp('Pos array is:');
%                 disp(pos);
                if is_preadded_block
                    h = get_param([obj.sys this_blk_name], 'handle');
                    set_param(h,'Position',pos);
                else
                    h = add_block(block_name{1}{1}, [obj.sys, this_blk_name], 'Position', pos);
                    obj.set_sample_time_for_discrete_blk(h, block_name{1});
                end
                
                % Save the handle of this new block. Accessing a block by
                % its handle is faster than accessing by its name
                
                obj.slb.handles{cur_blk} = h;
                
                % Generate hierarchy and subsystem blocks
                
                if is_preadded_block
                    blk_type = get_param(h, 'blocktype');
                else
                    blk_type = block_name{1}{1};
                end
                                
                if obj.blk_construction.contains(blk_type)
%                     disp('matched!');
                    obj.(obj.blk_construction.get(blk_type))(h)
%                 else
%                     disp('not matched!')
                end
                    
                
                if obj.blkchooser.is_hierarchy_block(blk_type)
                    fprintf('Hierarchy block %s found.\n', this_blk_name);

                    mdl_name = obj.handle_hierarchy_blocks();
                    fprintf('Generated this hierarchy model: %s\n', mdl_name);

                    set_param(h, 'ModelNameDialog', mdl_name);
                end

                if obj.blkchooser.is_submodel_block(blk_type)
                    fprintf('Submodel block %s found.\n', this_blk_name);
                    obj.handle_submodel_creation(this_blk_name, obj.sys);
                end
                
                % Configure block parameters
                
                
                obj.config_block(h, blk_type, this_blk_name);
                
                
                %%%%%%% Done configuring block %%%%%%%%%
                
                % Get its inputs and outputs
                ports = get_param(h, 'Ports');
                obj.slb.new_block_added(cur_blk, ports);
                
                obj.slb.create_node(cur_blk, ports, block_name{1}{1}, h);

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
            
            if obj.c_block == 0
                fprintf('Resetting block count!\n');
                obj.c_block =   numel(util.get_all_top_level_blocks(obj.sys));
            end
            
            obj.c_block = obj.c_block + 1;
            
            h_len = obj.d_x + obj.width;

            pos = [obj.d_x, obj.d_y, h_len, obj.d_y + obj.height];
            
            this_blk_name = obj.create_blk_name(obj.c_block);
            
%             fprintf('Calculated this position array:\n');
%             disp(pos);
            
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
        
%         function ret = handle_hierachy_or_submodel(obj, mytype)
%         end
        
        
        
        function ret=handle_hierarchy_blocks(obj)
            
            if obj.hierarchy_new_count < obj.hierarchy_new_old(1)
                fprintf('Choosing from NEW hierarchy models...\n');                 
                model_name = ['hier' int2str(util.rand_int(1, 10000, 1))]; % TODO fix Max number
                
                fprintf('--x-- New Child Model Creation for %s --x-- \n', model_name);

                SIMULATE_MODELS = true;
                CLOSE_MODEL = true;
                LOG_SIGNALS = false;
                SIMULATION_MODE = [];
                COMPARE_SIM_RESULTS = false;
                
                for new_mdl_i = 1:cfg.HIERARCHY_NEW_MAX_ATTEMPT
                    
                    fprintf('New model creation attempt: %d\n', new_mdl_i);

                    hg = hier_generator(cfg.CHILD_MODEL_NUM_BLOCKS, model_name, SIMULATE_MODELS, CLOSE_MODEL, LOG_SIGNALS, SIMULATION_MODE, COMPARE_SIM_RESULTS);
                    hg.skip_after_creation = obj.skip_after_creation;
                    hg.max_hierarchy_level = obj.max_hierarchy_level;
                    hg.current_hierarchy_level = obj.current_hierarchy_level + 1;

                    if obj.current_hierarchy_level == 1
                        disp('CURR HIER: 1');
                        hg.root_result = obj.my_result;
                    else
                        disp('CURR HIER: NOT 1');
                        hg.root_result = obj.root_result;
                    end

        %             hg.root_result.hier_models

                    hg.blkchooser = innerblkchooser();

                    hg.init();

                    try
                        hg.go();
                        break;
                    catch e
                        fprintf('Exception in hierarchy model simulation: \n' );
                        getReport(e)
                        if new_mdl_i ~= cfg.HIERARCHY_NEW_MAX_ATTEMPT
                            close_system(model_name);
                        end
                    end
                end

                % Save this model?
                
                if new_mdl_i == cfg.HIERARCHY_NEW_MAX_ATTEMPT && obj.hierarchy_old_models.len > 0
                    fprintf('New Model creation unsuccessful but old models available.\n');
                else
                    save_system(model_name);
                    disp('SAVING SUB SYSTEM...');
                    hg.root_result.hier_models.add(model_name);

                    obj.hierarchy_new_count = obj.hierarchy_new_count + 1;
                    obj.hierarchy_old_models.add(model_name);

                    ret = model_name;
                    return;
                end
            end

            fprintf('Choosing from old hierarchy models...\n');
            ret = obj.hierarchy_old_models.get(randi([1, obj.hierarchy_old_models.len], 1, 1));
            
        end
        
        
        function handle_submodel_creation(obj, blk_name, parent_model)
            SIMULATE_MODELS = false;
            CLOSE_MODEL = true;
            LOG_SIGNALS = false;
            SIMULATION_MODE = [];
            COMPARE_SIM_RESULTS = false;
            
            full_model_name = [parent_model blk_name];
            
            hg = submodel_generator(cfg.CHILD_MODEL_NUM_BLOCKS, full_model_name, SIMULATE_MODELS, CLOSE_MODEL, LOG_SIGNALS, SIMULATION_MODE, COMPARE_SIM_RESULTS);                      
            hg.skip_after_creation = obj.skip_after_creation;
            hg.max_hierarchy_level = obj.max_hierarchy_level;
            hg.current_hierarchy_level = obj.current_hierarchy_level + 1;
            
            if obj.current_hierarchy_level == 1
                disp('CURR HIER: 1');
                hg.root_result = obj.my_result;
            else
                disp('CURR HIER: NOT 1');
                hg.root_result = obj.root_result;
            end
            
            hg.root_result.hier_models
            
            hg.blkchooser = submodel_block_chooser();
%             hg.blkchooser = innerblkchooser();

            hg.init();
            
            try
                hg.go();
            catch e
                fprintf('Exception in Sub-model creation: \n' );
                getReport(e)
            end
        end
        
        function obj = random_config_block(obj, h, blk_type, blk_name)
%             fprintf(' --> Random config %s\n', blk_name);
            
            bp_data = get_param(h, 'DialogParameters');
            try
                bp_names = fieldnames(bp_data);
            catch e
                % TODO
                return;
            end

            % Enumerating all parameters of a block
            for j=1:numel(bp_names)
                cur_param_name = bp_names{j};
                cur_param_all = bp_data.(cur_param_name);

                if strcmp(cur_param_all.Type, 'enum')
                    % enum
%                     fprintf('Enum found\n');
                    try
                        set_param(h, cur_param_name, cur_param_all.Enum{1}); % TODO
                    catch e
                    end
                end
            end
        end
        
        
        
        function obj=config_block(obj, h, blk_type, blk_name)
            
            if cfg.PRINT_BLOCK_CONFIG
                disp(['(' blk_name ') Attempting to config block ', blk_type]);
            end
            
            found = obj.blkcfg.get_block_configs(blk_type);
            
            if cfg.PRINT_BLOCK_CONFIG
                bp = get_param(h, 'DialogParameters');
                disp(bp);
            end
            
%             obj.random_config_block(h, blk_type, blk_name);
            
            if isempty(found)
                if cfg.PRINT_BLOCK_CONFIG
                    disp(['[!] Did not find config db for block ', blk_type]);
                end
                return;
            end
            
            if cfg.PRINT_BLOCK_CONFIG
            	disp(['[i] Will config block type ', blk_type]);
            end
            
            for i=found
                if cfg.PRINT_BLOCK_CONFIG
                    disp(['Configuring ', i{1}.p()]);
                end
                set_param(h, i{1}.p(), i{1}.get());
            end           
            
        end
   
    end
    
end



