function  metrics_agg_save(  )
%METRICS_AGG_SAVE Summary of this function goes here
%   Detailed explanation goes here

    global grand_tests;
    global grand_simples;
    global grand_advanced;
    global grand_libs;
    
    save('metricsdata', 'grand_simples', 'grand_advanced', 'grand_tests', 'grand_libs');
    
    fprintf('Saved!\n');
end

