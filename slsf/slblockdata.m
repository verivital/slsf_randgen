classdef slblockdata < handle
    %SLBLOCKDATA Contains PARSED information about a built-in block
    %   We collected the information parsing Simulink documentations
    %   `slblockdocparser` Parsed the documentation.
    
    properties
%         myname;
        in_dtypes;
        out_dtypes;
        out_data_type_param = [];
        default_out_param = [];
        is_source;
        is_sink;
        is_signed_only = false % Determine by the attribute '6' at Block-data type support page. Implies this block doesn't support unsigned
    end
    
    methods
        function obj = slblockdata()
            obj.in_dtypes = mycell();
            obj.out_dtypes = mycell();
            obj.is_source = false;
            obj.is_sink = false;
        end
        
    end
    
end

