classdef foriterator_blockconfigure < blockconfigure
    %Specify how to choose Dialog Parameters of Blocks under For Iterator
    %subsystem
    %randomly
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        
%         function obj = foriterator_blockconfigure()
%             obj@blockconfigure();
%         end
        
        
        
        
        
        function obj = populate_data(obj)
            
            populate_data@blockconfigure(obj); % calling superclass method
            
            %   simulink/Discrete/Discrete-TimeIntegrator - This setting
            %   will not be used anyway since this block is not supported
            %   in For-Iterator.
            t = {
                bcprops('InitialConditionSetting', {'Output'}, [], 'e')
            };
            obj.data.(util.mvn('simulink/Discrete/Discrete-TimeIntegrator')) = t;
            
            
       
        end
        
        
    end
    
end

