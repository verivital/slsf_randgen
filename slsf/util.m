classdef util < handle
    %UTIL Handy functions for SLSF Generator
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        
        function ret = mvn(s)
            % Make a valid name using parameter `s`
            ret = matlab.lang.makeValidName(s);
        end
        
        function ret = starts_with(s1, s2)
            % Returs true if s2 starts with s1
            res = strfind(s1, s2);
            
            if res == 1
                ret = true;
            else
                ret = false;
            end
        end
        
    end
    
end

