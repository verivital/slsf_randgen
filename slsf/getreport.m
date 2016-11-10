function [big_total, big_timedout] = getreport(datefrom)
    %%% datefrom is string in format 'yyyy-MM-dd-HH-mm-ss'
    
    break_after_single = true;

    report_dir = 'reports';

    file_list = dir([report_dir filesep '*.mat']);

    date_from = datetime(datefrom,'InputFormat','yyyy-MM-dd-HH-mm-ss');

    num_sim = 0;
    num_err = 0;
    num_suc = 0;
    num_compare = 0;
    num_timedout = 0;

    cur_file_index = 0;

    big_total = [];
    big_timedout = [];
    big_compare = [];
    
    
    rt_bs = 0;
    rt_pc = 0;
    rt_fas = 0;
    rt_sl = 0;
    rt_comp = 0;
    rt_tot = 0;
    
    big_block_sel = mymap();
    
    num_blocks = 0;


    for i = 1:numel(file_list)
        cur_file = file_list(i).name;
        cur_files = strsplit(cur_file, '.');

        f_date = datetime(cur_files(1),'InputFormat','yyyy-MM-dd-HH-mm-ss');

        if f_date >= date_from
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
            
            for j = 1:all_models.len
                cur = all_models.get(j);
                num_blocks = num_blocks + cur.num_blocks;
            end
            
            
            for j = 1:numel(block_selection.keys())
                k = block_selection.key(j);
                
                prev = big_block_sel.get(k);
                if isempty(prev)
                    prev = 0;
                end
                
                big_block_sel.put(k, (prev + block_selection.get(k)))
            end
            
            for j = 1:runtime.len
                d = runtime.get(j);

                % only count successful ones

                if d(singleresult.COMPARISON) > 0

                    rt_bs = rt_bs + d(singleresult.BLOCK_SEL);
                    rt_pc = rt_pc + d(singleresult.PORT_CONN);
                    rt_fas = rt_fas + d(singleresult.FAS);
                    rt_sl = rt_sl + d(singleresult.SIGNAL_LOGGING);
                    rt_comp = rt_comp + d(singleresult.COMPARISON);
                else
                    fprintf('NOT SUCCESSFUL! Skipping...\N');
                end

            end

            if break_after_single
                break;
            end

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
    fprintf('Error: %.2f %%\n', (num_err - num_timedout)/num_sim*100 );
    fprintf('Timed-out: %.2f %%\n', num_timedout/num_sim*100 );
    fprintf('Success: %.2f %%\n', num_suc/num_sim*100 );
    fprintf('Compare Error: %.2f %%\n', num_compare/num_sim*100 );
    
    fprintf('==== block selection stats ====\n');
    for j = 1:numel(big_block_sel.keys())
        k = big_block_sel.key(j);
        fprintf('%s\t\t\t\t%.2f\n', k, big_block_sel.get(k) / num_sim);
    end
    
    fprintf('==== Runtime stats ====\n');
    rt_tot = rt_bs + rt_pc + rt_fas + rt_sl + rt_comp;
    
    fprintf('Avg. BC \t %.2f \t %.2f\n', rt_bs/num_suc, rt_bs/rt_tot*100);
    fprintf('Avg. PC \t %.2f \t %.2f\n', rt_pc/num_suc, rt_pc/rt_tot*100);
    fprintf('Avg. FAS \t %.2f \t %.2f\n', rt_fas/num_suc, rt_fas/rt_tot*100);
    fprintf('Avg. SL \t %.2f \t %.2f\n', rt_sl/num_suc, rt_sl/rt_tot*100);
    fprintf('Avg. CMP \t %.2f \t %.2f\n', rt_comp/num_suc, rt_comp/rt_tot*100);
    fprintf('Avg. TOT \t %.2f \n', rt_tot/num_suc);
    
    fprintf('Avg. Blocks: %.2f\n', num_blocks/num_sim);
    
    fprintf('Total files: %d\n', cur_file_index);
end