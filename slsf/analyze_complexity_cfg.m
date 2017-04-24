classdef analyze_complexity_cfg < handle
    %ANALYZE_COMPLEXITY_CFG Configure analyze_complexity_script
    %   Detailed explanation goes here
    
    properties(Constant = true)
        % Models
    end
    
    properties
        bp_render;  % Which box plots to render
        % sldemo_mdlref_counter_bus causing issues in getAlgebraicLoops
        examples = {'sldemo_mdlref_variants_enum','sldemo_mdlref_bus','sldemo_mdlref_conversion','sldemo_mdlref_counter_datamngt','sldemo_mdlref_dsm','sldemo_mdlref_dsm_bot','sldemo_mdlref_dsm_bot2','sldemo_mdlref_F2C','ex_algebraic_loop'};
%         examples = {'sldemo_mdlref_variants_enum','sldemo_mdlref_bus','sldemo_mdlref_conversion','sldemo_mdlref_counter_bus','sldemo_mdlref_counter_datamngt','sldemo_mdlref_dsm','sldemo_mdlref_dsm_bot','sldemo_mdlref_dsm_bot2','sldemo_mdlref_F2C'};
%         examples = {'aeroblk_HL20'};
%         examples = {'sldemo_mdlref_variants_enum'};
%         examples = {'sldemo_mdlref_basic'};
%         examples = {'sldemo_auto_carelec'};
        github = {'aeroblk_self_cond_cntr'};
        
        matlab_central = {};
        
        research = {};
        
        cyfuzz = {};
        
        scripts_to_run = {};
%         scripts_to_run = {'InitializeCSTHDisturbedStdOp1', 'InitializeCSTHDisturbedStdOp2'};
    end
    
    methods
        
        function obj = analyze_complexity_cfg()
            obj.populate();
            
            obj.bp_render = zeros(analyze_complexity.NUM_METRICS);
            % Set true to those metrics which you wish to render
            obj.bp_render(analyze_complexity.METRIC_COMPILE_TIME) = true;
        end
        
        function obj = populate(obj)
            examples_a = {'sldemo_fuelsys', 'sldemo_auto_climatecontrol', 'sldemo_autotrans', 'sldemo_auto_carelec', 'sldemo_suspn', 'sldemo_auto_climate_elec',...
                'sldemo_absbrake', 'sldemo_enginewc', 'sldemo_engine', 'sldemo_fuelsys_dd', 'sldemo_clutch', 'sldemo_clutch_if'};
            examples_b = {'aero_guidance', 'sldemo_radar_eml', 'aero_atc', 'slexAircraftPitchControlExample', 'aero_six_dof', 'aero_dap3dof',...
                'slexAircraftExample', 'aero_guidance_airframe'};
            examples_c = {'sldemo_antiwindup', 'sldemo_pid2dof', 'sldemo_bumpless'};
            examples_d = {'aeroblk_wf_3dof', 'asbdhc2', 'asbswarm', 'aeroblk_HL20', 'asbQuatEML', 'aeroblk_indicated', 'aeroblk_six_dof',...
                'asbGravWPrec', 'aeroblk_calibrated', 'aeroblk_self_cond_cntr',};
%             obj.examples = examples_d;
            
            % Research
            
            research_a = {'Blending_Challenge', 'CSTHDisturbedStdOp1', 'CSTHDisturbedStdOp2', 'wind_turbine2'};
            research_b = {'fir8_03', 'fir12_03', 'pct_03', 'pid_03', 'pid_02', 'fir16tap', 'iir_biquad', 'pct', 'ACS', 'ALS', 'TTECTrA_example',...
                'Boiler_MIMOControl_PID12', 'Boiler_SISOControl_PID12', };
            research_c = {'benchmark_no_taylor', 'benchmark'};
            obj.research = research_c;
            
            % GitHub
            
            gh_a = {'AC_Quadcopter_Simulation', 'PC_Quadcopter_Simulation', 'Team37_Quadcopter_Simulation'};
            gh_b = {'GasTurbine_Dyn_Template', 'Plant_GasTurbine', 'GasTurbine_SS_Template', 'JT9D_Model_Dyn', 'JT9D_Model_SS', 'JT9D_SS_Cantera_Template', ...
                'NewtonRaphson_Equation_Solver', 'TTECTrA_example', 'qpsktxrx', 'ModeS_FixPt_Pipelined_ADI', 'ModeS_Simulink_libiio'};
            gh_c = {'sldemo_suspn', 'fourBar'};
            obj.github = gh_c;
        end
        
    end
    
end

