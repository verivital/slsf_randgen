classdef analyze_complexity_cfg < handle
    %ANALYZE_COMPLEXITY_CFG Configure analyze_complexity_script
    %   Detailed explanation goes here
    
    properties(Constant = true)
        % Models
    end
    
    properties
        bp_render;  % Which box plots to render

        examples = {'sldemo_mdlref_variants_enum', 'sldemo_mdlref_bus','sldemo_mdlref_conversion','sldemo_mdlref_counter_datamngt'};

        github = {'aeroblk_self_cond_cntr'};
        
        github_complex = {};
        
%         matlab_central = { 'ACTimeOvercurrentRelayBlock',  'Engine_Testrig',  'Fuel_Eco_TEST',  'HPW',  'HVDC_system',  'LF_AC29bus_HVDCdemo_V2_1',  'Link_A',  'Link_B',  'MAXPID_modelisation_multi_physique_MATLAB_2015a_Ivan_Liebgott',  'UPFC_1',  'Vehicle_Dynamics_Testrig',  'complex_multiply_example',  'downsample_upsample_example',  'enabled_subsystem_example',  'fir_filter_example',  'pvwindupfc11',  'realtime_pacer_lib',  'stateflow_example',  'sync_subsystem_example',  'view_wave_example',  'BB2',  'DMM',  'HVDC',  'MA_Model',  'MinorStepLib',  'OCR',  'PDQuadrotor',  'SimpleBounce',  'VFT',  'VU_NXTWay',  'VU_NXTWay_Simple',  'VU_lineFollow',  'VU_lineFollow1',  'VU_lineFollow1b',  'VU_lineFollow2',  'VU_motorSpdCtrl',  'VU_testBtTxRx',  'VU_testSoundTone1',  'VU_testSoundTone2',  'VU_testSoundTone3',  'VU_testUsbTxRx',  'Vehicle_Dynamics_Testrig',  'Wind_PMSG',  'lego_nxt_lib',  'lorenz3d',  'm3dscope_new',  'm3dscope_old',  'matrixFtse',  'microturbine_rectifierconverter',  'my_model',  'realtime_pacer_example',  'rev_pow_ckt_new4'  };
        
        research = {};
        
        simple = {};
        complex = {};
        
%         cyfuzz = {'untitled6'};
        
