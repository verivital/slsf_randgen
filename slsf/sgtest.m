% This is entry point to the Random Generator.
% Run this script from the command line. You can edit following options
% (options are always written using all upper-case letters).

NUM_TESTS = 1;                          % Number of models to generate
STOP_IF_ERROR = false;                   % Stop when meet the first simulation error
STOP_IF_OTHER_ERROR = true;             % For errors not related to simulation e.g. unhandled exceptions or code bug. ALWAYS KEEP IT TRUE
CLOSE_MODEL = true;                    % Close models after simulation
CLOSE_OK_MODELS = false;                % Close models for which simulation ran OK
SIMULATE_MODELS = true;                 % Will simulate model if value is true
NUM_BLOCKS = 30;                        % Number of blocks in each model (flat hierarchy)

SAVE_ALL_ERR_MODELS = true;             % Save the models which we can not simulate 
LOG_ERR_MODEL_NAMES = true;             % Log error model names keyed by their errors
SAVE_COMPARE_ERR_MODELS = true;         % Save models for which we got signal compare error after diff. testing

LOG_SIGNALS = true;                     % If set to true, will log all output signals for later comparison
SIMULATION_MODE = 'accelerator';        % See 'SimulationMode' parameter in http://bit.ly/1WjA4uE
COMPARE_SIM_RESULTS = true;             % Compare simulation results.

LOAD_RNG_STATE = true;                  % Load Random_Number_Generator state from Disc. Desired, if we want to create NEW models each time the script is run.
BREAK_AFTER_COMPARE_ERR = true;

%%%%%%%%%%%%%%%%%%%% End of Options %%%%%%%%%%%%%%%%%%%%
fprintf('\n =========== STARTING SGTEST ================\n');

% addpath('slsf');

WS_FILE_NAME = ['data' filesep 'savedws.mat'];       % Saving ws vars so that we can continue from new random models next time the script is run.
ERR_MODEL_STORAGE = ['reports' filesep 'errors'];    % In this directory save all the error models (not including timed-out models)
COMPARE_ERR_MODEL_STORAGE = ['reports' filesep 'comperrors'];    % In this directory save all the signal compare error models
OTHER_ERR_MODEL_STORAGE = ['reports' filesep 'othererrors'];

if LOAD_RNG_STATE
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

REPORT_FILE = ['reports' filesep datestr(now, 'yyyy-mm-dd-HH-MM-SS')];


% Script is Starting %

load_system('Simulink');

num_total_sim = 0;
num_suc_sim = 0;
num_err_sim = 0;
num_timedout_sim = 0;
num_compare_error = 0;
num_other_error = 0;

log_len_mismatch_count = 0;
log_len_mismatch_names = mycell(NUM_TESTS);

err_model_names = struct;                       % For each error models save the names of the models
compare_err_model_names = mycell(NUM_TESTS);     % Save those model names for which got signal compare error
other_err_model_names = struct;

errors = {};
e_map = struct;
e_later = struct;  % Errors which occurred after Normal simulation went OK

