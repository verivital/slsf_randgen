classdef comparator < handle
    %COMPARATOR Compare between two simulation results
    %   Detailed explanation goes here
    
    properties
        generator;
        data;                       % Data we receive from generator
        refined_data;               % After we process the `data`;
        try_count;
    end
    
    methods
        
        
        function obj = comparator(generator, data, try_count)
            % CONSTRUCTOR %
            obj.generator = generator;
            obj.data = data;
            obj.try_count = try_count;
        end
        
        
        function ret = compare(obj)
            fprintf('Starting Comparison...\n');
            obj.prepare_data();
%             fieldnames(obj.refined_data{1})
%             fieldnames(obj.refined_data{2})
            ret = obj.final_val_compare();
            
            
            
        end
        
        
        
        function ret = final_val_compare(obj)
            ret = true;
            f = obj.refined_data{1};                    % First Simulation Trace
            blocks = fieldnames(f);
            
            for i = 2: numel(obj.refined_data)
                fprintf('Comparing Simulation Number %d with %d\n', i, 1);
                
                for j = 1 : numel(blocks)
                    bl_name = blocks{j};
%                     fprintf('Comparing block: %s\n', bl_name);
                    
                    data_1 = f.(bl_name);
                    data_2 = obj.refined_data{i}.(bl_name);
                    
%                     fprintf('-----------------\n');
%                     
%                     data_1.Time
%                     data_1.Data
%                     data_2.Time
%                     data_2.Data
%                     
%                     fprintf('-----------------\n');
                    
                    % Last Data
                    
                    num_data_1 = numel(data_1.Data);
                    num_data_2 = numel(data_2.Data);
                    
                    num_time_1 = numel(data_1.Time);
                    num_time_2 = numel(data_2.Time);
                    
                    if obj.try_count == 1
                        if num_data_1 ~= num_data_2 || num_time_1 ~= num_time_2
                            fprintf('[!E!] Length mismatch. Will try again\n');
                            obj.generator.my_result.is_log_len_mismatch = true;
                            obj.generator.my_result.log_len_mismatch_count = obj.generator.my_result.log_len_mismatch_count + 1;
                            ret = false;
                            return;
                        end
                    end
                    
                    d_1 = data_1.Data(numel(data_1.Data));
                    d_2 = data_2.Data(numel(data_2.Data));
                    
                    t_1 = data_1.Time(numel(data_1.Time));
                    t_2 = data_2.Time(numel(data_2.Time));
                    
                    if d_1 == d_2
%                         fprintf('Data No Mismatch\n');
                    else
                        fprintf('Data Mismatch!\n');
                        ret = false;
                        obj.generator.last_exc = MException('RandGen:SL:CompareError', 'Compared Data Mismatch');
                        d_1
                        d_2
                        num_data_1
                        num_data_2
                        data_1.Data
                        data_2.Data
                    end
                    
                    
                    if t_1 == t_2
%                         fprintf('Time No Mismatch\n');
                    else
                        fprintf('Time Mismatch!\n');
                        ret = false;
                        obj.generator.last_exc = MException('RandGen:SL:CompareError', 'Compared Time Mismatch');
                        t_1
                        t_2
                        num_time_1
                        num_time_2
                        data_1.Time
                        data_2.Time
                    end
                    
                end
            end
        end
        
        
        
        function obj = prepare_data(obj)
            fprintf('Preparing Data...\n');
            obj.refined_data = cell(1, numel(obj.data));
            
            for i = 1:numel(obj.data)
                % This loop iterates through ALL simulations.
                single_simulation = struct;
                
                cur_dataset = obj.data{i};
                
                for j = 1:cur_dataset.numElements
                    % This iterates through all blocks of a particular
                    % simulation
                    new_data = struct;
                    
                    s_dataset = cur_dataset.getElement(j);
                    
                    new_data.Time = s_dataset.Values.Time;
                    new_data.Data = s_dataset.Values.Data;
                    
                    bp = char(s_dataset.BlockPath.convertToCell());
%                     fprintf('Now inserting data in\n');
                    
                    single_simulation.(util.mvn(bp)) = new_data;
                end
                
                obj.refined_data{i} = single_simulation;
            end
            
            
        end
        
    end
    
end

