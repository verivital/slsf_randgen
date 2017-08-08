classdef cfg
    %CFG User-changable configurations
    %   Change various configure parameters here before calling `sgtest`
    %   script to run an experiment. Refer to the CyPhy 2016 paper to
    %   understand various "phases" of experiment.
    
    properties(Constant = true)
        NUM_TESTS = 50;                                % Number of random models to generate (and use in differntial testing)
        CSMITH_CREATE_C = false;                % Whether to call Csmith to create C files. Set to False if reproducing previous experiment.
        
        SIMULATE_MODELS = true;                 % To invoke "Analyze Model" and "Fix Errors" phase 

        LOG_SIGNALS = true;                         % Log all block-output signals for comparison ("Log Signals" phase). Note: it disregards `USE_PRE_GENERATED_MODEL` setting.

        COMPARE_SIM_RESULTS = false;         % Compare simulation results obtained by logging signals ("Compare" phases),
       

        USE_PRE_GENERATED_MODEL = [];         % If non-empty and a string, then instead of generating random model, will use value of this variable (already generated model) in log signal/comparison phases.   
%          USE_PRE_GENERATED_MODEL = 'sampleModel246';  % Instead of randomly
%          generating model will use this particular model for further
%          phases of CyFuzz

        LOAD_RNG_STATE = true;                  % Set this `true` if we want to create NEW models each time the script is run. Set to `false` if generating same models at each run of the script is desired. For first time running in a new computer set to false, as this will fail first time if set to true.

        SKIP_IF_LAST_CRASHED = false;            % Skip one model if last time Matlab crashed trying to run the same model.
        
        STOP_IF_ERROR = false;                  % Stop the script when meet the first simulation error
        STOP_IF_OTHER_ERROR = true;             % Stop the script for errors not related to simulation e.g. unhandled exceptions or code bug. ALWAYS KEEP IT TRUE to detect my own bugs.

        CLOSE_MODEL = true;                    % Close models after experiment
        CLOSE_OK_MODELS = true;                % Close "OK" models (refer to CyPhy paper)
        
        FINAL_CLEAN_UP = true;                 % Will delete models and related artifacts (e.g. binaries) for the model

        GENERATE_TYPESMART_MODELS = true;      % Will create models that respects data-type compatibility between blocks.
        ELIMINATE_FEEDBACK_LOOPS = true;
        
        NUM_BLOCKS = [75 100];
        CHILD_MODEL_NUM_BLOCKS = [20 30];
        SUBSYSTEM_NUM_BLOCKS = [20 30];
        IF_ACTION_SUBSYS_NUM_BLOCKS = [5 15];
        
        MAX_HIERARCHY_LEVELS =1;               % Minimum value is 1 indicating a flat model with no hierarchy.

        SAVE_ALL_ERR_MODELS = true;             % Save the models which we can not simulate 
        LOG_ERR_MODEL_NAMES = true;             % Log error model names keyed by their errors
        SAVE_COMPARE_ERR_MODELS = true;         % Save models for which we got signal compare error after diff. testing
        SAVE_SUCC_MODELS = true;                % Save successful simulation models in a folder

        PAUSE_BETWEEN_FIX_ERROR_STEPS = false;
        PAUSE_BETWEEN_CYCLE_REMOVING = false;
        PRESENTATION_MODE = false;   % Pause between various CyFuzz phases.
        
        PAUSE_AFTER_THIS_SUBSYSTEM = {};

        USE_SIGNAL_LOGGING_API = true;          % If true, will use Simulink's Signal Logging API, otherwise adds Outport blocks to each block of the top level model
        SIMULATION_MODE = {'accelerator'};      % See 'SimulationMode' parameter in http://bit.ly/1WjA4uE
        COMPILER_OPT_VALUES = {'off'};          % Compiler opt. values of Accelerator and Rapid Accelerator modes

        BREAK_AFTER_COMPARE_ERR = true;
        
        SL_SIM_TIMEOUT = 200;                   % After these many seconds give up testing the model and mark as Timed-Out model
        
        % Will only use following SL libraries/blocks. If this is a
        % library, set `is_blk` false. Set true for blocks.
        
        SL_BLOCKLIBS = {
           struct('name', 'Discrete', 'is_blk', false, 'num', 0.3)
            struct('name', 'Continuous', 'is_blk', false,  'num', 0.3)
   %         struct('name', 'Math Operations', 'is_blk', false, 'num', .15)
%             struct('name', 'Logic and Bit Operations', 'is_blk', false, 'num', 0.15)
            struct('name', 'Sinks', 'is_blk', false, 'num', 0.2)
            struct('name', 'Sources', 'is_blk', false, 'num', 0.2)
%             struct('name', 'simulink/Ports & Subsystems/Subsystem', 'is_blk', true, 'num', 0.05)
%             struct('name', 'simulink/Ports & Subsystems/If', 'is_blk', true, 'num', .05)
%             struct('name', 'simulink/Ports & Subsystems/For Iterator Subsystem', 'is_blk', true, 'num', .05)
%             struct('name', 'simulink/User-Defined Functions/S-Function', 'is_blk', true, 'num', 0.20)
%             struct('name', 'simulink/Ports & Subsystems/Model', 'is_blk', true, 'num', 0.06)
        };
    
        % Won't use following SL blocks in generated models:
    
        SL_BLOCKS_BLACKLIST = {
            'simulink/Sources/From File'
            'simulink/Sources/FromWorkspace'
            'simulink/Sources/EnumeratedConstant'
            'simulink/Discrete/Discrete Derivative'
            'simulink/Discrete/Resettable Delay'                        % For testing DFT analysis
            'simulink/Math Operations/FindNonzeroElements'
            'simulink/Continuous/VariableTransport Delay'
            'simulink/Continuous/VariableTime Delay'
            'simulink/Continuous/Transport Delay'
            'simulink/Sinks/StopSimulation'
            'simulink/Discrete/First-OrderHold'
            'simulink/Discrete/Memory'
            'simulink/Math Operations/Algebraic Constraint'
        };
    
        % ALLOW LIST: LOOKS LIKE ALLOW_LIST IS NOT IMPLEMENTED.
    


        SAVE_SIGLOG_IN_DISC = true; % Persistently save logged signals in dic

        DELETE_MODEL = true;    % Delete the model from working directory after testing 
        
        REPORTSNEO_DIR = 'reportsneo';  % Reports will be stored in this directory
        
        STOP_IF_LISTED_ERRORS = true;  % If any of the errors from the list below occurs, break even if STOP_IF_ERROR == false.
        STOP_ERRORS_LIST = {};