%         cyfuzz = {'sampleModel1000', 'sampleModel1002', 'sampleModel1004', 'sampleModel1012', 'sampleModel1018', 'sampleModel1024', 'sampleModel1028', 'sampleModel1032', 'sampleModel1033', 'sampleModel1034', 'sampleModel1035', 'sampleModel904', 'sampleModel908', 'sampleModel917', 'sampleModel925', 'sampleModel928', 'sampleModel930', 'sampleModel937', 'sampleModel938', 'sampleModel941', 'sampleModel944', 'sampleModel945', 'sampleModel946', 'sampleModel947', 'sampleModel950', 'sampleModel953', 'sampleModel962', 'sampleModel964', 'sampleModel965', 'sampleModel967', 'sampleModel970', 'sampleModel971', 'sampleModel973', 'sampleModel974', 'sampleModel975', 'sampleModel977', 'sampleModel978', 'sampleModel979', 'sampleModel980', 'sampleModel984', 'sampleModel986', 'sampleModel988', 'sampleModel989', 'sampleModel990', 'sampleModel995', 'sampleModel996'};
%         cyfuzz = {'sampleModel1849', 'sampleModel1851', 'sampleModel1852', 'sampleModel1853', 'sampleModel1854', 'sampleModel1855', 'sampleModel1856', 'sampleModel1857', 'sampleModel1858', 'sampleModel1859', 'sampleModel1860', 'sampleModel1861', 'sampleModel1862', 'sampleModel1863', 'sampleModel1864', 'sampleModel1865', 'sampleModel1866', 'sampleModel1867', 'sampleModel1868', 'sampleModel1869', 'sampleModel1870', 'sampleModel1871', 'sampleModel1872', 'sampleModel1873', 'sampleModel1874', 'sampleModel1875', 'sampleModel1876', 'sampleModel1877', 'sampleModel1878', 'sampleModel1879', 'sampleModel1880', 'sampleModel1881', 'sampleModel1882', 'sampleModel1883', 'sampleModel1884', 'sampleModel1885', 'sampleModel1886', 'sampleModel1887', 'sampleModel1889', 'sampleModel1890', 'sampleModel1891', 'sampleModel1892', 'sampleModel1893', 'sampleModel1894', 'sampleModel1895', 'sampleModel1896', 'sampleModel1897', 'sampleModel1898' };
        cyfuzz = {'sampleModel1327', 'sampleModel1328', 'sampleModel1329', 'sampleModel1330', 'sampleModel1331', 'sampleModel1332', 'sampleModel1333', 'sampleModel1334', 'sampleModel1336', 'sampleModel1337', 'sampleModel1338', 'sampleModel1339', 'sampleModel1340', 'sampleModel1341', 'sampleModel1342', 'sampleModel1343', 'sampleModel1344', 'sampleModel1345', 'sampleModel1346', 'sampleModel1347', 'sampleModel1348', 'sampleModel1349', 'sampleModel1350', 'sampleModel1351', 'sampleModel1352', 'sampleModel1353', 'sampleModel1354', 'sampleModel1355', 'sampleModel1357', 'sampleModel1358', 'sampleModel1359', 'sampleModel1360', 'sampleModel1361', 'sampleModel1362', 'sampleModel1363', 'sampleModel1365', 'sampleModel1366', 'sampleModel1367', 'sampleModel1368', 'sampleModel1369', 'sampleModel1370', 'sampleModel1371', 'sampleModel1372', 'sampleModel1373', 'sampleModel1374', 'sampleModel1375', 'sampleModel1376', 'sampleModel1377', 'sampleModel1378', 'sampleModel1379', 'sampleModel1380', 'sampleModel1381', 'sampleModel1382', 'sampleModel1383', 'sampleModel1384', 'sampleModel1385', 'sampleModel1386', 'sampleModel1387', 'sampleModel1388', 'sampleModel1389', 'sampleModel1390', 'sampleModel1391', 'sampleModel1392', 'sampleModel1393', 'sampleModel1394', 'sampleModel1395', 'sampleModel1396', 'sampleModel1397', 'sampleModel1398', 'sampleModel1399', 'sampleModel1400', 'sampleModel1401', 'sampleModel1403', 'sampleModel1404', 'sampleModel1405', 'sampleModel1406', 'sampleModel1408', 'sampleModel1409', 'sampleModel1410', 'sampleModel1411', 'sampleModel1412', 'sampleModel1413', 'sampleModel1414', 'sampleModel1415', 'sampleModel1416', 'sampleModel1417', 'sampleModel1418', 'sampleModel1419', 'sampleModel1420', 'sampleModel1421', 'sampleModel1422', 'sampleModel1424', 'sampleModel1425', 'sampleModel1426'};
        old_cyfuzz = {'sampleModel1', 'sampleModel10', 'sampleModel100', 'sampleModel11', 'sampleModel12', 'sampleModel13', 'sampleModel14', 'sampleModel15', 'sampleModel16', 'sampleModel17', 'sampleModel18', 'sampleModel19', 'sampleModel2', 'sampleModel21', 'sampleModel22', 'sampleModel23', 'sampleModel24', 'sampleModel25', 'sampleModel26', 'sampleModel27', 'sampleModel28', 'sampleModel3', 'sampleModel30', 'sampleModel31', 'sampleModel32', 'sampleModel33', 'sampleModel34', 'sampleModel35', 'sampleModel37', 'sampleModel38', 'sampleModel39', 'sampleModel4', 'sampleModel40', 'sampleModel41', 'sampleModel42', 'sampleModel44', 'sampleModel45', 'sampleModel46', 'sampleModel47', 'sampleModel48', 'sampleModel49', 'sampleModel5', 'sampleModel50', 'sampleModel51', 'sampleModel52', 'sampleModel53', 'sampleModel54', 'sampleModel55', 'sampleModel56', 'sampleModel57', 'sampleModel58', 'sampleModel59', 'sampleModel6', 'sampleModel60', 'sampleModel61', 'sampleModel62', 'sampleModel63', 'sampleModel64', 'sampleModel65', 'sampleModel66', 'sampleModel67', 'sampleModel68', 'sampleModel69', 'sampleModel7', 'sampleModel70', 'sampleModel71', 'sampleModel72', 'sampleModel74', 'sampleModel75', 'sampleModel76', 'sampleModel77', 'sampleModel78', 'sampleModel79', 'sampleModel8', 'sampleModel80', 'sampleModel81', 'sampleModel82', 'sampleModel83', 'sampleModel84', 'sampleModel85', 'sampleModel86', 'sampleModel87', 'sampleModel89', 'sampleModel9', 'sampleModel90', 'sampleModel91', 'sampleModel92', 'sampleModel94', 'sampleModel95', 'sampleModel97', 'sampleModel98', 'sampleModel99'};
        
        mc_complex_e = { 'EXTENSION1',  'EXTENSIONnewwithfuzzy',  'EXTENSIONwithfuellcell', 'Detailed_PMSG_one_machine', 'microgrid_Finalcircutperfect', 'Three_Phase_ACDCAC_PWMconverter',...
            'HVDC_system', 'LF_AC29bus_HVDCdemo_V2_1'};
        
        mc_complex = {'OSWEC',    'RM3','sldemo_drivecycle', 'VU_lineFollow',  'VU_lineFollow1',  'VU_lineFollow1b',  'VU_lineFollow2',  'VU_motorSpdCtrl',  'VU_testBtTxRx',  'VU_testSoundTone1',  'VU_testSoundTone2',  'VU_testSoundTone3',  'VU_testUsbTxRx',  'VU_NXTWay',  'VU_NXTWay_Simple',...
            'DFIGPI_by_indraneel_saki',  'connectwithoutmech_by_indraneel_saki',  'windturbinemod', 'complex_multiply_example',  'downsample_upsample_example',  'enabled_subsystem_example',  'fir_filter_example',  'stateflow_example',  'sync_subsystem_example',  'view_wave_example',...
            'rev_pow_ckt_new4',  'OCR', 'ssc_Probes_test_all_16b',  'ssc_dc_motor',  'ssc_three_phase', 'Dual_Clutch_Trans', 'Vehicle_Dynamics_Testrig',  'Dual_Clutch_Trans_SDO',...
            'Vehicle_Dynamics_Tests', 'bad_idea',  'motion_example1',  'motion_example2',  'motion_example3',  'ref4_rt',  'ref4_xy',...
            'ab',  'AircraftB', 'ACTimeOvercurrentRelayBlock', 'quad_control', 'HPW', 'FDI_SVM_WT',  'FDI_measures', 'MAXPID_modelisation_multi_physique_MATLAB_2015a_Ivan_Liebgott',...
            'singele_phase_to_3phase_svpwm_IM', 'EXTENSION', 'Actuated_Pioneer3DXAssembly',  'Controller_Pioneer3DXAssembly',  'MotionConstraints_Pioneer3DXAssembly',  'Pioneer3DXAssembly',  'SL3DAnim_Pioneer3DXAssembly',  'main_demo_real_robot',...
            'HEV_SeriesParallel',  'HEV_Battery_Testrig_v1',  'HEV_Battery_Testrig_v2',  'Engine_Testrig', 'PV_panel', 'PVarray_Grid_IncCondReg_det',  'PVarray_Grid_PandO_avg',...
            'Wind_Turbine', 'Wind_Turbine_Flexible_Blades', 'Wind_Testrig', 'Geartrain_Testrig', 'Generator_Testrig', 'Turbine_State_Machine_Testrig', 'Pitch_Control_Ideal_Testrig', 'Yaw_Gearbox_Testrig',...
            'Wind_PMSG', 'youBot_Arm',  'youBot',  'youBot_damping', 'youBot_STEP_URDF', 'main1', 'inverter_pwm2', 'singele_phase_to_3phase_svpwm_IM_VF_PI', 'IM', ...
            'ssc_lithium_battery_1CellMultiplied',  'ssc_lithium_battery_80Cells',  'ssc_lithium_cell_1RC',  'ssc_lithium_cell_1RC_estim',  'ssc_lithium_cell_2RC', 'pvwindupfc11', 'Buck_PWM',  'zerocross', 'mybldc_mdl2', 'CONTROLLER_MOD',  'changer',  'cont_lower',  'cont_modifed',...
            'LLR_equivalent', 'UPFC_1', 'microturbine_rectifierconverter', 'VFT',...
            'hyperloop_arc',  'sl2ge_hyperloop',...
            'ec_concept',  'ec_datadict_buses',  'ec_fixed_config_subsys',  'ec_fixed_eml_simple',  'ec_fixed_lct_tb1',  'ec_fixed_packngo',  'ec_fixed_slm_16bit_tb1',  'ec_fixed_slm_hardcode',  'ec_fixed_slm_structures',  'ec_fixed_slm_verify',  'ec_fixed_slm_with_bypass',  'ec_fixed_slm_with_bypass_reset',  'ec_fixed_slp_brute_force',  'ec_fixed_slp_fb_better',  'ec_fixed_slp_sb',  'ec_fixed_slp_sb_autoscaled',  'ec_fixed_slp_sb_with_mask',  'ec_single_vs_fixed',  'ec_single_vs_fixed_autoscale',  'ec_single_vs_fixed_old',  'ec_using_config',...
            'BackgroundEst',  'OpticalFlow',  'vipabandonedobj_bayer_abstract',  'Pre_SysGen_Post_embedded',  'vipabandonedobj_bayer_1800_frames',  'vipabandonedobj_bayer_1800_noframes',  'vipabandonedobj_bayer_3400_frames',  'vipabandonedobj_bayer_ml506_frames',  'Pre_SysGen_Post_sh_fifo_nohwcs',  'vipabandonedobj_bayer_hwcs_noframes',  'vipabandonedobj_bayer_hwcs_replaced_inputs',  'vipabandonedobj_bayer_hwcs_replaced_inputs_outputs',  'vipabandonedobj_bayer_sg',...
            };
        
        
        mc_simple = {'lorenz3d',  'm3dscope_new',  'm3dscope_old', 'serialRunOnPC', 'serialRunOnArduino', 'my_model',...
            'SimpleBounce',  'sim1',  'sim_tutorial',  'sim_tutorial2',  'sim_tutorial3',  'simrotor1',  'simrotor3a',  'statetest',...
            'realtime_pacer_example', 'dcIntrocomplete'}
        mc_rest = {'PDQuadrotor', 'GearSelect_Testrig', 'PV_MPPT', 'PV_model_Param', 'PV_module'}
        
        % For some models to compile, we need to run some scripts
        scripts_to_run = {};
