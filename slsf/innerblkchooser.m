classdef innerblkchooser < blockchooser
    %INNERBLKCHOOSER Block Chooser for models which are children models
    %   Detailed explanation goes here
    
    properties
        categories = {
%             struct('name', 'Discrete', 'num', 10)
%             struct('name', 'Continuous', 'num', 10)
%             struct('name', 'Math Operations', 'num', 10)
%             struct('name', 'Logic and Bit Operations', 'num', 10)
            struct('name', 'Sinks', 'num', 1)
            struct('name', 'Sources', 'num', 1)
        };
    
        allowlist = {
            struct('name', 'simulink/Ports & Subsystems/Model')
            struct('name', 'simulink/Sources/In')
            struct('name', 'simulink/Sinks/Out')
            };
    end
    
    methods
%         function obj = innerblkchooser()
%         end
    end
    
end

