classdef analyze_complexity
    %ANALYZE_COMPLEXITY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        base_dir = '';
        
        exptype = 'example';
        
        examples = {'sldemo_fuelsys'};
    end
    
    methods
        
        function  obj = analyze_complexity(exptype)
            obj.exptype = exptype;
        end
        
        function start(obj)
            switch obj.exptype
                case 'example'
                    obj.analyze_examples();
                otherwise
                    error('Invalid Argument');
            end
        end
        
        function analyze_examples(obj)
            disp('Analyzing examples');
            for i = 1:numel(obj.examples)
                s = obj.examples{i};
                eval(s);
                sys = gcs;
                close_system(sys);
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

