classdef analyze_complexity < handle
    %ANALYZE_COMPLEXITY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant = true)
        % Excel File Columns
        MODEL_NAME = 1;
        BLOCK_COUNT_AGGR = 2;
        BLOCK_COUNT_ROOT = 3;
        CYCLOMATIC = 4;
        SUBSYSTEM_COUNT_AGGR = 5;
        SUBSYSTEM_DEPTH_AGGR = 6;
        LIBRARY_LINK_COUNT = 7;
        
        BP_LIBCOUNT_GROUPLEN = 10;  % length of group for Metric 9
        BP_ALL_EXPERIMENTS_GROUPLEN = 14;  % length of group for those boxplots which have all experiments inside them
        % Different classes of simulink models (i.e. different experiment types)
        EXP_EXAMPLES = 'example';   % Examples and demos that come with Simulink 
        EXP_GITHUB = 'github';
        EXP_MATLAB_CENTRAL = 'matlabcentral';
        EXP_RESEARCH = 'others';  % Academic and industrial research
        EXP_CYFUZZ = 'cyfuzz';
        
        % Metric IDS
        
        METRIC_CHILD_REUSE = 1;
        METRIC_2 = 2;
        METRIC_3 = 3;
        METRIC_4 = 4;
        METRIC_5 = 5;
        METRIC_6 = 6;
        METRIC_7 = 7;
        METRIC_8 = 8;
        METRIC_9 = 9;
        METRIC_11 = 11;
        METRIC_COMPILE_TIME = 12;
        METRIC_13 = 13;
        METRIC_14 = 14;
        METRIC_15 = 15;
        METRIC_16 = 16;
        METRIC_18 = 18;
        METRIC_19= 19;
        METRIC_20 = 20;
        METRIC_21 = 21;
        METRIC_22 = 22;
        
        NUM_METRICS = 22;
        
        % Meta information about an experiment
        META_NUM_MODELS = 'total';
        META_NUM_COMPILE = 'compile';   % Those who compiles
        META_NUM_HIER = 'hier';
        META_BLOCK_TYPE_MAP = 'btm';
        
        
    end
    
    properties
        base_dir = '';
        % types of lists supported: example,cyfuzz,openSource
        exptype;        % Current Experiment type
        exp_names;      % MyCell. stores name of all experiments
        
        data;  % For single exp
        all_data;   % Collection of all obj.data. After running an experiment copy obj.data to obj.all_data
        di;
        
        examples;   % This array will be populated by all models of the model class
        
        % array containing blockTypes to check for child models in a model
        childModelList = {'SubSystem','ModelReference'};
        % maps for storing metrics per model
        map;
        blockTypeMap;
        uniqueBlockMap;
        childModelMap;
        childModelPerLevelMap;
        connectionsLevelMap;
        targetModelMap; % Metric 15
        
        % global vectors storing data for box plot for displaying some
        % metrics that need to be calculated for all models in a list
