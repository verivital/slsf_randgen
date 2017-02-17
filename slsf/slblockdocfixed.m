classdef (Sealed) slblockdocfixed < handle
    %SLBLOCKDOCFIXED SL block documentations collected manually
    %   Detailed explanation goes here
    
    properties 
        source_dtypes;
        df;
    end
    
   methods (Access = private)
      function obj = slblockdocfixed
          % Output Data Types %
          obj.source_dtypes = mymap(); 
          obj.source_dtypes.put('Sources/CounterFree_Running', mycell({'int'})); 
          obj.source_dtypes.put('Sources/CounterLimited', mycell({'int'}));
          
          % Direct Feed-through %
          
          obj.df = mymap();
          
          
      end
   end
   methods (Static)
      function singleObj = getInstance
         persistent localObj
         if isempty(localObj) || ~isvalid(localObj)
            localObj = slblockdocfixed;
         end
         singleObj = localObj;
      end
   end
end

