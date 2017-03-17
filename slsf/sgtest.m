% This is entry-point to all CyFuzz experiments.
% Run this script from the command line. Change configurations in cfg.m
% class. 

function sgtest(skip_first)

    abrupt_return = false;

    if nargin == 0
        skip_first = false;
    end

    fprintf('\n =========== STARTING SGTEST ================\n');

    % addpath('slsf');

    nowtime_str = datestr(now, 'yyyy-mm-dd-HH-MM-SS');

    REPORTS_BASE = [cfg.REPORTSNEO_DIR filesep nowtime_str];
    mkdir(REPORTS_BASE);
    copyfile('cfg.m', REPORTS_BASE)

    WS_FILE_NAME_ACTUAL = 'savedws.mat';

    WS_FILE_NAME = ['data' filesep WS_FILE_NAME_ACTUAL];       % Saving ws vars so that we can continue from new random models next time the script is run.
    ERR_MODEL_STORAGE = [REPORTS_BASE filesep 'errors'];    % In this directory save all the error models (not including timed-out models)
    mkdir(ERR_MODEL_STORAGE);
    COMPARE_ERR_MODEL_STORAGE = [REPORTS_BASE filesep 'comperrors'];    % In this directory save all the signal compare error models
    mkdir(COMPARE_ERR_MODEL_STORAGE);
    OTHER_ERR_MODEL_STORAGE = [REPORTS_BASE filesep 'othererrors'];
    mkdir(OTHER_ERR_MODEL_STORAGE);
    SUCC_MODEL_STORAGE = [REPORTS_BASE filesep 'success'];
    mkdir(SUCC_MODEL_STORAGE);
    LOG_LEN_MISMATCH_STORAGE = [REPORTS_BASE filesep 'loglenmismatch'];
    mkdir(LOG_LEN_MISMATCH_STORAGE);
    WSVAR_BACKUP_DIR = ['data' filesep 'backup'];

    if cfg.LOAD_RNG_STATE
        % Backup the variable first
        try
            copyfile(WS_FILE_NAME, [REPORTS_BASE filesep WS_FILE_NAME_ACTUAL]);
        catch e
            disp('FATAL: did not find previous state of random generator. Try setting `LOAD_RNG_STATE = false` in `cfg.m` file');
            return;
        end
        disp('Restoring RNG state from disc')
        load(WS_FILE_NAME);
    end

    % For each run of this script, new random numbers will be selected. If you
    % want to stop this behavior (e.g. if you want to generate the SAME models
    % each time you run this script) set the value of rand_start_over variable
    % in workspace. Do not edit below.

    if ~ exist('rng_state', 'var')
        rng_state = [];
        mdl_counter = 0; % To count how many unique models we generate
    end

    if ~exist('rand_start_over', 'var')
        rand_start_over = false;
    end

    if isempty(rng_state) || rand_start_over
        disp('~~ RandomNumbers: Starting Over ~~');
        rng(0,'twister');           % Random Number Generator  - Initialize
        mdl_counter = 0;
    else
        disp('~~ RandomNumbers: Storing from previous state ~~');
        rng(rng_state);
    end



    REPORT_FILE_NAME = 'reports';
    REPORT_FILE = [REPORTS_BASE filesep REPORT_FILE_NAME];

    % Reload configuration. This is necessary as the only instance of the
    % singleton class `slblocklibcfg` is not deleted between subsequent run of
    % `sgtest.m` in Matlab.

    singleInst = slblocklibcfg.getInstance();
    singleInst.reload_config();

    % Script is Starting %

    fprintf('Loading Simulink...\n');
    load_system('Simulink');

    num_total_sim = 0;
    num_suc_sim = 0;
    num_err_sim = 0;
    num_timedout_sim = 0;
    num_compare_error = 0;
    num_other_error = 0;

    log_len_mismatch_count = 0;
    log_len_mismatch_names = mycell(cfg.NUM_TESTS);

    err_model_names = struct;                       % For each error models save the names of the models
    compare_err_model_names = mycell(cfg.NUM_TESTS);     % Save those model names for which got signal compare error
    other_err_model_names = struct;

    errors = {};
    e_map = struct;
    e_later = struct;  % Errors which occurred after Normal simulation went OK

    l_logged = [];
    all_siglog = mycell(cfg.NUM_TESTS);
    all_models = mycell(cfg.NUM_TESTS);             % Store some stats before running simulation for all models e.g. number of blocks in the model
    all_models_sr = cell(1, cfg.NUM_TESTS);         % Store instance of savedresult class for each model
    
    dtc_stat = mycell(cfg.NUM_TESTS); % data-type conversion stats

    block_selection = mymap();                  % Stats on library selection
    total_time = [];                            % Time elapsed so far since the start of the experiment
    runtime = mycell(-1);

    break_main_loop = false;

    git_info = getGitInfo();

    save(REPORT_FILE, 'git_info');

    for ind = 1:cfg.NUM_TESTS

        if break_main_loop
            fprintf('---XXXX--- BREAKING MAIN SGTEST LOOP ---XXXX---\n');
            break;
        end

        % Store random number settings for future usage
        rng_state = rng;
        save(WS_FILE_NAME, 'rng_state', 'mdl_counter'); % Saving workspace variables (we're only interested in the variable rng_state)

        mdl_counter = mdl_counter + 1;
        model_name = strcat('sampleModel', int2str(mdl_counter));
        
        sr = savedresult(model_name);
        all_models_sr{ind} = sr;

        sg = simple_generator(cfg.NUM_BLOCKS, model_name, cfg.SIMULATE_MODELS, cfg.CLOSE_MODEL, cfg.LOG_SIGNALS, cfg.SIMULATION_MODE, cfg.COMPARE_SIM_RESULTS);
        sg.max_hierarchy_level = cfg.MAX_HIERARCHY_LEVELS;
        sg.current_hierarchy_level = 1;

        sg.use_pre_generated_model = cfg.USE_PRE_GENERATED_MODEL;

        sg.simulation_mode_values = cfg.COMPILER_OPT_VALUES;
        sg.use_signal_logging_api = cfg.USE_SIGNAL_LOGGING_API;
    %     sg.log_signal_adding_outport = true;    % TODO: Manual INVALID NOW?

        num_total_sim = num_total_sim + 1;
        
        if skip_first
            sg.skip_after_creation = true;
            skip_first = false;
        end
        
        try
            sg.init();
        catch e
            throw(MException('SL:RandGen:LastModelNotClosed', 'Please Close the last model before continuing'));
        end

        cur_mdl_data = struct;

        cur_mdl_data.sys = sg.sys;
        cur_mdl_data.num_blocks = sg.NUM_BLOCKS;

        all_models.add(cur_mdl_data);

        try
            sim_res = sg.go();
            
            sg.my_result.update_saved_result(sr);
            
    %         l_logged = sg.my_result.logdata;

    %         total_time = toc();

            % Statistics on block selection
            lib_stats = sg.my_result.block_sel_stat;
            lib_stats_keys = lib_stats.keys();
            for i = 1:numel(lib_stats_keys)
                k = lib_stats_keys{i};

                prev_val = block_selection.get(k);
                if isempty(prev_val)
                    prev_val = 0;
                end

                block_selection.put(k, (prev_val + lib_stats.get(k)));
            end

            % Runtime

            runtime.add(sg.my_result.runtime);
            
            dtc_stat.add({sg.my_result.dc_analysis, sg. my_result.dc_sim});

            if ~ sim_res

                num_err_sim = num_err_sim + 1;

                % Keep record of the exception

                c = struct;
                c.m_no = model_name;
                e = sg.my_result.exc;
                                
                if isempty(e)
                    abrupt_return = true;
                    throw(MException('SL:RandGen:TestTerminatedWithoutExceptions',... 
                    'The model does not have any exceptions, yet was not simulated successfully. Check for abrupt return from the script.'));
                end

                switch e.identifier
    %                 case {'MATLAB:MException:MultipleErrors'}
    %                     e = e.cause{1};

                    case {'RandGen:SL:SimTimeout'}
                        num_timedout_sim = num_timedout_sim + 1;
                        disp('Timed Out Simulation. Proceeding to the next model...');

    %                     if CLOSE_MODEL sg.close(); end
    %                     
    %                     % Delete sub-models
    %                     sg.my_result.hier_models.print_all('Printing sub models...');
    %                     for i = 1:sg.my_result.hier_models.len
    %                         close_system(sg.my_result.hier_models.get(i));  % TODO closing subsystem, so will not be visible for inspection if desired.
    %                         delete([sg.my_result.hier_models.get(i) '.slx']);
    %                     end
    %                     
    %                     continue;

                    case {'RandGen:SL:ErrAfterNormalSimulation'}
                        
                        sr.errors = sg.my_result.main_exc;
                        sr.is_err_after_normal_sim = true;
                        
                        err_key = ['AfterError_' e.message];
                        
                        e_later = util.map_inc(e_later, e.message);

                        if cfg.LOG_ERR_MODEL_NAMES
                            err_model_names = util.map_append(err_model_names, err_key, model_name);
                        end

                        util.cond_save_model(cfg.SAVE_ALL_ERR_MODELS, model_name, ERR_MODEL_STORAGE, sg.my_result);

                    case {'RandGen:SL:CompareError'}
                        fprintf('Compare Error occurred...\n');
                        num_compare_error = num_compare_error + 1;
                        compare_err_model_names.add(model_name);
                        util.cond_save_model(cfg.SAVE_COMPARE_ERR_MODELS, model_name, COMPARE_ERR_MODEL_STORAGE, sg.my_result);

                        if cfg.BREAK_AFTER_COMPARE_ERR
                            fprintf('COMPARE ERROR... BREAKING');
                            break_main_loop = true;
                        end

                    otherwise

                        if cfg.LOG_ERR_MODEL_NAMES
                            err_model_names = util.map_append(err_model_names, e.identifier, model_name);
                        end

                        util.cond_save_model(cfg.SAVE_ALL_ERR_MODELS, model_name, ERR_MODEL_STORAGE, sg.my_result);

                end

                e_map = util.map_inc(e_map, e.identifier);

                if cfg.STOP_IF_ERROR
                    if util.cell_str_in(cfg.CONTINUE_ERRORS_LIST, e.identifier)
                        fprintf('An error occured, but SGTEST is not stopping even STOP_IF_ERROR is set to true. You asked me to do this for this specific error in cfg.m file.\n');
                    else
                        disp('BREAKING FROM MAIN LOOP AS ERROR OCCURRED IN SIMULATION');
                        break_main_loop = true;
                    end
                elseif cfg.STOP_IF_LISTED_ERRORS && util.cell_str_in(cfg.STOP_ERRORS_LIST, e.identifier)
                    disp('BREAKING FROM MAIN LOOP --- You asked me to stop for this specific error in the cfg.m FILE.');
                    break_main_loop = true;
                end

                if cfg.CLOSE_MODEL
                    sg.close();
                end

            else
                % Successful Simulation! %
                num_suc_sim = num_suc_sim + 1;

                if sg.my_result.log_len_mismatch_count > 0
                    log_len_mismatch_count = log_len_mismatch_count + 1;
                    log_len_mismatch_names.add(model_name);

                    util.cond_save_model(true, model_name, LOG_LEN_MISMATCH_STORAGE, sg.my_result);

    %                 fprintf('BREAKING DUE TO MISMATCH...\n');
    %                 break;
                end

                util.cond_save_model(cfg.SAVE_SUCC_MODELS, model_name, SUCC_MODEL_STORAGE, sg.my_result);

                if cfg.CLOSE_MODEL || cfg.CLOSE_OK_MODELS
                    sg.close();           % Close Model
                end

            end
        catch e
            %%%%%%%%%%%%% "OTHER ERROR" %%%%%%%%%%%
            % Exception occurred when simulating, but the error was not caught.
            % Reason: code bug/unhandled errors. ALWAYS INSPECT THESE ERRORS!!
            warning('EEEEEEEEEEEEEEEEEEEE Unhandled Error In YOUR CODE! EEEEEEEEEEEEEEEEEEEEEEEEEE');
    %         e
    %         e.message
    %         e.cause
    % %         e.cause{1}
    % %         e.cause{2}
    %         e.stack.line
              getReport(e)

            % Following timeout will never occur here?
    %         if strcmp(e.identifier, 'RandGen:SL:SimTimeout')
    %             num_timedout_sim = num_timedout_sim + 1;
    %             disp('Timed Out Simulation. Proceeding to the next model...');
    %             continue;
    %         end

            e_map = util.map_inc(e_map, e.identifier);

            num_other_error = num_other_error + 1;

            other_err_model_names = util.map_append(other_err_model_names, e.identifier, model_name);
            util.cond_save_model(true, model_name, OTHER_ERR_MODEL_STORAGE, sg.my_result);

            if cfg.STOP_IF_OTHER_ERROR
                
                if util.cell_str_in(cfg.CONTINUE_ERRORS_LIST, e.identifier)
                    fprintf('Continuing SGTEST script, although an "other error" occured. This is specified in cfg.m file.\n');
                else
                    disp('Stopping: STOP_IF_OTHER_ERROR=True. WARNING: This will not be saved in reports.');
                    break_main_loop = true;
                end
            end

            if cfg.CLOSE_MODEL
                sg.close();
            end
        end

        disp(['%%% %%%% END ONE MODEL ' int2str(mdl_counter) ' %%% %%%%']);


        mdl_counter
        num_total_sim
        num_suc_sim
        num_err_sim
        num_compare_error
        num_other_error
        num_timedout_sim
        e_map
        e_later
        log_len_mismatch_count

        compare_err_model_names.print_all('-- printing COMPARE ERR model names --');
    %     log_len_mismatch_names.print_all('-- printing log_length mismatch model names --');

        % Save statistics in file
        if cfg.SAVE_SIGLOG_IN_DISC
            all_siglog.add(sg.my_result.logdata);
        end

        save(REPORT_FILE, 'mdl_counter', 'num_total_sim', 'num_suc_sim', 'num_err_sim', ...
            'num_compare_error', 'num_other_error', 'num_timedout_sim', 'e_map', ... 
            'err_model_names', 'compare_err_model_names', 'other_err_model_names', ...
            'e_later', 'log_len_mismatch_count', 'log_len_mismatch_names', 'all_siglog', 'all_models', 'block_selection', 'runtime',...
            'dtc_stat', 'all_models_sr',...
            '-append');

        if cfg.DELETE_MODEL && isempty(cfg.USE_PRE_GENERATED_MODEL)
            fprintf('Deleting model...\n');
            delete([sg.sys '.slx']);  % TODO Warning: when running a pre-generated model this will delete it! So keep the model in a different directory and add that directory in Matlab path.
        end

        % Close and/or Delete sub-models
        sg.my_result.hier_models.print_all('Printing sub models...');
        for i = 1:sg.my_result.hier_models.len
            if cfg.CLOSE_MODEL || (sim_res && cfg.CLOSE_OK_MODELS)
                close_system(sg.my_result.hier_models.get(i));  % TODO closing subsystem, so will not be visible for inspection if desired.
            end
            
            if cfg.DELETE_MODEL
                delete([sg.my_result.hier_models.get(i) '.slx']);
            end
        end

        delete(sg);
    %     clear sg;
    end

    % Clean-up

    if cfg.FINAL_CLEAN_UP && isempty(cfg.USE_PRE_GENERATED_MODEL)
        delete('*.c');
        delete('*.mat');
        delete('*.mexa64');
        delete('*_msf.*');  % Files generated in Windows
    end

    disp(['%%% %%%% %%%% %%%% %%%% Final Statistics %%% %%%% %%%% %%%% %%%%']);
    % toc

    mdl_counter
    num_total_sim
    num_suc_sim
    num_err_sim
    num_compare_error
    num_other_error
    num_timedout_sim
    e_map
    e_later
    log_len_mismatch_count


    compare_err_model_names.print_all('-- printing COMPARE ERR model names --');
    log_len_mismatch_names.print_all('-- printing log_length mismatch model names --');


    %%% Block Library Selection Stats %%%
    fprintf('==== block selection stats ====\n');
    for i = 1:numel(block_selection.keys())
        k = block_selection.key(i);
        fprintf('%s\t\t\t\t%.2f\n', k, block_selection.get(k) / num_total_sim);
    end

    if abrupt_return
        warning('The model does not have any exceptions, yet was not simulated successfully. Check for abrupt return from the script.'); 
    end
    
    cfg.print_warnings();

    fprintf('------ BYE from SGTEST. Report saved in %s.mat -------\n', nowtime_str);
end
