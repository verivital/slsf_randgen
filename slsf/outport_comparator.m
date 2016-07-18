classdef outport_comparator < comparator
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function obj = outport_comparator(varargin)
            obj = obj@comparator(varargin{:});
        end
        
        function ret = compare(obj)
            fprintf('Starting Comparison...\n');
            obj.log_all();
            
            ret = obj.final_val_compare();

        end
        
        function ret = final_val_compare(obj)
            ret = true;
           
            last_run_time = obj.data{1}.time;
            last_run_data = obj.data{1}.signals;
            
            for i = 2:numel(obj.data)
                fprintf('Comparing group %d...\n', i);
                out_data = obj.data{i};
                
                if last_run_time ~= out_data.time
                    fprintf('Time mismatch in mode %s.\n', modes{j});

                    disp('---------------- Previous Time ------------------');
                    last_run_time
                    disp('---------------- Current Time ------------------');
                    out_data.time
                    
                    ret = false;
                    obj.my.exc = MException('RandGen:SL:CompareError', 'Compared Time Mismatch');
                else
                    fprintf(' time matched!\n');
                end



                if ~ outcompare(last_run_data, out_data.signals)
                    fprintf('Data mismatch in group %d.\n', i);
                    ret = false;
                    obj.my.exc = MException('RandGen:SL:CompareError', 'Compared Data Mismatch');
                else
                    fprintf(' data matched!\n');
                end
            end
        end
        
        
        function log_all(obj)
            obj.my.logdata = obj.data;
        end
        
        
    end
    
end

