classdef blockconfigure < handle
    %BLOCKCONFIGURE Specify how to choose Dialog Parameters of Blocks
    %randomly
    %   Detailed explanation goes here
    
    properties
        data;
    end
    
    methods
        
        
        function obj = blockconfigure()
            % CONSTRUCTOR %
            obj.init();
        end
        
        
        function obj  = init(obj)
            obj.populate_data();
        end
        
        
        function found = get_block_configs(obj, blk_type)
            
            found = [];
            
            k = util.mvn(blk_type);
            
            if isfield(obj.data, k)
                found = obj.data.(k);
            end
        end
        
        
        function obj = populate_data(obj)
            d = struct();
            
            t = {
                bcprops('IfExpression', {'u1 >= 0'}, [], 'e')
            };
            d.(util.mvn('simulink/Ports & Subsystems/If')) = t;
            
            %%%%%%%%%%%%%% Math Ops %%%%%%%%%%%%%%
            
            %   Add
            t = {
                bcprops('Inputs', char(['+' '-']), 2, 'r')
            };
            d.(util.mvn('simulink/Math Operations/Add')) = t;
            
            %   Gain
            t = {
                bcprops('Gain', [], [], 'n')
            };
            d.(util.mvn('simulink/Math Operations/Gain')) = t;
            
            %   Math Function
            t = {
                bcprops('Operator', {'exp', 'log', '10^u' , 'log10' ,...
                        'magnitude^2', 'square' , 'pow' , 'conj' ,...
                         'hypot' , 'rem' , 'mod' ,...
                        'transpose' , 'hermitian'}, [], 'e')
            };
            d.(util.mvn('simulink/Math Operations/Math Function')) = t;
                        
            %   Divide
            t = {
                bcprops('Inputs', char(['*' '*']), 2, 'r')
            };
            d.(util.mvn('simulink/Math Operations/Divide')) = t;
            
            %   Min Max
            t = {
                bcprops('Function', {'min', 'max'}, [], 'e')
                bcprops('Inputs', char('1': '3'), 1, 'r')
            };
            d.(util.mvn('simulink/Math Operations/MinMax')) = t;
            
            %   simulink/Math Operations/Sqrt
            t = {
                bcprops('AlgorithmType', {'Newton-Raphson'}, [], 'e');
            };
            d.(util.mvn('simulink/Math Operations/Reciprocal Sqrt')) = t;
            
            % Bias
            
            t = {
                bcprops('Bias', [], [], 'n');
            };
            d.(util.mvn('simulink/Math Operations/Bias')) = t;
            
            %%%%%%%%%%%%%% Sources %%%%%%%%%%%%%%
            
            t = {
                bcprops('Value', [], [], 'n')
                bcprops('SampleTime', {'1'}, [], 'e')
            };
            d.(util.mvn('simulink/Sources/Constant')) = t;
            
            
            t = {
                bcprops('Cov', [1, 10e9], [], 'n')
                bcprops('seed', [1, 10e9], [], 'n', @floor)
            };
            d.(util.mvn('simulink/Sources/Band-LimitedWhite Noise')) = t;
            
            
            t = {
                bcprops('f1', [], [], 'n')
                bcprops('T', [], [], 'n') 
                bcprops('f2', [], [], 'n')
            };
            d.(util.mvn('simulink/Sources/Chirp Signal')) = t;
            
            t = {
                bcprops('After', char('1':'9'), 2, 'r')
            };
            d.(util.mvn('simulink/Sources/Step')) = t;
            
            
            t = {
                bcprops('NumBits', [1, 60], [], 'n', @floor);
            };
            d.(util.mvn('simulink/Sources/CounterFree-Running')) = t;
            
            
            t = {
                bcprops('uplimit', [1, 1000], [], 'n', @floor);
            };
            d.(util.mvn('simulink/Sources/CounterLimited')) = t;
            
            t = {
                bcprops('uplimit', [1, 1000], [], 'n', @floor);
            };
            d.(util.mvn('simulink/Sources/CounterLimited')) = t;
            
            t = {
                bcprops('Amplitude', [], [], 'n');
                bcprops('Period', [1, 10e7], [], 'n');
                bcprops('PhaseDelay', [1, 10], [], 'n', @floor); 
            };
            d.(util.mvn('simulink/Sources/PulseGenerator')) = t;
            
            t = {
                bcprops('slope', [-10e3, 10e3], [], 'n');
                bcprops('start', [1, 50], [], 'n');
                bcprops('InitialOutput', [-10e5, 10e5], [], 'n');
            };
            d.(util.mvn('simulink/Sources/Ramp')) = t;
            
            t = {
                bcprops('Mean', [-10e4, 10e4], [], 'n');
                bcprops('Variance', [0, 10e4], [], 'n');
                bcprops('Seed', [1, 10e8], [], 'n', @floor); 
            };
            d.(util.mvn('simulink/Sources/RandomNumber')) = t;
            
            
            t = {
                bcprops('rep_seq_y', [], 2, 'n'); % 1X2 vector
            };
            d.(util.mvn('simulink/Sources/RepeatingSequence')) = t;
            
            t = {
                bcprops('OutValues', [], 5, 'n'); % 1X5 vector
                bcprops('LookUpMeth', {'Interpolation-Use End Values',...
                                        'Use Input Nearest',...
                                        'Use Input Below',  ...
                                        'Use Input Above'}, [], 'e'); 
            };
            d.(util.mvn('simulink/Sources/RepeatingSequenceInterpolated')) = t;
            
            t = {
                bcprops('OutValues', [], 2, 'n'); % 1X5 vector
            };
            d.(util.mvn('simulink/Sources/RepeatingSequenceStair')) = t;
            
            t = {
                bcprops('Amplitude', [], [], 'n'); 
%                 bcprops('Frequency', [1, 10e8], [], 'n'); % causing timeouts
                bcprops('WaveForm', {'sine', 'square', 'sawtooth', 'random',...
                                    }, [], 'e');
                bcprops('Units', { 'rad/sec' , 'Hertz',...
                                    }, [], 'e'); 
            };
            d.(util.mvn('simulink/Sources/SignalGenerator')) = t;
            
            t = {
                bcprops('Amplitude', [], [], 'n'); 
                bcprops('Bias', [], [], 'n'); 
            };
            d.(util.mvn('simulink/Sources/Sine Wave')) = t;
            
            t = {
                bcprops('Time', [1, 50], [], 'n', @floor); 
                bcprops('Before', [], [], 'n'); 
                bcprops('After', [], [], 'n'); 
            };
            d.(util.mvn('simulink/Sources/Step')) = t;
            
            t = {
                bcprops('Minimum', [-10e9, 0], [], 'n'); 
                bcprops('Maximum', [0, 10e9], [], 'n'); 
                bcprops('Seed', [1,1e8], [], 'n', @floor); 
            };
            d.(util.mvn('simulink/Sources/Uniform RandomNumber')) = t;
            
             %%%%%%%%%%%%%% Sinks %%%%%%%%%%%%%%
            
            % simulink/Sinks/To Workspace
            t = {
                bcprops('VariableName', char('a':'z'), 7, 'r')
            };
            d.(util.mvn('simulink/Sinks/To Workspace')) = t;
            
            
            % simulink/Discrete/Tapped Delay
            t = {
                bcprops('NumDelays', char('1':'1'), 1, 'r')  % Otherwise creates dimension problem
            };
            d.(util.mvn('simulink/Discrete/Tapped Delay')) = t;
            
            
            
            % simulink/Sinks/To File
            t = {
                bcprops('Filename', char('a':'z'), 4, 'r')
            };
            d.(util.mvn('simulink/Sinks/To File')) = t;
            
            
            
            % simulink/Continuous/VariableTime Delay
            t = {
                bcprops('InitialOutput', char('1':'9'), 8, 'r'),...
                bcprops('ZeroDelay', {'on'}, [], 'e')
            };
            d.(util.mvn('simulink/Continuous/VariableTime Delay')) = t;
            
            
            % simulink/Continuous/TransportDelay
            t = {
                bcprops('InitialOutput', char('1':'9'), 8, 'r')
            };
            d.(util.mvn('simulink/Continuous/TransportDelay')) = t;
            
            
            
            % simulink/Continuous/VariableTransportDelay
            t = {
                bcprops('InitialOutput', char('1':'9'), 8, 'r'),...
                bcprops('ZeroDelay', {'on'}, [], 'e')
            };
            d.(util.mvn('simulink/Continuous/VariableTransportDelay')) = t;
            
            
            % simulink/Logic and BitOperations/Combinatorial Logic
            t = {
                bcprops('TruthTable', {'int', [0 1]}, [2 1], 'm')
            };
            d.(util.mvn('simulink/Logic and BitOperations/Combinatorial Logic')) = t;
            
            % simulink/Discrete/Difference -- to prevent the
            % Internal rule which is problematic
            t = {
                bcprops('OutDataTypeStr', {'Inherit: Inherit via back propagation'}, [], 'e')
            };
            d.(util.mvn('simulink/Discrete/Difference')) = t;
            
            % Save All
            
            obj.data = d;
        end
        
        
    end
    
end

