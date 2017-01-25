classdef slblockdata < handle
    %SLBLOCKDATA Contains information about a built-in block
    %   We collected the information parsing Simulink documentations
    %   `slblockdocparser` Parsed the documentation.
    
    properties
%         myname;
        in_dtypes;
        out_dtypes;
        out_data_type_param = [];
        default_out_param = [];
    end
    
    methods
        function obj = slblockdata()
            obj.in_dtypes = mycell();
            obj.out_dtypes = mycell();
        end
    end
    
end

