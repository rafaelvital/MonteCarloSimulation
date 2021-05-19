function [percentualConferancia, nPedidosContados] = confereProbabilidades(resultSimulation, confianca)


%% cria lista output
listaOutput = zeros(0,3);
if(resultSimulation.nPedido ~= 1)
    multipedido = true;
    indiceListaOutput = 1;    
    for iProcesso = 1:resultSimulation.nProcesso
        pedidosValidos = resultSimulation.carteiraInicial.processos{iProcesso}.pedidos ~= 0;
        indicePedidosValidos = find(pedidosValidos==1);
        nPedidosProcesso = sum(double(pedidosValidos));
        listaOutput(indiceListaOutput:indiceListaOutput+nPedidosProcesso-1,1) = iProcesso;
        listaOutput(indiceListaOutput:indiceListaOutput+nPedidosProcesso-1,2) = indicePedidosValidos';
        indiceListaOutput = indiceListaOutput + nPedidosProcesso;
    end
else
    multipedido = false;
    listaOutput(1:length(listaProcessoUnico),1) = 1:length(listaProcessoUnico);
    listaOutput(:,2) = 1;
end
listaOutput(:,3) = sub2ind([resultSimulation.nProcesso, ...
                            resultSimulation.nPedido], listaOutput(:,1), listaOutput(:,2));


%1 - primeira 
%2 - segundaDef
%3 - segundaInd
%4 - terceiraDef
%5 - terceiraInd
%6 - quartaDef
%7 - quartaInd


%% Pega informações do resultSimulation
simulado = zeros(size(listaOutput,1),resultSimulation.nSim,7);
for iSim=1:resultSimulation.nSim
    simulado(:,iSim,1) = resultSimulation.estado1Julga{iSim}(listaOutput(:,3));
    simulado(:,iSim,2) = resultSimulation.estado2JulgaDef{iSim}(listaOutput(:,3));
    simulado(:,iSim,3) = resultSimulation.estado2JulgaInd{iSim}(listaOutput(:,3));
    simulado(:,iSim,4) = resultSimulation.estado3JulgaDef{iSim}(listaOutput(:,3));
    simulado(:,iSim,5) = resultSimulation.estado3JulgaInd{iSim}(listaOutput(:,3));
    simulado(:,iSim,6) = resultSimulation.estado4JulgaDef{iSim}(listaOutput(:,3));
    simulado(:,iSim,7) = resultSimulation.estado4JulgaInd{iSim}(listaOutput(:,3));
end

%% Pega as probabilidades do resultSimulation
probabilidades = zeros(size(listaOutput,1),7);
for iPedido = 1:size(listaOutput,1)
    probabilidades(iPedido,1) = resultSimulation.carteiraInicial.processos{listaOutput(iPedido,1)}.matClasseProb(listaOutput(iPedido,2));
    probabilidades(iPedido,2) = resultSimulation.carteiraInicial.processos{listaOutput(iPedido,1)}.matClasseProbDecisaoDef(listaOutput(iPedido,2),1);
    probabilidades(iPedido,3) = resultSimulation.carteiraInicial.processos{listaOutput(iPedido,1)}.matClasseProbDecisaoIndef(listaOutput(iPedido,2),1);
    probabilidades(iPedido,4) = resultSimulation.carteiraInicial.processos{listaOutput(iPedido,1)}.matClasseProbDecisaoDef(listaOutput(iPedido,2),2);
    probabilidades(iPedido,5) = resultSimulation.carteiraInicial.processos{listaOutput(iPedido,1)}.matClasseProbDecisaoIndef(listaOutput(iPedido,2),2);
    probabilidades(iPedido,6) = resultSimulation.carteiraInicial.processos{listaOutput(iPedido,1)}.matClasseProbDecisaoDef(listaOutput(iPedido,2),3);
    probabilidades(iPedido,7) = resultSimulation.carteiraInicial.processos{listaOutput(iPedido,1)}.matClasseProbDecisaoIndef(listaOutput(iPedido,2),3);  
end


%% Contabiliza informações do resultSimulation
%contagem é da forma
%(nPedidos,[procedentes improcedentes probabilidadesSimulada],instancia)
contagem = zeros(size(listaOutput,1),3,7);
for ins=1:7
    contagem(:,1,ins) = sum(simulado(:,:,ins) == 2,2);
    contagem(:,2,ins) = sum(simulado(:,:,ins) == 1,2);
    contagem(:,3,ins) = contagem(:,1,ins)./(contagem(:,1,ins)+contagem(:,2,ins));
end

% sigma e delta do intervalo para cada pedido e cada instancia
% sigma e delta tem a forma (pedidos, instancia)
sigma = sqrt(probabilidades.*(1-probabilidades)./squeeze(contagem(:,1,:)+contagem(:,2,:)));
deltaIntervalo = sigma.*tinv((1-(1-confianca)/2),squeeze(contagem(:,1,:)+contagem(:,2,:))-1);

%verifica quando a probabilidade simulada (contagem(:,3,:) está dentro do
%limite do intervalo
dentroLimite = squeeze(contagem(:,3,:)) >= probabilidades -deltaIntervalo & ...
               squeeze(contagem(:,3,:)) <= probabilidades + deltaIntervalo;           
pedidosInstanciaValidos = squeeze(contagem(:,1,:)+contagem(:,2,:)) > 1;

%% saida da função
percentualConferancia = sum(dentroLimite .* pedidosInstanciaValidos,1) ./ sum(pedidosInstanciaValidos,1);
nPedidosContados = sum(pedidosInstanciaValidos,1);


end