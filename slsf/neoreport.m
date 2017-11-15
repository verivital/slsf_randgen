function [big_total, big_timedout,all_solvers] = neoreport(datefrom, break_after_single)
    %%% datefrom is string in format 'yyyy-MM-dd-HH-mm-ss'
    
    if nargin <= 1
        break_after_single = true;
    end

    report_dir = cfg.REPORTSNEO_DIR;

    file_list = dir([report_dir]);

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
    
    big_dc = mycell();
    
    big_num_fe_attempts = 0;
    
    all_solvers = mycell();
    
    rt_bs = 0;
    rt_pc = 0;
    rt_fas = 0;
    rt_sl = 0;
    rt_comp = 0;
    rt_tot = 0;
    rt_tot_count = 0; % For how many models counted
    
    big_block_sel = mymap();
    
    num_blocks = 0;
    
    later_errors = struct;


    for i = 1:numel(file_list)
        
        cur_file = file_list(i).name;
        
        if ~file_list(i).isdir || strcmp(cur_file, '.') || strcmp(cur_file, '..')
%             disp('Not a directory.... ignoring.');
            continue;
        end
        
        
        f_date = datetime(cur_file,'InputFormat','yyyy-MM-dd-HH-mm-ss');

        if f_date >= date_from
            fprintf('Processing file %s...\n', cur_file);

            try
                load([report_dir filesep cur_file filesep 'reports.mat']);
            catch e
                disp('Didnt find reports.mat file. Skipping....');
                continue;
            end

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
            
            big_dc.add(dtc_stat);
            
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
            
            
            for j=1:numel(all_models_sr)
                cur_saved_res = all_models_sr{j};
                if cur_saved_res.is_successful
                    big_num_fe_attempts = big_num_fe_attempts + cur_saved_res.num_fe_attempts;
                end
            end
            
            assert(runtime.len == numel(all_models_sr));
            
            
            for j = 1:runtime.len
                d = runtime.get(j);

                % only count successful ones
                cur_saved_res = all_models_sr{j};

                if cur_saved_res.is_successful

                    rt_bs = rt_bs + d(singleresult.BLOCK_SEL);
                    rt_pc = rt_pc + d(singleresult.PORT_CONN);
                    rt_fas = rt_fas + d(singleresult.FAS);
                    rt_sl = rt_sl + d(singleresult.SIGNAL_LOGGING);
                    rt_comp = rt_comp + d(singleresult.COMPARISON);
                    rt_tot_count = rt_tot_count + 1;
                else
%                     fprintf('NOT SUCCESSFUL! Skipping...\n');
                end

            end
            
%             fprintf('Errors Listing \n');
    
           for am_i = 1:numel(all_models_sr)
                if isempty(all_models_sr{am_i})
                    continue;
                end
                                
                c = all_models_sr{am_i};
                
                for solver_i = 1:numel(c.solvers_used)
                    all_solvers.add(c.solvers_used{solver_i});
                end
                
                if c.is_err_after_normal_sim
                    fprintf('Found Err aftder normal sim\n');
                    e = c.errors;
                    switch e.identifier
                        case {'MATLAB:MException:MultipleErrors'}
                           
                            for ae_i = 1:numel(e.cause)
                                ae = e.cause{ae_i};
                                later_errors =  util.map_inc(later_errors,ae.identifier);
                            end
                            
                        otherwise
                            later_errors =  util.map_inc(later_errors,e.identifier);
                    end
                end
                    
           end

%             fn = fieldnames(e_later)
%             for eli=1:numel(fn)
%                 k = fn{i};
%                 fprintf('%s\t%d\n', e_later.(k));
%             end

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
    fprintf('>>> Counted runtime for %d models <<< \n', rt_tot_count);
    
    fprintf('Avg. Blocks: %.2f\n', num_blocks/num_sim);
    
    fprintf('Total files: %d\n', cur_file_index);
    
    fprintf('Data Conversion statistics\n');
    fprintf('Experiment-Model number \t Num-Analyzed \tNum-FixError \n');
    
    big_dtc_num_a = 0; % Total DTC block added by analysis
    big_dtc_num_fe = 0; % otal DTC block added by Fix Error phase
    
    for i = 1:big_dc.len
        c = big_dc.get(i);
        for j=1:c.len
            x = c.get(j);
            fprintf('%d-%d \t %d \t %d \n', i, j, x{1}, x{2});
            big_dtc_num_a = big_dtc_num_a + x{1};
            big_dtc_num_fe = big_dtc_num_fe + x{2};
        end
    end
    
    %     big_dtc_num_a
    %     big_dtc_num_fe
    
    fprintf('Avg. # of DTC by analysis: %.2f\n', big_dtc_num_a/num_sim);
    fprintf('Avg. # of DTC by FixError: %.2f\n', big_dtc_num_fe/num_sim);
    
    big_num_fe_attempts
    fprintf('--- Avg. Fix Error Attempts: %.2f ---\n', big_num_fe_attempts/num_suc);
    

    fprintf('---- Errors after normal simulation---\n');
    
    later_errors
end