function metrics_agg( r )
%METRICS_AGG Summary of this function goes here
%   Detailed explanation goes here
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

