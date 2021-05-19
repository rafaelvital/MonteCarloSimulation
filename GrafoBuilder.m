classdef GrafoBuilder
    %GrafoBuilder Classe que possui apenas o método estativo excelBuild, que 
    % constrói o grafo com base no excel de grafos
    
    properties (Constant)
        colIdArvore = 2;
        colIdBloco = 3;
        colTipo = 4;
        colListaSinks = 5;
        colTipoBloco = 7;
        colListaSinksTempo = 8;
        colListaSinksCusto = 14;
        colListaSinksProb = 16;
        colEsp = 18;
        colPortAcordo = 19;
        colPercAcordo = 20;
        colProbAcordo = 21;
        colTempoEmbargo = 40; %28;
        colProbEmbargo = 43; %31;
    end
    
    methods (Static)        
        function validateExcelInput(gnum, gtxt)
            hasError = false;
            for idNoh = 1 : size(gnum, 1)
                nanPattern = isnan(gnum(idNoh, :));
                intPattern = (gnum(idNoh, :) == floor(gnum(idNoh, :))) & gnum(idNoh, :) >= 0;
                switch gtxt{idNoh + 1, model.GrafoBuilder.colTipo}
                    case 'CONTROLE'
                        hasError = ~all(nanPattern == [0 0 0 1 0 0 1 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0]);%[0 0 0 1 0 0 1 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0]);
                        hasErrorInt = sum(intPattern(logical([0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 0]))) ~= 9;
                    case 'ACORDO'
                        hasError = ~all(nanPattern == [0 0 0 1 0 0 1 0 0 0 0 0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1]);%[0 0 0 1 0 0 1 0 0 0 0 0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 1 1 1 1]);
                        hasErrorInt = sum(intPattern(logical([0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]))) ~= 6;
                    case 'FOLHA'
                        hasError = ~all(nanPattern == [0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);%[0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                    case 'RAIZ'
                        hasError = ~all(nanPattern == [0 0 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);%[0 0 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                    case 'OUTRO'
                        hasError = ~all(nanPattern == [0 0 0 1 0 0 1 0 0 0 0 0 0 1 1 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]) ...
                            && ~all(nanPattern == [0 0 0 1 0 1 1 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                        hasErrorInt = ~ (sum(intPattern(logical([0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]))) == 6 || ...
                                      sum(intPattern(logical([0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]))) == 3);
                        
                        listaSinksProb = gnum(idNoh, model.GrafoBuilder.colListaSinksProb + [0 1])';
                        listaSinksProb = listaSinksProb(~isnan(listaSinksProb));
                        if ~all(isnan(listaSinksProb)) && (abs(sum(listaSinksProb)-1) > 0.0001 || any(listaSinksProb < 0) || any(listaSinksProb > 1))
                            throw(MException('ErrorChecking:WrongInput',['Entrada errada no id = ' num2str(idNoh) '. Probabilidades nao somam 1.']));
                        end
                        
%                         if ~all(isnan(listaSinksProb)) && sum(listaSinksProb) ~= 1
%                             throw(MException('ErrorChecking:WrongInput',['Entrada errada no id = ' num2str(idNoh) '. Probabilidades nao somam 1.']));
%                         end
                end
                if hasError
                    sNanPattern = '';
                    for p = nanPattern
                        sNanPattern = [sNanPattern num2str(p)];
                    end
                    throw(MException('ErrorChecking:WrongInput',['Entrada errada no id = ' num2str(idNoh) '. nanPattern = ' sNanPattern]));
                end
                if hasErrorInt
                    error(['Entrada errada no id = ' num2str(idNoh) '. Alguma distribuição tem numero negativo ou não inteiro']);
                end
            end
        end
        
        function [listaGrafos] = excelBuild(excelFileName,inputLog, arvoreModelo, verificar)   
 
            DirInfoMat = dir([excelFileName '.mat']);
            DirInfoXls = dir([excelFileName '.xlsx']);
            
            lerXlsx = 1; 
            if verificar && exist([excelFileName '.mat'],'file') && DirInfoMat.datenum > DirInfoXls.datenum
                load([excelFileName '.mat']);
                if(exist('timeRand','var'))
                    if(timeRand == inputLog.isTimeRand)
                        lerXlsx = 0;
                    end
                end
            end
                    
            if(lerXlsx)                
                [gnumMain, gtxt] = xlsread(excelFileName, 'main');
                [~, sheets] = xlsfinfo(excelFileName);
                nClusters = length(sheets) - 1;
                gnumClusters = cell(nClusters, 1);
                [nr,nc]=size(gnumMain);
                for idCluster = 1 : nClusters
                    gnumClusters{idCluster} = xlsread(excelFileName, ['cluster' num2str(idCluster)]);
                    [nrCl,ncCl]=size(gnumClusters{idCluster});
                    if nrCl<nr
                        gnumClusters{idCluster}(nrCl+1:nr,:)=NaN;
                    end
                    if ncCl<nc
                        gnumClusters{idCluster}(:,ncCl+1:nc)=NaN;
                    end
                end
                
                nNoh = size(gnumMain, 1);
                listaGrafos = cell(nClusters, 1);
                
                for idCluster = 1 : nClusters
                    
                    gnumCluster = gnumClusters{idCluster};
                    gnum = gnumMain;
                    gnum(~isnan(gnumCluster)) = gnumCluster(~isnan(gnumCluster));
                    
                    gnum(:,8:13) = round(gnum(:,8:13));
                    gnum(:,18) = NaN;
                    
                    model.GrafoBuilder.validateExcelInput(gnum, gtxt);
                    
                    clusterBuilded = model.Cluster();
                    
                    for idNoh = 1 : nNoh
                        idArvore = gnum(idNoh, model.GrafoBuilder.colIdArvore);
                        idBloco = gnum(idNoh, model.GrafoBuilder.colIdBloco);
                        
                        switch gtxt{idNoh + 1, model.GrafoBuilder.colTipo}
                            case 'CONTROLE'
                                tipo = model.NohModelo.CONTROLE;
                            case 'ACORDO'
                                tipo = model.NohModelo.ACORDO;
                            case 'FOLHA'
                                tipo = model.NohModelo.FOLHA;
                            case 'RAIZ'
                                tipo = model.NohModelo.RAIZ;
                            case 'OUTRO'
                                tipo = model.NohModelo.OUTRO;
                        end                        
                        
                        if tipo ~= model.NohModelo.RAIZ
                            listaSinksProb = gnum(idNoh, model.GrafoBuilder.colListaSinksProb + [0 1])';
                        else
                            listaSinksProb = 1;
                        end
                        listaSinksProb = listaSinksProb(~isnan(listaSinksProb));
                        if tipo == model.NohModelo.OUTRO && all(isnan(listaSinksProb))
                            listaSinksProb = 1;
                        end                        
                        
                        listaSinksTempo = gnum(idNoh, model.GrafoBuilder.colListaSinksTempo + [1 4])';
                        listaSinksTempo = listaSinksTempo(~isnan(listaSinksTempo));
                        
                        %Calcula distribuição
                        distribuicao = cell(2,1);
                        listaSinksTempoCompleto = gnum(idNoh, model.GrafoBuilder.colListaSinksTempo + [0 1 2 3 4 5])';
                        listaSinksTempoCompleto = listaSinksTempoCompleto(~isnan(listaSinksTempoCompleto));
                        if length(listaSinksTempoCompleto)>1
                            if listaSinksTempoCompleto(1)==listaSinksTempoCompleto(3)
                                distribuicao{1} = [listaSinksTempoCompleto(1) listaSinksTempoCompleto(2) listaSinksTempoCompleto(3)];
                            else
                                distTempo1 = makedist('Triangular', 'a', listaSinksTempoCompleto(1), 'b', listaSinksTempoCompleto(2), 'c', listaSinksTempoCompleto(3));
                                contagem1 = hist(distTempo1.icdf(linspace(0,1,1e4)), listaSinksTempoCompleto(1):listaSinksTempoCompleto(3));
                                contagem1 = round(contagem1 / min(contagem1));
                                for ind = 1 : length(contagem1)
                                    distribuicao{1} = [distribuicao{1}; ones(contagem1(ind),1)*ind];
                                end
                                distribuicao{1} = distribuicao{1} + (listaSinksTempoCompleto(1)-1);
                            end
                            if length(listaSinksTempoCompleto)>3
                                if listaSinksTempoCompleto(4)==listaSinksTempoCompleto(6)
                                    distribuicao{2} = [listaSinksTempoCompleto(4) listaSinksTempoCompleto(4) listaSinksTempoCompleto(6)];
                                else
                                    distTempo2 = makedist('Triangular', 'a', listaSinksTempoCompleto(4), 'b', listaSinksTempoCompleto(5), 'c', listaSinksTempoCompleto(6));
                                    contagem2 = hist(distTempo2.icdf(linspace(0,1,1e4)), listaSinksTempoCompleto(4):listaSinksTempoCompleto(6));
                                    contagem2 = round(contagem2 / min(contagem2));                                    
                                    for ind = 1 : length(contagem2)
                                        distribuicao{2} = [distribuicao{2}; ones(contagem2(ind),1)*ind];
                                    end
                                    distribuicao{2} = distribuicao{2} + (listaSinksTempoCompleto(4)-1);
                                end
                            end
                        end
                        
                       
                        % Calcula probabilidade de embargo e suas
                        % probabilidadas
                        percAcordo = [];
                        probAcordo = [];
                        curvaA = [];
                        curvaB = [];
                        probEmbargo = 0;
                        distEmbargo = [];
                        tempoEmbargo = [0 0];
                        switch tipo
                            case model.NohModelo.CONTROLE % Aumento proporcional de tempo por embargo
                                probEmbargo = gnum(idNoh, model.GrafoBuilder.colProbEmbargo);
                                if probEmbargo ~= 0
                                    tempoEmbargo = gnum(idNoh, model.GrafoBuilder.colTempoEmbargo + [0 1 2]);
%                                     listaSinksTempo = listaSinksTempo + round(probEmbargo * tempoEmbargo(2));
                                    distTempo = makedist('Triangular', 'a', tempoEmbargo(1), 'b', tempoEmbargo(2), 'c', tempoEmbargo(3));
                                    contagem = hist(distTempo.icdf(rand(1e4,1)), tempoEmbargo(1):tempoEmbargo(3));
                                    contagem = round(contagem / min(contagem));
                                    for ind = 1 : length(contagem)
                                        distEmbargo = [distEmbargo; ones(contagem(ind),1)*ind];
                                    end
                                    distEmbargo = distEmbargo + (tempoEmbargo(1)-1);
                                end
                            case model.NohModelo.ACORDO
                                percAcordo = gnum(idNoh, model.GrafoBuilder.colPercAcordo + [18 0 2 4 6 8 10 12 14 16 19]);%gnum(idNoh, GrafoBuilder.colPercAcordo + [6 0 2 4 7]);
                                probAcordo = [0 gnum(idNoh, model.GrafoBuilder.colProbAcordo + [0 2 4 6 8 10 12 14 16]) 1]; %[0 gnum(idNoh, GrafoBuilder.colProbAcordo + [0 2 4]) 1];
                                curvaA = zeros(length(percAcordo)-1,1);
                                curvaB = zeros(length(percAcordo)-1,1);
                                for i=1:length(percAcordo)-1
                                    curvaA(i) = (probAcordo(i+1)-probAcordo(i))./(percAcordo(i+1)-percAcordo(i));
                                    curvaB(i) = probAcordo(i)-curvaA(i) * percAcordo(i);
                                end 
%                                 percAcordo = [0 percAcordo];
%                                 probAcordo= [0 probAcordo];
%                                 probAcordo(2) = 0.00001;
                                xp = (percAcordo(1) : inputLog.passoCurvaAcordo : percAcordo(end))';
                                probAcordo = interp1(percAcordo, probAcordo, xp);
                                percAcordo = xp;
                            case model.NohModelo.FOLHA
                            case model.NohModelo.RAIZ
                                listaSinksTempo = 0;
                            case model.NohModelo.OUTRO
                        end
                        
                        clusterBuilded.id = idCluster;                        
%                         clusterBuilded.curva_acordo{idArvore,idBloco} = [percAcordo' probAcordo'];    
                        clusterBuilded.curva_acordo{idArvore,idBloco} = [percAcordo probAcordo]; 
                        clusterBuilded.probEmbargo(idArvore,idBloco) = probEmbargo;
                        clusterBuilded.distEmbargo{idArvore,idBloco} = distEmbargo;
                        clusterBuilded.tempoEmbargo(idArvore,idBloco) = tempoEmbargo(2);
                         for i=1:length(listaSinksTempo)
                            clusterBuilded.tempo_aresta(idArvore,idBloco,i) = listaSinksTempo(i);
                        end
                        clusterBuilded.prob_aresta{idArvore,idBloco} = listaSinksProb;
                        clusterBuilded.distribuicao{idArvore,idBloco,1} = distribuicao{1};
                        clusterBuilded.distribuicao{idArvore,idBloco,2} = distribuicao{2};
                        
                        clusterBuilded.curvaA{idArvore,idBloco} = curvaA;
                        clusterBuilded.curvaB{idArvore,idBloco} = curvaB;
                        
                     end  % termina de percorrer os nó's                     
                    
                    listaGrafos{idCluster} = clusterBuilded;
                    
                end % termina de percorrer os clusters
                
                % Salva o array de cluster criado
                timeRand = inputLog.isTimeRand;
                save([excelFileName '.mat'],'listaGrafos','timeRand');                
            end
            
        
            
        end
        
        function [curvas] = curvaBuilder(excelFileName,inputLog, arvoreModelo,isCurvasDiferentesEmCadaBloco, verificar)
            
            DirInfoMat = dir([excelFileName '.mat']);
            DirInfoXls = dir([excelFileName '.xlsx']);
            
            lerXlsx = 1; 
            if verificar && exist([excelFileName '.mat'],'file') && DirInfoMat.datenum > DirInfoXls.datenum
                load([excelFileName '.mat']);
                if(exist('isCurvasDiferentesEmCadaBloco','var'))
                    if(isCurvasDiferentesEmCadaBloco == inputLog.isCurvasDiferentesEmCadaBloco)
                        lerXlsx = 0;
                    end
                end
            end
            
            if(lerXlsx)
                if(~inputLog.isCurvasDiferentesEmCadaBloco)
                    % Caso onde as curvas são separadas por fase  
                    
                    curvas = model.Curvas();
                    
                    % Numero de arvore e de blocos                   
                    nArvore = size(arvoreModelo.idPair2idNoh,1);
                    nBloco = size(arvoreModelo.idPair2idNoh,2);
                    
                    % Define os blocos de conhecimento, recursal e execução.
                    % Colocando 1 nos blocos que são externo de acordo
                    tipo = (arvoreModelo.tipo == model.NohModelo.ACORDO);
                    tipoBloco = (arvoreModelo.tipoBloco == model.NohModelo.ACORDO);
                    noAcordo = tipo & tipoBloco;
                    
                    noConhecimento = zeros(nArvore,nBloco);
                    noConhecimento(1,:) = ones(1,nBloco);
                    noConhecimento = noConhecimento & noAcordo;
                    % Blocos de conhecimento que são externoe  de acordo
                    
                    noRecursal = zeros(nArvore,nBloco);
                    noRecursal(2:100,:) = ones(99,nBloco); %99 = 100-2
                    noRecursal = noRecursal & noAcordo;
                    % Blocos recursal que são externoe  de acordo
                    
                    noExecucao = zeros(nArvore,nBloco);
                    noExecucao(101:end,:) = ones(nArvore-100,nBloco);  %nArvore-100 = numero de arvores na execução
                    noExecucao = noExecucao & noAcordo;
                    % Blocos de execução que são externoe  de acordo
                    
                    % Le o excel e inicializa o cell array de curva
                    gnum = xlsread(excelFileName);
                    curvas.curva_acordo = cell(nArvore,nBloco);
                    
                    % Identifica no excel as curvas e cria a curvas para os
                    % nos de conhecimento
                    nPontos =  find(gnum(2,:)==1);
                    if(isempty(nPontos) || ~all(isnan(gnum(2,nPontos+1:end))))
                        error('O ultimo ponto da probabilidade de curva de acordo não é 1');
                    end
                    curvaConhecimento(:,1) = gnum(1,1:nPontos);
                    curvaConhecimento(:,2) = gnum(2,1:nPontos);
                    model.GrafoBuilder.verificaCurva(curvaConhecimento);
                    for i=1:nArvore
                        for j=1:nBloco
                            if(noConhecimento(i,j))
                                 curvas.curva_acordo{i,j} = curvaConhecimento;
                            end
                        end
                    end
                    
                    % recursal
                    nPontos =  find(gnum(4,:)==1,1);
                    if(isempty(nPontos) || ~all(isnan(gnum(4,nPontos+1:end))))
                        error('O ultimo ponto da probabilidade de curva de acordo não é 1');
                    end
                    curvaRecursal(:,1) = gnum(3,1:nPontos);
                    curvaRecursal(:,2) = gnum(4,1:nPontos);
                    model.GrafoBuilder.verificaCurva(curvaRecursal);
                     for i=1:nArvore
                        for j=1:nBloco
                            if(noRecursal(i,j))
                                 curvas.curva_acordo{i,j} = curvaRecursal;
                            end
                        end
                    end
                    
                    % execução
                    nPontos =  find(gnum(6,:)==1,1);
                    if(isempty(nPontos) || ~all(isnan(gnum(6,nPontos+1:end))))
                        error('O ultimo ponto da probabilidade de curva de acordo não é 1');
                    end
                    curvaExecucao(:,1) = gnum(5,1:nPontos);
                    curvaExecucao(:,2) = gnum(6,1:nPontos);
                    model.GrafoBuilder.verificaCurva(curvaExecucao);
                     for i=1:nArvore
                        for j=1:nBloco
                            if(noExecucao(i,j))
                                 curvas.curva_acordo{i,j} = curvaExecucao;
                            end
                        end
                    end
                else
                    % Caso onde as curvas são separadas por bloco
                    curvas = model.Curvas();
                    
                    % Numero de arvore e de blocos
                    nArvore = size(arvoreModelo.idPair2idNoh,1);
                    nBloco = size(arvoreModelo.idPair2idNoh,2);                    
                    
                    % Le o excel e inicializa o cell array de curva
                    gnum = xlsread(excelFileName);
                    
                    if(size(gnum,1) ~= 2*size(arvoreModelo.listaNohs,2))
                        error('A lista de curva de acordo não corresponde ao modelo');
                    end
                        
                    curvas.curva_acordo = cell(nArvore,nBloco);
                    
                    for i=1:2:size(gnum,1)
                        if(gnum(i,4) == 1) %se o bloco tiver acordo
                            nPontos =  find(gnum(i+1,5:end)==1,1);  %numero de pontos do acordo (procura em probabilidade)
                            if(isempty(nPontos) || ~all(isnan(gnum(i+1,nPontos+6:end))))
                                error('O ultimo ponto da probabilidade de curva de acordo não é 1');
                            end
                            curvaBloco(:,1) = gnum(i,5:4+nPontos); %percentual de acordo
                            curvaBloco(:,2) = gnum(i+1,5:4+nPontos);  %prob de acordo
                            model.GrafoBuilder.verificaCurva(curvaBloco);
                            curvas.curva_acordo{gnum(i,2),gnum(i,3)} = curvaBloco;  %gnum(i,2) = id arvore ,gnum(i,3) = id bloco
                            clear curvaBloco;
                        end
                    end                    
                    
                end
                
                % Salva o array de cluster criado
                isCurvasDiferentesEmCadaBloco = inputLog.isCurvasDiferentesEmCadaBloco;
                save([excelFileName '.mat'],'curvas','isCurvasDiferentesEmCadaBloco');
                
            end     
        end
        
        % Verifica se os pontos iniciais e finais são válidos e se a curva
        % é monotonica estritamente crescente        
        function verificaCurva(curva)            
            if(curva(1,1)~=0  || curva(1,2)~=0)
                error('O ponto inicial da curva não é (perc,prob) = (0,0)');
            end
            for i=2:size(curva,1)
                if(curva(i,1) > curva(i-1,1) && curva(i,2) > curva(i-1,2))                    
                else
                    error('A curva de acordo deve ser monotonica estritamente crescente')
                end
            end
        end
    end
end
        
     