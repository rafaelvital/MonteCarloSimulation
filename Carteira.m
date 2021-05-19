classdef Carteira < handle
    
    properties
        
        processos %lista que contém todos os processos da carteira.
        
        nAgente
        indiceTempo
        processoNoTempo %Lista que indica quais são os processos que devem ser executados em determinado instante de tempo, lembrar que o matlab começa do 1
        numeroProcessosAndamento
        outputCarteira
        
        % Parametros da simulaçãos
        data
        tsim
        fatorGetEsperado
        isDataPedMatrixDataDistribuicao
        filtroJulgamento
        honorarioSucumbencia
        ordenarGanhoEsperado
        naoPagaCondenacao
        recorreJulgamentoExecucao
        decideRecorrer
        aplicarMulta
        contribuidoresBudget
        
        % Variaveis Globais comum a todos os processos e tipos de carteira (civel, jec, trab)
        budgetVector
        estrategia %string que define o tipo de estratégia ('opt', 'rand', '40' , '100')
        capacityMes
        isTimeRand
        estrategiaDouble  %Caso a estratégia seja do tipo 0-100, essa variavel deve ser inicializada com esse valor numerico, caso contrario deve ser -1
        
        % Variavel usada para controlar o output da linha de comando
        reverseStr
        
        % Vetor que salve os parametros da estratégia Optimum
        nomeCarteira
        mapaNoh
        
        % durante a simulação mostra o progresso atual da simulação
        mostraProgresso
        
        % Parametros especificos (Usado para fazer algo especifico para
        % o cliente), esse atributo pode ser um escalar, vetor, cell ou objeto
        parametrosEspecificos
        
        ganhoEsperado
        indiceGanhoEsperado
        
        % Indices Monetarios
        indiceMonetario
        posicaoIndiceMonetarioInicial
        indiceMonetarioInicial
        
    end
    
    methods
        
        % Existe dois tipos de contrutores, um que inicia as "variaveis
        % globais" e o outro que é o construtor default. O normal é utilizar o
        % contrutor que inicializa as variaveis globais, mas algumas
        % operações, como por exemplo, a deepCopy requer um construtor
        % default.
        function self = Carteira(inputlog)
            if nargin == 1 && isa(inputlog,'model.InputLog')
                
                self.processos = cell(inputlog.nProcesso,1);
                self.nAgente  = 0;
                self.indiceTempo = 0;
                self.tsim = inputlog.tsim;
                self.processoNoTempo = cell(self.tsim+1,1);
                self.ganhoEsperado = cell(self.tsim+1,1);
                
                self.numeroProcessosAndamento = 0;
                self.outputCarteira = model.OutputCarteira(self.tsim, inputlog.nProcesso, inputlog.nPedido);
                
                self.data = inputlog.data;
                self.isTimeRand = inputlog.isTimeRand;
                self.fatorGetEsperado = inputlog.fatorGetEsperado;
                self.isDataPedMatrixDataDistribuicao = inputlog.isDataPedMatrixDataDistribuicao;
                self.filtroJulgamento = inputlog.filtroJulgamento;
                self.honorarioSucumbencia = inputlog.honorarioSucumbencia;
                self.ordenarGanhoEsperado = inputlog.ordenarGanhoEsperado;
                self.aplicarMulta = inputlog.aplicarMulta;
                
                self.estrategia = [];
                self.estrategiaDouble = -1;
                
                self.capacityMes = inputlog.capacity;
                self.budgetVector = inputlog.budgetVector;
                self.parametrosEspecificos = inputlog.parametrosEspecificos;
                
                self.reverseStr = '';
                
                self.nomeCarteira = inputlog.nomeCarteira;
                self.indiceGanhoEsperado = 1;
                self.naoPagaCondenacao = inputlog.naoPagaCondenacao;
                self.recorreJulgamentoExecucao = inputlog.recorreJulgamentoExecucao;
                self.decideRecorrer = inputlog.decideRecorrer;
                self.contribuidoresBudget = inputlog.contribuidoresBudget;
                
                % Indices Monetarios
                self.indiceMonetario = [];
                self.posicaoIndiceMonetarioInicial = [];
                self.indiceMonetarioInicial = [];
                
            elseif nargin == 0
                %              default Contructor
            else
                error('Numero de argumentos errado');
            end
            
        end
        
        % copia completa da carteira
        function obj = deepCopy(self)
            
            obj = model.Carteira();
            obj.tsim = self.tsim;
            obj.nAgente = self.nAgente;
            
            % Realiza a deepCopy de cada um dos Processos
            refObj = obj;
            for i = 1:self.nAgente
                obj.processos{i} = deepCopy(self.processos{i});
                obj.processos{i}.carteira = refObj;
                %Ao realizar a deepCopy, o handle da carteira deve apontar para
                %a nova carteira
            end
            obj.ganhoEsperado = self.ganhoEsperado;
            
            % Contiuna a deepcopy das outras variaveis
            obj.indiceTempo = self.indiceTempo;
            obj.numeroProcessosAndamento = self.numeroProcessosAndamento;
            obj.processoNoTempo = self.processoNoTempo;
            obj.outputCarteira = self.outputCarteira.deepCopy();
            
            obj.data = self.data;
            obj.tsim = self.tsim;
            
            obj.fatorGetEsperado = self.fatorGetEsperado;
            obj.isDataPedMatrixDataDistribuicao = self.isDataPedMatrixDataDistribuicao;
            obj.filtroJulgamento  = self.filtroJulgamento;
            obj.honorarioSucumbencia = self.honorarioSucumbencia;
            obj.isTimeRand = self.isTimeRand;
            obj.estrategia = self.estrategia;
            obj.ordenarGanhoEsperado = self.ordenarGanhoEsperado;
            
            obj.budgetVector = self.budgetVector;
            obj.capacityMes = self.capacityMes;
            obj.parametrosEspecificos = self.parametrosEspecificos;
            
            obj.estrategiaDouble = self.estrategiaDouble;
            obj.reverseStr = self.reverseStr;
            
            obj.nomeCarteira = self.nomeCarteira;
            obj.mapaNoh = self.mapaNoh; %Não é uma deepCopy
            obj.indiceGanhoEsperado = self.indiceGanhoEsperado;
            obj.naoPagaCondenacao = self.naoPagaCondenacao;
            obj.recorreJulgamentoExecucao = self.recorreJulgamentoExecucao;
            obj.decideRecorrer = self.decideRecorrer;
            obj.aplicarMulta = self.aplicarMulta;
            obj.contribuidoresBudget = self.contribuidoresBudget;
            
            obj.indiceMonetario = self.indiceMonetario;
            obj.posicaoIndiceMonetarioInicial = self.posicaoIndiceMonetarioInicial;
            obj.indiceMonetarioInicial = self.indiceMonetarioInicial;
            
        end
        
        %limpa a carteira retirando a referencia ciclica
        function obj = carteiraLimpa(self)
            obj = deepCopy(self);
            objInterno = deepCopy(self);
            for i=1:obj.nAgente
                obj.processos{i}.carteira = objInterno;
            end
            objInterno.processos = [];
            objInterno.outputCarteira = [];
            obj.outputCarteira = [];
            objInterno.processoNoTempo = [];
            obj.processoNoTempo = [];
            objInterno.ganhoEsperado = [];
            obj.ganhoEsperado = [];
            objInterno.mapaNoh = [];
            obj.mapaNoh = [];
        end
        
        %         function setIndiceMonetario(self,indiceMonetario)
        %             self.indiceMonetario = indiceMonetario;
        %             nIndice = size(self.indiceMonetario,2);
        %             self.posicaoIndiceMonetarioInicial = zeros(nIndice,1);
        %             self.indiceMonetarioInicial = zeros(nIndice,1);
        %             for i=1:nIndice
        %                 self.posicaoIndiceMonetarioInicial(i) = floor(interp1(self.indiceMonetario{i}(:,1),1:size(self.indiceMonetario{i},1),self.data));
        %                 self.indiceMonetarioInicial(i) = self.indiceMonetario{i}(self.posicaoIndiceMonetarioInicial(i),2);
        %             end
        %         end
        
        function setIndiceMonetario(self,indiceMonetario,inputLog)
            self.indiceMonetario = indiceMonetario;
            nIndice = size(self.indiceMonetario,1);
            self.posicaoIndiceMonetarioInicial = zeros(nIndice,1);
            self.indiceMonetarioInicial = zeros(nIndice,1);
            dataRefencia = self.indiceMonetario{model.ConstIndiceMonetario.referencia}(:,1);
            %             dataInicial =  datenum(model.ConstIndiceMonetario.dataInicial,'dd/mm/yyyy');
            
            for i=1:nIndice
                if(i ~= model.ConstIndiceMonetario.referencia)
                    indiceLocal = zeros(size(dataRefencia,1),3);
