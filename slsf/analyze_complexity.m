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
        
        BP_LIBCOUNT_GROUPLEN = 20;  % length of group for Metric 9
        BP_COMPILE_TIME_GROUPLEN = 20;  % length of group for compile time metric
        
        % Different classes of simulink models (i.e. different experiment types)
        EXP_EXAMPLES = 'example';   % Examples and demos that come with Simulink 
        EXP_GITHUB = 'github';
        EXP_MATLAB_CENTRAL = 'matlabcentral';
        EXP_RESEARCH = 'research';  % Academic and industrial research
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
        
        
        
    end
    
    properties
        base_dir = '';
        % types of lists supported: example,cyfuzz,openSource
        exptype;        % Current Experiment type
        
        data;  % For single exp
        all_data;   % Collection of all obj.data. After running an experiment copy obj.data to obj.all_data
        di;
        
        examples;   % This array will be populated by all models of the model class
        
        % array containing blockTypes to check for child models in a model
        childModelList = {'SubSystem','ModelReference'};
        % maps for storing metrics per model
        map;
        blockTypeMap;
        childModelMap;
        childModelPerLevelMap;
        
        % global vectors storing data for box plot for displaying some
        % metrics that need to be calculated for all models in a list
        boxPlotChildModelReuse;
        boxPlotBlockCountHierarchyWise;
        boxPlotChildRepresentingBlockCount;
        
        bp_SFunctions;
        bp_lib_count;
        bp_compiletime;
        bp_hier_depth_count; % Metric 4
        
        % model classes
        model_classes;
        
        max_level = 5;  % Max hierarchy levels to follow
        
        blocktype_library_map; % Map, key is blocktype, value is the library
        libcount_single_model;  % Map, keys are block-library; values are count (how many time a block from that library occurred in a single model)
        blk_count;
        
        max_unique_blocks = 10;
        
        % Multi experiment environment
        exp_pointer = 0; % Will be incremented each time a new experiment is started
        
        models_having_hierarchy_count = 0;
        models_no_hierarchy_count = 0;
        
        % For storing Metric 15 (Target model uses embedded real time count)
        model_uses_ert_count=0;
        model_uses_grt_count=0;
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
            obj.blocktype_library_map = util.getLibOfAllBlocks();
            obj.model_classes = mymap('example', 'Simulink Examples', 'opensource', 'Open Source', 'cyfuzz', 'CyFuzz');
            
            % Init those data structures which carries data for all
            % experiments
            
            % Compile time
            obj.bp_compiletime = boxplotmanager(obj.BP_COMPILE_TIME_GROUPLEN);
        end
        
        function start(obj, exptype)
            % Start a single experiment
            obj.exp_pointer = obj.exp_pointer + 1;
            obj.exptype = exptype;
            
            obj.init_excel_headers();
            switch obj.exptype
                case analyze_complexity.EXP_EXAMPLES
                    obj.examples = analyze_complexity_cfg.examples;
                    obj.analyze_all_models_from_a_class();
                case analyze_complexity.EXP_GITHUB
                    obj.examples = analyze_complexity_cfg.github;
                    obj.analyze_all_models_from_a_class();
                case analyze_complexity.EXP_MATLAB_CENTRAL
                    obj.examples = analyze_complexity_cfg.matlab_central;
                    obj.analyze_all_models_from_a_class();
                case analyze_complexity.EXP_RESEARCH
                    obj.examples = analyze_complexity_cfg.research;
                    obj.analyze_all_models_from_a_class();
                case analyze_complexity.EXP_CYFUZZ
                    obj.examples = analyze_complexity_cfg.cyfuzz;
                    obj.analyze_all_models_from_a_class();
                otherwise
                    error('Invalid Argument');
            end
            
            %obj.write_excel();
            
            obj.renderAllBoxPlots();
            disp(obj.data);
            obj.all_data{obj.exp_pointer} = obj.data;
        end
        
        function obj = get_metric_for_all_experiments(obj)
            % Call this method to after running experiments for all classes
            % of models
            % Compile Time
            
            obj.bp_compiletime.draw('Metric 12 (Compile Time)', 'Model Classes', 'Compilation time (seconds)');
            
        end
           
        function analyze_all_models_from_a_class(obj)
            fprintf('=================== Analyzing %s =====================\n', obj.exptype);
            
            obj.data = cell(1, 7);
            obj.di = 1;
            
            % intializing vectors for box plot
            obj.boxPlotChildModelReuse = zeros(numel(obj.examples),1);
            % max hierarchy level we add to our box plot is 5.
            obj.boxPlotBlockCountHierarchyWise = zeros(numel(obj.examples),obj.max_level);
            obj.boxPlotBlockCountHierarchyWise(:) = NaN; % Otherwise boxplot will have wrong statistics by considering empty cells as Zero. 
            % we will only count upto level 5 as this is our requirement.
            % some models may have more than 5 hierarchy levels but they are rare.
            obj.boxPlotChildRepresentingBlockCount = zeros(numel(obj.examples),obj.max_level); 
            obj.boxPlotChildRepresentingBlockCount(:) = NaN;
            
            obj.blockTypeMap = mymap();
            
            % S-Functions
            obj.bp_SFunctions = boxplotmanager();
            
            obj.bp_hier_depth_count = boxplotmanager();
            
            % Lib count: metric 9
            obj.bp_lib_count = boxplotmanager(obj.BP_LIBCOUNT_GROUPLEN);  % Max 10 character is allowed as group name
            
            
            % loop over all models in the list
            for i = 1:numel(obj.examples)
                s = obj.examples{i};
                open_system(s);
                
                cs = getActiveConfigSet(s);
                % Metric 15
                obj.obtain_hardware_type_metric(cs);
                
                % initializing maps for storing metrics
                obj.map = mymap();
                obj.childModelPerLevelMap = mymap();
                obj.childModelMap = mymap();
                obj.libcount_single_model = mymap();
                obj.blk_count = 0;
                
                % API function to obtain metrics
                obj.do_single_model(s);
                
                % Our recursive function to obtain metrics that are not
                % supported in API
                obj.obtain_hierarchy_metrics(s,1,false);
                
                % display metrics calculated
                disp('[DEBUG] Number of blocks Level wise:');
                disp(obj.map.data);
                
                disp('[DEBUG] Number of child models with the number of times being reused:');
                disp(obj.childModelMap.data);
                
                obj.calculate_child_model_ratio(obj.childModelMap,i);
                obj.calculate_number_of_blocks_hierarchy(obj.map,i);
                obj.calculate_child_representing_block_count(obj.childModelPerLevelMap,i);
                obj.calculate_lib_count(obj.libcount_single_model);
                
                obj.calculate_compile_time_metrics(s);
                
                close_system(s);
            end
        end
        
        function renderAllBoxPlots(obj)
