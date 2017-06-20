classdef foriterator_block_chooser < subsystem_block_chooser
    % Chooses blocks for subsystems
    %   Detailed explanation goes here
    
    properties
       
    end
    
    methods
        
        function obj = foriterator_block_chooser()
            obj = obj@subsystem_block_chooser();
            
            
            % Blacklist
            
            % Mainly because of a For Iterator block appearing at parent level
            obj.blocklist.(util.mvn('simulink/Discrete/Discrete PID Controller')) = 1;
            obj.blocklist.(util.mvn('simulink/Discrete/Discrete PID Controller (2DOF)')) = 1;
            obj.blocklist.(util.mvn('simulink/Discrete/Discrete-TimeIntegrator')) = 1;
%             obj.blocklist.(util.mvn('simulink/Sinks/Scope')) = 1;
%             obj.blocklist.(util.mvn('simulink/Sinks/FloatingScope')) = 1;
        end
        
    end
    
end

