classdef SuppressWarnings < handle
    %SUPPRESSWARNINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        w_ids = {
            'SimulinkBlocks:Delay:DelayLengthValueIsNotInteger'
            'SimulinkFixedPoint:util:fxpParameterPrecisionLoss'
            'SimulinkFixedPoint:util:Overflowoccurred'
            'Simulink:DataType:WarningOverflowDetected'
        };
    
        last_state;
        
        is_parfor;
    
    end
    
    methods
        
        function set_val(obj, is_parfor)
            obj.is_parfor = is_parfor;
            obj.last_state = warning;
            
            % Set all off!
            warning('off', 'all');
            
            if is_parfor
                try
                    pctRunOnAll warning('off', 'all');
                catch
                    gcp(); % Creates parallel pool - bad coding
                    pctRunOnAll warning('off', 'all');
                end
            end
        end
        
        function restore(obj)
            warning(obj.last_state);
            
%             if obj.is_parfor
%                 pctRunOnAll warning(obj.last_state);
%             end
        end
    end
end

