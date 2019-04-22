function  inspect(errors, err_id, report_dir)
%INSPECT Inspect a model which threw err_id 
%   Obtain `errors` executing `sgpreport`
    exceptions = arrayfun(@(p)p.errors.identifier, errors, 'UniformOutput', false);
    match_ids = strcmp(exceptions, err_id);

    matches = errors(match_ids);

    model_names = arrayfun(@(p)p.model_name, matches, 'UniformOutput', false);

    open_system([report_dir filesep '..' filesep 'errors' filesep model_names{1}]);
end

