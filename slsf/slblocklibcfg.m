classdef (Sealed) slblocklibcfg < handle
    
    properties
    
        categories;
        blocklist = struct;
        hierarchy_blocks;
        submodel_blocks;
    
    end
    
   methods (Access = private)
      function obj = slblocklibcfg
          
          obj.categories = cfg.SL_BLOCKLIBS;  % Seems like this performs a deep copy
          
          for i=1:numel(cfg.SL_BLOCKS_BLACKLIST)
            obj.blocklist.(util.mvn(cfg.SL_BLOCKS_BLACKLIST{i})) = 1;
          end
          
          obj.hierarchy_blocks = mymap.create_from_cell(cfg.SL_HIERARCHY_BLOCKS);
          obj.submodel_blocks = mymap.create_from_cell(cfg.SL_SUBSYSTEM_BLOCKS);
          
      end
   end
   
   methods (Static)
      function singleObj = getInstance
         persistent localObj
         if isempty(localObj) || ~isvalid(localObj)
            localObj = slblocklibcfg;
         end
         singleObj = localObj;
      end
   end
end

