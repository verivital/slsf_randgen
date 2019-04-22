function [errors] = sgpreport(err_id)
%SGPREPORT Generate Report for SGPAR
% Aggregates all reports in `report_loc` directory. 
% If aggregate is missing then aggregates individual cache results to a 
% file. Otherwise uses it or loades from disc if empty.
% Example:
% report() Aggregate from the latest directory in emi.cfg.REPORTS_DIR
% report('abc') aggregate but from 'abc' directory
% report([], []) don't aggregate. Load from emi.cfg.RESULT_FILE
% report([], data) don't aggregate, use data

    addpaths();

    l = logging.getLogger('sgp_report');
    
    if nargin < 1
        err_id = [];
    end

%     if nargin < 2 % Run aggregation
%         if nargin < 1 % From latest directory
            report_loc = utility.get_latest_directory(cfg.REPORTSNEO_DIR);

            if isempty(report_loc)
                l.warn('No direcotry found in %s', cfg.REPORTSNEO_DIR);
                return;
            end
            l.info('Aggregating from "latest" directory: %s', report_loc);
%         end
        
        report_loc = [report_loc filesep 'pardata'];
        
        sgp_result = utility.batch_process(report_loc, [],... % load all vars
            {{@utility.file_extension_filter, {'mat'}}},...
            @process_data, '', true, true); % explore subdirs; uniform output
        sgp_result = struct2table(sgp_result);
%     elseif isempty(aggregate) % Use provided aggregated or load from disc
%         l.info('Loading aggregated result from disc...');
%         readdata = load(emi.cfg.RESULT_FILE);
%         sgp_result = readdata.emi_result;
%     else
%         sgp_result = aggregate;
%     end
    
    srs = sgp_result.sr;
    oks = [srs.is_successful];
    
    errors = srs(~oks);
    exceptions = {errors.errors};
    
    l.info('Is Successful?');
    tabulate(oks);
    
    errs_after_norm = [srs.is_err_after_normal_sim];
    if any(errs_after_norm)
        l.info('Is Error After Normal Simulation?');
        tabulate(errs_after_norm);
    end
    
    
    if ~isempty(exceptions) 
        l.info('Exceptions:');
        exc_ids = cellfun(@(p)p.identifier, exceptions, 'UniformOutput', false);
        tabulate(exc_ids);
        
        if ~isempty(err_id)
            inspect(errors, err_id, report_loc);
        end
        
    end
    
    n_exp = size(sgp_result, 1);
    
    if length(oks) ~= n_exp
        l.error('Possible crashes during %d experiments -- data unavailable', n_exp-length(oks) );
    end

    % Write in disc
%     save(emi.cfg.RESULT_FILE, 'emi_result', 'stats_table');
    
end


function ret = process_data(data)
%     disp(data);
    ret = data;
end
