sys = 'potential';
simOutNorm = sim(sys, 'SimulationMode', 'normal'); 
yOutNorm = simOutNorm.get('yout'); 
simOutRapid = sim(sys, 'SimulationMode', 'rapid'); 
yOutRapid = simOutRapid.get('yout'); 



for i=1:numel(yOutNorm.signals)
    figure;
    plot(yOutNorm.signals(i).values,'gx');
    hold on; 
    plot(yOutRapid.signals(i).values,'ro');
    
    isequal(yOutNorm.signals(i).values, yOutRapid.signals(i).values)
end