%         boxPlotChildModelReuse;
        boxPlotBlockCountHierarchyWise;
        boxPlotChildRepresentingBlockCount;
        
        bp_SFunctions;
        bp_lib_count;
        bp_compiletime;
        bp_hier_depth_count; % Metric 4
        bp_block_count; % Metric 2
        bp_child_model_reuse;   % Metric 1
        bp_block_count_level_wise;  % Metric 3
        bp_matlab_cyclomatic;
        bp_algebraic_loop_count;
        bp_connections_depth_count; % Metric 21
        bp_connections_aggregated_count; % Metric 22
        bp_unique_block_aggregated_count; % Metric 23
        bp_descendants_count;
        bp_simulation_time; % Metric 17
        
        % model classes
        model_classes;
        
        max_level = 5;  % Max hierarchy levels to follow
        
        blocktype_library_map; % Map, key is blocktype, value is the library
        libcount_single_model;  % Map, keys are block-library; values are count (how many time a block from that library occurred in a single model)
        blk_count;  % Aggregated block count excluding hidden and masked blocks
        blk_count_masked;   % Aggregated block count including masked and hidden .. using sldiagnostic API
        descendants_count;  % Count all children and grandchildren for the top model - aggregated result.
        
        max_unique_blocks = 10;
        max_hardware_types = 5;
        
        % Multi experiment environment
        exp_pointer = 0; % Will be incremented each time a new experiment is started
        
        
        % For storing Metric 15 (Target model uses embedded real time count)
        model_uses_ert_count=0;
        model_uses_grt_count=0;
        
        models_having_hierarchy_count; % metric 8
        models_no_hierarchy_count; % metric 8
        
        all_exp_meta;   % mycell, each content is one instance of cur_exp_meta
        cur_exp_meta;   % Map, key is an exp_meta for the current experiment set.
        
        cfg; %  Instance of analyze_complexity_cfg class
    end
    
    methods
        
        
        function obj = init_excel_headers(obj)
            obj.data{1, obj.MODEL_NAME} = 'Model name';
            obj.data{1, obj.BLOCK_COUNT_AGGR} = 'BC';
            obj.data{1, obj.BLOCK_COUNT_ROOT} = 'BC(R)';
            obj.data{1, obj.CYCLOMATIC} = 'CY';
            obj.data{1, obj.SUBSYSTEM_COUNT_AGGR} = 'Ss cnt';
            obj.data{1, obj.SUBSYSTEM_DEPTH_AGGR} = 'Ss dpt';
            obj.data{1, obj.SUBSYSTEM_DEPTH_AGGR} = 'Ss dpt';
            obj.data{1, obj.LIBRARY_LINK_COUNT} = 'LibLink cnt';
        end
        
        function  obj = analyze_complexity()
            obj.cfg = analyze_complexity_cfg();
            obj.blocktype_library_map = util.getLibOfAllBlocks();
            obj.model_classes = mymap(obj.EXP_EXAMPLES, 'Examples', obj.EXP_GITHUB, 'GitHub', obj.EXP_RESEARCH, 'Others',...
                obj.EXP_CYFUZZ, 'CyFuzz', obj.EXP_MATLAB_CENTRAL, 'MatlabCentral' );
            obj.exp_names = mycell();
            
            % Init those data structures which carries data for all
            % experiments
            
            obj.bp_compiletime = boxplotmanager(obj.BP_ALL_EXPERIMENTS_GROUPLEN); % Compile time
            obj.bp_compiletime.calc_stats = true;
            
            obj.bp_block_count = boxplotmanager(obj.BP_ALL_EXPERIMENTS_GROUPLEN); % Metric 2
            obj.bp_block_count.calc_stats = true;
            
            obj.bp_child_model_reuse = boxplotmanager(obj.BP_ALL_EXPERIMENTS_GROUPLEN);
            obj.bp_hier_depth_count = boxplotmanager(obj.BP_ALL_EXPERIMENTS_GROUPLEN); % Metric 4
            obj.bp_hier_depth_count.calc_stats = true;
            
            obj.bp_matlab_cyclomatic = boxplotmanager(obj.BP_ALL_EXPERIMENTS_GROUPLEN);
            obj.bp_matlab_cyclomatic.calc_stats = true;
            
            obj.bp_connections_aggregated_count = boxplotmanager(obj.BP_ALL_EXPERIMENTS_GROUPLEN); %Metric 22
            obj.bp_connections_aggregated_count.calc_stats = true;
            
            obj.bp_unique_block_aggregated_count = boxplotmanager(obj.BP_ALL_EXPERIMENTS_GROUPLEN); % Metric 23
            obj.bp_unique_block_aggregated_count.calc_stats = true;
            
            obj.bp_algebraic_loop_count = boxplotmanager(obj.BP_ALL_EXPERIMENTS_GROUPLEN);
            obj.bp_descendants_count = boxplotmanager(obj.BP_ALL_EXPERIMENTS_GROUPLEN);
            obj.bp_simulation_time = boxplotmanager(obj.BP_ALL_EXPERIMENTS_GROUPLEN);
            
            % Init group boxplots
            
            obj.bp_block_count_level_wise = boxplotmanager_grouped();
            obj.bp_lib_count = boxplotmanager_grouped(obj.BP_LIBCOUNT_GROUPLEN);
%             obj.bp_lib_count.label_orientation = 'inline';
            
            obj.bp_connections_depth_count = boxplotmanager_grouped();
%             obj.bp_block_count_level_wise.plotstyle = 'compact';
            
            % meta
            obj.all_exp_meta = mycell();
            
            % Run those scripts which are required by the models in order
            % to compile them
            for i=1:numel(obj.cfg.scripts_to_run)
                eval(obj.cfg.scripts_to_run{i});
            end
        end
        
        function start(obj, exptype)
            % Start a single experiment
            obj.exp_pointer = obj.exp_pointer + 1;
            obj.exp_names.add(exptype);
            obj.exptype = exptype;
            
            obj.init_excel_headers();
            
            
            obj.cur_exp_meta = mymap();
            
            switch obj.exptype
                case analyze_complexity.EXP_EXAMPLES
                    obj.examples = obj.cfg.examples;
                    obj.analyze_all_models_from_a_class();
                case analyze_complexity.EXP_GITHUB
                    obj.examples = obj.cfg.github;
                    obj.analyze_all_models_from_a_class();
                case analyze_complexity.EXP_MATLAB_CENTRAL
                    obj.examples = obj.cfg.matlab_central;
                    obj.analyze_all_models_from_a_class();
                case analyze_complexity.EXP_RESEARCH
                    obj.examples = obj.cfg.research;
                    obj.analyze_all_models_from_a_class();
                case analyze_complexity.EXP_CYFUZZ
                    obj.examples = obj.cfg.cyfuzz;
                    obj.analyze_all_models_from_a_class();
                otherwise
                    error('Invalid Argument');
            end
            
            %obj.write_excel();
            
            obj.render_all_box_plots();
