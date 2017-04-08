classdef mymap < handle
    %MYMAP HashMap
    %   Detailed explanation goes here
    
    properties
        data
        data_keys = [];                  % WARNING Value of this field is valid ONLY after calling keys() method.
    end
    
    
    methods (Static)
      function ret = create_from_cell(data)
         ret = mymap();
         
         for i=1:numel(data)
            ret.put(data{i}, 1);
         end
      end
   end
    
    methods
        function obj = mymap(varargin)
            obj.data = struct;
            
            if nargin >0
%                 disp('MyMap called with argument!');
                for i = 1:2:numel(varargin)
                    obj.put(varargin{i}, varargin{i+1});
                end
%             else
%                 disp('MyMap with NO arguments');
            end
            
        end
        
%         function obj = test(obj, a, b)
%             fprintf('varargin: %d\n', nargin);
%          end
        
        function ret =  create_if_not_exists(obj, k, classn)
            if obj.contains(k)
                ret = obj.get(k);
            else
                ret = feval(classn);
                obj.put(k, ret);
            end
        end
        
        
        function put(obj, k, v)
            effective_key = util.mvn(k);
            obj.data.(effective_key) = v;
        end
        
        function ret = contains(obj, k)
            ret = isfield(obj.data, util.mvn(k));
        end
        
        function ret = get(obj, k)
            if ~ isfield(obj.data, util.mvn(k))
                ret = [];
            else
                ret = obj.data.(util.mvn(k));
            end
        end
        
        function ret = keys(obj)
            ret = fieldnames(obj.data);
            obj.data_keys = ret;
        end
        
        function ret  = key(obj, index)
            %  WARNING only call this after calling `keys()` first
            %  otherwise you might not get updated values.
            ret = obj.data_keys{index};
        end
        
        function obj = print_all(obj)
            fprintf('Printing MyMap -->\n');
            for i=1:numel(obj.keys)
                k = obj.keys{i};
                fprintf('%s --> %s \t', k, obj.get(k));
            end
            fprintf('\n');
        end
        
        function obj = print_keys(obj)
             fprintf('Printing MyMap Keys -->\n');
            for i=1:numel(obj.keys)
                k = obj.keys{i};
                fprintf('%s; \t', k);
            end
            fprintf('\n');
        end
    end
    
end

