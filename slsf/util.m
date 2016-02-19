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
        
        
        
        
        function h = select_me_or_parent(inner)
            % If `inner` is a block inside a subsystem, then get the parent
            % block.
            parent = get_param(inner, 'parent');
                    
            if strcmp(get_param(parent, 'Type'), 'block')
                disp('WILL FETCH PARENT');
                h = get_param(get_param(inner, 'parent'), 'Handle');
            else
                 disp('NOT fetching PARENT');
                h = inner;
            end
        end
        
        
        function m = map_inc(m, k)
            map_k = util.mvn(k);

            if isfield(m, map_k)
                m.(map_k) = m.(map_k) + 1;
            else
                m.(map_k) = 1;
            end
        end
        
        
    end
    
end