%         STOP_ERRORS_LIST = {'Simulink:Engine:BlkWithPortInLoop'};
        
%         STOP_ERRORS_LIST = {'Simulink:Engine:SolverConsecutiveZCNum', 'Simulink:blocks:SumBlockOutputDataTypeIsBool'};

%         CONTINUE_ERRORS_LIST = {'SL:RandGen:TestTerminatedWithoutExceptions'};                      % Don't stop sgtest if these errors occur.
        CONTINUE_ERRORS_LIST = {'Simulink:Engine:ExtraModelrefNoncontSignal'};                      % Don't stop sgtest if these errors occur.
    
    
        % Subsystem/hierarchy model related
        
        HIERARCHY_NEW_MAX_ATTEMPT = 5;
        HIERARCHY_NEW_OLD_RATIO = {struct('name', 'new', 'num', 0.7)
            struct('name', 'old', 'num', 0.3)
        };


        % Debugging Related
        
        PRINT_BLOCK_CONNECTION = false;
        PRINT_BLOCK_CONFIG = false;
        STOP_IF_DTC_ERROR = false; % Data type conversion from typesmart analysis
        STOP_BEFORE_SIMULATION = false;  % To return abruptly before iterative simulations in the "Fix Errors" phase
        
        % Don't change folllowing
        
        BLOCK_NAME_PREFIX = 'cfblk';
        
        SUBSYSTEM_FIX = true;
    
    end
    
    
    methods(Static)
      function print_warnings
                    
         if ~ cfg.SIMULATE_MODELS
            warning('Generated models were Not Simulated!');
         end
          
         if ~ cfg.LOG_SIGNALS
            warning('Signal Logging was not enabled!');
         end
         
         if ~ cfg.COMPARE_SIM_RESULTS
            warning('Comparison Framework was not run!');
         end
         
         
      end
    end
    
    methods
    end
    
end

