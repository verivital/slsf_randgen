classdef simple_generator < handle
    % Random Generator. Generates a random model (and also runs comparison framework)
    %   Detailed explanation goes here
    
    properties(Constant = true)
       DEBUG = true;
       LIST_BLOCK_PARAMS = false;    % Will list all dialog parameters of a block which is chosen for current chart
       LIST_CONN = true;            % If true will print info when connecting blocks
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
        pre_analysis_only = false;              % If true then will return from Fix Errors phase after `pre analysis'
        is_subsystem = true;
        
        blkcfg = [];    % instance of blockconfigure; determines how some block parameters are configured
        blkchooser = [];                 % instance of blockchooser; determines how to randomly select blocks
        
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

        blk_in_line = cfg.NUM_BLOCKS_IN_A_ROW;
        
        % hierarchy related
        hierarchy_new_old = []; % Ratio of new and old submodels
        hierarchy_new_count = 0;
        hierarchy_old_models;
        descendant_generators;   % a hashmap, key is descendant child model name, value is the generator object
        
        % Block construction and constraint solving hooks
        blk_construction;            % Hooks to run for specific blocks, inside `draw_blocks` function.
        pre_block_connection;    % Hooks to run for specific blocks, just before `connect_blocks` function.
        post_block_connection;  % Hooks to run for specific blocks, just after `connect_blocks` function.
        
        assign_sampletime_for_discrete = true;  % Assign sample time for discrete blocks. In some subsystems (e.g. Action subsystem) we can't do this.
        
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
            obj.descendant_generators = mymap();
            
            obj.blk_construction = mymap('simulink/User-Defined Functions/S-Function', 'bc_sfunction', 'simulink/Ports & Subsystems/If', 'bc_if');
            obj.pre_block_connection = mycell();
            obj.post_block_connection = mycell();
        end
        
        
        function ret = go(obj)
            % Call this function to start
            obj.p('--- Starting Simple Generator ---');
            if obj.current_hierarchy_level == 1
                fprintf('CyFuzz::NewRun\n');
            end
            
            ret = false;
            
%             obj.init(); % NOTE: Client has to call init() explicityly!
                        
            if isempty(obj.use_pre_generated_model)
            
                obj.get_candidate_blocks();
                
                ret = obj.draw_blocks();
                
                if ~ ret
                    fprintf('Drawing blocks failed, returning\n');
                    return;
                end
                
                if cfg.PRESENTATION_MODE
                    fprintf('---- CyFuzz: Block Selection Phase Completed ---- \n');
                    pause();
                end
               

                obj.chk_compatibility();
                
                obj.my_result.store_runtime(singleresult.BLOCK_SEL);
                
                obj.run_pre_block_connection_hooks();
                obj.connect_blocks();
                obj.run_post_block_connection_hooks();
                
                obj.my_result.store_runtime(singleresult.PORT_CONN);
                
                fprintf('--Done Connecting!--\n');
                
                if cfg.PRESENTATION_MODE
                    fprintf('---- CyFuzz: Port Connection Phase Completed ---- \n');
                    pause();
                end

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
            
            obj.configure_model();
            
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
                
           
                % Run simulation again for comparing results
                
                
                if ~ obj.compare_results
                    fprintf('Comparing results is turned off. Returning...\n');
                    return;
                end
                                
                diff_tester = difftester(obj.sys, obj.my_result, obj.num_log_len_mismatch_attempt, obj.simulation_mode, obj.simulation_mode_values, obj.compare_results);
                diff_tester.logging_method_siglog = obj.use_signal_logging_api;
                
                ret = diff_tester.go();
                
            else
                obj.my_result.set_mode(singleresult.NORMAL, singleresult.ER);
                % Don't need to record timed_out, it is already logged
                % inside Simulator.m class
            end
            
            
            
            fprintf('------------------- END of One Generator Call -------------------\n');
        end
        
        function obj  = configure_model(obj)
%             set_param(obj.sys, 'BooleanDataType', 'off'); % If this optimization is kept on, boolean values will not be treated as doubles. see "Implement logic signals as Boolean data (vs. double)"
        end
        
        function obj = init(obj)
            % Perform Initialization
            
            % Choose number of blocks to use
            
            if ~ isscalar(obj.NUM_BLOCKS)
                obj.NUM_BLOCKS = util.rand_int(obj.NUM_BLOCKS(1), obj.NUM_BLOCKS(2), 1);
                fprintf('NUM_BLOCKS chosen to %d \n', obj.NUM_BLOCKS);
            end
            
            if isempty(obj.blkcfg)
                obj.blkcfg = blockconfigure();
            end
            obj.my_result = singleresult(obj.sys, obj.record_runtime);
            
            obj.my_result.init_runtime_recording();
            
            obj.create_and_open_system();
        end
        
        
        function ret = get_root_generator(obj)
            if isa(obj, 'hier_generator')
                ret = obj.root_generator;
            else
                ret = obj;
            end
        end
        
        
        function create_and_open_system(obj)
            if isempty(obj.use_pre_generated_model)
                new_system(obj.sys);
                open_system(obj.sys);
            end
        end
        
        
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
                if strcmp(get_param(all_blocks(i), 'blocktype'), 'If')
                    continue;
                end
                port_handles = get_param(all_blocks(i), 'PortHandles');
                out_ports = port_handles.Outport;
                
                for j = 1: numel(out_ports)
                    set_param(out_ports(j), 'DataLogging', 'On');
                end
            end
            
            
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
            
            if ~ obj.is_subsystem
                set_param(obj.sys, 'BlockReduction', 'off');
            end
            
            simul = simulator(obj, obj.max_simul_attempt);
            ret =  simul.simulate(obj.slb, obj.pre_analysis_only);
            
%             set_param(obj.sys, 'BlockReduction', 'on');  % Would be
%             incorrect.
            
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
            % Will be implemented by subclasses
        end
        
        
        
        function obj = get_candidate_blocks(obj)
            % Randomly choose which blocks will be used to populate the
            % model
            all = obj.get_all_simulink_blocks();  % does the random selection part
            
%             disp('all blocks:')
%             all
%             obj.candi_blocks
            
            obj.process_preadded_blocks();
            
%             disp('after processing preadded');
%             obj.candi_blocks
            
            if obj.num_preadded_blocks == 0
                obj.candi_blocks = cell(1, obj.NUM_BLOCKS);
            end
            
            
%             obj.num_preadded_blocks
%             obj.NUM_BLOCKS
            
%             rand_vals = randi([1, numel(all)], 1, obj.NUM_BLOCKS);
            
            for index = 1:obj.NUM_BLOCKS
                obj.candi_blocks{index + obj.num_preadded_blocks} = all.get(index);
            end
            
            obj.NUM_BLOCKS = obj.NUM_BLOCKS + obj.num_preadded_blocks;
            
%             disp('candi blocks in get_candi_blocks')
%             obj.candi_blocks
            
            
            % Calculate new-old ratio for hierarchy models
            obj.hierarchy_new_old = util.roulette_wheel(cfg.HIERARCHY_NEW_OLD_RATIO, obj.blkchooser.hier_block_count);
            if obj.hierarchy_new_old(1) == 0
                % If choosing zero NEW blocks.
                obj.hierarchy_new_old = [ceil(obj.blkchooser.hier_block_count/2), floor(obj.blkchooser.hier_block_count/2)];
            end
            fprintf('Hierarchy blocks ratio: New %d; Old %d\n', obj.hierarchy_new_old(1), obj.hierarchy_new_old(2));
        end
        
        
        function ret = get_all_simulink_blocks(obj)
            % Although the name suggests to get all possible simulink
            % blocks, this function actually respects the cfg.m file and
            % randomly selects from libraries and bocks listed in the cfg.m
            % file.

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
        
        function obj = run_pre_block_connection_hooks(obj)
            fprintf('-- Calling Pre-Block-Connection Hooks --\n');
            for i=1:obj.pre_block_connection.len
                data = obj.pre_block_connection.get(i);
                obj.(data{1})(data{2});
            end
        end
        
        function obj = run_post_block_connection_hooks(obj)
            fprintf('-- Calling Post-Block-Connection Hooks --\n');
            for i=1:obj.post_block_connection.len
                data = obj.post_block_connection.get(i);
                obj.(data{1})(data{2});
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
                
%                 if cfg.GENERATE_TYPESMART_MODELS
                obj.slb.connect_nodes(r_o_blk, r_o_port, r_i_blk, r_i_port);
%                 end
                
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
            ret = strcat(cfg.BLOCK_NAME_PREFIX, num2str(num));
        end
        
        
        function obj = set_sample_time_for_discrete_blk(obj, h, blk, blk_type)
            
            if strcmp(blk_type,  'simulink/Ports & Subsystems/If')
                set_param(h, 'sampletime', '1'); % TODO
                return;
            end
            
%             fprintf('[!!] Sample time for %s ----- \n', getfullname(h));
%             disp(obj.assign_sampletime_for_discrete);
            
            if ~ blk{2}
%                 disp('NOT A DISCRETE BLOCK. RETURN');
                return;
            end
            
%             disp('DISCRETE BLK!');
            
            try
                if obj.assign_sampletime_for_discrete
%                     fprintf('Will assign sampletime 1');
                    sampletime = '1';
                else
%                     fprintf('Will assign inherited sampletime -1');
                    sampletime = '-1';
                end
                set_param(h, 'SampleTime', sampletime);  % TODO random choose sample time?
            catch e
                if strcmp(blk_type, sprintf('simulink/Discrete/First-Order\nHold'))
                    set_param(h,'MaskValues',{'-1'})
%                     fprintf('settt');
                end
            end
                
        end
        
        
        function ret = draw_blocks(obj)
            % Puts ("draws") blocks in the newly created  empty model. Then starts
            % configuring and constructing them.
            ret = true;
            
%             disp('DRAWING BLOCKS...');
            
            obj.slb = slblocks(obj.NUM_BLOCKS);
            
            cur_blk = 0;

            x = obj.pos_x;
            y = obj.pos_y;
            

            while true
                % block_name is a cell, where
                % first element of the cell is the block TYPE if this is
                % NOT a pre-added block, and block NAME otherwise.
                % and 2nd
                % element is boolean: whether the block is discrete.
                
                cur_blk = cur_blk + 1;          % Create block name
                
                if cur_blk > numel(obj.candi_blocks)
                    break;
                end
                
                block_name = obj.candi_blocks{cur_blk};
                
                is_preadded_block = cur_blk <= obj.num_preadded_blocks;
                
                if is_preadded_block
                    this_blk_name = obj.create_blk_name(cur_blk);
                    set_param([obj.sys '/' block_name{1}], 'name', this_blk_name);
                else
                    this_blk_name = obj.create_blk_name(cur_blk);
                end
                

                % Add this block information in obj.slb registry
                obj.slb.all{cur_blk} = this_blk_name;
                
                this_blk_name = strcat('/', this_blk_name);

                h_len = x + obj.width;
                pos = [x, y, h_len, y + obj.height];
                
                if is_preadded_block
                    h = get_param([obj.sys this_blk_name], 'handle');
                    set_param(h,'Position',pos);
                    blk_type = get_param(h, 'blocktype');
                    
                else
%                     block_name
                    h = add_block(block_name{1}, [obj.sys, this_blk_name], 'Position', pos);
                    blk_type = block_name{1};
                    obj.set_sample_time_for_discrete_blk(h, block_name, blk_type);
                end
                
                 % WARNING: pre-added and non-preadded blocks have different
                % blk_type. E.g. an input port if pre-added will have
                % blk_type `Inport` whereas if not pre-added will have
                % blk_type 'simulink/Sources/Inp...'. Thus, blk_type-based
                % logic will be affected. E.g. possibly can't find fixeddoc
                % info or parsed info for these pre-added blocks.
                
%                 disp(blk_type);
%                 blk_type
                
                obj.slb.handles{cur_blk} = h;

                % Do block-specific mandatory constructions, e.g. for
                % S-functions have to ``construct'' the block.
                if obj.blk_construction.contains(blk_type)
%                     disp('matched!');
                    obj.(obj.blk_construction.get(blk_type))(h, cur_blk);
%                 else
%                     disp('not matched!')
                end
                    
                % Construct the block if it is a hierarchy block
                if obj.blkchooser.is_hierarchy_block(blk_type)
                    fprintf('Hierarchy block %s found.\n', this_blk_name);
                    try
                        mdl_name = obj.handle_hierarchy_creation();
                    catch e
                        if strcmp(e.identifier, 'RandGen:SL:ChildModelCreationAttemptExhausted')
                            obj.my_result.exc = e;
                            ret = false;
                            return;
                        end
                    end
                    fprintf('Generated this hierarchy model: %s\n', mdl_name);

                    set_param(h, 'ModelNameDialog', mdl_name);
                end
                
                % Construct the block if it is a subsystem block
                if obj.blkchooser.is_submodel_block(blk_type)
                    fprintf('SubSystem block %s found.\n', this_blk_name);
                    obj.handle_subsystem_creation(this_blk_name, obj.sys, blk_type);
                end

                % Configure block parameters
                obj.config_block(h, blk_type, this_blk_name);
 
                %%%%%%% Done configuring block %%%%%%%%%
                
                % Get its inputs and outputs
                ports = get_param(h, 'Ports');
                
                if strcmp(blk_type, 'simulink/Ports & Subsystems/If')
                    ports(2) = 0;   % Output ports of IF block should not participate in connections
                end
                
                obj.slb.new_block_added(cur_blk, ports);
                
%                 if cfg.GENERATE_TYPESMART_MODELS
                obj.slb.create_node(cur_blk, ports, blk_type, h);
%                 end

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
            obj.c_block = cur_blk - 1;
%             fprintf('c_block stored to %d\n', obj.c_block);
        end
        
        
        
        
        function [this_blk_name, h] = add_new_block(obj, block_type)
            
%             fprintf('Inside add new block\n');
            
            if obj.c_block == 0
                fprintf('Resetting block count!\n');
                obj.c_block =   numel(util.get_all_top_level_blocks(obj.sys));
            end
            
            obj.c_block = obj.c_block + 1;
            
%             fprintf('This is new block number: %d\n', obj.c_block);
            
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
        
        
        
        function ret=handle_hierarchy_creation(obj)
            
            if obj.hierarchy_new_count < obj.hierarchy_new_old(1)
                fprintf('Choosing from NEW hierarchy models...\n');                 
                model_name = ['hier' int2str(util.rand_int(1, 10000000, 1))]; % TODO fix Max number
                
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
                        hg.root_generator = obj;
                    else
                        disp('CURR HIER: NOT 1');
                        hg.root_result = obj.root_result;
                        hg.root_generator = obj.root_generator;
                    end

        %             hg.root_result.hier_models

                    hg.blkchooser = hier_block_chooser();

                    hg.init();

                    try
                        res = hg.go();
                        if res
                            fprintf('Success in child model creation \n');
                            break;
                        else
                            fprintf('Child model generation UNsuccessful. Will try again\n');
                            close_system(model_name, 0);
                        end
                    catch e
                        fprintf('Exception in hierarchy model simulation: \n' );
                        getReport(e)
                        
                        error('FATAL: Hierarchy Model creation error');
                        
%                         if new_mdl_i ~= cfg.HIERARCHY_NEW_MAX_ATTEMPT
%                             close_system(model_name);
%                         end
                    end
                end

                % Save this model?
                
                if ~res 
                    if obj.hierarchy_old_models.len > 0
                        fprintf('New Model creation unsuccessful but old models available.\n');
                    else
                        throw(MException('RandGen:SL:ChildModelCreationAttemptExhausted', 'Could not create a valid child model'));
                    end
                else
                    save_system(model_name);
                    disp('SAVING SUB SYSTEM...');
                    hg.root_result.hier_models.add(model_name);

                    obj.hierarchy_new_count = obj.hierarchy_new_count + 1;
                    obj.hierarchy_old_models.add(model_name);
                    
                    hg.root_generator.descendant_generators.put(model_name, hg);

                    ret = model_name;
                    return;
                end
            end

            fprintf('Choosing from old hierarchy models...\n');
            ret = obj.hierarchy_old_models.get(randi([1, obj.hierarchy_old_models.len], 1, 1));
            
        end
        
        
        function handle_subsystem_creation(obj, blk_name, parent_model, blk_type)
            SIMULATE_MODELS = true; % pre-analysis only
            CLOSE_MODEL = true;
            LOG_SIGNALS = false;
            SIMULATION_MODE = [];
            COMPARE_SIM_RESULTS = false;
            
            full_model_name = [parent_model blk_name];
            assign_sample_time_for_discrete = obj.assign_sampletime_for_discrete;
            
            bconfigure = [];    % block configure: instance of blockconfigure class;
            
            switch blk_type
            
                case {'simulink/Ports & Subsystems/Subsystem'}
                    num_blks =cfg.SUBSYSTEM_NUM_BLOCKS;
                    bchooser = subsystem_block_chooser();
                case {sprintf('simulink/Ports & Subsystems/For Iterator Subsystem')}
                    num_blks =cfg.SUBSYSTEM_NUM_BLOCKS;
                    assign_sample_time_for_discrete = false;
                    bchooser = foriterator_block_chooser();
                    bconfigure = foriterator_blockconfigure();
                case {sprintf('simulink/Ports &\nSubsystems/If Action\nSubsystem')}
                    num_blks = cfg.IF_ACTION_SUBSYS_NUM_BLOCKS;
                    assign_sample_time_for_discrete = false;
                    bchooser = subsystem_block_chooser();
                otherwise
                    fatal('subsystem type not matched: %s', blk_type);
            end
            
            hg = subsystem_generator(num_blks, full_model_name, SIMULATE_MODELS, CLOSE_MODEL, LOG_SIGNALS, SIMULATION_MODE, COMPARE_SIM_RESULTS);                      
            hg.pre_analysis_only = true;
            hg.is_subsystem = true;
            hg.skip_after_creation = obj.skip_after_creation;
            hg.max_hierarchy_level = obj.max_hierarchy_level;
            hg.current_hierarchy_level = obj.current_hierarchy_level + 1;
            hg.assign_sampletime_for_discrete = assign_sample_time_for_discrete;
            
            if obj.current_hierarchy_level == 1
%                 disp('CURR HIER: 1');
                hg.root_result = obj.my_result;
                hg.root_generator = obj;
            else
%                 disp('CURR HIER: NOT 1');
                hg.root_result = obj.root_result;
                hg.root_generator = obj.root_generator;
            end
            
%             hg.root_result.hier_models

            fprintf('Subsystem before go: blk_name: %s; full name: %s\n', blk_name, full_model_name);

            hg.root_generator.descendant_generators.put(full_model_name, hg);
            
            hg.blkchooser = bchooser;
            hg.blkcfg = bconfigure();
            hg.init();
            
            try
                hg.go();
            catch e
                fprintf('Exception in Sub-model creation: \n' );
                getReport(e)
                error('FATAL: SUBSYSTEM creation error');
            end
            
            
            if util.cell_str_in(cfg.PAUSE_AFTER_THIS_SUBSYSTEM , full_model_name)
                fprintf('Pausing after model (subsystem) %s\n', full_model_name);
                pause
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
            
            for j=1:numel(found)
                i = found{j};
                if cfg.PRINT_BLOCK_CONFIG
                    disp(['Configuring ', i.p()]);
                end
                
                try
                    pm_val = i.get();
                    set_param(h, i.p(), pm_val);
                catch e
                    throw( ...
                        MException('RandGen:SL:BlockConfigBySetParam',...
                            sprintf('setparam failed for %s. key: %s; value: %s',...
                                blk_type, i.p(), pm_val ...
                            )...
                        )...
                    );
                end
            end           
            
        end
        
        % Block Construction Functions - these functions are used for
        % constructing specific blocks and satisfying block-specific
        % constraints
        
        function obj = bc_sfunction(obj, h, blk_id)
            % Hook: block construction for S-functions
            fprintf('BC HOOK: S FUNCTION..... \n');
            sfcreator = sfuncreator();
            sfname = sfcreator.go(obj.skip_after_creation);
            if obj.current_hierarchy_level == 1
                obj.my_result.sfuns.add(sfname);
            else
                obj.root_result.sfuns.add(sfname);
            end
            set_param(h, 'FunctionName', sfname)
        end
        
        function introduce_new_blocks(obj, blk_type)
            obj.NUM_BLOCKS = obj.NUM_BLOCKS + 1;
            obj.candi_blocks{obj.NUM_BLOCKS} = {blk_type, false};
            obj.slb.NUM_BLOCKS = obj.NUM_BLOCKS;
        end
        
        function bc_if(obj, h, blk_id)
            % Hook: Block construction for If subsytems
            fprintf('BC HOOK: IF SUBSYSTEM..... \n');
            num_output = 2; % TODO make it dynamic
            
            obj.post_block_connection.add({'post_bc_if', {blk_id, num_output, obj.NUM_BLOCKS}});
            
            obj.introduce_new_blocks(sprintf('simulink/Ports &\nSubsystems/If Action\nSubsystem'));
            obj.introduce_new_blocks(sprintf('simulink/Ports &\nSubsystems/If Action\nSubsystem'));
            
%             obj.candi_blocks{obj.NUM_BLOCKS + 1} = {sprintf('simulink/Ports &\nSubsystems/If Action\nSubsystem'), false};
%             obj.candi_blocks{obj.NUM_BLOCKS + 2} = {sprintf('simulink/Ports &\nSubsystems/If Action\nSubsystem'), false};
            
%             obj.NUM_BLOCKS = obj.NUM_BLOCKS + num_output;
%             obj.slb.NUM_BLOCKS = obj.NUM_BLOCKS;

        end
        
        function post_bc_if(obj, data)
            fprintf('Post-BlockConnection HOOK: IF SUBSYSTEM..... \n');
            % Hook: Pre-block-connection for If Subsystems. Connects output
            % ports of the IF block to Action ports of the If-Action
            % subsystems. Both draws and connects slbnodes objects.
            
            id_if = data{1};
            num_outputs = data{2};
            output_base = data{3};  % ID of the block BEFORE the first output subsystem in the slb registry
            
            if_blk_node = obj.slb.nodes{id_if};
            if_blk_node.is_outports_actionports = true;
            
            last_action_ss_id = output_base + num_outputs;
            first_action_ss_id = output_base + 1;
            
            for i=1:num_outputs
                action_block_id = output_base + i;
                add_line(obj.sys, [obj.slb.all{id_if} '/' int2str(i)], [obj.slb.all{action_block_id} '/Ifaction'], 'autorouting','on')
                obj.slb.connect_nodes(id_if, i, action_block_id, slbnode.ACTION_PORT);
                % Set "mutually exclusive data-flow dependant blocks"
                action_block_node = obj.slb.nodes{action_block_id};
                action_block_node.dfmutex_blocks = [[first_action_ss_id : action_block_id-1],  [action_block_id+1 : last_action_ss_id]];    % All blocks except the action block
                fprintf('Mut-Ex data flow blocks found for block %d:', action_block_id);
                disp(action_block_node.dfmutex_blocks);
            end
        end
        
        
   
    end
    
end



