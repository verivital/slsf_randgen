classdef nonvirtualblockcount < slmetric.metric.Metric
    %nonvirtualblockcount calculates number of nonvirtual blocks per level.
    % BusCreator, BusSelector and BusAssign are treated as nonvirtual.
    properties
        VirtualBlockTypes = {'Demux','From','Goto','Ground', ...
            'GotoTagVisiblity','Mux','SignalSpecification', ...
            'Terminator','Inport'};
    end
    
    methods
    function this = nonvirtualblockcount()
        this.ID = 'nonvirtualblockcount';
        this.Name = 'Nonvirtual Block Count';
        this.Version = 1;
        this.CompileContext = 'None';
        this.Description = 'Algorithm that counts nonvirtual blocks per level.';
        this.ComponentScope = [Advisor.component.Types.Model, ...
            Advisor.component.Types.SubSystem];
        this.AggregationMode = slmetric.AggregationMode.Sum;
	    this.AggregateComponentDetails = true;
        this.ResultChecksumCoverage = true;
            
    end

    function res = algorithm(this, component)
        % create a result object for this component
        res = slmetric.metric.Result();	

        % set the component and metric ID
        res.ComponentID = component.ID;
        res.MetricID = this.ID;

        % use find_system to get all blocks inside this component
        blocks = find_system(getPath(component), ...
            'SearchDepth', 1, ...
            'Type', 'Block');

        isNonVirtual = true(size(blocks));

        for n=1:length(blocks)
            blockType = get_param(blocks{n}, 'BlockType');

            if any(strcmp(this.VirtualBlockTypes, blockType))
                isNonVirtual(n) = false;
            else
                switch blockType
                    case 'SubSystem'
                        % Virtual unless the block is conditionally executed
                        % or the Treat as atomic unit check box is selected.
                        if strcmp(get_param(blocks{n}, 'IsSubSystemVirtual'), ...
                                'on')
                            isNonVirtual(n) = false;
                        end
                    case 'Outport'
                        % Outport: Virtual when the block resides within
                        % any SubSystem block (conditional or not), and 
                        % does not reside in the root (top-level) Simulink window.
                        if component.Type ~= Advisor.component.Types.Model
                            isNonVirtual(n) = false;
                        end
                    case 'Selector'
                        % Virtual only when Number of input dimensions 
                        % specifies 1 and Index Option specifies Select 
                        % all, Index vector (dialog), or Starting index (dialog).
                        nod = get_param(blocks{n}, 'NumberOfDimensions');
                        ios = get_param(blocks{n}, 'IndexOptionArray');

                        ios_settings = {'Assign all', 'Index vector (dialog)', ...
                            'Starting index (dialog)'};

                        if nod == 1 && any(strcmp(ios_settings, ios))
                            isNonVirtual(n) = false;
                        end
                    case 'Trigger'
                        % Virtual when the output port is not present.
                        if strcmp(get_param(blocks{n}, 'ShowOutputPort'), 'off')
                            isNonVirtual(n) = false;
                        end
                    case 'Enable'
                        % Virtual unless connected directly to an Outport block.
                        isNonVirtual(n) = false;

                        if strcmp(get_param(blocks{n}, 'ShowOutputPort'), 'on')
                            pc = get_param(blocks{n}, 'PortConnectivity');

                            if ~isempty(pc.DstBlock) && ...
                                    strcmp(get_param(pc.DstBlock, 'BlockType'), ...
                                    'Outport')
                                isNonVirtual(n) = true;
                            end
                        end
                end
            end
        end

        blocks = blocks(isNonVirtual);

        res.Value = length(blocks);
    end
    end
end