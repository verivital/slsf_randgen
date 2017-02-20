classdef (Sealed) slblockdocfixed < handle
    %SLBLOCKDOCFIXED SL block documentations collected manually
    %   Detailed explanation goes here
    
    properties(Constant = true)
        HIER = 'a';
        SUBSYS = 'b';
        prefix = 'simulink/';
    end
    
    properties 
        source_dtypes;
        d;
    end
    
   methods
       
      function ret = get(obj, blk, prop)
        ret = [];
        
        sn = strsplit(blk, 'simulink/');
        
        if numel(sn) == 2
            blk = sn{2};
        end
        
        if ~ obj.d.contains(blk)
            return;
        end
        
        blkdata = obj.d.get(blk);
        
        if ~ isfield(blkdata, prop)
            return;
        end
        
        ret = blkdata.(prop);
        
      end
       
   end
    
   methods (Access = private)
      function obj = slblockdocfixed
          % Output Data Types %
          obj.source_dtypes = mymap(); 
          obj.source_dtypes.put('Sources/CounterFree_Running', mycell({'int'})); 
          obj.source_dtypes.put('Sources/CounterLimited', mycell({'int'}));
          
          % All Data
          
          obj.d = mymap();
          
          obj.d.put('Ports & Subsystems/Model',...
              struct(obj.HIER, true));
          
          obj.d.put('Ports & Subsystems/For Each Subsystem',...
              struct(obj.SUBSYS, true));
          
          
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

