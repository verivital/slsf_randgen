classdef analyze_complexity < handle
    %ANALYZE_COMPLEXITY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant = true)
        MODEL_NAME = 1;
        BLOCK_COUNT_AGGR = 2;
        BLOCK_COUNT_ROOT = 3;
        CYCLOMATIC = 4;
        SUBSYSTEM_COUNT_AGGR = 5;
        SUBSYSTEM_DEPTH_AGGR = 6;
        LIBRARY_LINK_COUNT = 7;
    end
    
    properties
        base_dir = '';
        % types of lists supported: example,cyfuzz,openSource
        exptype = 'example';
        
        % lists containing models
        % examples = {'sldemo_fuelsys','sldemo_mdlref_variants_enum','sldemo_mdlref_basic','untitled2'};
        examples = {'sldemo_mdlref_basic','sldemo_mdlref_variants_enum','sldemo_mdlref_bus','sldemo_mdlref_conversion','sldemo_mdlref_counter_bus','sldemo_mdlref_counter_datamngt','sldemo_mdlref_dsm','sldemo_mdlref_dsm_bot','sldemo_mdlref_dsm_bot2','sldemo_mdlref_F2C'};
        openSource = {'hyperloop_arc','staticmodel'};
        cyfuzz = {'sldemo_mdlref_basic','sldemo_mdlref_variants_enum'};
        
        data = cell(1, 7);
        di = 1;
        
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
        
        function  obj = analyze_complexity(exptype)
            obj.exptype = exptype;
        end
        
        function start(obj)
            obj.init_excel_headers();
            switch obj.exptype
                case 'example'
                    obj.analyze_examples();
                case 'openSource'
                    obj.examples = obj.openSource;
                    obj.analyze_examples();
                case 'cyfuzz'
                    obj.examples = obj.cyfuzz;
                    obj.analyze_examples();
                otherwise
                    error('Invalid Argument');
            end
            %obj.write_excel();
            obj.renderAllBoxPlots();
            disp(obj.data);
        end
           
        function analyze_examples(obj)
            disp('Analyzing examples');
            % intializing vectors for box plot
            obj.boxPlotChildModelReuse = zeros(numel(obj.examples),1);
            % max hierarchy level we add to our box plot is 5.
            obj.boxPlotBlockCountHierarchyWise = zeros(numel(obj.examples),5);
            % we will only count upto level 5 as this is our requirement.
            % some models may have more than 5 hierarchy levels but they are rare.
            obj.boxPlotChildRepresentingBlockCount = zeros(numel(obj.examples),5); 
            obj.blockTypeMap = mymap();
            
            % loop over all models in the list
            for i = 1:numel(obj.examples)
                s = obj.examples{i};
                open_system(s);
             
                % initializing maps for storing metrics
                obj.map = mymap();
                obj.childModelPerLevelMap = mymap();
                obj.childModelMap = mymap();
                
                % API function to obtain metrics
                obj.do_single_model(s);
                
                % Our recursive function to obtain metrics that are not
                % supported in API
                obj.obtain_hierarchy_metrics(s,1,false);
                
                % display metrics calculated
                disp('Number of blocks Level wise:');
                disp(obj.map.data);
                
                disp('Number of child models with the number of times being reused:');
                disp(obj.childModelMap.data);
                
                obj.calculate_child_model_ratio(obj.childModelMap,i);
                obj.calculate_number_of_blocks_hierarchy(obj.map,i);
                obj.calculate_child_representing_block_count(obj.childModelPerLevelMap,i);
                close_system(s);
            end
        end
        
        function renderAllBoxPlots(obj)
            obj.calculate_number_of_specific_blocks(obj.blockTypeMap);
            obj.calculate_metrics_using_api_data();
            
            % rendering boxPlot for child model reuse %
            figure
            boxplot(obj.boxPlotChildModelReuse);
            xlabel(obj.exptype);
            ylabel('% Reuse');
            title('Metric 1: Child Model Reuse(%)');
            
            % rendering boxPlot for block counts hierarchy wise
            figure
            boxplot(obj.boxPlotBlockCountHierarchyWise);
            ylabel('Number Of Blocks');
            title('Metric 3: Block Count across Hierarchy');
            
            % rendering boxPlot for child representing blockcount
            figure
            boxplot(obj.boxPlotChildRepresentingBlockCount);
            ylabel('Number Of Child Blocks');
            title('Metric 5: Child-Representing blocks(Model Reference and Subsystems)');
        end
        
        function calculate_child_representing_block_count(obj,m,modelCount)
            m.keys();
            keys = m.data_keys();
            
            for k = 1:numel(keys)
                levelString = strsplit(keys{k},'x');
                level = str2num(levelString{2});
                if level<=5
                    obj.boxPlotChildRepresentingBlockCount(modelCount,level) = obj.boxPlotChildRepresentingBlockCount(modelCount,level) + m.data.(keys{k});
                end
            end
        end
        
        function calculate_number_of_specific_blocks(obj,m)
            m.keys();
            keys = m.data_keys();
            disp('Number of specific blocks with their counts:');
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
            for i=numel(keys)-10:numel(keys)
                fprintf('%25s | %3d\n',vectorTemp(sortedVector(i,1)),sortedVector(i,2));
            end
            
            % rendering boxPlot for number of specific blocks used across
            % all models in the list.
            figure
            boxplot(sortedVector(end-10:end,2));
            ylabel(obj.exptype);
            title('Metric 7: Number of Specific blocks');
        end
        
        function calculate_number_of_blocks_hierarchy(obj,m,modelCount)
            m.keys();
            keys = m.data_keys();
            
            for k = 1:numel(keys)
                levelString = strsplit(keys{k},'x');
                level = str2num(levelString{2});
                if level <=5
                    obj.boxPlotBlockCountHierarchyWise(modelCount,level) = obj.boxPlotBlockCountHierarchyWise(modelCount,level) + m.data.(keys{k});
                end
            end
        end
        
        function calculate_metrics_using_api_data(obj)
            [row,~]=size(obj.data);
            aggregatedBlockCount = zeros(row-1,1);
            cyclomaticComplexityCount = zeros(row-1,1);
            %skip the first row as it is the column name
            for i=2:row 
                aggregatedBlockCount(i,1)=obj.data{i,2};
                if ~isnan(obj.data{i,4})
                    cyclomaticComplexityCount(i,1)=obj.data{i,4};
                end
            end
            
            %rendering boxPlot for block counts hierarchy aggregated
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
        
        function calculate_child_model_ratio(obj,m,modelCount)
            m.keys();
            keys = m.data_keys();
            reusedModels = 0;
            newModels = numel(keys);
            
            for k = 1:numel(keys)
                x = m.data.(keys{k});
                if x > 1
                    reusedModels = reusedModels+x-1;
                end
            end
            ratio = reusedModels/(newModels+reusedModels);
            if ~isnan(ratio)
                % formula to calculate the reused model ratio
                obj.boxPlotChildModelReuse(modelCount) = reusedModels/(newModels+reusedModels);
            end
        end
        
        %our recursive function to calculate metrics not supported by API
        function obtain_hierarchy_metrics(obj,sys,depth,isModelReference)
            all_blocks = find_system(sys,'SearchDepth',1);
            if isModelReference
                mdlRefName = get_param(sys,'ModelName');
                load_system(mdlRefName);
                all_blocks = find_system(mdlRefName,'SearchDepth',1);
                all_blocks = all_blocks(2:end);
            end
            count=0;
            childCountLevel=0;
            [blockCount,~] =size(all_blocks);
            
            %skip the root model which always comes as the first model
            for i=1:blockCount
                currentBlock = all_blocks(i);
                if strcmp(currentBlock, sys) ~=1
                    blockType = get_param(currentBlock, 'blocktype');
                    obj.addToBlockTypeMap(blockType{1,1});
                    if util.cell_str_in(obj.childModelList,blockType)
                        % child model found
                        childCountLevel=childCountLevel+1;
                        if strcmp(blockType,'ModelReference') == 1
                            modelName = get_param(currentBlock,'ModelName');
                            obj.addToChildModelMap(modelName{1,1});
                            
                            obj.obtain_hierarchy_metrics(currentBlock,depth+1,true);
                        else
                            obj.obtain_hierarchy_metrics(currentBlock,depth+1,false);
                        end
                        
                    end
                    count=count+1;
                end
            end
            mapKey = num2str(depth);
            if count >0
                if obj.map.contains(mapKey)
                    existingCount = obj.map.get(mapKey);
                    obj.map.put(mapKey,existingCount + count);
                else
                    obj.map.put(mapKey,count);
                end
            end
            if obj.childModelPerLevelMap.contains(mapKey)
                existingCount = obj.childModelPerLevelMap.get(mapKey);
                obj.childModelPerLevelMap.put(mapKey,existingCount + childCountLevel);
            else
                obj.childModelPerLevelMap.put(mapKey,childCountLevel);
            end
        end
        
        function addToBlockTypeMap(obj,key)
            if obj.blockTypeMap.contains(key)
                existingCount = obj.blockTypeMap.get(key);
                obj.blockTypeMap.put(key,existingCount + 1);
            else
                obj.blockTypeMap.put(key,1);
            end
        end
        
        function addToChildModelMap(obj,key)
            if obj.childModelMap.contains(key)
                existingCount = obj.childModelMap.get(key);
                obj.childModelMap.put(key,existingCount + 1);
            else
                obj.childModelMap.put(key,1);
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
        function go(exptype)
            disp('--- Complexity Analysis --');
            analyze_complexity(exptype).start();
        end
    end
end

