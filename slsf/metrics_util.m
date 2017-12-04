classdef metrics_util
    %METRICS_UTIL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant = true)
        data_file_name = 'mclina3metrics';
    end
    
    properties
    end
    
    methods
    end
    
    methods (Static)
        
        function agg( r )
            global grand_tests;
            global grand_simples;
            global grand_advanced;
            global grand_libs;


            grand_simples = [grand_simples, r.simples.data];
            grand_advanced = [grand_advanced, r.advances.data];
            grand_tests = [grand_tests, r.tests.data];
            grand_libs = [grand_libs, r.libs.data];

            strjoin([r.simples.data, r.advances.data], ', ')

        end
        
        function  agg_save()

            global grand_tests;
            global grand_simples;
            global grand_advanced;
            global grand_libs;

            save(metrics_util.data_file_name, 'grand_simples', 'grand_advanced', 'grand_tests', 'grand_libs');

            fprintf('Saved!\n');
        end
        
        function agg_init()
            global grand_tests;
            global grand_simples;
            global grand_advanced;
            global grand_libs;
            
            grand_tests = {};
            grand_simples = {};
            grand_advanced = {};
            grand_libs = {};
        end
        
        function agg_print()
            global grand_tests;
            global grand_simples;
            global grand_advanced;
            global grand_libs;
            
            s = mycell();
            
            fprintf('Simples\n');
            
            for i=1: numel(grand_simples)
                s.add(['''' grand_simples{i} '''']);
            end
            
            strjoin(s.data, ', ')
            
            s = mycell();
            
            for i=1: numel(grand_advanced)
                s.add(['''' grand_advanced{i} '''']);
            end
            
            fprintf('Advanced\n');
            
            strjoin(s.data, ', ')
            
            fprintf('Libs\n');
            
            s = mycell();
            
            for i=1: numel(grand_libs)
                s.add(['''' grand_libs{i} '''']);
            end
                        
            strjoin(s.data, ', ')
            
            fprintf('Tests\n');
            
            s = mycell();
            
            for i=1: numel(grand_tests)
                s.add(['''' grand_tests{i} '''']);
            end
                        
            strjoin(s.data, ', ')
        end
        
    end
    
end

