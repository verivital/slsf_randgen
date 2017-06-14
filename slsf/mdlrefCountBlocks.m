function totalBlocks = mdlrefCountBlocks(mdl)


% mdlrefCountBlocks Count the subsystem equivalent number of blocks 


% in a model reference hierarchy.


 


% Copyright 2009 The MathWorks, Inc


 


%% Open the model


% fprintf('[DEBUG] Inside mdlrefCountBlocks function... \n');

open_system(mdl)


 


%% Get instance information


[mDep,mInst] = find_mdlrefs(mdl);


% Open dependent models


for i = 1:length(mDep)


    load_system(mDep{i})


end


 


%% Count the number of instances of each dependency


mCount = zeros(size(mDep));


mCount(end) = 1; % Last element is the top model, only one instance


for i = 1:length(mInst)


    mod = get_param(mInst{i},'ModelName');


    mCount = mCount + strcmp(mod,mDep);


end


%%


for i = 1:length(mDep)


%     disp([num2str(mCount(i)) ' instances of ' mDep{i}])


end


disp(' ')


 


%% Loop over dependencies, get number of blocks


s = cell(size(mDep));


for i = 1:length(mDep)


    [t,s{i}] = sldiagnostics(mDep{i},'CountBlocks');


    disp([mDep{i} ' has ' num2str(s{i}(1).count) ' blocks'])


end


 


%% Multiply number of blocks, times model count, add to total


totalBlocks = 0;


for i = 1:length(mDep)


    totalBlocks = totalBlocks + s{i}(1).count * mCount(i);


end


 


disp(' ')

disp(['Total blocks: ' num2str(totalBlocks)])