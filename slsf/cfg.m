classdef cfg
    %CFG User-changable configurations
    %   Detailed explanation goes here
    
    properties(Constant = true)
        NUM_TESTS = 100;                        % Number of models to generate

        SIMULATE_MODELS = true;                 % To simulate generated model

        LOG_SIGNALS = true;                     % To log all output signals for comparison

        COMPARE_SIM_RESULTS = true;             % To compare simulation results obtained by logging signals.

        % If this is non-empty and a string, then instead of generating a model, will use value of this variable as an already generated model. 
        % Put empty ``[]'' to randomly generate models.

        USE_PRE_GENERATED_MODEL = [];           
        % USE_PRE_GENERATED_MODEL = 'potential';  

        LOAD_RNG_STATE = true;                  % Set this `true` if we want to create NEW models each time the script is run. Set to `false` if generating same models at each run of the script is desired. For first time running in a new computer set to false, as this will fail first time if set to true.

        STOP_IF_ERROR = true;                  % Stop the script when meet the first simulation error
        STOP_IF_OTHER_ERROR = true;             % Stop the script for errors not related to simulation e.g. unhandled exceptions or code bug. ALWAYS KEEP IT TRUE to detect my own bugs.

        CLOSE_MODEL = false;                    % Close models after simulation
        CLOSE_OK_MODELS = true;                % Close models for which simulation ran OK

        NUM_BLOCKS = 10;                    % Number of blocks in each model. Give single number or a matrix [minval maxval]. Example: "5" will create models with exactly 5 blocks. "[5 10]" will choose a value randomly between 5 and 10.

        MAX_HIERARCHY_LEVELS = 1;               % Minimum value is 1 indicating a flat model with no hierarchy.

        SAVE_ALL_ERR_MODELS = true;             % Save the models which we can not simulate 
        LOG_ERR_MODEL_NAMES = true;             % Log error model names keyed by their errors
        SAVE_COMPARE_ERR_MODELS = true;         % Save models for which we got signal compare error after diff. testing
        SAVE_SUCC_MODELS = true;                % Save successful simulation models in a folder



        USE_SIGNAL_LOGGING_API = true;          % If true, will use Simulink's Signal Logging API, otherwise adds Outport blocks to each block of the top level model
        SIMULATION_MODE = {'accelerator'};      % See 'SimulationMode' parameter in http://bit.ly/1WjA4uE
        COMPILER_OPT_VALUES = {'off'};          % Compiler opt. values of Accelerator and Rapid Accelerator modes

        BREAK_AFTER_COMPARE_ERR = true;
        
        
        SL_BLOCKLIBS = {
%            struct('name', 'Discrete', 'num', 0.7)
             struct('name', 'Continuous', 'num', 0.7)
%             struct('name', 'Math Operations', 'num', 10)
%             struct('name', 'Logic and Bit Operations', 'num', 10)
            struct('name', 'Sinks', 'num', 0.15)
            struct('name', 'Sources', 'num', 0.15)
        };
    
        SL_BLOCKS_BLACKLIST = {
            'simulink/Sources/From File'
            'simulink/Sources/FromWorkspace'
            'simulink/Sources/EnumeratedConstant'
            'simulink/Discrete/Discrete Derivative'
            'simulink/Math Operations/FindNonzeroElements'
            'simulink/Continuous/VariableTransport Delay'
            'simulink/Continuous/VariableTime Delay'
            'simulink/Continuous/Transport Delay'
            'simulink/Sinks/StopSimulation'
        };
    
        SL_HIERARCHY_BLOCKS = {'simulink/Ports & Subsystems/Model'};                    % Blocks used to create child models
        SL_SUBSYSTEM_BLOCKS = {'simulink/Ports & Subsystems/For Each Subsystem'};       % Blocks used to create subsystem

        SAVE_SIGLOG_IN_DISC = true;

        DELETE_MODEL = true;
        
        REPORTSNEO_DIR = 'reportsneo';
    end
    
    methods
    end
    
end