for ind = 1:NUM_TESTS
    % Store random number settings for future usate
    rng_state = rng;
    save(WS_FILE_NAME, 'rng_state', 'mdl_counter'); % Saving workspace variables (we're only interested in the variable rng_state)
    
    mdl_counter = mdl_counter + 1;
    model_name = strcat('sampleModel', int2str(mdl_counter));
    
    sg = simple_generator(NUM_BLOCKS, model_name, SIMULATE_MODELS, CLOSE_MODEL, LOG_SIGNALS, SIMULATION_MODE, COMPARE_SIM_RESULTS);
    
    num_total_sim = num_total_sim + 1;
    
    try
        sim_res = sg.go();
        
        if ~ sim_res

            num_err_sim = num_err_sim + 1;

            % Keep record of the exception

            c = struct;
            c.m_no = model_name;
            e = sg.last_exc;
            
            switch e.identifier
%                 case {'MATLAB:MException:MultipleErrors'}
%                     e = e.cause{1};
                    
                case {'RandGen:SL:SimTimeout'}
                    num_timedout_sim = num_timedout_sim + 1;
                    disp('Timed Out Simulation. Proceeding to the next model...');
                    
                    if CLOSE_MODEL sg.close(); end
           
                    continue;
                    
                case {'RandGen:SL:ErrAfterNormalSimulation'}
                    err_key = ['AfterError_' e.message];
                    e_later = util.map_inc(e_later, e.message);
                    
                    if LOG_ERR_MODEL_NAMES
                        util.map_append(err_model_names, err_key, model_name);
                    end
                    
                    util.cond_save_model(SAVE_ALL_ERR_MODELS, model_name, ERR_MODEL_STORAGE);
                    
                case {'RandGen:SL:CompareError'}
                    fprintf('Compare Error occurred...\n');
                    num_compare_error = num_compare_error + 1;
                    compare_err_model_names.add(model_name);
                    util.cond_save_model(SAVE_COMPARE_ERR_MODELS, model_name, COMPARE_ERR_MODEL_STORAGE);
                    
                    if BREAK_AFTER_COMPARE_ERR
                        fprintf('COMPARE ERROR... BREAKING');
                        break;
                    end
                    
                otherwise
                    
                    if LOG_ERR_MODEL_NAMES
                        util.map_append(err_model_names, e.identifier, model_name);
                    end
                    
                    util.cond_save_model(SAVE_ALL_ERR_MODELS, model_name, ERR_MODEL_STORAGE);
                
            end

%             if(strcmp(e.identifier, 'MATLAB:MException:MultipleErrors'))
%                 e = e.cause{1};
%             end

            e_map = util.map_inc(e_map, e.identifier);

            if STOP_IF_ERROR
                disp('BREAKING FROM MAIN LOOP AS ERROR OCCURRED IN SIMULATION');
                break;
            end
            
            if CLOSE_MODEL
                sg.close();
            end

        else % Successful Simulation! %
            num_suc_sim = num_suc_sim + 1;
            
            if sg.my_result.log_len_mismatch_count > 0
            	log_len_mismatch_count = log_len_mismatch_count + 1;
                log_len_mismatch_names.add(model_name);
            end
            
            if CLOSE_MODEL || CLOSE_OK_MODELS
                sg.close();           % Close Model
            end

        end
    catch e
        % Exception occurred when simulating, but the error was not caught.
        % Reason: code bug/unhandled errors. ALWAYS INSPECT THESE ERRORS!!
        disp('EEEEEEEEEEEEEEEEEEEE Unhandled Error In Simulation EEEEEEEEEEEEEEEEEEEEEEEEEE');
        e
        e.message
        e.cause
%         e.cause{1}
%         e.cause{2}
        e.stack.line
        
        % Following timeout will never occur here?
%         if strcmp(e.identifier, 'RandGen:SL:SimTimeout')
%             num_timedout_sim = num_timedout_sim + 1;
%             disp('Timed Out Simulation. Proceeding to the next model...');
%             continue;
%         end
        
        e_map = util.map_inc(e_map, e.identifier);
        
        num_other_error = num_other_error + 1;
        
        util.map_append(other_err_model_names, e.identifier, model_name);
        util.cond_save_model(true, model_name, OTHER_ERR_MODEL_STORAGE);
        
        if STOP_IF_OTHER_ERROR
            disp('Stopping: STOP_IF_OTHER_ERROR=True.');
            break;
        end
    end
    
%     delete sg;
%     clear sg;
    
    disp(['%%% %%%% %%%% %%%% %%%% AFTER ' int2str(mdl_counter) 'th SIMULATION %%% %%%% %%%% %%%% %%%%']);
    
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
    save(REPORT_FILE, 'mdl_counter', 'num_total_sim', 'num_suc_sim', 'num_err_sim', ...
        'num_compare_error', 'num_other_error', 'num_timedout_sim', 'e_map', ... 
        'err_model_names', 'compare_err_model_names', 'other_err_model_names', ...
        'e_later', 'log_len_mismatch_count', 'log_len_mismatch_names');
end

% Clean-up
delete('*.mat');
delete('*_acc.mexa64');

disp('----------- SGTEST END -------------');

disp(['%%% %%%% %%%% %%%% %%%% Final Statistics %%% %%%% %%%% %%%% %%%%']);

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


disp('------ BYE from SGTEST -------');
