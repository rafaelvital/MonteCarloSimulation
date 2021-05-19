classdef ContenciosoSimulator < handle
    % ContenciosoSimulator: Armazena os modelos das arvores, os cluster,
    % a carteira e input de configuração.
    % Carrega todos os objetos citados acima.
    % Inicia a simulação, gerando o .mat correspondente
    
    properties
        carteiraInicial
        inputLog
        
        arvoreTrab  % excel modeloArvore
        arvoreCivel
        arvoreJec
        
        clusterTrab % Grafos
        clusterCivel
        clusterJec
        
        curvasTrab
        curvasCivel
        curvasJec
        
        % indices de correção monetaria
        %         indicesCM
        
        verbose
        % Tres opções para verbose
        %  0 - Sem, o modelo não indica qual simulação
        %  1 - Simulacao, o modelo inidca apenas a simulação atual
        %  2 - Completo (default), indica a simulação o tempo e o processo atual
        
    end
    
    properties (Constant)
%         ipca = 1;
%         inpc = 2;
%         igpm = 3;
%         tr = 4;
%         memoriaLimitePC = 4e9; %4GB de resultSimulation contando todos os processadores(incluindo historico)
        memoriaLimitePC = 1e6;
    end
    
    methods
        
        % Contrui o contensioso baseado no inputLog. O construtor copia o
        % inputLog para o contencioso e inicializa o carteira. O
        % carregamento dos modeloes não é executado.
        function self = ContenciosoSimulator(inputLog,verbose)
            if(nargin == 2)
                if isa(inputLog,'model.InputLog')
                    self.inputLog = inputLog;
                    self.carteiraInicial = model.Carteira(inputLog);
                    self.verbose = verbose;
                else
                    error('inputLog não é do tipo InputLog');
                end
            elseif(nargin == 1)
                if isa(inputLog,'model.InputLog')
                    self.inputLog = inputLog;
                    self.carteiraInicial = model.Carteira(inputLog);
                    self.verbose = 2;
                else
                    error('inputLog não é do tipo InputLog');
                end
            else
                error('Numero de argumentos inválidos');
            end
        end
        
        % Simulada a carteira baseado nos modelos e inputs salvando o
        % resultado em um .mat
        % Preequisito: Carregar os modelos e inputs da carteira a simulação pode
        % Inputs
        % nSim: numero de cenarios
        % name: nome da simulação e do arquivo .mat de resultado
        % estrategia: cell de string que indicas as estratégia de
        %           acordo. é salvo um .mat para cada estratégia
        % Output
        % .mat chamado name_estrategia que contem o resultadoda simulação
        % resultSimulation: resultado da simualação, apenas o da ultuma estratégia
        % tempoSimulacao: vetor que contem o tempo de simulação de cada estratégia
        function [resultSimulation,tempoSimulacao]= simulate(self,nSim, name,estrategia,descricao,complemento)
           
            
            % verifica o numero de estratégia
            nEstrategia = length(estrategia);
            if(nEstrategia == 0)
                error('estrategia deve ser um vetor (cell) de string');
            end
            tempoSimulacao = zeros(nEstrategia,1);
            
            % Cria um resultSimulation (e um .mat) para cada estratégia
            for i=1:nEstrategia
                tinicial = tic;
                estra = estrategia{i};
                % resultSimulation = model.ResultSimulation(nSim, name, self.inputLog, estra, self.carteiraInicial);
                resultSimulation = model.ResultSimulationV2(name, self.inputLog, estra,descricao,complemento);
                
                % apaga a simulação anterior que tem o mesmo nome, estratégia e complemento                 
                if(strcmp(complemento,''))
                    nomeCompleto = [name '_' estra];
                else
                    nomeCompleto = [name '_' estra '_' complemento];
                end
                if(exist([nomeCompleto '.mat'],'file'))
                    model.apaga(nomeCompleto);
                    self.dispVerbose(['Apagando a simulação ' nomeCompleto ' anterior']);
                end
                %caso a estratégia seja do tipo optDireto, então
                %internamente o simula salvará os vetor de não acordo.
                %Então, pegamos esse vetor de não acordo e passamos para
                % a carteira incial, de modo que todas as copias de
                % carteira, disponham desse vetor pré calculado
                if(strncmp(estra,'optDireto',9)|| strncmp(estra,'primeiroSet',11))
                    ultimaLetra = estra(end);
                    if(ultimaLetra == 'U' )
                        self.carteiraInicial.loadNaoAcordo();
                    else
                        self.carteiraInicial.computaNaoAcordo();
                    end
                end
                
                %simula nSim cenarios
                for iSim = 1:nSim
                    self.dispVerbose(['Executando a simulação de numero ' num2str(iSim) ' com a estratégia ' estra]);
                    
                    % como durante a simuação o estado do carteira
                    % é modificado, temos fazer uma copia do
                    % carteira, mantendo o original intocavel.
                    copiaCarteira = deepCopy(self.carteiraInicial);
                    % define a estratégia
                    copiaCarteira.estrategia = estra;
                    %simula na copia do Carteira
                    if(self.verbose==2)
                        copiaCarteira.mostraProgresso = 1;
                    end
                    copiaCarteira.simula();
                    %Adiciona o resultado da simulação no objeto resultSimulation
                    resultSimulation.add(copiaCarteira.outputCarteira);
                end
                resultSimulation.carteiraInicial  = self.carteiraInicial.carteiraLimpa();
                % salva
                resultSimulation.salvar();
                % seta o tempo de simulação
                tempoSimulacao(i) = toc(tinicial);
            end
        end
        
        
        function [resultSimulation,tempoSimulacao]= simulateParFor(self,nSim, name,estrategia, nProcessadores, saveParcial, descricao,complemento)
                        
            if(nProcessadores>nSim)
                error('Numero de simulações deve ser maior ou igual ao numero de procesadores');
            end
            
            % verifica o numero de estratégia
            nEstrategia = length(estrategia);
            if(nEstrategia == 0)
                error('estrategia deve ser um vetor (cell) de string');
            end
            tempoSimulacao = zeros(nEstrategia,1);
            
            % cria parfor pool            
            pool = gcp('nocreate');
            if isempty(pool)
                parpool(nProcessadores);
            else
                if(pool.NumWorkers ~= nProcessadores)
                    delete(pool);
                    parpool(nProcessadores);
                end
            end
            
            % Cria um resultSimulation (e um .mat) para cada estratégia
            for i=1:nEstrategia
                tinicial = tic;
                estra = estrategia{i};
                
                % apaga a simulação anterior que tem o mesmo nome, estratégia e complemento                 
                if(strcmp(complemento,''))
                    nomeCompleto = [name '_' estra];
                else
                    nomeCompleto = [name '_' estra '_' complemento];
                end
                if(exist([nomeCompleto '.mat'],'file'))
                    model.apaga(nomeCompleto);
                    self.dispVerbose(['Apagando a simulação ' nomeCompleto ' anterior']);
                end
                
                
                %caso a estratégia seja do tipo optDireto, então
                %internamente o simula salvará os vetor de não acordo.
                %Então, pegamos esse vetor de não acordo e passamos para
                % a carteira incial, de modo que todas as copias de
                % carteira, disponham desse vetor pré calculado
                if(strncmp(estra,'optDireto',9) || strncmp(estra,'primeiroSet',11))
                    ultimaLetra = estra(end);
                    if(ultimaLetra == 'U')
                        self.carteiraInicial.loadNaoAcordo();
                    else                        
                        self.carteiraInicial.computaNaoAcordoParalelo();
                    end
                end
                
                cInicial = self.carteiraInicial;
                cLimpa = self.carteiraInicial.carteiraLimpa();
                
                %verifica se é o caso de fazer inicialmente simulação parcial e depois completar
                if(saveParcial)
                    nItecaoEstimacao = saveParcial;
                else
                    nItecaoEstimacao = nProcessadores;
                end
                                
                % iniciliza resultSimulation,estimadorTamanho e
                % outputCarteiraVec                
                estimadorTamanho = zeros(nItecaoEstimacao,1);
                outputCarteiraVec = cell(nItecaoEstimacao,1);
                if(saveParcial)
                    if(complemento == '')
                        resultSimulation= model.ResultSimulationV2(name, self.inputLog, estra,descricao, 'parcial');
                    else
                        resultSimulation= model.ResultSimulationV2(name, self.inputLog, estra,descricao, [complemento '_parcial']);
                    end
                else
                    resultSimulation= model.ResultSimulationV2(name, self.inputLog, estra,descricao, complemento);
                end
                resultSimulation.carteiraInicial = cLimpa;
                
                % Primeiro uma vez, estimando o tamanho da simulação
                parfor iSimu = 1:nItecaoEstimacao
                    disp(['Executando a simulação de numero ' num2str(iSimu) ' com a estratégia ' estra]);
                    % como durante a simulação o estado do carteira
                    % é modificado, temos fazer uma copia do
                    % carteira, mantendo o original intocavel.
                    copiaCarteira = deepCopy(cInicial);
                    % define a estratégia
                    copiaCarteira.estrategia = estra;
                    %simula na copia do Carteira
                    copiaCarteira.simula();
                    %Adiciona o resultado da simulação no objeto resultSimulation
                    outputCarteiraVec{iSimu} = copiaCarteira.outputCarteira;
                    estimadorTamanho(iSimu) = copiaCarteira.outputCarteira.getSize();
                end
               
                % Junta a primeira rodada
                for iSim = 1:nItecaoEstimacao
                    resultSimulation.add(outputCarteiraVec{iSim});
                    outputCarteiraVec{iSim} = [];
                end
                  
                % Salva resultado parcial               
                if(saveParcial)
                    resultSimulation.salvar();
                end
                resultSimulation.complemento = complemento;
                                
                % Estima o tamanho da primeira rodado, verificando quantos ciclos devemos simular
                iteracoesJaFeitas = nItecaoEstimacao+1;
                
                % tamanhoMédio de cada simulação           
                tamanhoEstimadoMedio = sum(estimadorTamanho)/nItecaoEstimacao;
                
                %numero de realizações possiveis de se simular em um ciclo sem estrapolar o limite
                nIteracoesPorCiclo = (self.memoriaLimitePC/tamanhoEstimadoMedio);
                
                % Modifica o numero de iterações por ciclos de modo que ele seja multiplo do numero de processadores            
                nIteracoesPorCiclo = floor(nIteracoesPorCiclo/nProcessadores)*nProcessadores;
                if(nIteracoesPorCiclo == 0)
                    error('Simulação muito grande,talvez o matlab não consiga gerir toda essa informação.Elevar o limite de memoria utilizavel por ciclo, ou diminua o numero de processadores utilizados simultaneamente')
                end
                numeroCiclos = ceil(nSim/nIteracoesPorCiclo);
                
                if(numeroCiclos>1)
                    disp('Será necessario fazer mais de um ciclo de simulação, isto é, a saidá terá mais de uma parte');
                    disp(['Serão executados ' num2str(numeroCiclos) ' ciclos. Cada ciclo com ' num2str(nIteracoesPorCiclo) ' iterações']);
                end
                
                % Completa resultSimulationVec para ser capaz de rodas as nIteracoesPorCiclo
                outputCarteiraVec = cell(nIteracoesPorCiclo,1);
                
                % Simula os ciclos
                for iCiclo=1:numeroCiclos                    
                    % Faz a iteração do ciclo
                    if(numeroCiclos>1)
                        self.dispVerbose(['Executando o ciclo de numero ' num2str(iCiclo) ' com a estratégia ' estra]);
                    end
                    
                    %Se for o ultimo ciclo executa o ciclo até nSim simulações
                    if(iCiclo == numeroCiclos)
                        nIteracoesPorCicloAtual = nSim-nIteracoesPorCiclo*(iCiclo-1);
                    else
                        nIteracoesPorCicloAtual = nIteracoesPorCiclo;
                    end
                        
