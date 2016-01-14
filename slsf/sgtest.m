% Test simple_generator
rng(0,'twister');           % Random Number Generator Init

NUM_TESTS = 1;

for ind = 1:NUM_TESTS
    sg = simple_generator(10, strcat('sampleModel', int2str(ind)));
    sg.go();
end