%             disp(obj.data);
            
            obj.all_data{obj.exp_pointer} = obj.data;
            obj.all_exp_meta.add(obj.cur_exp_meta);
        end
        
        function obj = get_metric_for_all_experiments(obj)
            % Call this method to after running experiments for all classes
            % of models
            % Compile Time
            
            obj.bp_child_model_reuse.draw('Child Model Reuse #1', 'Model Classes', 'Reuse rate (%)');
            obj.bp_compiletime.draw('Compile Time #12', 'Model Classes', 'Compilation time (sec)');
            obj.bp_block_count.draw('Block Count Aggregated #2', 'Model Classes', 'Blocks count');
            obj.bp_hier_depth_count.draw('Maximum Hierarchy Depth #4', 'Model Classes', 'Hierarchy depth');
            obj.bp_matlab_cyclomatic.draw('MathWorks Cyclomatic Complexity', 'Model classes', 'Complexity');
            obj.bp_connections_aggregated_count.draw('Aggregated Connections Count #22', 'Model classes', 'Connections Count');
            obj.bp_unique_block_aggregated_count.draw('Aggregated Unique Block Count #23', 'Model classes', 'Blocks count');
            obj.bp_algebraic_loop_count.draw('Algebraic Loops Count', 'Model classes', 'Loop Count');
            obj.bp_descendants_count.draw('Child-representing blocks count (Aggregated)', 'Model classes', 'Blocks count');
            obj.bp_simulation_time.draw('Model Simulation Time(Aggregated) #17', 'Model classes', 'Simulation Time');
            
            % Group draw
            obj.bp_block_count_level_wise.group_draw('Block Count (level wise)', 'Hierarchy levels', 'Blocks count', true);
            obj.bp_lib_count.group_draw('Library participation', 'Simulink library', 'Blocks (%)'); 
            obj.bp_connections_depth_count.group_draw('Connections Count (level wise)', 'Hierarchy Levels', 'Connections Count', true);
      
            
            obj.bp_compiletime.get_stat();
            obj.bp_block_count.get_stat();
            obj.bp_hier_depth_count.get_stat();
            obj.bp_matlab_cyclomatic.get_stat();
            obj.bp_connections_aggregated_count.get_stat();
            obj.bp_unique_block_aggregated_count.get_stat();
            obj.bp_descendants_count.get_stat();
           
            
            
            % All other
            
            fprintf('===== Info regarding all experiments =====\n');
            
            for i = 1:obj.exp_names.len
                c = obj.exp_names.get(i);
                fprintf('\t*** %s ***\n', c);
                
                mt = obj.all_exp_meta.get(i);
                fprintf('\t\tTotal: %d; \t\t Compiled: %d; \t\tHier: %d;\n',...
                    mt.get(obj.META_NUM_MODELS), mt.get(obj.META_NUM_COMPILE), mt.get(obj.META_NUM_HIER));
                obj.calculate_number_of_specific_blocks(mt.get(obj.META_BLOCK_TYPE_MAP));
            end
            
        end
           
        function analyze_all_models_from_a_class(obj)
            fprintf('=================== Analyzing %s =====================\n', obj.exptype);
            
            obj.data = cell(1, 7);
            obj.di = 1;
            
            % intializing vectors for box plot
%             obj.boxPlotChildModelReuse = zeros(numel(obj.examples),1);
            % max hierarchy level we add to our box plot is 5.
            obj.boxPlotBlockCountHierarchyWise = zeros(numel(obj.examples),obj.max_level);
            obj.boxPlotBlockCountHierarchyWise(:) = NaN; % Otherwise boxplot will have wrong statistics by considering empty cells as Zero. 
            % we will only count upto level 5 as this is our requirement.
            % some models may have more than 5 hierarchy levels but they are rare.
            obj.boxPlotChildRepresentingBlockCount = zeros(numel(obj.examples),obj.max_level); 
            obj.boxPlotChildRepresentingBlockCount(:) = NaN;
            
            % Metric 7
            obj.blockTypeMap = mymap();
            
            % Metric 15
            obj.targetModelMap = mymap();
            
            % Metric 3
            obj.bp_block_count_level_wise.init_sg(obj.exptype);
            
            % S-Functions
            obj.bp_SFunctions = boxplotmanager();
            
%             obj.bp_hier_depth_count = boxplotmanager();
            
            % Lib count: metric 9
            obj.bp_lib_count.init_sg(obj.exptype);  % Max 10 character is allowed as group name