%             obj.calculate_number_of_specific_blocks(obj.blockTypeMap);
            obj.calculate_metrics_using_api_data();
            
            % rendering Metric 1: boxPlot for child model reuse %
            % TODO render later, when data for all classes are available.
            figure
            boxplot(obj.boxPlotChildModelReuse);
            xlabel('Classes');
            ylabel('% Reuse');
            title('Metric 1: Child Model Reuse(%)');
            
            % rendering boxPlot for block counts hierarchy wise
            figure
%             disp('[DEBUG] Boxplot metric 3');
%             obj.boxPlotBlockCountHierarchyWise
            boxplot(obj.boxPlotBlockCountHierarchyWise);
            ylabel('Number Of Blocks');
            title(['Metric 3: Block Count across Hierarchy in ' obj.model_classes.get(obj.exptype)]);
            
            % rendering boxPlot for child representing blockcount
            figure
            disp('[DEBUG] Box Plot: Child representing blocks...');
%             obj.boxPlotChildRepresentingBlockCount
            boxplot(obj.boxPlotChildRepresentingBlockCount);
            ylabel('Number Of Child-representing Blocks');
            title('Metric 5: Child-Representing blocks(across hierarchy levels)');
            
            % S-Functions count
            obj.bp_SFunctions.draw('Metric 20 (Number of S-Functions)', 'Hierarchy Levels', 'Block Count');
            
            % Lib Count (Metric 9)
            obj.bp_lib_count.draw(['Metric 9 (Library Participation) in ' obj.model_classes.get(obj.exptype)], 'Simulink library', 'Blocks from this library (%)');
            
            % Hierarchy depth count (Metric 4)
            obj.bp_hier_depth_count.draw(['Metric 4 (Maximum Hierarchy Depth) in ' obj.model_classes.get(obj.exptype)], obj.model_classes.get(obj.exptype), 'Hierarchy depth');
            
            % Table showing Models having hierarchy (Metric 8)
            disp(['Metric 8 (Models having Hierarchy Count) in ' obj.model_classes.get(obj.exptype)]);
            fprintf('With Hierarchy:    %3d \n',obj.models_having_hierarchy_count);
            fprintf('Without Hierarchy: %3d \n ',obj.models_no_hierarchy_count);
            
            disp('Metric 15 Target (EmbeddedRealTime/GenericRealTime) count');
            fprintf('Generic Real Time: %3d\n',obj.model_uses_grt_count);
            fprintf('Other: %3d\n ',obj.model_uses_ert_count);
            
        end
        
        function obj = calculate_compile_time_metrics(obj, s)
            [~, sRpt] = sldiagnostics(s, 'CompileStats');
            elapsed_time = sum([sRpt.Statistics(:).WallClockTime]);
            fprintf('[DEBUG] Compile time: %d \n', elapsed_time);
            obj.bp_compiletime.add(elapsed_time, obj.exptype);
        end
        
        function calculate_child_representing_block_count(obj,m,modelCount)
            for k = 1:m.len_keys()
                levelString = strsplit(m.key(k),'x');
                level = str2double(levelString{2});
                if level<=obj.max_level
                    assert(isnan(obj.boxPlotChildRepresentingBlockCount(modelCount,level)));
                    obj.boxPlotChildRepresentingBlockCount(modelCount,level) = m.get(m.key(k));
                end
            end
        end
        
        function calculate_number_of_specific_blocks(obj,m)
            m.keys();
            keys = m.data_keys();
            fprintf('Number of Top %d specific blocks with their counts:\n',obj.max_unique_blocks);
            %disp(m.data);
            vectorTemp = strings(numel(keys),1);
            vectorTemp(:,1)=keys;
            
            countTemp = zeros(numel(keys),2);
            for k = 1:numel(keys)
               countTemp(k,1)=k;
               countTemp(k,2)=m.data.(keys{k});
            end
            
            sortedVector = sortrows(countTemp,2);
            fprintf('%25s | Count\n','Block Type');
            startingPoint = 1;
            % adding checks for if unique block types are less than 10 to
            % avoid exception
            if numel(keys) > obj.max_unique_blocks
                startingPoint = numel(keys) - obj.max_unique_blocks;
            end
            for i=startingPoint:numel(keys)
                fprintf('%25s | %3d\n',vectorTemp(sortedVector(i,1)),sortedVector(i,2));
            end
            
            % rendering boxPlot for number of specific blocks used across
            % all models in the list.
            figure
            boxPlotVector = sortedVector(:,2);
            if numel(keys) > obj.max_unique_blocks
                boxPlotVector = sortedVector(end-obj.max_unique_blocks:end,2);
            end
            boxplot(boxPlotVector);
            ylabel(obj.exptype);
            title('Metric 7: Number of Specific blocks');
        end
        
        function calculate_number_of_blocks_hierarchy(obj,m,modelCount)
            if m.len_keys() > 1
                obj.models_having_hierarchy_count = obj.models_having_hierarchy_count + 1;
                obj.bp_hier_depth_count.add(m.len_keys(),1);
            else
                obj.models_no_hierarchy_count = obj.models_no_hierarchy_count + 1;
            end
            for k = 1:m.len_keys()
                levelString = strsplit(m.key(k),'x');
                level = str2double(levelString{2});
                
