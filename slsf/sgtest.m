% Test simple_generator

NUM_TESTS = 10;
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

num_suc_sim = 0;
num_err_sim = 0;

errors = {};
e_map = struct;

for ind = 1:NUM_TESTS
    chart_name = strcat('sampleModel', int2str(ind));
    
    % Store random number settings
    rng_state = rng;
    
    sg = simple_generator(30, chart_name, SIMULATE_MODELS, CLOSE_MODEL);
    
    if ~sg.go()
        
        num_err_sim = num_err_sim + 1;
        
        % Keep record of the exception
        
        c = struct;
        c.m_no = chart_name;
        e = sg.last_exc;
        
        if(strcmp(e.identifier, 'MATLAB:MException:MultipleErrors'))
            e = e.cause{1};
        end
        
        map_k = util.mvn(e.identifier);
        
        if isfield(e_map, map_k)
            e_map.(map_k) = e.(map_k) + 1;
        else
            e_map.(map_k) = 1;
        end
        
        if STOP_IF_ERROR
            disp('BREAKING FROM MAIN LOOP AS ERROR OCCURRED IN SIMULATION');
            break;
        end
        
    else
        num_suc_sim = num_suc_sim + 1;
        sg.close();           % Close Model
    end
end

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

num_suc_sim
num_err_sim
e_map
