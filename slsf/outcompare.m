function ret  = outcompare( prev, cur )
%OUTCOMPARE Summary of this function goes here
%   Detailed explanation goes here

    disp('--- PREV: ---');
    prev.blockName
    disp('--- CUR: ---');
    cur.blockName

    ret = true;
    
    if ~ util.are_cells_equal(util.struct_arr2cell_arr(prev, 'blockName'), util.struct_arr2cell_arr(cur, 'blockName') )
        fprintf('[!] Block Name mismatch\n');
            
        disp('---------------- Previous  ------------------');
        prev.blockName
        disp('---------------- Current  ------------------');
        cur.blockName
        ret = false;
    end
    
    if ~ isequal( cat(1, prev.dimensions), cat(1, cur.dimensions))
        fprintf('[!] Dimension mismatch\n');
            
        disp('---------------- Previous  ------------------');
        prev.dimensions
        disp('---------------- Current  ------------------');
        cur.dimensions
        ret = false;
    end
    
    if ~ isequal(cat(1, prev.values), cat(1, cur.values))
        fprintf('[!] Values mismatch\n');
            
        disp('---------------- Previous  ------------------');
        prev.values
        disp('---------------- Current  ------------------');
        cur.values
        ret = false;
    end

end

