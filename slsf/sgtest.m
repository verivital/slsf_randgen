% Test simple_generator
rng(0,'twister');           % Random Number Generator Init

NUM_TESTS = 1;

for ind = 1:NUM_TESTS
    chart_name = strcat('sampleModel', int2str(ind));
    sg = simple_generator(5, chart_name, true);
    sg.go();
end