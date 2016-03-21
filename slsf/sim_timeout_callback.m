function sim_timeout_callback(obj, event, sim_ob)
    %SIM_TIMEOUT_CALLBACK Execute me when timeout occurs in a simulation
    %   Detailed explanation goes here

    try
%         disp('TIMEOUT CALLED');
        sim_ob.sim_status = get_param(sim_ob.generator.sys,'SimulationStatus');
        if strcmp(sim_ob.sim_status, 'running')
            set_param(sim_ob.generator.sys, 'SimulationCommand', 'stop');
        end
    catch e
        % Do Nothing
    end
end

