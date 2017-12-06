classdef (Sealed) slblockdocparser < handle
    %SLBLOCKDOCPARSER Parses Simulink documenation to collect info
    %   about Simulink blocks. Information are stored in `slblockdata`
    %   instances. Support for input data-types were retrived from
    %   `showblockdatatypetable ` command.
    
    properties (Constant = true)
        DTYPES = {[], [], 'double', 'single', 'boolean', 'int32'};
        INP_PARSE_START = 3;
        INP_PARSE_END = 6;
    end
    
    properties
    
        data = mymap();
        
%         fixed_data = slblockdocfixed.getInstance();
    
    end
    
    methods
        
        function blkob = get(obj, lib, blk)
            
            blkob = [];
            
            if nargin == 2
                args = strsplit(lib, '/');
                lib = args{1};
                blk = args{2};
            end
            
            if ~ obj.data.contains(lib)
                fprintf('Lib %s not found!\n', lib);
                return;
            end
            
            libob = obj.data.get(lib);
            
            if ~ libob.contains(blk)
                fprintf('Block %s not found!\n', blk);
                return;
            end
            
            blkob = libob.get(blk);
            
        end
        
        function [in_types, out_types] = get_types_of_block(obj, lib, blk)
            in_types = [];
            out_types = [];

            
            blkob = obj.get(lib, blk);
            
            in_types = blkob.in_dtypes;
            out_types = blkob.out_dtypes;
        end
    
        function reload_config(obj)
            
            obj.data = mymap();
%             return;
            
            obj.parse_block_data_type_support();
            obj.parse_block_specific_params();
            
            fprintf('=-=-=- END Block Data Parsing =-=-=-=-=- \n');
            
        end
        
        function obj = parse_block_data_type_support(obj)
            fprintf('Reading block data type supports (Input data-types support info)...\n');
            
            fid = [];
            
            try
                fid = fopen('resources/slblockdatatype.psv');                
                libname = [];
                libmap = [];
                
                skip_library = false;
                
                while true
                    
                    %%%%%% Read next line %%%%%%
%                     fprintf('New LIne:\n');
                    tline = fgetl(fid);
                    
                    if ~ ischar(tline)
                        break;
                    end
                    
%                     disp(tline)
                    
                    tokens = strsplit(tline, {'#'}, 'CollapseDelimiters', false);
                    
                    if ~isempty(tokens{1})
                        
                        % Indicates a new library
                        
                        if strcmpi(tokens{1}, 'Sublibrary')
%                             fprintf('Skipping.....\n');
                            continue;
                        end
                        
                        libname = tokens{1};
                        
                        skip_library = obj.is_skip_library(libname);
                        
                        if ~ skip_library
                            libmap = mymap();
                            obj.data.put(libname, libmap);
                            
                            if strcmp(libname, 'Sources')
                                is_source_block = true;
                            else
                                is_source_block = false;
                            end
                            
                             if strcmp(libname, 'Sinks')
                                is_sink_block = true;
                            else
                                is_sink_block = false;
                            end
                            
                        end
                    end
                    
                    if skip_library || isempty(tokens{2})
%                         fprintf('Skipping...\n');
                        continue;
                    end
                    
                    blname = strsplit(tokens{2}, {' ('});
                    
                    blname = blname{1};
                    
                    bl_obj = slblockdata();
%                     bl_obj.myname = blname;

                    for i=obj.INP_PARSE_START:obj.INP_PARSE_END
                        if util.starts_with(tokens{i}, 'X')
                            bl_obj.in_dtypes.add(obj.DTYPES{i});
%                             fprintf('Block %s: %s\n', blname, obj.DTYPES{i});

                            special_attributes = regexp(tokens{i}, '[\d]+', 'match');
                            
                            for sp_at_i = 1:numel(special_attributes)
                                if strcmp(special_attributes{sp_at_i}, '6')
                                    bl_obj.is_signed_only = true;
                                end
                            end
                            
                        end
                    end
                    
                    bl_obj.is_source = is_source_block;
                    bl_obj.is_sink = is_sink_block;
                    
                    libmap.put(blname, bl_obj);
                    
                    
                end
            catch e
                fprintf('Exception while reading slinputs\n');
