function checkout_github_repos( varargin )
%CHECKOUT_GITHUB_REPOS Clone the GitHub repositories
%   First argument: location where the projects will be clone

    gh_data_file = 'github_data';
    load(gh_data_file);
    global github_repos;

    if nargin < 1
        target_dir = 'gmodels';
        mkdir(target_dir);
    else
        target_dir = [varargin{1} filesep];
    end

    num_reps = 0;

    for i=1:numel(github_repos)

        c = github_repos{i};

        if isempty(c)
            continue;
        end

        c = strip(c);

        num_reps = num_reps + 1;

        repo_parts = strsplit(c, '/');

        project_dir = [target_dir repo_parts{end}];

        res = system(['git clone ' c ' ' project_dir]);

        % Delete the .git folder
        if res == 0
            try
                rmdir([project_dir filesep '.git'], 's');
            catch e
                getError(e)
            end
        end
    end

end