%         scripts_to_run = {'InitializeCSTHDisturbedStdOp1', 'InitializeCSTHDisturbedStdOp2', 'install_3dscope', 'startup_DCT_Model', 'Machine_Parameters_new'};
        
        mc_simple_lina = {'blink_challenge_sch', 'blink_challenge_sf', 'blink_led_sim', 'encoder_sim', 'motor_sim', 'servo_sim', 'stepper_sim', 'Driver_Speed_Test', 'LEGO_NXT_M1V4_Closed_Loop_DC_Motor_Position_Control', 'LEGO_NXT_M1V4_Motor_Step_Response', 'LEGO_NXT_M2V3_Closed_Loop_DC_Motor_Position_Control', 'LEGO_NXT_M2V3_Motor_Step_Response', 'LEGO_NXT_MSM_Closed_Loop_DC_Motor_Position_Control', 'LEGO_NXT_MSM_Motor_Step_Response', 'Maxon_M1V4_Motor_Step_Response', 'Maxon_M2V3_Motor_Step_Response', 'Maxon_MSM_Motor_Step_Response', 'MinSegMega_Demo_V2', 'MinSegNano_Demo', 'MinSegPro_Demo', 'MinSegShield_Demo_M1V4', 'MinSegShield_Demo_M1V4_UNO', 'MinSegShield_Demo_M1V5', 'MinSegShield_Demo_M2V3', 'PandO', 'mod_ref_root', 'myarduino_LCD_LED', 'myarduino_UART_basic', 'myarduino_blink', 'myarduino_blink2', 'myarduino_blink2_PIL', 'myarduino_blink2_leonardo', 'myarduino_blink_ExtMode_mega2560', 'myarduino_blink_double', 'myarduino_blink_double_leonardo', 'myarduino_blink_expander', 'myarduino_blink_micros_UART', 'myarduino_blink_sr04', 'myarduino_blink_sr04_LCD_printf', 'myarduino_blink_uart', 'myarduino_empty', 'myarduino_extint', 'myarduino_extint_test', 'myarduino_extint_test2', 'myarduino_extint_test_manageTimer', 'myarduino_hc04_test', 'myarduino_i2c_master', 'myarduino_i2c_slave', 'myarduino_performance_test', 'myarduino_servo', 'myarduino_stairs_uart', 'myarduino_uart_in', 'myarduino_varaible_blink', 'myarduino_varaible_blink_leonardo', 'realtime_pacer_example', 'encoder_slsp', 'encoder_slsp_mega', 'input_slsp', 'output_slsp', 'output_slsp_masked', 'aout_eml', 'din_eml', 'dio_eml', 'dout_eml', 'enc_eml', 'encaout_eml', 'aout_lct', 'din_lct', 'dio_lct', 'dout_lct', 'enc_lct', 'encaout_lct', 'analog_output_arduino_test', 'analog_output_raspi_test', 'digitalio_arduino_test', 'digitalio_raspi_test', 'digitalwrite_arduino_test', 'encoder_arduino_test', 'encoder_raspi_test', 'source_sink_test', 'arduinouno_gettingstarted', 'arduinouno_servocontrol_potentiometer', 'arduinouno_servocontrol_sweep', 'sys6', 's1eig', 'cs3', 's1a', 's1b', 's1c', 'smg', 's4eig', 's4stp', 's3a', 's3b', 's1c', 'Driver_Glider', 'PTB_GliderModel', 'Geneva_Drive_imported', 'Collision_01_Ball_Infinite_Plane', 'Geneva_Drive_imported', 'Collision_01_Ball_Infinite_Plane', 'Geneva_Drive_imported', 'Collision_01_Ball_Infinite_Plane', 'ASK', 'BPSK', 'OOK', 'cppll', 'dpll', 'dpll_fixpt', 'linearpll', 'BasicQuadRotor', 'Blade', 'CascadeControl_DCmotor', 'Motor_Param_Est', 'Simple_Blade', 'smc_mass_1d', 'fig2_18', 'fig2_19ax', 'fig2_19bx', 'fig8_08', 'fig8_10a', 'fig2_17', 'PMSM_speed', 'blink_challenge_sch', 'blink_challenge_sf', 'blink_led_sim', 'encoder_sim', 'motor_sim', 'servo_sim', 'stepper_sim', 'DC_Motor_Model', 'SVMph3', 'host_rx', 'DC_Motor_Fuzzy', 'logger', 'anndemo', 'Control_Design_PID', 'EmbeddedOpenLoop', 'Host_serial_final', 'Host_serial_final_MATLAB', 'EmbeddedClosedLoop_Ard', 'moveMotor', 'IMU_Serial_Example', 'myo_sfun_one_myo_imu', 'myo_sfun_one_myo_imu_emg'};
        mc_complex_lina = {'blink_challenge_sim', 'MICROGRID_PV_Wind', 'Solar_MPPT_Resistaince_load', 'power_HEV_powertrain', 'IEEE_9bus_new_o', 'arduinouno_drive_closedloop', 'arduinouno_drive_openloop', 'anfismicrogrid', 'simple_svpwm', 'BLDC_speed_control', 'mpptir9', 'fuzzytriangular15', 's1', 's2', 's2eig', 's3', 's3eig', 's3g', 's3geig', 's4', 's5', 's1', 's2', 's3', 's4', 's2', 's4', 's2', 's3', 's1', 's5a', 's5b', 's6', 's1', 's3', 's3eig', 's4', 's5', 's1', 's2', 's4', 's5', 's1o', 's2c', 's2o', 's3', 'BatteryChargeControl', 'direct_torque_control', 'BEV', 'ConventionalVehicle', 'PTB_BatteryElectricVehicle', 'PTB_ConventionalModel', 'Cam_Follower', 'Belts_01_Two_Belts', 'Geneva_Drive', 'Collision_02_Disk_Finite_Plane_Fixed', 'Collision_03_Disk_Finite_Plane_Spin', 'Collision_04_Disks_in_Box', 'Collision_05_Disk_in_Ring', 'Collision_06_Catapult', 'Collision_07_Ball_Finite_Plane_Float', 'Collision_08_Compare_Forces', 'Friction_01_Box_on_Ramp_Constraint', 'Friction_02_Box_on_Ramp', 'Friction_03_Double_Pendulum_Constraint', 'Friction_04_Disk_Rolling_on_Ramp', 'Friction_05_Beam_on_Wheel', 'Friction_06_Disk_on_Disk', 'Friction_07_Floating_Disks', 'Friction_08_Disks_and_Ring', 'Friction_09_Ring_on_Disk_Float', 'Friction_10_Ball_on_Wheel', 'Spinning_Boxes', 'Gripper_2Belts', 'Robot_2_Whl', 'Coll3D_01_Ball_Plane_Fixed', 'Coll3D_02_Ball_Plane_Spin', 'Coll3D_03_Balls_in_Box', 'Coll3D_04_Ball_in_Tube_Fixed', 'Coll3D_05_Ball_Peg_Board', 'Coll3D_06_Ball_in_Ball', 'Coll3D_07_Balls_and_Sliding_Tube', 'Coll3D_08_Ball_in_Spinning_Cone', 'Frict3D_01_Box_on_Table', 'Frict3D_02_Ball_on_Table', 'Frict3D_03_Board_on_Balls', 'Frict3D_04_Ball_on_Ball', 'Frict3D_05_Tube_on_Balls', 'Frict3D_06_Ball_on_Balls', 'Frict3D_07_Ball_in_Ball', 'Cam_Follower', 'Belts_01_Two_Belts', 'Geneva_Drive', 'Collision_02_Disk_Finite_Plane_Fixed', 'Collision_03_Disk_Finite_Plane_Spin', 'Collision_04_Disks_in_Box', 'Collision_05_Disk_in_Ring', 'Collision_06_Catapult', 'Collision_07_Ball_Finite_Plane_Float', 'Collision_08_Compare_Forces', 'Friction_01_Box_on_Ramp_Constraint', 'Friction_02_Box_on_Ramp', 'Friction_03_Double_Pendulum_Constraint', 'Friction_04_Disk_Rolling_on_Ramp', 'Friction_05_Beam_on_Wheel', 'Friction_06_Disk_on_Disk', 'Friction_07_Floating_Disks', 'Friction_08_Disks_and_Ring', 'Friction_09_Ring_on_Disk_Float', 'Friction_10_Ball_on_Wheel', 'Spinning_Boxes', 'Gripper_2Belts', 'Robot_2_Whl', 'Coll3D_01_Ball_Plane_Fixed', 'Coll3D_02_Ball_Plane_Spin', 'Coll3D_03_Balls_in_Box', 'Coll3D_04_Ball_in_Tube_Fixed', 'Coll3D_05_Ball_Peg_Board', 'Coll3D_06_Ball_in_Ball', 'Coll3D_07_Balls_and_Sliding_Tube', 'Coll3D_08_Ball_in_Spinning_Cone', 'Frict3D_01_Box_on_Table', 'Frict3D_02_Ball_on_Table', 'Frict3D_03_Board_on_Balls', 'Frict3D_04_Ball_on_Ball', 'Frict3D_05_Tube_on_Balls', 'Frict3D_06_Ball_on_Balls', 'Frict3D_07_Ball_in_Ball', 'Cam_Follower', 'Belts_01_Two_Belts', 'Geneva_Drive', 'Collision_02_Disk_Finite_Plane_Fixed', 'Collision_03_Disk_Finite_Plane_Spin', 'Collision_04_Disks_in_Box', 'Collision_05_Disk_in_Ring', 'Collision_06_Catapult', 'Collision_07_Ball_Finite_Plane_Float', 'Collision_08_Compare_Forces', 'Friction_01_Box_on_Ramp_Constraint', 'Friction_02_Box_on_Ramp', 'Friction_03_Double_Pendulum_Constraint', 'Friction_04_Disk_Rolling_on_Ramp', 'Friction_05_Beam_on_Wheel', 'Friction_06_Disk_on_Disk', 'Friction_07_Floating_Disks', 'Friction_08_Disks_and_Ring', 'Friction_09_Ring_on_Disk_Float', 'Friction_10_Ball_on_Wheel', 'Spinning_Boxes', 'Gripper_2Belts', 'Robot_2_Whl', 'Coll3D_01_Ball_Plane_Fixed', 'Coll3D_02_Ball_Plane_Spin', 'Coll3D_03_Balls_in_Box', 'Coll3D_04_Ball_in_Tube_Fixed', 'Coll3D_05_Ball_Peg_Board', 'Coll3D_06_Ball_in_Ball', 'Coll3D_07_Balls_and_Sliding_Tube', 'Coll3D_08_Ball_in_Spinning_Cone', 'Frict3D_01_Box_on_Table', 'Frict3D_02_Ball_on_Table', 'Frict3D_03_Board_on_Balls', 'Frict3D_04_Ball_on_Ball', 'Frict3D_05_Tube_on_Balls', 'Frict3D_06_Ball_on_Balls', 'Frict3D_07_Ball_in_Ball', 'FSK', 'QPSK', 'PV15kw', 'PMSM_DRIVES_SIMULATION', 'powerpll', 'DFIG_Basics', 'QUADROTOR', 'Quadrotor_Controller', 'inverter_SVM4', 'microgridwithMICukdc_dcby_indraneel_saki', 'Battery_Charging_Discharding_model', 'MLIunequalDCsources', 'quadrotorsim', 'hybridPV_FUELCELL', 'microgridwithmicrturbine', 'microgridwithwind', 'Buck_Boost', 'blink_challenge_sim', 'c28027pmsmfoc', 'c28027pmsmfoc_ert', 'SAPF', 'MPPT_charger_V2', 'SPWMinverter3P_Final', 'BLDC_PI', 'boostr', 'Tariq', 'simple_wind_turbine_pmsg', 'nxtway_gs', 'nxtway_gs_controller_fixpt', 'nxtway_gs_vr', 'pndo', 'finalmodel15_10', 'se_filter', 'myo_sfun_one_myo_imu_visualization', 'myo_sfun_two_myo_imu', 'Simulink_serial_example', 'IEEE80211a', 'IEEE80211a_NoSF', 'IEEE80211a', 'boostspi'};
    
        mc_simple_lina3 = {    'optsim1', 'OFDM_64QAM_R14', 'arduinomega2560_communication', 'arduinomega2560_gettingstarted', 'arduinomega2560_servocontrol_potentiometer', 'arduinomega2560_servocontrol_sweep', 'Digital_Out_SFunction_Example', 'autotunerPID', 'steppidsupport', 'kalmanfilter', 'CONTROLLER_MOD', 'CONT_CORE', 'CONT_MOD', 'IC', 'NEW_CONTROLLER', 'SET1', 'SET2', 'SET3', 'all_phase', 'all_phase_inv', 'changer', 'cont_lower', 'cont_modifed', 'deg_120_trig', 'error_gen', 'estimate', 'ind_trig', 'inital', 'threshold_single', 'zerocross', 'OFDM_4QAM', 'inpguitest', 'opguitest', 'rpi_driver_blocks', 'MathModel_Boost_Subsys_ClosedLoop', 'Simulink_1', 'Simulink_10', 'Simulink_2', 'Simulink_3', 'Simulink_4', 'Simulink_5', 'Simulink_6', 'Simulink_7', 'Simulink_8', 'Simulink_9', 'nid_cvst_depth', 'nid_cvst_image', 'nid_cvst_ir', 'nid_cvst_motion', 'nid_cvst_point_cloud', 'nid_cvst_skeleton', 'nid_cvst_what_is_nid', 'nid_depth', 'nid_motion', 'nid_skeleton_eML', 'nid_sl', 'nid_cvst_color_in_motion', 'nid_cvst_depth', 'nid_cvst_image', 'nid_cvst_ir', 'nid_cvst_kinect_sdk_sensor_angle', 'nid_cvst_motion', 'nid_cvst_multi_instance_device', 'nid_cvst_point_cloud', 'nid_cvst_skeleton', 'nid_cvst_skeleton2', 'nid_cvst_what_is_nid', 'nid_cvst_what_nid_see', 'nid_spb_cvst_kinect_sdk_what_is_nid', 'spb_kinect_sdk_audio', 'nid_cvst_corner_detection', 'nid_cvst_pattern_tracking', 'bot_demo', 'pv_cell_model', 'RC_Demo_CAN_Host'};
        mc_complex_lina3 = {    'boost_close_loop', 'Assembly_Quadrotor', 'power_measurement', 'arduinomega2560_drive_closedloop', 'arduinomega2560_drive_openloop', 'CPYQPC', 'abc123ca', 'mybldc_mdl2', 'PMSM_SMO', 'Boost_Circuit_Subsys_ClosedLoop', 'CC_CV_Charger', 'nid_skeleton_SL', 'hybridPVWind', 'Inverter1', 'pv_array', 'pv_cell_effect_of_varying_Rs', 'pv_cell_effect_of_varying_Rsh', 'pv_cell_effects_of_solar_radiation', 'pv_cell_effects_of_temp', 'pv_cell_effects_of_varying_Is', 'RC_Demo_C2000_Control_Unit', 'mpptmodel_newtest'};
        
        sf_simpe = {    'create_rc_params_Preq', 'sim_validate_rint', 'bd_btyrc', 'bd_ess_test', 'CompareSims', 'bd_dynamiccomparesims', 'BD_INTERACTIVE_REPLAY', 'BD_ess_test2', 'customsaberdemo', 'CameraMotion', 'ObjectImaging', 'aeropropmodel', 'oloop3', 'oloop3a', 'Competition', 'imageStreamJoystick', 'imageStreamKeyboard', 'modelKeyboard', 'modelSquare', 'fwiine_example', 'iir', 'canon', 'RTex', 'example', 'grampc_R2013a', 'grampc_R2016b', 'grampc_R2013a', 'grampc_R2016b', 'grampc_R2013a', 'grampc_R2016b', 'grampc_R2013a', 'grampc_R2016b', 'grampc_R2013a', 'grampc_R2016b', 'grampc_R2013a', 'grampc_R2016b', 'grampc_R2013a', 'grampc_R2016b', 'grampc_R2012a', 'grampc_R2013a', 'grampc_R2016b', 'grampc_R2010a', 'new_mod', 'TST_EnumTypes', 'TST_EnumTypesStateflow', 'TST_ArraySelectors', 'TST_BusCreatorForwardOptimization', 'TST_InterpolationAndLookup', 'TST_LogicOperations', 'TST_StateflowBitOperations', 'TST_StateflowDefaultTransitionCondition', 'TST_BusSelectorProblem', 'TST_DuringActionTest', 'TST_InnerTransition', 'TST_SfVariableInputTest', 'TST_DoorsRequirements', 'TST_DoorsRequirementsWithSurrogate', 'TST_WordRequirements', 'TST_SfFunctionWithBusTypes', 'TST_StateflowHistoryJunction', 'TST_AdvancedStateflowLoops', 'TST_AdvancedStateflowLoops2', 'TST_AdvancedStateflowLoops3', 'TST_AdvancedStateflowLoops4', 'TST_StateflowLoops', 'TST_HelloWorldModel'};
        sf_complex = {    'KTH_103002', 'create_rc_params', 'sim_validate_rc', 'FuelCellWorkBench', 'MC_PB_ESS3', 'advisor_ess_options', 'ess_adapt_cs', 'fuelcell_adapt_cs', 'BD_DynamicCompareSims2', 'BD_CONV', 'BD_CONV2', 'BD_CONVAT', 'BD_CONVCVT', 'BD_EV', 'BD_FUELCELL', 'BD_FUZZY_EMISSIONS', 'BD_INSIGHT', 'BD_PAR', 'BD_PAR_AUTO', 'BD_PAR_CVT', 'BD_PAR_SA', 'BD_PAR_SA_AUTO', 'BD_PAR_SimplorerDemo', 'BD_PAR_saber_cosim', 'BD_PRIUS_JPN', 'BD_PTH', 'BD_SER', 'BD_SER2', 'BD_SER_saber_cosim', 'bd_par_auto2', 'bd_ser_elect_cosim', 'fc_KTH_lib_init', 'HYBVS', 'IBVS', 'IBVS3Dp', 'IBVSendeff', 'IBVSeq', 'IBVShandcoded', 'IBVSstereo', 'IBVStrack', 'PBVS', 'beaver', 'apilot1', 'apilot2', 'apilot3', 'pah', 'pahrah', 'rah', 'oloop1', 'oloop1a', 'oloop2', 'fullModelJoystick', 'fullModelKeyboard', 'gamingJoystick', 'gamingKeyboard', 'modelJoystick', 'controlledsystem'};
    
        sf_other_1 = {    'ADC_DAC', 'AD_9S12', 'AD_stepper_simulation_all', 'BLNoiseTest', 'ChirpTest', 'DAC', 'DigINPort', 'DigOUTPort', 'FreePortComm_RXTX', 'FreePortComm_RXTX_noExt', 'FreePortComm_RXTX_noExt2', 'FreePortComm_RX_7Seg_MiniDragon', 'FreePortComm_RX_simple', 'FreePortComm_RX_simple2', 'FreePortComm_RX_simple3', 'FreePortComm_RX_simple4', 'FreePortComm_RX_simple_test', 'FreePortComm_TXRX', 'FreePortComm_TXRX_noExt', 'FreePortComm_TXRX_noExt2', 'FreePortComm_TX_counter', 'FreePortComm_TX_simple', 'FreePortComm_TX_simple2', 'FreePortComm_TX_simple3', 'FreePortComm_TX_simple4', 'FreePortComm_TX_simple_test', 'Fuzzy_2i1o', 'Fuzzy_3i1o', 'InterModel_RX', 'InterModel_TX', 'Onboard_DAC_Dragon12RevE', 'PWM', 'PWM2', 'PWM2_pc', 'PWM3', 'PWM_and_Servo', 'RFCcliRX', 'RFCcliRXTX_formtd_noExt', 'RFCcliRX_PTH_client1', 'RFCcliRX_PTH_client1_RF13', 'RFCcliRX_PTH_client1_formtd', 'RFCcliRX_PTH_client2', 'RFCcliRX_PTH_client3', 'RFCcliRX_PTH_client4', 'RFCcliRX_PTH_client5', 'RFCcliRX_freePort0_5', 'RFCcliRX_freePort0_5_formtd_PC', 'RFCcliRX_freePort0_5_formtd_noExt', 'RFCcliRX_freePort0_5x2_formtd_PC', 'RFCcliRX_freePort0_5x2_formtd_noExt', 'RFCcliTX_noExt', 'RFComm_server_TX_freePort0', 'RFCsvrRXTX_formtd_noExt', 'RFCsvrRX_noExt', 'RFCsvrTX_counter', 'RFCsvrTX_counter_5clients_noExt', 'RFCsvrTX_counter_formtd_noExt', 'RFCsvrTX_freePort0_5', 'RFCsvrTX_freePort0_5_formtd', 'RFCsvrTX_freePort0_5_formtd_noExt', 'RFCsvrTX_freePort0_5x2_formtd_noExt', 'RFCsvrTX_freePort0_noExt', 'Robot', 'Robot_pc', 'Servo_PWM', 'SimpleModel', 'Sonar', 'SpeedControl', 'SpeedControl_PWM', 'SysID', 'SysID_RGS', 'Timer', 'Timer_IC', 'Timer_OC', 'Timer_OC_2', 'TogPort', 'TogPortNoComms', 'atest', 'borrar', 'borrar_MiniDragon', 'ex3_1', 'f14', 'test', 'testBCIRobot', 'testBCIRobot3a', 'testBCIRobotCommsRX', 'testBCIRobotCommsRX_noExtMode', 'testMiniDragonDisplay', 'test_PC', 'vdp'};
        sf_other_2 = {    'deadlock', 'deadlock2', 'AD_Stepper', 'AD_Stepper_Simulation', 'Shaker_Driver_sysID2', 'ex3_2', 'shower', 'testBCIRobot2', 'testBCIRobot3', 'testBCIRobot3b', 'testBCIRobot3c', 'testBCIRobot3d', 'testBCIRobot3e', 'testBCIRobot3e_ext', 'testBCIRobot3e_sim', 'testBCIRobot3f_ext', 'testBCIRobot3f_sim', 'testBCIRobot3g_ext'};
    end
    
    methods
        
        function obj = analyze_complexity_cfg()
            obj.populate();
            
            obj.bp_render = zeros(analyze_complexity.NUM_METRICS);
            % Set true to those metrics which you wish to render
            obj.bp_render(analyze_complexity.METRIC_COMPILE_TIME) = true;
        end
        
        function obj = populate(obj)
            % Lists which models we want to analyze, in various groups.
            
            % Tutorial Models
            examples_a = {'sldemo_fuelsys', 'sldemo_auto_climatecontrol', 'sldemo_autotrans', 'sldemo_auto_carelec', 'sldemo_suspn', 'sldemo_auto_climate_elec',...
                'sldemo_absbrake', 'sldemo_enginewc', 'sldemo_engine', 'sldemo_fuelsys_dd', 'sldemo_clutch', 'sldemo_clutch_if'};
            examples_b = {'aero_guidance', 'sldemo_radar_eml', 'aero_atc', 'slexAircraftPitchControlExample', 'aero_six_dof', 'aero_dap3dof',...
                'slexAircraftExample', 'aero_guidance_airframe'};
            examples_c = {'sldemo_antiwindup', 'sldemo_pid2dof', 'sldemo_bumpless'};
            examples_d = {'aeroblk_wf_3dof', 'asbdhc2', 'asbswarm', 'aeroblk_HL20', 'asbQuatEML', 'aeroblk_indicated', 'aeroblk_six_dof',...
                'asbGravWPrec', 'aeroblk_calibrated', 'aeroblk_self_cond_cntr',};
            examples_e = {'sldemo_mdlref_variants_enum', 'sldemo_mdlref_bus','sldemo_mdlref_conversion','sldemo_mdlref_counter_datamngt','sldemo_mdlref_dsm','sldemo_mdlref_dsm_bot','sldemo_mdlref_dsm_bot2','sldemo_mdlref_F2C'};