%             obj.bp_lib_count.plotstyle = 'compact';
            
            % Metric 11
            obj.bp_algebraic_loop_count = boxplotmanager();
            
            obj.bp_lib_count.plotstyle = 'compact';
            
            % Metric 21
            obj.bp_connections_depth_count.init_sg(obj.exptype);
            
            %Metric 22
            obj.bp_connections_aggregated_count = boxplotmanager();
            
            %Metric 23
            obj.bp_unique_block_aggregated_count = boxplotmanager();
           
            % Metric 8
            obj.models_having_hierarchy_count = 0;
            obj.models_no_hierarchy_count = 0;
            
            
            % loop over all models in the list
            for i = 1:numel(obj.examples)
                obj.cur_exp_meta.inc(analyze_complexity.META_NUM_MODELS);
                s = obj.examples{i};
                fprintf('~~~~~~~~~~~~~~ %s ~~~~~~~~~~~~~~ \n', s);
                open_system(s);
                
                
                % initializing maps for storing metrics
                obj.map = mymap();
                obj.uniqueBlockMap = mymap();
                obj.childModelPerLevelMap = mymap();
                obj.childModelMap = mymap();
                obj.connectionsLevelMap = mymap();
                obj.libcount_single_model = mymap();
                obj.blk_count = 0;
                obj.descendants_count = 0;
                 obj.blk_count_masked = 0; % Metric 2
                
                % Metric 15
                cs = getActiveConfigSet(s);
                obj.obtain_hardware_type_metric(cs);

                % API function to obtain metrics
                obj.do_single_model(s);
                
                % Our recursive function to obtain metrics that are not
                % supported in API
                obj.obtain_hierarchy_metrics(s,1,false);
                
                % display metrics calculated
%                 disp('[DEBUG] Number of blocks Level wise:');
%                 disp(obj.map.data);
                
                disp('[DEBUG] Number of child models with the number of times being reused:');
                disp(obj.childModelMap.data);
                
                obj.bp_unique_block_aggregated_count.add(obj.uniqueBlockMap.len_keys(),obj.exptype);
                obj.calculate_child_model_ratio(obj.childModelMap,i);
                obj.calculate_number_of_blocks_hierarchy(obj.map,i);
                obj.calculate_child_representing_block_count(obj.childModelPerLevelMap,i);
                obj.calculate_lib_count(obj.libcount_single_model);
                obj.calculate_connections_level_wise(obj.connectionsLevelMap);
                obj.calculate_compile_time_metrics(s);
                
                % All blocks (including masked, hidden) in the model
                blk_count_sldiag = mdlrefCountBlocks(s);
                obj.bp_block_count.add(blk_count_sldiag, obj.exptype);
                
%                 fprintf('My block count: %d; SLDIAG block count: %d\n', obj.blk_count, blk_count_sldiag);
                assert(abs(obj.blk_count - blk_count_sldiag) < 30);
                assert(obj.blk_count >= blk_count_sldiag);
                
                obj.bp_descendants_count.add(obj.descendants_count, obj.exptype);
                
                close_system(s);
            end
        end
        
        function render_all_box_plots(obj)
            obj.cur_exp_meta.put(obj.META_BLOCK_TYPE_MAP, obj.blockTypeMap);
%             obj.calculate_number_of_specific_blocks(obj.blockTypeMap);
            obj.calculate_metrics_using_api_data();
            
            % rendering Metric 1: boxPlot for child model reuse %
            % TODO render later, when data for all classes are available.
%             figure
%             boxplot(obj.boxPlotChildModelReuse);
%             xlabel('Classes');
%             ylabel('% Reuse');
%             title('Metric 1: Child Model Reuse(%)');
            
            % rendering boxPlot for block counts hierarchy wise
%             figure
% %             disp('[DEBUG] Boxplot metric 3');
% %             obj.boxPlotBlockCountHierarchyWise
%             boxplot(obj.boxPlotBlockCountHierarchyWise);
%             ylabel('Number Of Blocks');
%             title(['Metric 3: Block Count across Hierarchy in ' obj.model_classes.get(obj.exptype)]);

            
            % rendering boxPlot for child representing blockcount NOT
            % DOOING IT... SEEMS REDUNDANT
%             figure
%             disp('[DEBUG] Box Plot: Child representing blocks...');
% %             obj.boxPlotChildRepresentingBlockCount
%             boxplot(obj.boxPlotChildRepresentingBlockCount);
%             ylabel('Number Of Child-representing Blocks');
%             title('Metric 5: Child-Representing blocks(across hierarchy levels)');
            
