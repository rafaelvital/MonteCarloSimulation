function [resultSimulationJuntado] = juntaSimulacaoV2(nome)

import model.ResultSimulation;

listaResultados = dir([nome '_*.mat']);

load(listaResultados(1).name);

% Cria um resultSimulation com complemento nulo
resultSimulationJuntado = model.ResultSimulationV2(resultSimulation.name, resultSimulation.inputLogs, ...
    resultSimulation.estrategia,resultSimulation.descricao, '');
resultSimulationJuntado.carteiraInicial = resultSimulation.carteiraInicial;
resultSimulationJuntado.primeiroSetAcordo = resultSimulation.primeiroSetAcordo;

for i = 1:length(listaResultados)
    if(i ~= 2)
        load(listaResultados(i).name);
    end
    for iSim=1:resultSimulation.nSim
        [outputCarteira, historico, historicoAcordo] = readSim(resultSimulation,iSim);
        outputCarteira.historico = historico;
        outputCarteira.historicoAcordo = historicoAcordo;
        resultSimulationJuntado.add(outputCarteira);
    end
end

resultSimulation = resultSimulationJuntado;
save(nome,'resultSimulation');

for i = 1:length(listaResultados)
    load(listaResultados(i).name);
    resultSimulation.apaga();
end

end