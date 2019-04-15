% Entry-point to run SLFORGE - parallel mode
% Run this script from Matlab command line. Change configurations in cfg.m
% class. You should not be changing anything in this file.

function sgpar()

    fprintf('\n =========== STARTING SGPAR - (SLFORGE) ================\n');

    nowtime_str = datestr(now, 'yyyy-mm-dd-HH-MM-SS');
    
    sw = SuppressWarnings();
    sw.set_val(true);

    REPORTS_BASE = [cfg.REPORTSNEO_DIR filesep nowtime_str];
    mkdir(REPORTS_BASE);
    copyfile('cfg.m', REPORTS_BASE)
    
    PAR_DATA = [REPORTS_BASE filesep 'pardata'];
    mkdir(PAR_DATA);

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
    
    fprintf('Shuffling random numbers, experiments would be unique\n');
    rng('shuffle');

    REPORT_FILE_NAME = 'reports'; % overall report
    REPORT_FILE = [REPORTS_BASE filesep REPORT_FILE_NAME];

    % Reload configuration. This is necessary as the only instance of the
    % singleton class `slblocklibcfg` is not deleted between subsequent run of
    % `sgtest.m` in Matlab.

    singleInst = slblocklibcfg.getInstance();
    singleInst.reload_config();

    % Script is Starting %

    fprintf('Loading Simulink... (will take a while)\n');
    load_system('simulink');

    git_info = getGitInfo(); %#ok<NASGU>
    
    time_start = tic();

    parfor ind = 1:cfg.NUM_TESTS
        fprintf('[***] Creating %d of %d models \t\t\t %.2f\% Done \n',...
            ind, cfg.NUM_TESTS, ind/cfg.NUM_TESTS*100);
        
        load_system('simulink');
        
        model_name = sprintf('slforge_%d_%d', randi(10^9), ind);
        
        sr = savedresult(model_name);

        sg = simple_generator(cfg.NUM_BLOCKS, model_name, cfg.SIMULATE_MODELS, cfg.CLOSE_MODEL, cfg.LOG_SIGNALS, cfg.SIMULATION_MODE, cfg.COMPARE_SIM_RESULTS);
        sg.max_hierarchy_level = cfg.MAX_HIERARCHY_LEVELS;
        sg.current_hierarchy_level = 1;

        sg.use_pre_generated_model = cfg.USE_PRE_GENERATED_MODEL;

        sg.simulation_mode_values = cfg.COMPILER_OPT_VALUES;
        sg.use_signal_logging_api = cfg.USE_SIGNAL_LOGGING_API;
    %     sg.log_signal_adding_outport = true;    % TODO: Manual INVALID NOW?


        try
            sg.init();
        catch e % very low probability due to random number shuffle
            throw(MException('SL:RandGen:LastModelNotClosed', 'Please Close the last model before continuing'));
        end

        try
            sim_res = sg.go();

            sg.my_result.update_saved_result(sr);
            sr.is_successful = sim_res;

            if ~ sim_res
                e = sg.my_result.exc;

                if isempty(e)
                    throw(MException('SL:RandGen:TestTerminatedWithoutExceptions',... 
                    'The model does not have any exceptions, yet was not simulated successfully. Check for abrupt return from the script.'));
                end

                switch e.identifier
                    case {'RandGen:SL:SimTimeout'}
                        disp('Timed Out Simulation. Proceeding to the next model...');
                    case {'RandGen:SL:ErrAfterNormalSimulation'}
                        sr.errors = sg.my_result.main_exc;
                        sr.is_err_after_normal_sim = true;
                        util.cond_save_model(cfg.SAVE_ALL_ERR_MODELS, model_name, ERR_MODEL_STORAGE, sg.my_result);
                    case {'RandGen:SL:CompareError'}
                        fprintf('Compare Error occurred...\n');
                        util.cond_save_model(cfg.SAVE_COMPARE_ERR_MODELS, model_name, COMPARE_ERR_MODEL_STORAGE, sg.my_result);
                    otherwise
                        util.cond_save_model(cfg.SAVE_ALL_ERR_MODELS, model_name, ERR_MODEL_STORAGE, sg.my_result);
                end

                if cfg.CLOSE_MODEL
                    sg.close();
                end

            else % Successful Simulation! %
                if sg.my_result.log_len_mismatch_count > 0
                    util.cond_save_model(true, model_name, LOG_LEN_MISMATCH_STORAGE, sg.my_result);
                end

                util.cond_save_model(cfg.SAVE_SUCC_MODELS, model_name, SUCC_MODEL_STORAGE, sg.my_result);

                if cfg.CLOSE_MODEL || cfg.CLOSE_OK_MODELS
                    sg.close();           
                end

            end
        catch e
            %%%%%%%%%%%%% "OTHER ERROR" %%%%%%%%%%%
            % Exception occurred when simulating, but the error was not caught.
            % Reason: code bug/unhandled errors. ALWAYS INSPECT THESE ERRORS!!
            warning('EEEEEEEEEEEEEEEEEEEE Unhandled Error In YOUR CODE! EEEEEEEEEEEEEEEEEEEEEEEEEE');
              getReport(e)
            util.cond_save_model(true, model_name, OTHER_ERR_MODEL_STORAGE, sg.my_result);

            sr.is_slforge_crash = true;

            if cfg.CLOSE_MODEL
                sg.close();
            end
        end

        disp(['%%% %%%% END ONE MODEL ' int2str(ind) ' %%% %%%%']);

        % Save result
        SOLE_MODEL_REPORT = [PAR_DATA filesep int2str(ind)] ;
        sole_result = sg.my_result; 
        num_blocks = sg.NUM_BLOCKS; 
        
        save_sole_results(SOLE_MODEL_REPORT, sr, sole_result, num_blocks);
        
        if cfg.DELETE_MODEL && isempty(cfg.USE_PRE_GENERATED_MODEL)
            fprintf('Deleting model...\n');
            delete([sg.sys '.slx']);  
        end

        % Close and/or Delete sub-models
        sg.my_result.hier_models.print_all('Printing sub models...');
        for i = 1:sg.my_result.hier_models.len
            if cfg.CLOSE_MODEL || (sim_res && cfg.CLOSE_OK_MODELS)
                close_system(sg.my_result.hier_models.get(i), 0);  % TODO closing subsystem, so will not be visible for inspection if desired.
            end

            if cfg.DELETE_MODEL
                delete([sg.my_result.hier_models.get(i) '.slx']);
            end
        end

        delete(sg);
    end  %% PARFOR
    
    total_dur = toc(time_start); %#ok<NASGU>
    save(REPORT_FILE, 'git_info', 'total_dur');

    sw.restore();
    
    % Clean-up
    if cfg.FINAL_CLEAN_UP && isempty(cfg.USE_PRE_GENERATED_MODEL)
        delete('*.c');
        delete('*.mat');
        delete('*.mexa64');
        delete('*_msf.*');  % Files generated in Windows
    end

    cfg.print_warnings();
    fprintf('------ BYE from SGPAR. Report saved in reportsneo/%s directory.\n Call sgpreport to see reports. -------\n', nowtime_str);
end

function save_sole_results(SOLE_MODEL_REPORT, sr, sole_result, num_blocks) %#ok<INUSD>
    save(SOLE_MODEL_REPORT, 'sr', 'sole_result', 'num_blocks');
end