%             % S-Functions count SEEMS REDUNDANT
%             obj.bp_SFunctions.draw('Metric 20 (Number of S-Functions)', 'Hierarchy Levels', 'Block Count');
            
            % Algebraic Loops Count( Metric 11)
%             obj.bp_algebraic_loop_count.draw(['Metric 11 (Algebraic Loops Count) in ' obj.model_classes.get(obj.exptype)], obj.model_classes.get(obj.exptype), 'Loop Count')

            
            % Hierarchy depth count (Metric 4)
%             obj.bp_hier_depth_count.draw(['Metric 4 (Maximum Hierarchy Depth) in ' obj.model_classes.get(obj.exptype)], obj.model_classes.get(obj.exptype), 'Hierarchy depth');
            
            
             
%              pause;
            
            % Unique Blocks Aggregated ( Metric 23)
%             obj.bp_unique_block_aggregated_count.draw(['Metric 23 (Aggregated Unique Block Count) in ' obj.model_classes.get(obj.exptype)], obj.model_classes.get(obj.exptype), 'Block Count')
            
            % Table showing Models having hierarchy (Metric 8)
%             disp(['Metric 8 (Models having Hierarchy Count) in ' obj.model_classes.get(obj.exptype)]);
%             fprintf('With Hierarchy:    %3d \n',obj.models_having_hierarchy_count);
%             fprintf('Without Hierarchy: %3d \n ',obj.models_no_hierarchy_count);
            obj.cur_exp_meta.put(obj.META_NUM_HIER, obj.models_having_hierarchy_count);
            
            % Metric 15
            obj.display_metric15();
        end
        
        
        function display_metric15(obj)
            fprintf('\nMetric 15 Target Hardware Count\n');
            [keyVector,sortedVector] = obj.targetModelMap.sort_by_value();
            startingPoint = 1;
            len = obj.targetModelMap.len_keys();
            if len > obj.max_hardware_types
                startingPoint = len - obj.max_hardware_types;
            end
            for i=len:-1:startingPoint
                fprintf('%25s | %3d\n',keyVector(sortedVector(i,1)),sortedVector(i,2));
            end
        end
        
        function calculate_connections_level_wise(obj,m)
            count = 0;
            for k = 1:m.len_keys()
                levelString = strsplit(m.key(k),'x');
                level = str2double(levelString{2});
                
                if level<=obj.max_level
                    countLevel = m.get(m.key(k)); 
                    count = count + countLevel;
                    obj.bp_connections_depth_count.add(countLevel,num2str(level));
                end
            end
            obj.bp_connections_aggregated_count.add(count,obj.exptype);
        end
        
        function obj = calculate_compile_time_metrics(obj, s)
            
            is_compiling = false;
            
            % First check whether it compiles
            try
                eval([s '([], [], [], ''compile'');'])
                obj.cur_exp_meta.inc(analyze_complexity.META_NUM_COMPILE);
                is_compiling = true;
                try
                    eval([s '([], [], [], ''term'');'])
                catch 
                end
                
            catch e
                fprintf('(!) Model failed to compile');
                e.identifier
                e.message
%                 error('compile failed');
%                 eval([s '([], [], [], ''term'');'])
%                 pause();
            end
            
            if is_compiling
                [~, sRpt] = sldiagnostics(s, 'CompileStats');
                elapsed_time = sum([sRpt.Statistics(:).WallClockTime]);
%                 fprintf('[DEBUG] Compile time: %d \n', elapsed_time);
                obj.bp_compiletime.add(elapsed_time, obj.exptype);
                
                % finding algebraic loops if the model compiles
                aloops = Simulink.BlockDiagram.getAlgebraicLoops(s);
                if numel(aloops) > 0
                    obj.bp_algebraic_loop_count.add(numel(aloops),obj.exptype);
                end
            end
        end
        
        function calculate_child_representing_block_count(obj,m,modelCount)
            cnt = 0;
            for k = 1:m.len_keys()
                levelString = strsplit(m.key(k),'x');
                level = str2double(levelString{2});
                if level<=obj.max_level
                    assert(isnan(obj.boxPlotChildRepresentingBlockCount(modelCount,level)));
                    obj.boxPlotChildRepresentingBlockCount(modelCount,level) = m.get(m.key(k));
                end
                cnt = cnt + m.get(m.key(k));
            end
