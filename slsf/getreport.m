report_dir = 'reports';

file_list = dir([report_dir filesep '*.mat']);

date_from = datetime('2013-06-01-00-00-00','InputFormat','yyyy-MM-dd-HH-mm-ss');

num_sim = 0;
num_err = 0;
num_suc = 0;
num_compare = 0;
num_timedout = 0;

cur_file_index = 0;

big_total = [];
big_timedout = [];
big_compare = [];


for i = 1:numel(file_list)
    cur_file = file_list(i).name;
    cur_files = strsplit(cur_file, '.');
    
    f_date = datetime(cur_files(1),'InputFormat','yyyy-MM-dd-HH-mm-ss');
    
    if f_date > date_from
        fprintf('Processing file %s...\n', cur_file);
        
        load([report_dir filesep cur_file]);
        
        cur_file_index = cur_file_index + 1;
        
        % Start Counting
        
        num_sim = num_sim + num_total_sim;
        num_err = num_err + num_err_sim;
        num_suc = num_suc + num_suc_sim;
        num_compare = num_compare + num_compare_error;
        num_timedout = num_timedout + num_timedout_sim;
        
        big_total(cur_file_index) = num_total_sim;
        big_timedout(cur_file_index) = num_timedout_sim;
        big_compare(cur_file_index) = num_compare_error;

        
    end
end


fprintf('----- Final --------\n');

num_sim
num_err
num_suc
num_compare
num_timedout

big_total = big_total';
big_timedout = big_timedout';
big_compare = big_compare';

fprintf('Total Models: %d\n', num_sim);
fprintf('Error: %.2f %%\n', num_err/num_sim*100 );
fprintf('Timed-out: %.2f %%\n', num_timedout/num_sim*100 );
fprintf('Success: %.2f %%\n', num_suc/num_sim*100 );
fprintf('Compare Error: %.2f %%\n', num_compare/num_sim*100 );

fprintf('Total files: %d\n', cur_file_index);