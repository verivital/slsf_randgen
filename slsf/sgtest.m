% Test simple_generator

NUM_TESTS = 1;
STOP_IF_ERROR = true;
CLOSE_MODEL = false;
SIMULATE_MODELS = true;

%%%%%%%%%%%%%%%%%%%% End of Options %%%%%%%%%%%%%%%%%%%%

if ~ exist('rng_state', 'var')
    rng_state = [];
end

if ~exist('rand_start_over', 'var')
    rand_start_over = false;
end

if isempty(rng_state) || rand_start_over
    disp('~~ RandomNumbers: Starting Over ~~');
    rng(0,'twister');           % Random Number Generator Init
else
    disp('~~ RandomNumbers: Storing from previous state ~~');
    rng(rng_state);
end

load_system('Simulink');

for ind = 1:NUM_TESTS
    chart_name = strcat('sampleModel', int2str(ind));
    
    % Store random number settings
    rng_state = rng;
    
    sg = simple_generator(30, chart_name, SIMULATE_MODELS, CLOSE_MODEL);
    
    if ~sg.go() && STOP_IF_ERROR
        disp('BREAKING FROM MAIN LOOP AS ERROR OCCURRED IN SIMULATION');
        break;
    end
end