%             cnt
%             obj.descendants_count
            assert(cnt == obj.descendants_count);
        end
        
        function calculate_number_of_specific_blocks(obj,m)
            startingPoint = 1;
            % adding checks for if unique block types are less than 10 to
            % avoid exception
            if m.len_keys() > obj.max_unique_blocks
                startingPoint = m.len_keys() - obj.max_unique_blocks;
            end
            
            [keyVector, sortedVector] = m.sort_by_value();
            fprintf('Metric 7: Number of Top %d blocks with their counts:\n',obj.max_unique_blocks);
            for i=m.len_keys():-1:startingPoint
                fprintf('%25s | %3d\n',keyVector(sortedVector(i,1)),sortedVector(i,2));
            end
        end
        
        function calculate_number_of_blocks_hierarchy(obj,m,modelCount)
            if m.len_keys() > 1
                obj.models_having_hierarchy_count = obj.models_having_hierarchy_count + 1;
                obj.bp_hier_depth_count.add(m.len_keys(), obj.exptype);
            else
                obj.models_no_hierarchy_count = obj.models_no_hierarchy_count + 1;
            end
            for k = 1:m.len_keys()
                levelString = strsplit(m.key(k),'x');
                level = str2double(levelString{2});
                
%                 disp('debug');
%                 modelCount
%                 level
                
                if level <=obj.max_level
%                     obj.boxPlotBlockCountHierarchyWise(modelCount,level)
                    assert(isnan(obj.boxPlotBlockCountHierarchyWise(modelCount,level)));
                    v = m.get(m.key(k));
%                     if v == 0
%                         disp('v is zero');
%                         v = NaN;
%                     else
%                         fprintf('V is not zero:%d\n', v);
%                     end
                    obj.boxPlotBlockCountHierarchyWise(modelCount,level) =  v;
                    % Cross-validation
                    if level == 1
                        assert(v == obj.data{modelCount + 1, obj.BLOCK_COUNT_ROOT});
                    end 
                end
            end
        end
        
        function calculate_metrics_using_api_data(obj)
            [row,~]=size(obj.data);
%             aggregatedBlockCount = zeros(row-1,1);
%             cyclomaticComplexityCount = zeros(row-1,1);
            %skip the first row as it is the column name
            for i=2:row 
%                 aggregatedBlockCount(i-1,1)=obj.data{i,2};
%                 if ~isnan(obj.data{i,4})

                if isempty(obj.data{i, 4})
%                     cyclomaticComplexityCount(i-1,1)= NaN;
                else
%                     cyclomaticComplexityCount(i-1,1)=obj.data{i,4};
                    obj.bp_matlab_cyclomatic.add(obj.data{i,4}, obj.exptype);
                end
            end
            
            %rendering boxPlot for block counts hierarchy aggregated
%             disp('[DEBUG] Aggregated block count');
%             aggregatedBlockCount
%   Note: instead of following code we calculate it using sldiagnostic
%             figure
%             boxplot(aggregatedBlockCount);
%             xlabel(obj.exptype);
%             ylabel('Number Of Blocks');
%             title('Metric 2: Block Count Aggregated');
            
            
            %rendering boxPlot for cyclomatic complexity
%             figure
%             boxplot(cyclomaticComplexityCount);
%             xlabel(obj.exptype);
%             ylabel('Count');
%             title('Metric 6: Cyclomatic Complexity Count');
        end
        
        function calculate_lib_count(obj, m)
%             fprintf('[D] Calculate Lib Count Metric\n');
%             num_blocks = obj.data{model_index + 1, obj.BLOCK_COUNT_AGGR};
            count_blocks = 0;
            for i = 1:m.len_keys()
                k = m.key(i);
                ratio = m.get(k)/obj.blk_count * 100;
                obj.bp_lib_count.add(round(ratio), k);
%                 fprintf('\t[D] calculate lib count: library: %s, ratio: %.2f; val: %d\n', k, ratio, m.get(k));
                count_blocks = count_blocks + m.get(k);
            end
%             disp(count_blocks);
%             disp(obj.blk_count);
            
            assert(count_blocks == obj.blk_count);
%             fprintf('[D] Final Count: %d; Manual: %d\n', count_blocks, obj.blk_count);
        end
        
        function calculate_child_model_ratio(obj,m,modelCount)
            reusedModels = 0;
            newModels = m.len_keys();
            
            for k = 1:newModels
                x = m.get(m.key(k));
                if x > 1
                    reusedModels = reusedModels+x-1;
                end
            end
            
            if newModels > 0
                % formula to calculate the reused model ratio
                ratio = reusedModels/(newModels+reusedModels);
                obj.bp_child_model_reuse.add(ratio, obj.exptype);
%                 obj.boxPlotChildModelReuse(modelCount) = reusedModels/(newModels+reusedModels);
%             else
%                 obj.boxPlotChildModelReuse(modelCount) = NaN;
            end
        end
        
        function obtain_hardware_type_metric(obj, cs) % cs = configuarationSettings of a model
            obj.targetModelMap.inc(cs.get_param('TargetHWDeviceType'));
            startTime = cs.get_param('StartTime');
            stopTime = cs.get_param('StopTime');
            try
                startTime = str2double(startTime);
                stopTime = str2double(stopTime);
                if startTime > 0
                    disp('DEBUG START TIME FOUND GREATER THAN 0.0');
                    disp(startTime);
                end
                obj.bp_simulation_time.add(stopTime, obj.exptype);
            catch ME
                disp('DEBUG Exception occured while getting Simulation Time Metric 17');
                disp(ME);
                rethrow(ME);
            end
