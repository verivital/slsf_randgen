classdef util < handle
    %UTIL Handy functions
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        
        function ret = mvn(s)
            % Make a valid name using parameter `s`
            ret = matlab.lang.makeValidName(s);
        end
        
        function ret = strip_simulink_prefix(s)
            ret = s;
            if util.starts_with(s, 'simulink/')
                ret = strsplit(s, 'simulink/');  % Stripping of the simulink tag
                ret = ret{2};
            elseif util.starts_with(s, 'Simulink/')
                ret = strsplit(s, 'Simulink/');  % Stripping of the simulink tag
                ret = ret{2};
            end
        end
        
        function ret = starts_with(s1, s2)
            % s2: prefix; s1: larger string
            res = strfind(s1, s2);
            
            if res == 1
                ret = true;
            else
                ret = false;
            end
        end
        
        function h = select_me_or_parent(inner, my_level)
            % If `inner` is a block inside a subsystem, then get the parent
            % block.

            if nargin < 2
                my_level = 1;
            end
            
            my_full_name = getfullname(inner);
            fprintf('Select Me Or Parent --> Subject: %s\n', my_full_name);
            
            if cfg.SUBSYSTEM_FIX
                slash_pos = strfind(my_full_name, '/');
                       
                all = strsplit(my_full_name, '/');

                i = numel(all) + 1;

                if util.starts_with(all{i-1}, cfg.BLOCK_NAME_PREFIX)
                    fprintf('select me\n');
                    h = inner;
                    return;
                end
                j = -1;
                while i>0
                    i = i - 1;
                    j = j + 1;
                    if util.starts_with(all{i}, cfg.BLOCK_NAME_PREFIX)
                        break;
                    end
                end
    %             numel(slash_pos)
    %             j
                h = my_full_name(1:slash_pos(numel(slash_pos) + 1 - j) - 1);
                fprintf('select some parent: %s\n', h);
                
            else
                slash_pos = strfind(my_full_name, '/');

                desired_slash_pos = my_level + 1;

                if numel(slash_pos) < desired_slash_pos
                    disp('Not Fetching Parent!');
                    h = inner;
                else
                    h = my_full_name(1: (slash_pos(desired_slash_pos) - 1));
                    fprintf('Fetched this parent: %s\n', getfullname(h));
                end
            end
        end
        
        function h = select_parent(my_full_name, my_level)
            % If `inner` is a block inside a subsystem, then get the parent
            % block.
            
            fprintf('Subject: %s\n', my_full_name);
            
            slash_pos = strfind(my_full_name, '/');
                       
            all = strsplit(my_full_name, '/');
            
            i = numel(all) + 1;
            
            if util.starts_with(all{i-1}, 'bl')
                fprintf('select me\n');
                return;
            end
            j = -1;
            while i>0
                i = i - 1;
                j = j + 1;
                if util.starts_with(all{i}, 'bl')
                    break;
                end
            end
%             numel(slash_pos)
%             j
            
            fprintf('select some parent:%s\n', my_full_name(1:slash_pos(numel(slash_pos) + 1 - j) - 1));
            
            
        end
        
        