%                 disp('debug');
%                 modelCount
%                 level
                
                if level <=5
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
            aggregatedBlockCount = zeros(row-1,1);
            cyclomaticComplexityCount = zeros(row-1,1);
            %skip the first row as it is the column name
            for i=2:row 
                aggregatedBlockCount(i-1,1)=obj.data{i,2};
%                 if ~isnan(obj.data{i,4})

                if isempty(obj.data{i, 4})
                    cyclomaticComplexityCount(i-1,1)= NaN;
                else
                    cyclomaticComplexityCount(i-1,1)=obj.data{i,4};
                end
            end
            
            %rendering boxPlot for block counts hierarchy aggregated
%             disp('[DEBUG] Aggregated block count');
%             aggregatedBlockCount
            figure
            boxplot(aggregatedBlockCount);
            xlabel(obj.exptype);
            ylabel('Number Of Blocks');
            title('Metric 2: Block Count Aggregated');
            
            %rendering boxPlot for cyclomatic complexity
            figure
            boxplot(cyclomaticComplexityCount);
            xlabel(obj.exptype);
            ylabel('Count');
            title('Metric 6: Cyclomatic Complexity Count');
        end
        
        function calculate_lib_count(obj, m)
            fprintf('[D] Calculate Lib Count Metric\n');
