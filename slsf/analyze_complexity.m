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
        exptype = 'example';
        examples = {'sldemo_fuelsys','sldemo_mdlref_variants_enum','sldemo_mdlref_basic'};
        openSource = {'openSource/hyperloop_arc','staticmodel'};
        cyFuzz = {'sampleModel30'};
        data = cell(1, 7);
        di = 1;
        childModelList = {'SubSystem','ModelReference'};
        map;
        blockTypeMap;
        childModelMap;
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
                    obj.examples = obj.cyFuzz;
                    obj.analyze_examples();
                otherwise
                    error('Invalid Argument');
            end
            %obj.write_excel();
            disp(obj.data);
        end
           
        function analyze_examples(obj)
            disp('Analyzing examples');
            
            for i = 1:numel(obj.examples)
                s = obj.examples{i};
                open_system(s);
                sys = gcs;
                % initializing maps to store metrics
                obj.map = mymap();
                obj.blockTypeMap = mymap();
                obj.childModelMap = mymap();
                
                % api function to obtain metrics
                obj.do_single_model(sys);
                
                % recursive function to obtain metrics
                obj.obtain_hierarchy_metrics(sys,1,false);
                
                % display metrics calculated
                disp('Number of blocks Level wise:');
                disp(obj.map.data);
                disp('Number specific blocks with their counts:');
                disp(obj.blockTypeMap.data);
                disp('Number of child models with the number of times being reused:');
                disp(obj.childModelMap.data);
                close_system(sys);
            end
        end
        
        function obtain_hierarchy_metrics(obj,sys,depth,isModelReference)
            all_blocks = find_system(sys,'SearchDepth',depth);
            if isModelReference
                mdlRefName = get_param(sys,'ModelName');
                load_system(mdlRefName);
                all_blocks = find_system(mdlRefName,'SearchDepth',depth);
                all_blocks = all_blocks(2:end);
            end
            count=0;
            [blockCount,~] =size(all_blocks);
            
            %skip the root model which always comes as the first model
            for i=1:blockCount
                currentBlock = all_blocks(i);
                if strcmp(currentBlock, sys) ~=1
                    blockType = get_param(currentBlock, 'blocktype');
                    obj.addToBlockTypeMap(blockType{1,1});
                    if util.cell_str_in(obj.childModelList,blockType)
                        % child model found
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
            if count >0
                mapKey = num2str(depth);
                if obj.map.contains(mapKey)
                    existingCount = obj.map.get(mapKey);
                    obj.map.put(mapKey,existingCount + count);
                else
                    obj.map.put(mapKey,count);
                end
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