%         function h = select_me_or_parent(inner)
%             % If `inner` is a block inside a subsystem, then get the parent
%             % block.
%             disp('INSIDE: Select me or parent');
%             my_full_name = getfullname(inner);
%             fprintf('Subject: %s\n', my_full_name);
%             parent = get_param(inner, 'parent');
%                     
%             if strcmp(get_param(parent, 'Type'), 'block')
%                 disp('WILL FETCH PARENT');
%                 h = get_param(get_param(inner, 'parent'), 'Handle');
%             else
%                  disp('NOT fetching PARENT');
%                 h = inner;
%             end
%         end
        
        
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
        
        
        function ret=rand_float(num_numbers_to_generate)
            % Get random floating point value.
            ret  = rand(1, num_numbers_to_generate);
        end
        
        function cond_save_model(cond, mdl_name, store_dir, my_result)
            % Conditionally save `mdl_name` only when `cond` is true
            if cond && isempty(cfg.USE_PRE_GENERATED_MODEL)
                save_system(mdl_name, [store_dir filesep mdl_name '.slx']);
                % Save S-functions
                
                for i=1:my_result.sfuns.len
                    disp(['SFUN: ' my_result.sfuns.get(i)])
                end
                
                for i=1:my_result.sfuns.len
                    copyfile([my_result.sfuns.get(i) '*'], store_dir)
                end
                % Also save the sub-models generated in this phase
                for i = 1:my_result.hier_models.len
                    hier_mdl = my_result.hier_models.get(i);
                    save_system(hier_mdl, [store_dir filesep hier_mdl '.slx']);
                end
            end
        end
        
        
        function blnames()
            sys = get_param(gcs, 'name');
            fprintf('\n--- Printing blocks from %s ---\n', sys);
            num_blocks = 30;
            
            for i = 1:num_blocks
                fprintf('%s\t%s\n', int2str(i), get_param([sys '/bl' int2str(i)], 'BlockType'));
            end
            
        end
        
        
        function all_blocks = getBlocksOfLibrary(lib)
            all_blocks = find_system(['simulink/' lib]);
        end
        
        
        function getBlocksOfLibrary_PrettyPrint(lib)
            all_blocks = find_system(['simulink/' lib]);
            
            for i=1:numel(all_blocks)
                disp(all_blocks{i})
            end
        end
        
        function ret= getLibOfAllBlocks()
            ret = mymap();
            load_system('simulink');
            libs = {'Discrete', 'Sources', 'Sinks', 'Continuous', 'Discontinuities', 'Signal Attributes',...
                'Signal Routing', 'Math Operations', 'Logic and Bit Operations', 'Lookup Tables', 'User-Defined Functions', 'Ports & Subsystems', 'Additional Math & Discrete'};
            for i = 1:numel(libs)
                c_lib = libs{i};
                all_blocks = util.getBlocksOfLibrary(c_lib);
                for j = 1:numel(all_blocks)
                    c_block = all_blocks{j};
                    blocktype = get_param(c_block, 'blocktype');
%                     fprintf('Block %s; Type %s\n', c_block, blocktype);
                    ret.put(blocktype, c_lib);
                end
            end
        end
        
        
        function post_model_gen(sg)
            disp(halum);
        end
        
        
        function [myports, otherports] = get_other_blocks(me, is_outports)
            % To get all the blocks connected to the output ports, set
            % `is_outports` to true. Set false if interested in Inports. 
            
            a = get_param(me,'PortHandles');
            
            if is_outports
                myports = a.Outport;
            else
                myports = a.Inport;
            end
            
            otherports = cell(1, numel(myports));
            
            for i = 1:numel(myports)
                line = get_param(myports(i), 'Line');
                if is_outports
                    other_ports = get_param(line, 'Dstporthandle') ;
                else
                    other_ports = get_param(line, 'Srcporthandle') ;
                end
                
                other_port_objects = get(other_ports);
                otherports{i} = other_port_objects;
            end

        end
        
        function ret = get_all_top_level_blocks(sys)
            ret = find_system(sys, 'FindAll','On','SearchDepth',1,'type','block');
        end
        
        
        function found=cell_str_in(hay, needle)
            % Returns true if `needle` is one of the elements of cell `hay`
            found = false;
            
            for i = 1:numel(hay)
                if strcmp(needle, hay{i}) == 1
                    found = true;
                    return;
                end
            end
        end
        
        function found=cell_in(hay, needle)
            % Returns true if `needle` is one of the elements of cell `hay`
            found = false;
            
            for i = 1:numel(hay)
                if needle == hay{i}
                    found = true;
                    return;
                end
            end
        end
        
        
        function inspect_parameters(elem)
            x = get_param(elem, 'ObjectParameters');
            fn = fieldnames(x);
            for i=1:numel(fn)
                fn_i = fn{i};
                fprintf('************************** %s **********************\n', fn_i);
                get_param(elem, fn_i)
                x.(fn_i)
            end
        end
        
        function ret = strip(subject, needle)
            new_start = 1;
            len = numel(subject);
            new_end = len;
            
            for i=1:len                
                if subject(i) == needle
                    new_start = new_start + 1;
                else
                    break;
                end
            end
            
            for i=1:(len - new_start)
                if subject(len-i+1) == needle
                    new_end = new_end - 1;
                else
                    break;
                end
            end
            
            ret = subject(new_start:new_end);
        end
        
        
        function ret = struct_arr2cell_arr(struct_arr, fld)
            ret = cell(1, numel(struct_arr));
            
            for i = 1:numel(struct_arr)
                ret{i} = struct_arr(i).(fld);
            end
        end
        
        function ret = are_cells_equal(cell1, cell2)
            ret = false;
            
            num_cell1 = numel(cell1);
            
            if numel(cell2) ~= num_cell1
                return;
            end
            
            for i = 1: num_cell1
                if ~ strcmp(cell1{i}, cell2{i})
                    return;
                end
            end
            
            ret = true;
        end
        
        function counter = roulette_wheel(candidates, num_choose)
            % WARNING: ASSUMES MAX_WEIGHT 1.0   
            weight_sum = 0;
            candidates_len = numel(candidates);
            
            counter = zeros(candidates_len, 1);
            
            for i = 1:candidates_len
                weight_sum = weight_sum + candidates{i}.num;
            end
            
