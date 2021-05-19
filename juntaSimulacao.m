function [resultSimulation] = juntaSimulacao(nome,estrategia)

import model.ResultSimulation;

listaResultados = dir([nome '_' estrategia '_*.mat']);

load(listaResultados(1).name);
resultSimulationJuntado = resultSimulation;

for i=2:length(listaResultados)
    load(listaResultados(i).name);
    
    
    resultSimulationJuntado.append(resultSimulation);    
    
end

resultSimulation = resultSimulationJuntado;
save([nome '_' estrategia],'resultSimulation');

end