%             if contains(cs.get_param('TargetHWDeviceType'),'Generic')
%                 obj.model_uses_grt_count = obj.model_uses_grt_count + 1;
%             else
%                 obj.model_uses_ert_count = obj.model_uses_ert_count + 1;
%                 disp('[DEBUG] Metric 15 Model uses some other TargetHWDeviceType besides generic real time');
%                 disp(cs.get_param('TargetHWDeviceType'));
%             end
        end
        
        %our recursive function to calculate metrics not supported by API
        function count = obtain_hierarchy_metrics(obj,sys,depth,isModelReference)
%             sys
%             fprintf('[DEBUG] OHM - %s\n', char(sys));
            if isModelReference
                mdlRefName = get_param(sys,'ModelName');
                load_system(mdlRefName);
                all_blocks = find_system(mdlRefName,'SearchDepth',1, 'LookUnderMasks', 'all', 'FollowLinks','on');
                assert(strcmp(all_blocks(1), mdlRefName));
                all_blocks = all_blocks(2:end);
                lines = find_system(mdlRefName,'SearchDepth','1','FindAll','on', 'LookUnderMasks', 'all', 'FollowLinks','on', 'type','line');
%                 fprintf('[V] ReferencedModel %s; depth %d\n', char(mdlRefName), depth);
            else
                all_blocks = find_system(sys,'SearchDepth',1, 'LookUnderMasks', 'all', 'FollowLinks','on');
                assert(strcmp(all_blocks(1), sys));
                lines = find_system(sys,'SearchDepth','1','FindAll','on', 'LookUnderMasks', 'all', 'FollowLinks','on', 'type','line');
%                 fprintf('[V] SubSystem %s; depth %d\n', char(sys), depth);
            end
            
            count=0;
            childCountLevel=0;
            count_sfunctions = 0;
            
            [blockCount,~] =size(all_blocks);
            
            %skip the root model which always comes as the first model
            for i=1:blockCount
                currentBlock = all_blocks(i);
                if ~ strcmp(currentBlock, sys) 
                    blockType = get_param(currentBlock, 'blocktype');
                    obj.blockTypeMap.inc(blockType{1,1});
                    
                    libname = obj.get_lib(blockType{1, 1});
                    
                    obj.libcount_single_model.inc(libname);
                    obj.uniqueBlockMap.inc(blockType{1,1});
                    
                    if util.cell_str_in(obj.childModelList,blockType)
                        % child model found
                        
                        if strcmp(blockType,'ModelReference')
                            childCountLevel=childCountLevel+1;
                            
                            modelName = get_param(currentBlock,'ModelName');
                            is_model_reused = obj.childModelMap.contains(modelName);
                            obj.childModelMap.inc(modelName{1,1});
                            
                            %if ~ is_model_reused
                                % Will not count the same referenced model
                                % twice. % TODO since this is commented
                                % out, pass this param to
                                % obtain_hierarchy_metrics
                                obj.obtain_hierarchy_metrics(currentBlock,depth+1,true);
                            %end
                        else
                            inner_count  = obj.obtain_hierarchy_metrics(currentBlock,depth+1,false);
                            if inner_count > 0
                                % There are some subsystems which are not
                                % actually subsystems, they have zero
                                % blocks. Also, masked ones won't show any
                                % underlying implementation
                                childCountLevel=childCountLevel+1;
                            end
                        end
                    elseif util.cell_str_in({'S-Function'}, blockType) % TODO
                        % S-Function found
                        count_sfunctions = count_sfunctions + 1;
                    end
                    count=count+1;
                    obj.blk_count = obj.blk_count + 1;
                end
            end
            
            mapKey = int2str(depth);
            
%             fprintf('\tBlock Count: %d\n', count);
            
            
            unique_lines = 0;
            unique_line_map = mymap();
            
            for l_i = 1:numel(lines)
                c_l = get(lines(l_i));
                c_l.SrcBlockHandle;
                c_l.DstBlockHandle;
%                 fprintf('[LINE] %s %f\n',  get_param(c_l.SrcBlockHandle, 'name'), lines(l_i));
                for d_i = 1:numel(c_l.DstBlockHandle)
                    ulk = [num2str(c_l.SrcBlockHandle) '_' num2str(c_l.SrcPortHandle) '_' num2str(c_l.DstBlockHandle(d_i)) '_' num2str(c_l.DstPortHandle(d_i))];
                    if ~ unique_line_map.contains(ulk)
                        unique_line_map.put(ulk, 1);
                        unique_lines = unique_lines + 1;
