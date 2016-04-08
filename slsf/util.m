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
        
        
        function m = map_append(m, k, v)
            map_k = util.mvn(k);

            if ~ isfield(m, map_k)
                m.(map_k) = mycell(-1);
            end
            
            m.(map_k).add(v);
        end
        
        
        function ret=rand_int(start, finish, num_numbers_to_generate)
            % Get a random Integer.
            ret  = randi([start, finish], 1, num_numbers_to_generate);
        end
        
        
        function cond_save_model(cond, mdl_name, store_dir)
            % Conditionally save `mdl_name` only when `cond` is true
            if cond
                save_system(mdl_name, [store_dir filesep mdl_name '.slx']);
            end
        end
        
        
    end
    
end