%             num_blocks = obj.data{model_index + 1, obj.BLOCK_COUNT_AGGR};
            count_blocks = 0;
            for i = 1:m.len_keys()
                k = m.key(i);
                ratio = m.get(k)/obj.blk_count * 100;
                obj.bp_lib_count.add(round(ratio), k);
                fprintf('\t[D] calculate lib count: library: %s, ratio: %.2f\n', k, ratio);
                count_blocks = count_blocks + m.get(k);
            end
            assert(count_blocks == obj.blk_count);
            fprintf('[D] Final Count: %d; Manual: %d\n', count_blocks, obj.blk_count);
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
                obj.boxPlotChildModelReuse(modelCount) = reusedModels/(newModels+reusedModels);
            else
                obj.boxPlotChildModelReuse(modelCount) = NaN;
            end
        end
        
        function obtain_hardware_type_metric(obj, cs) % cs = configuarationSettings of a model
            if contains(cs.get_param('TargetHWDeviceType'),'Generic')
                obj.model_uses_grt_count = obj.model_uses_grt_count + 1;
            else
                obj.model_uses_ert_count = obj.model_uses_ert_count + 1;
            end
        end
        
        %our recursive function to calculate metrics not supported by API
        function count = obtain_hierarchy_metrics(obj,sys,depth,isModelReference)  
            if isModelReference
                mdlRefName = get_param(sys,'ModelName');
                load_system(mdlRefName);
                all_blocks = find_system(mdlRefName,'SearchDepth',1);
                all_blocks = all_blocks(2:end);
%                 fprintf('[V] ReferencedModel %s; depth %d\n', char(mdlRefName), depth);
            else
                all_blocks = find_system(sys,'SearchDepth',1);
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
                    obj.libcount_single_model.inc(obj.get_lib(blockType{1, 1}));
                    if util.cell_str_in(obj.childModelList,blockType)
                        % child model found
                        
                        if strcmp(blockType,'ModelReference')
                            childCountLevel=childCountLevel+1;
                            
                            modelName = get_param(currentBlock,'ModelName');
                            is_model_reused = obj.childModelMap.contains(modelName);
                            obj.childModelMap.inc(modelName{1,1});
                            
                            if ~ is_model_reused
                                % Will not count the same referenced model
                                % twice.
                                obj.obtain_hierarchy_metrics(currentBlock,depth+1,true);
                            end
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
                    elseif util.cell_str_in({'S-Function'}, blockType)
                        % S-Function found
                        count_sfunctions = count_sfunctions + 1;
                    end
                    count=count+1;
                    obj.blk_count = obj.blk_count + 1;
                end
            end
            
            mapKey = num2str(depth);
            
%             fprintf('\tBlock Count: %d\n', count);
            
            
            if count >0
                obj.map.insert_or_add(mapKey, count);
            end
            
            obj.childModelPerLevelMap.insert_or_add(mapKey, childCountLevel);
            
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
                    disp(['No results for:', result(n).MetricID]);
                end
                disp(' ');
            end
        end
    end
    
    methods(Static)
        function ac = go()
            % Entry point to run ALL analysis
            disp('--- Complexity Analysis --');
            ac = analyze_complexity();
            
            % Call as many experiments you want to run
            ac.start(analyze_complexity.EXP_EXAMPLES);
            %ac.start(analyze_complexity.EXP_GITHUB);
            
            % Get results for all experiments
            ac.get_metric_for_all_experiments();
        end
    end
end

