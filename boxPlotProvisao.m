% boxplot do valor presente total comparando diversas estrategias de uma
% mesma simula��o
% nomeSimulacao: Nome da simula��o
% estrategias: Lista de string com as estrat�gias, caso seja [], a fun��o
% faz o boxplot com todas as estrat�gias, em ordem alfabetica
function [hTotal, hPrinciapal,hB] = boxPlotProvisao(nomeSimulacao,estrategias,varargin)

temFiltro = false;
temLegenda = false;
for i = 1:2:length(varargin)
    switch varargin{i}
        case 'filtro'
            filtro = varargin{i+1};
            temFiltro = true;
        case 'legenda'
            temLegenda = true;
            legenda = varargin{i+1};
        otherwise
            error(['Parametro ' varargin{i} ' n�o reconhecido']);
    end
end

% Lista os .mat das estrat�gias que ser�o boxplotadas
% Se estrategias == [], se for pega todas as estrat�gias
if isempty(estrategias)
    listaResultados = dir([nomeSimulacao '_*.mat']);
else
    for i=1: length(estrategias)
        listaResultados(i) = dir([nomeSimulacao '_' estrategias{i} '.mat']);
    end
end
%Calcula o valor presente de cada simula��o de cada estrat�gia
%Acha o menor numero de simula��o simuladas entre as estrat�gias, por exemplo,
% Se na estrat�gia '0' foram feitas 5 simula��es e na 'opt' 20 simula��es,
% nSimMinimo = 5
nSimMinimo = Inf;
for indRes=1:length(listaResultados)
    
    load(listaResultados(indRes).name);
    if(resultSimulation.nSim < nSimMinimo)
        nSimMinimo = resultSimulation.nSim;
    end
    
    
    
    tipo = zeros(resultSimulation.nProcesso,1);
    fase = zeros(resultSimulation.nProcesso,1);
    classificacao = zeros(resultSimulation.nProcesso,1);
    for i=1:resultSimulation.nProcesso
        processo = resultSimulation.carteiraInicial.processos{i};
        if(processo.id_arvore_atual == 1)
            fase(i) = 1;
            classificacao(i) = 2;
        elseif(processo.id_arvore_atual < 100)
            fase(i) = 2;
            if(sum(processo.pedidos.*processo.pedidos_deferidos) > 0)
                classificacao(i) = 1;
            else
                classificacao(i) = 3;
            end
        else
            fase(i) = 3;
            if(sum(processo.pedidos.*processo.pedidos_deferidos) > 0)
                classificacao(i) = 1;
            else
                classificacao(i) = 3;
            end
        end
        tipo(i) = processo.arvoreModelo.tipoModelo;
    end
    
    [~, valorPresenteProcesso] = resultSimulation.getValorPresente();
    
    
    provisao{indRes} = shiftdim(sum(valorPresenteProcesso(filtro,1,:),1) + sum(valorPresenteProcesso(filtro & classificacao == 1,2,:),1),2);
    contingente{indRes} =  shiftdim(sum(valorPresenteProcesso(filtro & classificacao == 2,2,:),1),2);
    remoto{indRes} =  shiftdim(sum(valorPresenteProcesso(filtro & classificacao == 3,2,:),1),2);
    
    
    ind = find(listaResultados(indRes).name == '_');
    nomes{indRes} = listaResultados(indRes).name(ind+1:end-4);
    
end

% matrixPlot � da forma (nSimMinimo, numeroEstrat�gias)
% matrixPlot � a matriz que ser� boxplotada
matrixPlotprovisao = zeros(5*nSimMinimo,length(listaResultados));
matrixPlotcontingente = zeros(5*nSimMinimo,length(listaResultados));
matrixPlotremoto = zeros(5*nSimMinimo,length(listaResultados));

% Seleciona apenas nSimMinimo simula��es
for indRes=1:length(listaResultados)
    if(indRes<=2)
        matrixPlotprovisao(:,indRes) = repmat(provisao{indRes}(1:nSimMinimo)/1e6,5,1);
        matrixPlotcontingente(:,indRes) = repmat(contingente{indRes}(1:nSimMinimo)/1e6,5,1);
        matrixPlotremoto(:,indRes) = repmat(remoto{indRes}(1:nSimMinimo)/1e6,5,1);
    else
        matrixPlotprovisao(:,indRes) = provisao{indRes}/1e6;
        matrixPlotcontingente(:,indRes) = contingente{indRes}/1e6;
        matrixPlotremoto(:,indRes) = remoto{indRes}/1e6;
    end
end

% caso nSimMinimo==1
if(nSimMinimo==1)
    matrixPlotValor = [matrixPlotValor; matrixPlotValor];
    matrixPlotPrincipal = [matrixPlotPrincipal; matrixPlotPrincipal];
    % gambiarra necessaria, pois, caso contrario,o matlab interpreta que tem
    % nEstrat�gias simula��es e apenas uma estrat�gia, ao inv�s de
    % interpretar 1 simula��o e nEstrat�gias Estrat�gias
end

if(temLegenda)
    nomes = legenda;
end

% Boxplot
% nomes = {'0','10','20','30','40','50','60','70','80','90','100','rand','opt','optZero','optAcordo'};
hTotal = figure;
boxplot(matrixPlotprovisao, 'label',nomes,'whisker',20);
title(['Custo Total ' resultSimulation.name], ...
    'FontSize',16,'FontWeight','bold');
hold on;
media = mean(matrixPlotprovisao);
plot(media,'o');
for j=1:length(media)
    if(media(j) > 100 || media(j) == 0)
        text(j+0.27,media(j),num2str(media(j),3));
    elseif(media(j) > 10 || media(j) == 0)
        text(j+0.27,media(j),num2str(media(j),2));
    else
        text(j+0.27,media(j),num2str(media(j),'%1.1f'));
    end
end
ylabel('Valor presente MM (R$)','FontSize',16,'FontWeight','bold');
set(gca,'YGrid','on','YMinorGrid','on');

hPrinciapal = figure;
boxplot(matrixPlotcontingente, 'label',nomes,'whisker',20);
title(['Principal ' resultSimulation.name], ...
    'FontSize',16,'FontWeight','bold');
hold on;
media = mean(matrixPlotcontingente);
plot(media,'o');
for j=1:length(media)
    if(media(j) > 100 || media(j) == 0)
        text(j+0.27,media(j),num2str(media(j),3));
    elseif(media(j) > 10 || media(j) == 0)
        text(j+0.27,media(j),num2str(media(j),2));
    else
        text(j+0.27,media(j),num2str(media(j),'%1.1f'));
    end
end
ylabel('Valor presente MM (R$)','FontSize',16,'FontWeight','bold');
set(gca,'YGrid','on','YMinorGrid','on');

hB = figure;
boxplot(matrixPlotremoto, 'label',nomes,'whisker',20);
title(['Principal ' resultSimulation.name], ...
    'FontSize',16,'FontWeight','bold');
hold on;
media = mean(matrixPlotremoto);
plot(media,'o');
for j=1:length(media)
    if(media(j) > 100 || media(j) == 0)
        text(j+0.27,media(j),num2str(media(j),3));
    elseif(media(j) > 10 || media(j) == 0)
        text(j+0.27,media(j),num2str(media(j),2));
    else
        text(j+0.27,media(j),num2str(media(j),'%1.1f'));
    end
end
ylabel('Valor presente MM (R$)','FontSize',16,'FontWeight','bold');
set(gca,'YGrid','on','YMinorGrid','on');


end