%             obj.examples = {'sldemo_mdlref_variants_enum', 'sldemo_mdlref_bus','sldemo_mdlref_conversion','sldemo_mdlref_counter_datamngt'};
            obj.examples = [examples_a, examples_b, examples_c, examples_d, examples_e];
            
            % Research
            
            research_a = {'Blending_Challenge', 'CSTHDisturbedStdOp1', 'CSTHDisturbedStdOp2', 'wind_turbine2'};
            research_b = {'fir8_03', 'fir12_03', 'pct_03', 'pid_03', 'pid_02', 'fir16tap', 'iir_biquad', 'pct', 'ACS', 'ALS',...
                'Boiler_MIMOControl_PID12', 'Boiler_SISOControl_PID12', };
            research_c = {'benchmark_no_taylor', 'benchmark'};
            research_d = {'slsf_buck', 'flyback_openloop', 'forward_conv', 'forward_conv_hyst', 'fwr', 'buck_hvoltage2', 'pll'};
%             research_e = {'AbstractFuelControl_M1', 'AbstractFuelControl_M2', 'AbstractFuelControl_M3'};
            research_f = {'SimplifiedWTModel', 'testHarness', 'AbstractFuelControl_M1_Aquino'};
            
            obj.research = [research_a, research_b, research_c, research_d research_f, obj.sf_other_1, obj.sf_other_2];
            
