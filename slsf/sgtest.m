% This is entry point to the Random Generator.
% Run this script from the command line. You can edit following options
% (options are always written using all upper-case letters).

NUM_TESTS = 2;                          % Number of models to generate
STOP_IF_ERROR = false;                   % Stop when meet the first simulation error
STOP_IF_OTHER_ERROR = true;             % For errors not related to simulation e.g. unhandled exceptions or code bug. ALWAYS KEEP IT TRUE
CLOSE_MODEL = true;                    % Close models after simulation
CLOSE_OK_MODELS = false;                % Close models for which simulation ran OK
SIMULATE_MODELS = true;                 % Will simulate model if value is true
NUM_BLOCKS = 30;                        % Number of blocks in each model (flat hierarchy)

LOG_SIGNALS = true;                     % If set to true, will log all output signals for later comparison
SIMULATION_MODE = 'accelerator';        % See 'SimulationMode' parameter in http://bit.ly/1WjA4uE
COMPARE_SIM_RESULTS = true;             % Compare simulation results.

LOAD_RNG_STATE = true;                  % Load Random_Number_Generator state from Disc. Desired, if we want to create NEW models each time the script is run.

%%%%%%%%%%%%%%%%%%%% End of Options %%%%%%%%%%%%%%%%%%%%
fprintf('\n =========== STARTING SGTEST ================\n');

% addpath('slsf');

WS_FILE_NAME = ['data' filesep 'savedws.mat'];       % Saving ws vars so that we can continue from new random models next time the script is run.

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

log_len_mismatch_count = 0;
log_len_mismatch_names = mycell(NUM_TESTS);

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
                case {'MATLAB:MException:MultipleErrors'}
                    e = e.cause{1};
                    
                case {'RandGen:SL:SimTimeout'}
                    num_timedout_sim = num_timedout_sim + 1;
                    disp('Timed Out Simulation. Proceeding to the next model...');
                    
                    if CLOSE_MODEL sg.close(); end
           
                    continue;
                    
                case {'RandGen:SL:ErrAfterNormalSimulation'}
                    e_later = util.map_inc(e_later, e.message);
                    
                case {'RandGen:SL:CompareError'}
                    fprintf('Compare Error occurred. Breaking...\n');
                    break;
                
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
    num_timedout_sim
    e_map
    e_later
    log_len_mismatch_count
    
    disp('-- printing log_length mismatch model names --');
    log_len_mismatch_names.print_all();
    
    % Save statistics in file
    save(REPORT_FILE, 'mdl_counter', 'num_total_sim', 'num_suc_sim', 'num_err_sim', 'num_timedout_sim', 'e_map',... 
    'e_later', 'log_len_mismatch_count', 'log_len_mismatch_names');
end

% Clean-up
delete('*.mat');

disp('----------- SGTEST END -------------');

disp(['%%% %%%% %%%% %%%% %%%% Final Statistics %%% %%%% %%%% %%%% %%%%']);

mdl_counter
num_total_sim
num_suc_sim
num_err_sim
num_timedout_sim
e_map
e_later
log_len_mismatch_count

disp('-- printing log_length mismatch model names --');
log_len_mismatch_names.print_all();

disp('------ BYE from SGTEST -------');