%                     indiceLocal(1:length(indiceMonetario{i}),1) = indiceMonetario{i}(:,1);
%                     
                    %verifica até qual data o indice correspondente está
                    %prenchida
                    if(~isempty(indiceMonetario{i}))
                        if(indiceMonetario{i}(1,1) ~= dataRefencia(1))
                            error(['Indice Monetario da aba de número ' num2str(i) ' não inicia no mesmo mês que a aba referencia ']);
                        end
                        dataPrenchida = size(indiceMonetario{i},1);
                        indiceLocal(1:dataPrenchida,2:3) = indiceMonetario{i}(1:dataPrenchida,2:3);
                    else
                        dataPrenchida = 1;
                        indiceLocal(1,2:3) = [1 1];
                    end
                    
                    %completa as datas
                    indiceLocal(:,1) = dataRefencia;
                    if(i <= model.ConstIndiceMonetario.indicesCiveis)
                        indiceLocal(dataPrenchida+1:end,3) = 1+inputLog.tc;
                        indiceLocal(dataPrenchida+1:end,2) = indiceLocal(dataPrenchida,2)*cumprod((1+inputLog.tc)*ones(length(indiceLocal)-dataPrenchida,1));
                    elseif(i == model.ConstIndiceMonetario.tr || i == model.ConstIndiceMonetario.trcomIpc ||  i == model.ConstIndiceMonetario.trsemIpc)
                        indiceLocal(dataPrenchida+1:end,3) = 1+inputLog.tr;
                        indiceLocal(dataPrenchida+1:end,2) = indiceLocal(dataPrenchida,2)*cumprod((1+inputLog.tr)*ones(length(indiceLocal)-dataPrenchida,1));
                    elseif(i == model.ConstIndiceMonetario.jam)
                        indiceLocal(dataPrenchida+1:end,3) = 1+inputLog.jam;
                        indiceLocal(dataPrenchida+1:end,2) = indiceLocal(dataPrenchida,2)*cumprod((1+inputLog.jam)*ones(length(indiceLocal)-dataPrenchida,1));
                    elseif(i == model.ConstIndiceMonetario.taxa)
                        indiceLocal(dataPrenchida+1:end,3) = 1+inputLog.taxaDescontoMensal;
                        indiceLocal(dataPrenchida+1:end,2) = indiceLocal(dataPrenchida,2)*cumprod((1+inputLog.taxaDescontoMensal)*ones(length(indiceLocal)-dataPrenchida,1));
                    elseif(i == model.ConstIndiceMonetario.juros)
                        indiceLocal(dataPrenchida+1:end,3) = inputLog.juros;
                        indiceLocal(dataPrenchida+1:end,2) = indiceLocal(dataPrenchida,2)*cumsum((inputLog.juros)*ones(length(indiceLocal)-dataPrenchida,1));
                    else
                        error(['Indice ' num2str(i) ' não definido em model.ConstIndiceMonetario']);
                    end
                    
                    self.indiceMonetario{i} = indiceLocal;
                    self.posicaoIndiceMonetarioInicial(i) = floor(interp1(self.indiceMonetario{i}(:,1),1:size(self.indiceMonetario{i},1),self.data));
                    self.indiceMonetarioInicial(i) = self.indiceMonetario{i}(self.posicaoIndiceMonetarioInicial(i),2);
                end
            end
        end
        
        % adiciona o processo na lista de processos
        function self = addProcesso(self,processo,tempo)
            % verifica consistencia no handle
            if(processo.carteira ~= self)
                error('Inconsistencia no handle do processo, ele não aponta para este carteira');
            end
            self.nAgente = self.nAgente + 1; %atualiza o numero de processos
            self.processos{processo.idAgente,1} = processo; %Adiciona o processona lista de processos na posição do id
            self.processoNoTempo{tempo+1}(end+1) = processo.idAgente; %Adiciona o processona para ser executado no instante tempo
            if(self.ordenarGanhoEsperado) %adiciona ganho esperado quando a opção for habilitada
                self.ganhoEsperado{tempo+1}(end+1) = processo.ganhoEsperado;
            end
            self.numeroProcessosAndamento = self.numeroProcessosAndamento+1; %aAtualiza processos em andamento
            self.outputCarteira.historico{processo.idAgente,1}(1,1:3) = [tempo processo.id_arvore_atual processo.id_bloco_atual];% Cria primeira entrada do historico
        end
        
        % Executa os processos que estão em 'processoNoTempo' do instante 'indiceTempo'
        function [terminouSimulacao,self] = executarCarteira(self)
            
            i = 1;
            
            %Enquanto ainda existir algum processo a ser executado no instante
            %de tempo indiceTempo
            while(i <= length(self.processoNoTempo{self.indiceTempo+1}))
                if(self.ordenarGanhoEsperado && i==self.indiceGanhoEsperado)
                    [Y,I] = sort(self.ganhoEsperado{self.indiceTempo+1}(self.indiceGanhoEsperado:end),2,'descend');
                    self.ganhoEsperado{self.indiceTempo+1}(self.indiceGanhoEsperado:end) = Y;
                    processoNoTempoProximo = self.processoNoTempo{self.indiceTempo+1}(self.indiceGanhoEsperado:end);
                    self.processoNoTempo{self.indiceTempo+1}(self.indiceGanhoEsperado:end) = processoNoTempoProximo(I);
                    self.indiceGanhoEsperado = length(self.processoNoTempo{self.indiceTempo+1})+1;
                end
                
                % Pega o id do processo a ser executado
                idProcesso = self.processoNoTempo{self.indiceTempo+1}(i);
                
                % Imprime na linha de comando o indice tempo e o Id do
                % processo em execução. Apagando a impressão anterior.
                if(self.mostraProgresso)
                    msg = sprintf('Indice Tempo: %d  IdProcesso: %d', self.indiceTempo,idProcesso);
                    fprintf([self.reverseStr, msg]);
                    self.reverseStr = repmat(sprintf('\b'), 1, length(msg));
                end
                
                %Executa o processo
                self.processos{idProcesso}.executarProcesso();
                servTime = self.processos{idProcesso}.servTime;
                
                % Se o processo não foi encerrado, o processo é realocado
                % no vetor processoNoTempo para o tempo adequado
                if(~self.processos{idProcesso}.processoEnc)
                    if( self.indiceTempo+servTime <= self.tsim)
                        self.processoNoTempo{self.indiceTempo+1+servTime}(end+1) = idProcesso;
                        self.ganhoEsperado{self.indiceTempo+1+servTime}(end+1) = self.processos{idProcesso}.ganhoEsperado;
                    end
                else
                    %Processo encerrado
                    self.numeroProcessosAndamento = self.numeroProcessosAndamento-1;
                end
                
                % Gera output
                self.outputCarteira.addOutput(self.processos{idProcesso},self.indiceTempo);
                
                % avança na lista do instante indiceTempo
                i = i + 1;
            end
            
            %Verifica se a simulação terminou de acordo com o numero de
            %processos em andamento, caso nao tenha terminado, na proxima
            %iteração iremos executar os processos que estão no indice de
            %tempo indiceTempo + 1
            if(self.numeroProcessosAndamento == 0)
                terminouSimulacao = true;
                self.outputCarteira.budgetVector = self.budgetVector;
            else
                self.indiceGanhoEsperado = 1;
                terminouSimulacao = false;
                if(self.budgetVector ~= -1)
                    self.processos{1}.gerenciaBudget();
                end
            end
            
        end % function executarCarteira
        
        % Simula até indiceTempo atingir tsim , ou todos os processos serem
        % encerrados
        function self = simula(self)
            
            % Verifica se foi escolhida uma estratégia não vazia
            if(isempty(self.estrategia))
                error('Estratégia não definidada');
            end
            
            %Verifica se a estratégia é numerica, e se está entre 0 e 100
            if(isfinite(str2double(self.estrategia)))
                self.estrategiaDouble = str2double(self.estrategia);
                if (self.estrategiaDouble < 0 || self.estrategiaDouble > 100)
                    disp(['Opcao de estrategia = ' self.estrategia ' invalida.']);
                    error('Entrada invalida');
                end
                self.estrategia = 'porcentagem';
            end
            
            % Realiza a configuração inicial do processo, o que inclui
            % o sorteio do percentual minimo de aceitação de acordo
            for i=1:self.nAgente
                self.processos{i}.preSimulacao();
            end
            
            % Simulação que interessa apenas as primeiras propostas de acordos
            if(strncmp(self.estrategia,'primeiroSet',11))
                if(self.estrategia(end)=='U')
                    numeroAcordos = str2double(self.estrategia(12:end-1));
                else
                    numeroAcordos = str2double(self.estrategia(12:end));
                end
                self.calculaPrimeiroSet(numeroAcordos);
            else
                % Faz os ciclos de simulação, avançando o tempo da carteira
                terminouSimulacao = false;
                while(self.indiceTempo <= self.tsim && ~terminouSimulacao)
                    [terminouSimulacao,self] = executarCarteira(self);
                    self.indiceTempo = self.indiceTempo+ 1;
                end
            end
            
            % Limpa o output da linha de comando
            if(self.mostraProgresso) %Caso esteja ativa a opção de detalhamento
                fprintf(self.reverseStr);
            end
        end
        
        % Carrega o mapa dos nós para cada processo. Usado na estrategia Optimum
        function loadNaoAcordo(self)
            disp('Carregando precalculado dos valores de não acordo');
            load([self.nomeCarteira '_naoAcordo.mat'],'mapaNoh');
            self.mapaNoh = mapaNoh;
        end
        
        % Cria e salva o mapa dos nós para cada processo. Usado na estrategia Optimum
        function computaNaoAcordo(self)
            self.mapaNoh = model.mapaNos(self.nAgente);
            disp('Calculando valores de não acordo');
            for i=1:self.nAgente
                % Imprime na linha de comando Id do processo que estásendo calculado
                msg = sprintf('IdProcesso: %d',i);
                fprintf([self.reverseStr, msg]);
                self.reverseStr = repmat(sprintf('\b'), 1, length(msg));
                [custo,tempo] = self.processos{i}.calculaNaoAcordo();
                self.mapaNoh.custo{i} = custo;
                self.mapaNoh.tempo{i} = tempo;
            end
            
            % fprintf(self.reverseStr);
            mapaNoh = self.mapaNoh;
            save([self.nomeCarteira '_naoAcordo.mat'],'mapaNoh');
            
        end
        
        % Cria e salva o mapa dos nós para cada processo. Usado na estrategia Optimum
        function computaNaoAcordoParalelo(self)
            self.mapaNoh = model.mapaNos(self.nAgente);
            disp('Calculando valores de não acordo usando parfor');
            listaProcesso = self.processos;
            custo = cell(self.nAgente,1);
            tempo = cell(self.nAgente,1);
            parfor i=1:self.nAgente
                [custo{i},tempo{i}] = listaProcesso{i}.calculaNaoAcordo();
            end
            
            self.mapaNoh.custo = custo;
            self.mapaNoh.tempo = tempo;
            
            mapaNoh = self.mapaNoh;
            save([self.nomeCarteira '_naoAcordo.mat'],'mapaNoh');
            
        end
        
        function calculaPrimeiroSet(self,numeroAcordos)
            for idProcesso=1:length(self.processos)
                self.processos{idProcesso}.calculaPrimeiroSetAcordo(numeroAcordos);
            end
        end
        
        %  Carrega os inputs dos processos do excel
        function loadProcessos(self,inputProcessos,classeProcesso,arvoreModelo,clusterArray, curvasArray, inputLogs, verificar)
            
            % Fazemos a leitura do excel apenas se ele sofreu alguma alteração
            % As abas do excel são salvos em uma celula de nSheet posiçoes.
            % Cada celula é da forma (nProcesso, :)
            % Onde : é um numero variavel segundo o sheet
            DirInfoMat = dir([inputProcessos '.mat']);
            DirInfoXls = dir([inputProcessos '.xlsx']);
            if verificar && exist([inputProcessos '.mat'],'file') && DirInfoMat.datenum > DirInfoXls.datenum
                load([inputProcessos '.mat']);
            else
                [numero,texto,~] = xlsread(inputProcessos);
                [~, sheets] = xlsfinfo(inputProcessos);
                nSheet = length(sheets);
                readMatlab = cell(nSheet,1);
                for i=1:nSheet
                    [~,~,readMatlab{i}] = xlsread(inputProcessos,sheets{i});
                end
                nProcesso = max(size(numero,1),size(texto,1));
                save([inputProcessos '.mat'],'sheets','nSheet','readMatlab','nProcesso');
            end
            
            % Partindo do .mat dos inputs, cria-se um processo, carrega os
            % atributos inciais do processo, inicializa os outros atributos que
            % dependem dos atributos iniciais e por fim  por fim adiciona
            % o processo na carteira e na fila de execução.
            for i=1:nProcesso
                handleProcesso = classeProcesso();
                handleProcesso.carteira = self;
                handleProcesso.arvoreModelo = arvoreModelo;
                handleProcesso.execucao_provisoria_port = inputLogs.execucao_provisoria_port;
                for j=1:1:nSheet
                    handleProcesso.loadProperties(sheets{j}, readMatlab{j}(i,:),self.mostraProgresso);
                end
                
                % Adiciona a curva ao processo
                handleProcesso.curvas = curvasArray;
                
                % Traduz o numero do cluster para a referencia ao objeto cluster
                handleProcesso.changeClusterNum2Obj(clusterArray);
                
                handleProcesso.posLoad();
                
                if(handleProcesso.data_reclamacao < 0)
                    self.addProcesso(handleProcesso,0);
                else
                    self.addProcesso(handleProcesso,round(handleProcesso.data_reclamacao));
                end
            end
        end
        
        function taxaVp = calculaTaxaPresente(self,numerador,denominador)
            posicaoTaxa = model.ConstIndiceMonetario.taxa;
            numerador = round(numerador);
            denominador = round(denominador);
            taxaVp = (self.indiceMonetario{posicaoTaxa}(self.posicaoIndiceMonetarioInicial(posicaoTaxa)+numerador,2)) / ...
                (self.indiceMonetario{posicaoTaxa}(self.posicaoIndiceMonetarioInicial(posicaoTaxa)+denominador,2));
        end
        
        function taxaJam = calculaJam(self,numerador,denominador)
            posicaoJam= model.ConstIndiceMonetario.jam;
            numerador = round(numerador);
            denominador = round(denominador);
            taxaJam = (self.indiceMonetario{posicaoJam}(self.posicaoIndiceMonetarioInicial(posicaoJam)+numerador,2)) / ...
                (self.indiceMonetario{posicaoJam}(self.posicaoIndiceMonetarioInicial(posicaoJam)+denominador,2));
        end
        
    end % method
    
end % class