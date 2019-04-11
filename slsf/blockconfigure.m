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
            
            % simulink/Sources/Constant
            t = {
                bcprops('Value', [], [], 'n')
            };
            d.(util.mvn('simulink/Sources/Constant')) = t;
            
            
            % simulink/Sources/Step
            t = {
                bcprops('After', char('1':'9'), 2, 'r')
            };
            d.(util.mvn('simulink/Sources/Step')) = t;
            
            
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

