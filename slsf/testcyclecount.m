function [ num_cycles ] = testcyclecount( model_name )
%TESTCYCLECOUNT Return the number of simple cycles in the model `model_name`
%   
    
    open_system(model_name); % Load the model
        
    % Gets all blocks from the model
    all_blocks = find_system(model_name,'SearchDepth',1, 'LookUnderMasks', 'all', 'FollowLinks','on');
    
    [blockCount,~] =size(all_blocks);
    
    % Initialize graph data-structure
    slb = slblocks_light(0);
    
    % Loops through all of the blocks
    for i=1:blockCount
        currentBlock = all_blocks(i);
        
        % Special case handling
        if strcmp(currentBlock, model_name)
            continue;
        end

        % Adds the block in the gata structure `slb`
        slb.process_new_block(currentBlock);

    end
    
            
            
    fprintf('Get SCC for %s\n', char(model_name));
    % This function will actually compute the number of strongly connected
    % components from the graph data-structure `slb`
    con_com = getCountCycles(slb);
    fprintf('[ConComp] Got %d cycles\n', con_com);

    num_cycles = con_com;

    % Close the model
    try
        close_system(model_name);
    catch
    end

end