%             obj.research = research_e;
            
            % Temporary groups for simple and advanced category
            
            gh_a = {'AC_Quadcopter_Simulation', 'PC_Quadcopter_Simulation', 'Team37_Quadcopter_Simulation'};
            gh_b = {'GasTurbine_Dyn_Template', 'Plant_GasTurbine', 'GasTurbine_SS_Template', 'JT9D_Model_Dyn', 'JT9D_Model_SS', 'JT9D_SS_Cantera_Template', ...
                'NewtonRaphson_Equation_Solver', 'TTECTrA_example', 'qpsktxrx', 'ModeS_FixPt_Pipelined_ADI', 'ModeS_Simulink_libiio', 'JT9D_Model_Lin',  'JT9D_Model_PWLin'};
            gh_c = {'fourBar', 'hackrf_simple_tx_demo', 'hackrf_spectrum_scope_demo', 'HEV', 'motorcontroller'};
            gh_d = { 'ATWS',  'DCMotor',  'DEVICE1',  'LQR',  'OCA_2_Prop',  'OCA_SUB',  'OCA_SUB_modified',  'Orientation',  'PID',  'PR9',  'QTM2SI',  'Transmitter',  'XC',  'aa',  'analogicalgates',  'bianpinx1',  'danxiangjiangya',  'danxiangtiaoya',  'demostration09',  'demostration1',  'enginecontroller',  'feedforward1',  'feedforward2',  'jieyue',  'measurement',  'modello',  'nibian',  'pdcontrol',  'picpicpic',  'pidmodel',  'powercontroller',  'prog2',  'proj',  'quadtestmodel',  'rasberry',  'rester',  'robotjointmodel',  'shengyazhanbo',  'simone',  'simulation',  'test',  'testmodel',  'transmissioncontroller',  'u2pwm',  'untitled1_slx',  'vehiclecontroller',  'zh2fsk',  'zhengliu',  'Ackermann',  'Arrays1',  'Arrays2',  'Arrays3_0',  'Arrays3_1',  'Counter_with_prop',  'CruiseControl3',  'Early1',  'Events1',  'Events2',  'Events3',  'Events3Out',  'Events4',  'Events5',  'Events6',  'Events7',  'Flowchart1',  'Flowchart10',  'Flowchart2',  'Flowchart3',  'Flowchart4',  'Flowchart5',  'Flowchart6',  'Flowchart7',  'Flowchart8',  'Flowchart9',  'GraphFun1',  'Hierarchy1',  'Hierarchy2',  'Hierarchy3',  'Hierarchy4',  'History1',  'Iek1',  'Iek2',  'Inner1',  'Inner2',  'Inner3',  'Inner4',  'Junctions1',  'Junctions2',  'Junctions3',  'Junctions4',  'Junctions5',  'Junctions6',  'Junctions7',  'Junctions8',  'Junctions9',  'Loops1',  'Loops10',  'Loops2',  'Loops3',  'Loops4',  'Loops5',  'Loops6',  'Loops7',  'Loops8',  'Loops9',  'Nonterm1',  'On1',  'Outer1',  'Parallel1',  'Parallel2',  'Parallel3',  'Parallel4',  'Parallel5',  'ROSACE_VA_control',  'ROSACE_VA_control_simu',  'SetReset',  'SetResetOut',  'SetResetWait',  'SetResetWaitOut',  'SfSecurity',  'Single1',  'Stopwatch1',  'Stopwatch2',  'Subsys1',  'Super1',  'Super10',  'Super11',  'Super12',  'Super13',  'Super2',  'Super2Out',  'Super3',  'Super4',  'Super5',  'Super6',  'Super7',  'Super8',  'Super9',  'Temporal1',  'Twochart1'  };

            obj.simple = [obj.mc_simple, obj.mc_simple_lina3, gh_d, obj.mc_simple_lina, obj.sf_simpe];
            obj.complex = [obj.mc_complex_lina3, obj.mc_complex_e, obj.mc_rest, obj.mc_complex, gh_a, gh_b, gh_c, obj.mc_complex_lina, obj.sf_complex];
            
        end
    end
    
    methods(Static)
        
        function get_cf_models()
            target_dir = 'success';
            cur_path = ['publicmodels' filesep 'collection' filesep target_dir]
            addpath(genpath(cur_path));
            
            slx_files = dir([cur_path filesep 'sampleModel*.slx']);
            for i=1:numel(slx_files)
                x = strsplit(slx_files(i).name, '.slx');
                assert(numel(x) == 2)
                fprintf('''%s'', ', x{1});
%                 all_files.add(x{1});
            end
            fprintf('\n');
        end
        
        function all_files = get_local_models(exp_date)
            target_dir = 'success';
            cur_path = ['reportsneo' filesep exp_date filesep  target_dir]
            addpath(genpath(cur_path));
            
            all_files = mycell();
            
            slx_files = dir([cur_path filesep 'sampleModel*.slx']);
            for i=1:numel(slx_files)
                x = strsplit(slx_files(i).name, '.slx');
                assert(numel(x) == 2)
%                 fprintf('''%s'', ', x{1});
                all_files.add(x{1});
            end
%             fprintf('\n');
        end
        
        function ret = get_models(loc, prelist)
            
            CHECK_LIB_END = true;   % Checks whether a model name ends with the lib i.e. it's a suffix
            CHECK_BLOCK_COUNT = false;
            CHECK_CHILDREN = false;
            
            ret = struct;
            
            if nargin == 1
                prelist = [];
            end
            
            block_count_threshold = 1;
            
            base_dir = 'publicmodels';
            full_loc = [base_dir filesep loc];
            
            
            all_files = mycell();
            children = mymap();
            final_ret = mycell();
            simples = mycell();
            tests = mycell();
            libs = mycell();
            name_conflicts = mycell();
            model_path = mymap();  
            
            addpath(genpath(full_loc));
            
            all_path = genpath(full_loc);
            all_path=  strsplit(all_path, ';');
            
            lib_suffix = "lib";
            
            function ret = is_customlib(x, foldername)
                ret = false; % Caution: Only for lib and models not openable. Test status does not affect this value.
                assert(numel(x) == 2)
                
                if model_path.contains(x{1})
                    name_conflicts.add(x{1});
                else
                    model_path.put(x{1}, foldername);
                end
                
                
                try
                    open_system(x{1});
                catch
                    ret = true;
                    return;
                end
                
                if bdIsLibrary(x{1})
                    libs.add(x{1});
                    ret = true;
                elseif util.starts_with(x{1}, 'Lib_') || util.starts_with(x{1}, 'lib_') || util.starts_with(x{1}, 'library') || util.starts_with(x{1}, 'Library')
                    libs.add(x{1});
                    ret = true;
                elseif CHECK_LIB_END && endsWith(x{1}, lib_suffix, 'IgnoreCase',true)
                    libs.add(x{1});
                    ret = true;
                elseif contains(x{1}, 'library', 'IgnoreCase',true)
                    libs.add(x{1});
                    ret = true;
                elseif contains(x{1}, 'libraries', 'IgnoreCase',true)
                    libs.add(x{1});
                    ret = true;
                
                end
                
                if contains(x{1}, 'test', 'IgnoreCase',true)
                    tests.add(x{1});
                end
                
                try
                    close_system(x{1});
                catch
                end
            end
            
            for a_i = 1:numel(all_path)
                cur_path = all_path{a_i};
                
                if isempty(cur_path)
                    continue;
                end
                
                fprintf('Exploring path %s\n', cur_path);
                
                
                
                
                slx_files = dir([cur_path filesep '*.slx']);
                for i=1:numel(slx_files)
                    x = strsplit(slx_files(i).name, '.slx');
                    if is_customlib(x, slx_files(i).folder)
%                         fprintf('Found lib... continue\n');
                        continue;
                    end
                    
                    all_files.add(x{1});
                end

                mdl_files = dir([cur_path filesep '*.mdl']);
                for i=1:numel(mdl_files)
                    x = strsplit(mdl_files(i).name, '.mdl');
                    if is_customlib(x, mdl_files(i).folder)
                        continue;
                    end
                    all_files.add(x{1});
                end
            end
            
            if CHECK_CHILDREN
            
                for i=1:all_files.len
    %                 fprintf('Analyzing %s\n', all_files.get(i));
                    try
                        [mDep,~] = find_mdlrefs(all_files.get(i));
                    catch
                        try
                             close_system(all_files.get(i));
                        catch
                        end

                        continue;
                    end



                    for j = 1:length(mDep)
    %                     fprintf('Found children %s\n', mDep{j});
                        if ~ strcmp(all_files.get(i), mDep{j})
                            children.put(mDep{j}, 1);
                        end
                    end
                end
                
            end
            
            strbuf = '{';
            
%             open_models = true;
            
            for i=1:all_files.len
                cur = all_files.get(i);
                if ~ children.contains(cur)

                    if ~isempty(prelist) && ~ util.cell_str_in(prelist, cur)
                        fprintf('[PreList] Skipping %s\n', cur);
                        continue;
                    end
                    
                    if CHECK_BLOCK_COUNT && mdlrefCountBlocks(cur) < block_count_threshold
                        fprintf('[BlockThreshold] Skipping %s; %d \n', cur, mdlrefCountBlocks(cur));
                        simples.add(cur);
                        
                        try
                             close_system(cur);
                        catch
                        end
                        
                        continue;
                    end
                    
                    try
                         close_system(cur);
                    catch
                    end
                    
                    fprintf('\t\t** %s **\n', cur);
                    final_ret.add(cur);
                    strbuf = [strbuf ' ''' cur ''', '];
                    
                end
            end
            
%             ret = final_ret.data;
            strbuf = [strbuf ' };']
            
            ret.simples = simples;
            ret.advances = final_ret;
            ret.tests = tests;
            ret.libs = libs;
            ret.children = children;
            ret.paths = model_path;
            ret.duplicates = name_conflicts;
            
            fprintf('Found %d children ||| %d models \n', children.len_keys(), final_ret.len);
        end
        
        
        function print_models_for_excel()
            acc = analyze_complexity_cfg();
            cat = sort(acc.examples);
            for i=1:numel(cat)
                fprintf('%s\n', cat{i});
            end
            fprintf('--- Done (%d) ---- \n', numel(cat));
        end
        
    end
    
end

