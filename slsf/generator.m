disp('--- Starting ---');

rng(0,'twister');

NUM_BLOCKS = 5;

added_blocks = cell(1, NUM_BLOCKS);
inputs = cell(1, NUM_BLOCKS);
outputs = cell(1, NUM_BLOCKS);

inp_blocks = cell(1, NUM_BLOCKS);
oup_blocks = cell(1, NUM_BLOCKS);

num_inp_blocks = 0;
num_oup_blocks = 0;

num_inp_ports = 0;
num_oup_ports = 0;

sys = 'sampleModel';

new_system(sys);
open_system(sys);

possible_blocks = {'simulink/Sources/Constant', 'simulink/Sinks/Scope', 'simulink/Sources/Constant', 'simulink/Sinks/Display', 'simulink/Math Operations/Add'};

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
    
    this_blk_name = strcat('bl', num2str(cur_blk));
    
    % Add this block name to list of all added blocks
    added_blocks{cur_blk} = this_blk_name;
    
    this_blk_name = strcat('/', this_blk_name);
    
    h = add_block(block_name{1}, [sys, this_blk_name], 'Position', pos);
    
    
    % Get its inputs and outputs
    ports = get_param(h, 'Ports');
    
    num_inputs_cell = cell(1, ports(1));
    [num_inputs_cell{:}] = deal(0);
    
    inputs{cur_blk} = num_inputs_cell;
    
    if ports(1) > 0
        num_inp_blocks = num_inp_blocks + 1;
        inp_blocks{num_inp_blocks} = cur_blk;
        num_inp_ports = num_inp_ports + ports(1);
    end
    
    % Outputs
    
    outputs_cell = cell(1, ports(2));
    [outputs_cell{:}] = deal(0);
    
    outputs{cur_blk} = outputs_cell;
    
    if ports(2) > 0
        num_oup_blocks = num_oup_blocks + 1;
        oup_blocks{num_oup_blocks} = cur_blk;
        num_oup_ports = num_oup_ports + ports(2);
    end
    
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

while num_inp_ports > 0 || num_oup_ports > 0
    
    fprintf('Num Input port: %d; num output port: %d\n', num_inp_ports, num_oup_ports);
    
    if num_inp_ports > 0
       % choose an input port
       rand_num = randi([1, num_inp_blocks], 1, 1);
       r_i_blk = inp_blocks{rand_num(1)};
       
       % get a port of this input block
       t_all_ports = inputs{r_i_blk};
       
       r_i_port = 0;
       
       for t_i = t_all_ports
           r_i_port = r_i_port + 1;
           
           if t_i{1} == 0
               break;
           end
       end
       
       fprintf('Input: Blk %d Port %d chosen.\n', r_i_blk, r_i_port);
    end
    
    if num_oup_ports > 0
        % Choose output port
        
       rand_num = randi([1, num_oup_blocks], 1, 1);
       r_o_blk = oup_blocks{rand_num(1)};
       
       % get a port of this output block
       t_all_ports = outputs{r_o_blk};
       
       r_o_port = 0;
       
       for t_i = t_all_ports
           r_o_port = r_o_port + 1;
           
           if t_i{1} == 0
               break;
           end
       end
       
       fprintf('Output: Blk %d Port %d chosen.\n', r_o_blk, r_o_port);
    end
    
    % Add line
    t_i = strcat(added_blocks{r_i_blk}, '/', int2str(r_i_port));
    t_o = strcat(added_blocks{r_o_blk}, '/', int2str(r_o_port));
    disp(t_i);
    
    add_line(sys,t_i, t_o,'autorouting','on')
    
    break;  % AFter one iteration
    
    
end