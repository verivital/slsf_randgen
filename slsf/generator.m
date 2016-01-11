disp('--- Starting ---');

NUM_BLOCKS = 5;

added_blocks = cell(1, NUM_BLOCKS);
inputs = cell(1, NUM_BLOCKS);
outputs = cell(1, NUM_BLOCKS);

sys = 'sampleModel';

new_system(sys);
open_system(sys);

possible_blocks = {'simulink/Sources/Constant', 'simulink/Sources/Constant', 'simulink/Sources/Constant', 'simulink/Sources/Constant', 'simulink/Sources/Constant'};

pos_x = 30;
pos_y = 30;

width = 60;
height = 60;

offset = 60;

hz_space = 100;
vt_space = 150;

blk_in_line = 3;

pos = [pos_x, pos_y, pos_x + width, pos_y + height];

cur_blk = 0;

x = pos_x;
y = pos_y;

for block_name = possible_blocks
    cur_blk = cur_blk + 1;          % Create block name
    
    % Create position
    
%     if cur_blk > 1
%         x = x + hz_space;
%     end
    
    h_len = x + width;
    
    pos = [x, y, h_len, y + height];
    
    this_blk_name = strcat('/bl', num2str(cur_blk));
    
    h = add_block(block_name{1}, [sys, this_blk_name], 'Position', pos);
    
    % Add this block name to list of all added blocks
    added_blocks{cur_blk} = this_blk_name;
    
    % Get its inputs and outputs
    ports = get_param(h, 'Ports');
    
    num_inputs_cell = cell(1, ports(1));
    [num_inputs_cell{:}] = deal(0);
    
    inputs{cur_blk} = num_inputs_cell;
    
    outputs_cell = cell(1, ports(2));
    [outputs_cell{:}] = deal(0);
    
    outputs{cur_blk} = outputs_cell;
    
    % Update x
    x = h_len;
    
    % Update y
    if rem(cur_blk, blk_in_line) == 0
        y = y + vt_space;
        x = pos_x;
    else
        x = x + hz_space;
    end
    
end