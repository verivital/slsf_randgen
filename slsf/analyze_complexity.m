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
    end
    
    properties
        base_dir = '';
        
        exptype = 'example';
        
%         examples = {'sldemo_fuelsys'};
        examples = {'untitled'};
        
        data = cell(1, 6);
        di = 1;
        
    end
    
    methods
        
        function obj = init_excel_headers(obj)
            obj.data{1, obj.MODEL_NAME} = 'Model name';
            obj.data{1, obj.BLOCK_COUNT_AGGR} = 'BC';
            obj.data{1, obj.BLOCK_COUNT_ROOT} = 'BC(R)';
            obj.data{1, obj.CYCLOMATIC} = 'CY';
            obj.data{1, obj.SUBSYSTEM_COUNT_AGGR} = 'Ss cnt';
            obj.data{1, obj.SUBSYSTEM_DEPTH_AGGR} = 'Ss dpt';
        end
        
        function  obj = analyze_complexity(exptype)
            obj.exptype = exptype;
        end
        
        function start(obj)
            obj.init_excel_headers();
            switch obj.exptype
                case 'example'
                    obj.analyze_examples();
                otherwise
                    error('Invalid Argument');
            end
            obj.write_excel();
            disp(obj.data);
        end
        
        function analyze_examples(obj)
            disp('Analyzing examples');
            
            for i = 1:numel(obj.examples)
                s = obj.examples{i};
                eval(s);
                sys = gcs;
                obj.do_single_model(sys);
%                 close_system(sys);
            end
        end
        
        
        
        function obj = write_excel(obj)
            filename = 'MetricResults.xlsx';
            xlswrite(filename,obj.data);
        end
        
        function do_single_model(obj, sys)
            obj.di = obj.di + 1;
            obj.data{obj.di, obj.MODEL_NAME} = sys;
            
            metric_engine = slmetric.Engine();

            % Include referenced models and libraries in the analysis, these properties are on by default
            metric_engine.AnalyzeModelReferences = 1;
            metric_engine.AnalyzeLibraries = 1;
            
            metrics ={ 'mathworks.metrics.SimulinkBlockCount', 'mathworks.metrics.SubSystemCount', 'mathworks.metrics.SubSystemDepth', 'mathworks.metrics.CyclomaticComplexity'};
            
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