%                 e
                disp(getReport(e,'extended'));
            end
            
            if ~isempty(fid)
                fclose(fid);
            end
            
        end
        
        function ret = is_skip_library(obj, libname)
            found = false;
            for ilib=1:numel(cfg.SL_BLOCKLIBS)
                if strcmpi(libname, cfg.SL_BLOCKLIBS{ilib}.name)
                    found = true;
                    break;
                end
            end
            ret = ~found;
        end
        
        
        function obj = parse_block_specific_params(obj)
            fprintf('Reading block specific params...\n');
            
            fid = [];
            
            try
                fid = fopen('resources/slblockspecificparams.psv');
                
                libname = [];
                libmap = [];
                
                blname = [];
                blobj = [];
                
                skip_library = false;
                skip_block = false;
                
                while true
                    
                    %%%%%% Read next line %%%%%%
%                     fprintf('New LIne:\n');
                    tline = fgetl(fid);
                    
                    if ~ ischar(tline)
                        break;
                    end
                    
%                     disp(tline)
                    
                    tokens = strsplit(tline, {'#'}, 'CollapseDelimiters', false);
                    
                    if isempty(tokens{1}) || strcmp(tokens{1}, 'Block (Type)/Parameter') || strcmp(tokens{1}, '...')
                        % NOTE: This also skips certain lines which are
                        % continual of previous lines.
%                         fprintf('Skipping...\n');
                        continue;
                    end
                    
                    [C, matches] = strsplit(tokens{1}, ' Library Block Parameters', 'CollapseDelimiters', false);
                    
                    if ~ isempty(matches)                       
                        libname = C{1};
                        
                        skip_library = obj.is_skip_library(libname);
                        
                        if ~ skip_library
%                             fprintf('New SL library: %s\n', libname);
                            libmap = obj.data.create_if_not_exists(libname, 'mymap');
                        end
                        
                        continue;
                    end
                    
                    if skip_library
                        continue;
                    end
                    
                    if isempty(tokens{2}) && isempty(tokens{3})                        
                        [bltokens, matches] = strsplit(tokens{1}, ' (');
                        if isempty(matches)
                            % See line 318
                            continue;
%                             throw(MException('SL:RandGen:UnexpectedBehavior', 'SL Block Documentation Paraser'));
                        end
                        
                        blname = bltokens{1};
                        
                        try
                            get_param(['simulink/' libname '/' blname], 'name');
                            skip_block = false;
%                             fprintf('New SL Block: %s\n', blname);
                            blobj = libmap.create_if_not_exists(blname, 'slblockdata');
                        catch e
                            skip_block = true;
                        end
                        
                        
                        continue;
                    end
                    
                    if skip_block
                        continue;
                    end
                    
                    % Properties of blocks...
                    
                    if strcmpi(tokens{2}, 'Output data type')
                        blobj.out_data_type_param = tokens{1};
%                         fprintf('Output data type found as param:%s\n', tokens{1});
                       
                        
                        dtypes = strsplit(tokens{3}, '|');
                        
                        int_added = false;
                        uint_added = false;
                        
                        for j=1:numel(dtypes)
                            cur_d = strtrim(dtypes{j});
                            if cur_d(1) == '{'
                                blobj.default_out_param = util.strip(cur_d(2:numel(cur_d) - 1), '''');
                            else
                                cur_d_stripped = util.strip(cur_d, '''');
                                if util.starts_with(cur_d_stripped, 'Inherit:')
%                                     fprintf('Inherited\n'); %TODO save
%                                     inherit options
                                else
                                    if strcmp(cur_d_stripped, 'double')
                                        blobj.out_dtypes.add(obj.DTYPES{3});
                                    elseif strcmp(cur_d_stripped, 'single')
                                        blobj.out_dtypes.add(obj.DTYPES{4});
                                    elseif strcmp(cur_d_stripped, 'boolean')
                                        blobj.out_dtypes.add(obj.DTYPES{5});
                                    elseif ~int_added && util.starts_with(cur_d_stripped, 'int')
                                        blobj.out_dtypes.add(obj.DTYPES{6});
                                        int_added = true;
                                    elseif ~uint_added && util.starts_with(cur_d_stripped, 'uint')
                                        blobj.out_dtypes.add('uint');
                                        uint_added = true;
                                    end
                                    
                                end
                            end
                        end
                    end

                end
            catch e
                fprintf('Exception while reading sl block library info\n');
%                 e
                disp(getReport(e,'extended'));
            end
            
            if ~isempty(fid)
                fclose(fid);
            end
        end
        
    end
    
    methods (Access = private)
        function obj = slblockdocparser
            obj.reload_config();
        end
    end
   
    methods (Static)
        function singleObj = getInstance
         persistent localObj
         if isempty(localObj) || ~isvalid(localObj)
            localObj = slblockdocparser;
         end
         singleObj = localObj;
        end
    end
end

