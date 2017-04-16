classdef analyze_complexity_cfg < handle
    %ANALYZE_COMPLEXITY_CFG Configure analyze_complexity_script
    %   Detailed explanation goes here
    
    properties(Constant = true)
        % Models
        
        examples = {'sldemo_mdlref_variants_enum','sldemo_mdlref_bus','sldemo_mdlref_conversion','sldemo_mdlref_counter_bus','sldemo_mdlref_counter_datamngt','sldemo_mdlref_dsm','sldemo_mdlref_dsm_bot','sldemo_mdlref_dsm_bot2','sldemo_mdlref_F2C'};
%         examples = {'aeroblk_HL20'};
%         examples = {'sldemo_mdlref_bus'};
%         examples = {'sldemo_mdlref_basic', 'sldemo_mdlref_bus'};
%         examples = {'untitled'};


        github = {};
        
        matlab_central = {};
        
        research = {};
        
        cyfuzz = {};
        
        
    end
    
    properties
        bp_render;  % Which box plots to render
    end
    
    methods
        
        function obj = analyze_complexity_cfg()
            obj.bp_render = zeros(analyze_complexity.NUM_METRICS);
            % Set true to those metrics which you wish to render
            obj.bp_render(analyze_complexity.METRIC_COMPILE_TIME) = true;
        end
        
    end
    
end

