% Test simple_generator

if ~ exist('s', 'var')
    s = [];
end

if ~exist('rand_start_over', 'var')
    rand_start_over = false;
end

if isempty(s) || rand_start_over
    disp('~~ RandomNumbers: Starting Over ~~');
    rng(0,'twister');           % Random Number Generator Init
else
    disp('~~ RandomNumbers: Storing from previous state ~~');
    rng(s);
end

NUM_TESTS = 10;
STOP_IF_ERROR = true;

load_system('Simulink');

for ind = 1:NUM_TESTS
    chart_name = strcat('sampleModel', int2str(ind));
    
    % Store random number settings
    s = rng;
    
    sg = simple_generator(30, chart_name, true);
    
    if ~sg.go() && STOP_IF_ERROR
        disp('BREAKING FROM MAIN LOOP AS ERROR OCCURRED IN SIMULATION');
        break;
    end
end