%                         fprintf('[LINE] %s \t\t ---> %s\n',get_param(c_l.SrcBlockHandle, 'name'), get_param(c_l.DstBlockHandle(d_i), 'name'));
%                         hilite_system(lines(l_i));
%                         pause();
                    end
                end
                
            end
            
            
            if count >0
                if depth <= obj.max_level
                    obj.bp_block_count_level_wise.add(count, mapKey)
                end
                
                obj.map.insert_or_add(mapKey, count);
                % If there are blocks, only then it makes sense to count
                % connections
                obj.connectionsLevelMap.insert_or_add(mapKey,unique_lines);
                obj.descendants_count = obj.descendants_count + childCountLevel;
%             else
%                 error('0 block count!!');
            end
            
            obj.childModelPerLevelMap.insert_or_add(mapKey, childCountLevel); %WARNING shouldn't we do this only when
%             count>0?
            
            obj.bp_SFunctions.add(count_sfunctions, int2str(depth));
            
        end
        
        function ret = get_lib(obj, block_type)
            if obj.blocktype_library_map.contains(block_type)
                ret = obj.blocktype_library_map.get(block_type);
            else
                ret = 'Others';
            end
        end
        
        
        function obj = write_excel(obj)
            %filename = 'MetricResults.xlsx';
            %disp(obj.data);
            %xlswrite(filename,obj.data);
        end
        
        function do_single_model(obj, sys)
            obj.di = obj.di + 1;
            obj.data{obj.di, obj.MODEL_NAME} = sys;
            
            metric_engine = slmetric.Engine();

            % Include referenced models and libraries in the analysis, these properties are on by default
            metric_engine.AnalyzeModelReferences = 1;
            metric_engine.AnalyzeLibraries = 1;
            
            metrics ={ 'mathworks.metrics.SimulinkBlockCount', 'mathworks.metrics.SubSystemCount', 'mathworks.metrics.SubSystemDepth', 'mathworks.metrics.CyclomaticComplexity', 'mathworks.metrics.LibraryLinkCount'};
            
            setAnalysisRoot(metric_engine, 'Root',  sys);
            execute(metric_engine, metrics);
            res_col = getMetrics(metric_engine, metrics);
            
            
            for n=1:length(res_col)
                if res_col(n).Status == 0
                    result = res_col(n).Results;

                    for m=1:length(result)
                        
                        switch result(m).MetricID
                            case 'mathworks.metrics.SimulinkBlockCount'
                                if strcmp(result(m).ComponentPath, sys)
                                    obj.data{obj.di, obj.BLOCK_COUNT_AGGR} = result(m).AggregatedValue;
                                    obj.data{obj.di, obj.BLOCK_COUNT_ROOT} = result(m).Value;
                                end
                            case 'mathworks.metrics.CyclomaticComplexity'
                                if strcmp(result(m).ComponentPath, sys)
                                    obj.data{obj.di, obj.CYCLOMATIC} = result(m).AggregatedValue;
                                end
                            case 'mathworks.metrics.SubSystemCount'
                                if strcmp(result(m).ComponentPath, sys)
                                    obj.data{obj.di, obj.SUBSYSTEM_COUNT_AGGR} = result(m).AggregatedValue;
                                end
                            case 'mathworks.metrics.SubSystemDepth'
                                if strcmp(result(m).ComponentPath, sys)
                                    obj.data{obj.di, obj.SUBSYSTEM_DEPTH_AGGR} = result(m).Value;
                                end
                            case 'mathworks.metrics.LibraryLinkCount'
                                 if strcmp(result(m).ComponentPath, sys)
                                    obj.data{obj.di, obj.LIBRARY_LINK_COUNT} = result(m).Value;
                                end
                        end
                    end
                else
%                     disp(['No results for:', result(n).MetclcricID]);
                end
                disp(' ');
            end
        end
    end
    
    methods(Static)
        function ac = go()
            % Entry point to run ALL analysis
            base_dir = 'publicmodels';
            addpath(genpath([base_dir filesep 'academic_models']));
            addpath(genpath([base_dir filesep 'gh']));
            addpath([base_dir filesep 'github_slx_files']);
            addpath([base_dir filesep 'matalb_central_models']);
            
            addpath('')
            disp('--- Complexity Analysis --');
            ac = analyze_complexity();
            
            % Call as many experiments you want to run
            ac.start(analyze_complexity.EXP_EXAMPLES);
            %ac.start(analyze_complexity.EXP_GITHUB);
            %ac.start(analyze_complexity.EXP_MATLAB_CENTRAL);
            %ac.start(analyze_complexity.EXP_RESEARCH);
                        
            % Get results for all experiments
            ac.get_metric_for_all_experiments();
        end
    end
end