%                   % Simula em paralelo   
                    parfor iteracaoDoCiclo = iteracoesJaFeitas:nIteracoesPorCicloAtual
                        disp(['Executando a simulação de numero ' num2str(iteracaoDoCiclo+(iCiclo-1)*nIteracoesPorCiclo) ' com a estratégia ' estra]);
                        copiaCarteira = deepCopy(cInicial);
                        copiaCarteira.estrategia = estra;
                        copiaCarteira.simula();
                        outputCarteiraVec{iteracaoDoCiclo} = copiaCarteira.outputCarteira;
                    end
                    
                    % Junta os ciclos
                    for iteracaoDoCiclo = iteracoesJaFeitas:nIteracoesPorCicloAtual
                        resultSimulation.add(outputCarteiraVec{iteracaoDoCiclo});
                        outputCarteiraVec{iteracaoDoCiclo} = [];
                    end
                    iteracoesJaFeitas = 1;
                    
%                     % Identifica complemento caso seja necessario mais de um ciclo
%                     if(numeroCiclos>1)
%                         resultSimulation.complemento = [complemento '_ciclo' num2str(iCiclo)];
%                     else                        
%                         resultSimulation.complemento = complemento;
%                     end
%                     
%                     resultSimulation.salvar();
                                        
                end
                resultSimulation.salvar();
                tempoSimulacao(i) = toc(tinicial);
                                
            end
        end
        
        % Carrega todos os modelos e inputs
        function loadAll(self)
            self.load(0);
        end
        
        % Carrega os modelos e inputs que foram modificados
        function loadModified(self)
            self.load(1);
        end
        
        % Carrega os modelos e inputs que foram setados no inputLog.
        % verificar: Boolean que indica se o carregamento é completo ou
        % apenas dos arquivos modificados
        function load(self,verificar)
            if(self.inputLog.usarIndicesCM == 1)
                self.loadIndiceCM(verificar);
            end
            if(self.inputLog.simuTrab == 1)
                self.loadArvore('Trab',self.inputLog.modeloArvore,verificar);
                self.loadGrafos('Trab',self.inputLog.grafosTrab,verificar);
                self.loadCurvas('Trab',self.inputLog.curvasTrab,self.inputLog.isCurvasDiferentesEmCadaBloco,verificar);
                self.loadInputs('Trab',self.inputLog.inputsTrab,verificar);
            end
            if(self.inputLog.simuCivel == 1)
                self.loadArvore('Civel',self.inputLog.modeloArvore,verificar);
                self.loadGrafos('Civel',self.inputLog.grafosCivel,verificar);
                self.loadCurvas('Civel',self.inputLog.curvasCivel,self.inputLog.isCurvasDiferentesEmCadaBloco,verificar);
                self.loadInputs('Civel',self.inputLog.inputsCivel,verificar);
            end
            if(self.inputLog.simuJec == 1)
                self.loadArvore('Jec',self.inputLog.modeloArvore,verificar);
                self.loadGrafos('Jec',self.inputLog.grafosJec,verificar);
                self.loadCurvas('Jec',self.inputLog.curvasJec,self.inputLog.isCurvasDiferentesEmCadaBloco,verificar);
                self.loadInputs('Jec',self.inputLog.inputsJec,verificar);
            end
        end
        
        % Carrega o modelo das arvores.
        % tipoArvore: String 'Trab', 'Civel' ou 'Jec'.
        % modeloArvore: Nome do excel que contem o modeloArvore
        % verificar: Boolean que indica se o carregamento é completo ou
        % apenas dos arquivos modificados
        function loadArvore(self,tipoArvore,modeloArvore, verificar)
            % verifica existencia do arquivo excel.
            if(~exist([modeloArvore '.xlsx'],'file'))
                error([modeloArvore '.xlsx  não localizado'])
            end
            
            % Chama o excelBuild para construir o modelo da arvore
            switch tipoArvore
                case 'Trab'
                    self.dispVerbose('Carregando o modelo arvore Trabalhista');
                    self.arvoreTrab = model.ArvoreModelo.excelBuild(modeloArvore,'Trab',verificar);
                case 'Civel'
                    self.dispVerbose('Carregando o modelo arvore Civel');
                    self.arvoreCivel = model.ArvoreModelo.excelBuild(modeloArvore,'Civel',verificar);
                case 'Jec'
                    self.dispVerbose('Carregando o modelo arvore Jec');
                    self.arvoreJec = model.ArvoreModelo.excelBuild(modeloArvore,'Jec',verificar);
                otherwise
                    error('tipoArvore não identificado. Ele pode ser Trab , Civel ou Jec')
            end
            
        end
        
        % Carrega o inputs da carteira
        % tipoArvore: String 'Trab', 'Civel' ou 'Jec'.
        % modeloArvore: Nome do excel que contem os inputs
        % verificar: Boolean que indica se o carregamento é completo ou
        % apenas dos arquivos modificados
        function loadInputs(self,tipoArvore,input,verificar)
            % verifica existencia do arquivo excel.
            if(~exist([input '.xlsx'],'file'))
                error([input  '.xlsx não localizado']);
            end
            
            % Chama o método loadProcessos do carteira para
            % carregar as informações do processo
            switch tipoArvore
                case 'Trab'
                    self.dispVerbose('Carregando os inputs Trabalhista');
                    self.carteiraInicial.loadProcessos(...
                        input,self.inputLog.classeProcesso,self.arvoreTrab,self.clusterTrab,self.curvasTrab, self.inputLog, verificar);
                case 'Civel'
                    self.dispVerbose('Carregando os inputs Civel');
                    self.carteiraInicial.loadProcessos(...
                        input,self.inputLog.classeProcesso,self.arvoreCivel,self.clusterCivel, self.curvasCivel, self.inputLog, verificar);
                case 'Jec'
                    self.dispVerbose('Carregando os inputs Jec');
                    self.carteiraInicial.loadProcessos(...
                        input,self.inputLog.classeProcesso,self.arvoreJec,self.clusterJec, self.curvasJec, self.inputLog, verificar);
                otherwise
                    error('tipoArvore não identificado. Ele pode ser Trab , Civel ou Jec')
            end
            
        end
        
        % Carrega os Grafos
        % tipoArvore: String 'Trab', 'Civel' ou 'Jec'.
        % input: Nome do excel que contem os grafos
        % verificar: Boolean que indica se o carregamento é completo ou
        % apenas dos arquivos modificados
        function loadGrafos(self,tipoArvore,input,verificar)
            % verifica existencia do arquivo excel.
            if(~exist([input '.xlsx'],'file'))
                error([input  '.xlsx não localizado']);
            end
            
            % Chama o excelBuild de GrafoBuilder para construir os grafos
            switch tipoArvore
                case 'Trab'
                    self.dispVerbose('Carregando os grafos Trabalhista');
                    self.clusterTrab = model.GrafoBuilder.excelBuild(input,self.inputLog,self.arvoreTrab,verificar);
                case 'Civel'
                    self.dispVerbose('Carregando os grafos Civel');
                    self.clusterCivel = model.GrafoBuilder.excelBuild(input,self.inputLog,self.arvoreCivel,verificar);
                case 'Jec'
                    self.dispVerbose('Carregando os grafos Jec');
                    self.clusterJec = model.GrafoBuilder.excelBuild(input,self.inputLog,self.arvoreJec,verificar);
                otherwise
                    error('tipoArvore não identificado. Ele pode ser Trab , Civel ou Jec')
            end
        end
        
        function loadCurvas(self,tipoArvore,input,isCurvasDiferentesEmCadaBloco,verificar)
            % verifica existencia do arquivo excel.
            if(~exist([input '.xlsx'],'file'))
                error([input  '.xlsx não localizado']);
            end
            
            % Chama o curvaBuilder de GrafoBuilder para construir as curvas
            switch tipoArvore
                case 'Trab'
                    self.dispVerbose('Carregando as curvas Trabalhista');
                    self.curvasTrab = model.GrafoBuilder.curvaBuilder(input,self.inputLog,self.arvoreTrab,isCurvasDiferentesEmCadaBloco,verificar);
                case 'Civel'
                    self.dispVerbose('Carregando as curvas Civel');
                    self.curvasCivel = model.GrafoBuilder.curvaBuilder(input,self.inputLog,self.arvoreCivel,isCurvasDiferentesEmCadaBloco,verificar);
                case 'Jec'
                    self.dispVerbose('Carregando as curvas Jec');
                    self.curvasJec = model.GrafoBuilder.curvaBuilder(input,self.inputLog,self.arvoreJec,isCurvasDiferentesEmCadaBloco,verificar);
                otherwise
                    error('tipoArvore não identificado. Ele pode ser Trab , Civel ou Jec')
            end
        end
        
        % Carrega o indice de correção monetaria
        function loadIndiceCM(self,verificar)
            
            DirInfoMat = dir([self.inputLog.arquivoIndiceCM '.mat']);
            DirInfoExcel = dir([self.inputLog.arquivoIndiceCM '.xlsx']);
                        
            if (verificar && exist([self.inputLog.arquivoIndiceCM '.mat'],'file') && ...
                    DirInfoMat.datenum > DirInfoExcel.datenum)
                load([self.inputLog.arquivoIndiceCM '.mat']);
                self.carteiraInicial.setIndiceMonetario(indiceMonetario,self.inputLog); %#ok<NODEF> é carregado durante o load
            else
                if(~exist([self.inputLog.arquivoIndiceCM '.xlsx'],'file'))
                    error([self.inputLog.arquivoIndiceCM '.xlsx não localizado']);
                end
                
                [~, sheets] = xlsfinfo([self.inputLog.arquivoIndiceCM '.xlsx']);                
                nSheet = length(sheets);
                indiceMonetario = cell(nSheet,1);
                for i=1:nSheet
                    [~,~,raw] = xlsread([self.inputLog.arquivoIndiceCM '.xlsx'],sheets{i});