%             weight_sum
            
            for i = 1:num_choose
                
                r = util.rand_float(1) * weight_sum;
                
                found = false;
                
                for j=1:candidates_len
                    r = r - candidates{j}.num;
                    if r <= 0
                        counter(j) = counter(j) + 1;
                        found = true;
                        break;
                    end
                end
                
                if ~ found
                    % Only when rounding error occurs
                    fprintf('ROUNDING ERROR \n');
                    counter(candidates_len) = counter(candidates_len) + 1;
                end
                
            end
            
            % Print counter for debugging
            fprintf('===================\n');
            for i=1:candidates_len
                fprintf('%d:%d\t',i, counter(i));
            end
            fprintf('\n===================\n');
        end
        
        function counter = roulette_wheel_stoch_acceptance(candidates, num_choose)
            % WARNING: ASSUMES MAX_WEIGHT 1.0   
            MAX_WEIGHT = 1.0;
            candidates_len = numel(candidates)
            
            counter = zeros(candidates_len, 1);
            
            for i = 1:num_choose
                
                not_accepted = true;
                
                while not_accepted
                    r = util.rand_float(1);
                    pos = int32(r * candidates_len);
                    
                    if pos == 0
                        pos = 1;
                    end
                    
                    
                    r = util.rand_float(1);
                    c = candidates{pos};
                    
                    fprintf('Got this pos: %d\t%.2f\n', pos, r);
                    
                    if r < c.num/MAX_WEIGHT
                        counter(pos) = counter(pos) + 1;
                        not_accepted = false;
                        fprintf('ACC\n');
                    else
                        fprintf('Not ACC\n');
                    end
                    
                end
            end
            
            % Print counter for debugging
            fprintf('===================\n');
            for i=1:candidates_len
                fprintf('%d:%d\t',i, counter(i));
            end
            fprintf('\n===================\n');
        end
        
        function ret = is_type_equivalent(out_type, in_type, in_signed_only)
            fprintf('Called type equivalence check: out: %s; in: %s\n', out_type, in_type);
            ret = false;
            
            if strcmp(out_type, 'uint') && strcmp(in_type, 'int') && ~in_signed_only
                ret = true;
            elseif strcmp(out_type, 'int') && strcmp(in_type, 'uint') 
                ret = true;
            end
            
        end
        
        function find_system(sys)
            x = find_system(sys, 'SearchDepth','1','FindAll','on', 'LookUnderMasks', 'all', 'FollowLinks','on', 'type','line');
            for i=1:numel(x)
                get_param(x(i), 'type')
            end
        end
        
        function ret = is_nativelike_type(dtype)
            ret = false;
            if util.cell_str_in({'double', 'single', 'boolean'}, dtype) || util.starts_with(dtype, 'int') || util.starts_with(dtype, 'uint') % TODO fix points
                ret = true;
            end
        end
        
    end
    
end