%                     numel(raw,1) > 2
                    if(sum(isnan(raw{1,1})) == 0 && (i ~= model.ConstIndiceMonetario.referencia))
                        data = cellfun(@(date) datenum(date,'dd/mm/yyyy'),raw(:,1));
                        indiceAcumuladoEmensal = cell2mat(raw(:,2:3));
                        indiceMonetario{i} = [data indiceAcumuladoEmensal];
                    elseif(i == model.ConstIndiceMonetario.referencia)
                         data = cellfun(@(date) datenum(date,'dd/mm/yyyy'),raw(:,1));
                         indiceMonetario{i} = data;
                    else
                        indiceMonetario{i} = [];
                    end
                end
                save([self.inputLog.arquivoIndiceCM '.mat'],'indiceMonetario');                
                self.carteiraInicial.setIndiceMonetario(indiceMonetario,self.inputLog); 
            end
        end
                
        % Carrega o indice de correção monetaria
%         function loadIndiceCM(self,verificar)
%             
%             DirInfoMat = dir([self.inputLog.pastaIndiceCM '/indiceMonetario.mat']);
%             DirInfoIgpm = dir([self.inputLog.pastaIndiceCM '/igpm.xlsx']);
%             DirInfoInpc= dir([self.inputLog.pastaIndiceCM '/inpc.xlsx']);
%             DirInfoIpca= dir([self.inputLog.pastaIndiceCM '/ipca.xlsx']);
%             DirInfoTr= dir([self.inputLog.pastaIndiceCM '/tr.xlsx']);            
%             DirInfoJuros= dir([self.inputLog.pastaIndiceCM '/juros.xlsx']);
%             DirInfoJam= dir([self.inputLog.pastaIndiceCM '/jam.xlsx']);
%             DirInfoTaxa= dir([self.inputLog.pastaIndiceCM '/taxa.xlsx']);
%             
%             if (verificar && exist([self.inputLog.pastaIndiceCM '/indiceMonetario.mat'],'file') && ...
%                     DirInfoMat.datenum > DirInfoIgpm.datenum && ...
%                     DirInfoMat.datenum > DirInfoInpc.datenum && ...
%                     DirInfoMat.datenum > DirInfoTr.datenum && ...
%                     DirInfoMat.datenum > DirInfoIpca.datenum && ...
%                     DirInfoMat.datenum > DirInfoJuros.datenum && ...
%                     DirInfoMat.datenum > DirInfoJam.datenum && ...
%                     DirInfoMat.datenum > DirInfoTaxa.datenum)
%                 load([self.inputLog.pastaIndiceCM '/indiceMonetario.mat']);
%                 self.carteiraInicial.setIndiceMonetario(indiceMonetario); %#ok<NODEF> é carregado durante o load
%                 
%             else
%                 if(~exist([self.inputLog.pastaIndiceCM  '/igpm.xlsx'],'file'))
%                     error('igpm.xlsx não localizado');
%                 end
%                 if(~exist([self.inputLog.pastaIndiceCM '/inpc.xlsx'],'file'))
%                     error('inpc.xlsx não localizado');
%                 end
%                 if(~exist([self.inputLog.pastaIndiceCM '/ipca.xlsx'],'file'))
%                     error('ipca.xlsx não localizado');
%                 end
%                 if(~exist([self.inputLog.pastaIndiceCM '/tr.xlsx'],'file'))
%                     error('tr.xlsx não localizado');
%                 end
%                 if(~exist([self.inputLog.pastaIndiceCM '/juros.xlsx'],'file'))
%                     error('juros.xlsx não localizado');
%                 end
%                 if(~exist([self.inputLog.pastaIndiceCM '/jam.xlsx'],'file'))
%                     error('jam.xlsx não localizado');
%                 end
%                 if(~exist([self.inputLog.pastaIndiceCM '/taxa.xlsx'],'file'))
%                     error('taxa.xlsx não localizado');
%                 end
%                 
%                 [~,~,raw] = xlsread([self.inputLog.pastaIndiceCM '/ipca.xlsx']);
%                 data = cellfun(@(date) datenum(date,'dd/mm/yyyy'),raw(:,1));
%                 indice = cell2mat(raw(:,2:3));
%                 indiceMonetario{model.ConstIndiceMonetario.ipca} = [data indice];
%                 
%                 [~,~,raw] = xlsread([self.inputLog.pastaIndiceCM '/inpc.xlsx']);
%                 data = cellfun(@(date) datenum(date,'dd/mm/yyyy'),raw(:,1));
%                 indice = cell2mat(raw(:,2:3));
%                 indiceMonetario{model.ConstIndiceMonetario.inpc} = [data indice];
%                 
%                 [~,~,raw] = xlsread([self.inputLog.pastaIndiceCM '/igpm.xlsx']);
%                 data = cellfun(@(date) datenum(date,'dd/mm/yyyy'),raw(:,1));
%                  indice = cell2mat(raw(:,2:3));
%                 indiceMonetario{model.ConstIndiceMonetario.igpm} = [data indice];
%                 
%                 [~,~,raw] = xlsread([self.inputLog.pastaIndiceCM '/tr.xlsx']);
%                 data = cellfun(@(date) datenum(date,'dd/mm/yyyy'),raw(:,1));
%                  indice = cell2mat(raw(:,2:3));
%                 indiceMonetario{model.ConstIndiceMonetario.tr} = [data indice];
%                 
%                 [~,~,raw] = xlsread([self.inputLog.pastaIndiceCM '/juros.xlsx']);
%                 data = cellfun(@(date) datenum(date,'dd/mm/yyyy'),raw(:,1));
%                  indice = cell2mat(raw(:,2:3));
%                 indiceMonetario{model.ConstIndiceMonetario.juros} = [data indice];
%                 
%                 [~,~,raw] = xlsread([self.inputLog.pastaIndiceCM '/taxa.xlsx']);
%                 data = cellfun(@(date) datenum(date,'dd/mm/yyyy'),raw(:,1));
%                 indice = cell2mat(raw(:,2:3));
%                 indiceMonetario{model.ConstIndiceMonetario.taxa} = [data indice];
%                 
%                 [~,~,raw] = xlsread([self.inputLog.pastaIndiceCM '/jam.xlsx']);
%                 data = cellfun(@(date) datenum(date,'dd/mm/yyyy'),raw(:,1));
%                  indice = cell2mat(raw(:,2:3));
%                 indiceMonetario{model.ConstIndiceMonetario.jam} = [data indice];
%                 
%                 self.carteiraInicial.setIndiceMonetario(indiceMonetario);
%                 save([self.inputLog.pastaIndiceCM '/indiceMonetario.mat'],'indiceMonetario');
%                 
%             end
%         end
        
        function dispVerbose(self, str)
            if(self.verbose==1 || self.verbose==2)
                disp(str)
            end
        end
        
    end
    
end