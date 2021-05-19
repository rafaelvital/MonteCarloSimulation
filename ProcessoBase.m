classdef ProcessoBase < handle
    
    properties
        %Propriedades base do processo.
        idAgente
        nPedidos
        data_reclamacao
        data_distribuicao
        data_pedmatrix
        
        arvoreModelo %handle para a arvore Modelo
        carteira %handle do objeto carteira, comum a todos os processos
        cluster  %handle para o cluster do processo
        curvas %handle para a curva do processo
        UF %string
        
        listaCm %qual lista de correção monetaria usar
        indiceCmDataDistribuicao
        indiceJurosDataDistribuicao
        
        pedidos %array de double
        pedidos_deferidos  %array booleano
        pedidos_em_pauta  %array booleano
        
        valor_acordo
        fatorMulta
        
        primeiroAcordo %booleano que indica se já foi proposto ou não um acordo.
        percMinimoAcordo %percentual minimo para o reclamante aceitar acordo
        probMinimoAcordo %probabilidade associado ao percMinimoAcordo
        razaoSentenca %razão entre o valor_sentença antes e após julgamento
        
        % Os custos são momentaneos, dura apenas uma execução
        custo_recorrer_pago
        custo_recorrer
        custas_processuais % custo recorrer e pericial
        custo_deposito % depositos efetuados pelos reclamado no instante atual
        custo_honorario
        
        deposito_execucao % depositos acumulado
        deposito_recursal1 % depositos acumulado
        deposito_recursal2 % depositos acumulado
        
        id_arvore_atual
        id_bloco_atual
        
        tipoOutput
        switchPath
        processoEnc
        servTime
        
        primeiroServTime %booleano que indica se o processo já passou por um servTime .
        esperaInicial %Tempo em que o processo está parado no bloco Inicial.
        
        % execução provisoria, setado em 2
        execucao_provisoria_port;
        
        % provisao
        provisionado_julgamento
        provisionado_acordo
        provisionado_pagamento
        provisao
        
        % array, mesmo tamanho que pedidos, que indica a probabilidade de
        % ganhar a primeira instancia e reverter o resultado nos recursos
        matClasseProb
        matClasseProbDecisaoDef
        matClasseProbDecisaoIndef
        
        propostaNaoAceita %Proposta já oferecida e não aceita pelo reclamante
        contraProposta %Contra proposta minima oferecida pelo reclamante
        atualizarPropostaDeAcordo %Variavel que diz se temos que atualizar o valor do acordo,
        % entre o nó de proposta de acordo e de aceitação de acordo.
        
        custoMensal
        ganhoEsperado
        servTimePreSorteado
        idCliente
        tempoEncerramentoBloco
        
    end
    
    
    % Funções especificas do modelo
    methods (Abstract)
        
        % Função responsavel por dizer como funciona o custo mensal do
        % cliente. Dado o tempo inicial, a partir do inicio da carteira, e o tempo
        % final, calcula o valor dos honorarios do intervalo. Sendo que a
        % resposta se refere ao instante de tempo do tempoIncial.
        % fluxoHonorarioMensal é um vetor de tempo de tamanho tempoFinal-tempoInicial +1
        % com o desembolso de cada instante de tempo do intervalo
        [valorPresenteHonorarioMensal, fluxoHonorarioMensal] = calculaHonorarioMensal(self,tempoInicial, tempoFinal, taxaDescontoMensal)
        
        % dependePosicao é a parte que vai depender do arvore e do bloco atual ou de propriedades
        % estasticas do processo(pedMatrix e probabilidade)
        % naoDependePosicao são os honorarios de eventos que não dependem das proprieddaes acima
        % Usar a variavel do call do método quando queremos nos referir ao bloco
        [dependePosicao, naoDependePosicao] = calculaHonorariosEventos(self,arvore,bloco)
        
        % depende valor são os honorarios que dependem do valor de
        % acordo(desempenho/alcada)
        % naoDependeValorAcordo são so honrarios fixo de acordo, que não
        % depende do valor de acordo, mas pode depender de acordo com a
        % posição(arvore) ou estado(deferimento) do processo.
        [dependeValorAcordo, naoDependeValorAcordo] = calculaHonorarioAcordo(self)
        
        % A parte fixa é um valor fixo caso tenha exito, ou que dependa
        % apenas das variaveis estatica do
        % problema(pedMatrix,probabilidade)
        % ParteVariavel é o honorario de exito que depende dos atributos variaveis
        % do processo
        [parteFixa, parteVariavel] = calculaHonorarioExito(self)
        
        % Deve-se usar a variavel valorSentenca do call.
        % O output é dividido em duas partes, uma que depende exclusivamento do valorSenteça.
        % Outra que pode depender dos demais atributos de Processo
        [dependeSentenca,naoDependeSentenca]  = calculaHonorarioCondenacao(self,valorSentenca)
        
        especificoRecorrer(self)
        
        copy = deepCopy(ori)
        
        loadPropertiesEspecifico(self,nome,valor)
        
        estrategiaEspecifica(self)
        
        modificaProbabilidadeAcordo(self)
        
        gerenciaBudget(self)
        
    end
    
    methods
        
        % Construtor
        function self = ProcessoBase()
            self.idAgente = 0;
            self.data_reclamacao = 0;
            self.data_distribuicao = 0;
            self.data_pedmatrix = 0;
            self.arvoreModelo = 0;
            self.carteira = 0;
            self.cluster  = 0;
            self.curvas = 0;
            self.pedidos = 0;
            self.pedidos_deferidos = 0;
            self.pedidos_em_pauta = 0;
            self.valor_acordo = 0;
            self.custo_recorrer_pago = 0;
            self.custo_recorrer = 0;
            self.custas_processuais = 0;
            self.custo_deposito = 0;
            self.custo_honorario = 0;
            self.deposito_execucao = 0;
            self.deposito_recursal1 = 0;
            self.deposito_recursal2 = 0;
            self.id_arvore_atual = 0;
            self.id_bloco_atual = 0;
            self.servTime = 0;
            self.switchPath = 0;
            self.processoEnc = 0;
            self.execucao_provisoria_port = [];
            self.primeiroServTime = [];
            self.esperaInicial = 0;
            self.provisionado_julgamento = 0;
            self.provisionado_acordo = 0;
            self.provisionado_pagamento = 0;
            self.provisao = 0;
            self.matClasseProb = 0;
            self.matClasseProbDecisaoDef = 0;
            self.matClasseProbDecisaoIndef = 0;
            self.nPedidos = 0;
            self.primeiroAcordo = [];
            self.tipoOutput = [];
            self.percMinimoAcordo = 0;
            self.probMinimoAcordo = 0;
            self.UF = 0;
            self.propostaNaoAceita = -1;
            self.contraProposta = -1;
            self.atualizarPropostaDeAcordo = 0;
            self.custoMensal = 0;
            self.servTimePreSorteado = -1;
            self.ganhoEsperado = 0;
            self.idCliente = [];
            self.tempoEncerramentoBloco = 0;
            self.listaCm = [];
            self.indiceCmDataDistribuicao = [];
            self.fatorMulta = 1;
            self.indiceJurosDataDistribuicao = [];
            
        end
        
        %deepCopy
        function deepCopyBase(copy,ori)
            copy.carteira = ori.carteira;
            copy.idAgente = ori.idAgente;
            copy.data_reclamacao = ori.data_reclamacao;
            copy.data_distribuicao = ori.data_distribuicao;
            copy.data_pedmatrix = ori.data_pedmatrix;
            copy.arvoreModelo = ori.arvoreModelo;
            copy.cluster  = ori.cluster;
            copy.curvas = ori.curvas;
            copy.pedidos = ori.pedidos;
            copy.pedidos_deferidos = ori.pedidos_deferidos;
            copy.pedidos_em_pauta = ori.pedidos_em_pauta;
            copy.valor_acordo = ori.valor_acordo;
            copy.custo_recorrer_pago = ori.custo_recorrer_pago;
            copy.custo_recorrer = ori.custo_recorrer;
            copy.custas_processuais = ori.custas_processuais;
            copy.custo_deposito = ori.custo_deposito;
            copy.custo_honorario = ori.custo_honorario;
            copy.deposito_execucao = ori.deposito_execucao;
            copy.deposito_recursal1 = ori.deposito_recursal1;
            copy.deposito_recursal2 = ori.deposito_recursal2;
            copy.id_arvore_atual = ori.id_arvore_atual;
            copy.id_bloco_atual = ori.id_bloco_atual;
            copy.servTime = ori.servTime;
            copy.switchPath = ori.switchPath;
            copy.primeiroServTime =ori.primeiroServTime;
            copy.esperaInicial = ori.esperaInicial;
            copy.processoEnc = ori.processoEnc;
            copy.execucao_provisoria_port = ori.execucao_provisoria_port;
            copy.provisionado_julgamento = ori.provisionado_julgamento;
            copy.provisionado_acordo = ori.provisionado_acordo;
            copy.provisionado_pagamento = ori.provisionado_pagamento;
            copy.provisao = ori.provisao;
            copy.matClasseProb = ori.matClasseProb;
            copy.matClasseProbDecisaoDef = ori.matClasseProbDecisaoDef;
            copy.matClasseProbDecisaoIndef = ori.matClasseProbDecisaoIndef;
            copy.nPedidos = ori.nPedidos;
            copy.primeiroAcordo = ori.primeiroAcordo;
            copy.tipoOutput = ori.tipoOutput;
            copy.percMinimoAcordo = ori.percMinimoAcordo;
            copy.probMinimoAcordo = ori.probMinimoAcordo;
            copy.UF = ori.UF;
            copy.propostaNaoAceita = ori.propostaNaoAceita;
            copy.contraProposta = ori.contraProposta;
            copy.atualizarPropostaDeAcordo = ori.contraProposta;
            copy.custoMensal = ori.custoMensal;
            copy.servTimePreSorteado = ori.servTimePreSorteado;
            copy.ganhoEsperado = ori.ganhoEsperado;
            copy.idCliente = ori.idCliente;
            copy.tempoEncerramentoBloco = ori.tempoEncerramentoBloco;
            copy.listaCm  = ori.listaCm;
            copy.indiceCmDataDistribuicao = ori.indiceCmDataDistribuicao;
            copy.fatorMulta = ori.fatorMulta;
            copy.indiceJurosDataDistribuicao = ori.indiceJurosDataDistribuicao;
        end
        
        %ExecutarProcesso
        function executarProcesso(self)
            
            %Inicializa os atributos momentaneos
            self.ganhoEsperado = 0;
            self.razaoSentenca = 0;
            self.provisionado_julgamento = 0;
            self.provisionado_acordo = 0;
            self.provisionado_pagamento = 0;
            self.processoEnc = 0;
            self.custo_honorario = 0;
            self.custas_processuais = 0;
            self.custo_deposito = 0;
            carteira_ = self.carteira;
            arvoreModelo_ = self.arvoreModelo;
            
            % Verifica se o noh atual é controle ou externo, executando o
            % método estrategia ou externo
            if(arvoreModelo_.tipo(self.id_arvore_atual, self.id_bloco_atual) == model.NohModelo.CONTROLE)
                self.estrategia(); %custo_deposito, custo_recorer, valor_acordo, siwtchPath, custo_pericia
            else
                self.externo();%valor_acordo, siwtchPath, custo_pericia
            end
            
            % Identifica o Tipo de saida e o proximo Bloco de acordo com o
            % switchPath
            if(self.switchPath == 1)
                id_arvore_proximo = arvoreModelo_.proximoArvore1(self.id_arvore_atual, self.id_bloco_atual);
                id_bloco_proximo = arvoreModelo_.proximoBloco1(self.id_arvore_atual, self.id_bloco_atual);
                tipoDeSaida = arvoreModelo_.tipoSink1(self.id_arvore_atual, self.id_bloco_atual);
            else
                id_arvore_proximo = arvoreModelo_.proximoArvore2(self.id_arvore_atual, self.id_bloco_atual);
                id_bloco_proximo = arvoreModelo_.proximoBloco2(self.id_arvore_atual, self.id_bloco_atual);
                tipoDeSaida = arvoreModelo_.tipoSink2(self.id_arvore_atual, self.id_bloco_atual);
            end
            
            % Condicionalmente de execucao_provisoria_port, existe para os
            % modelos civel e trabalhista.
            if(self.execucao_provisoria_port == 1)
                if(id_arvore_proximo == 101 && id_bloco_proximo == 1 && ...
                        (arvoreModelo_.tipoModelo == 1 ||arvoreModelo_.tipoModelo == 3))
                    id_bloco_proximo = 3;
                    % tipoDeSaida = model.NohModelo.COMUM;
                end
            end
            
            % Executa o método funcServTime
            self.funcServTime();
            
            % Tipo de saida
            switch tipoDeSaida
                case model.NohModelo.ACORDO
                    % cria output acordo
                    % encerra processo
                    self.tipoOutput = tipoDeSaida; %model.NohModelo.ACORDO
                    [dependeValorAcordo, naoDependeValorAcordo]  = self.calculaHonorarioAcordo();
                    self.custo_honorario = self.custo_honorario+dependeValorAcordo+naoDependeValorAcordo;
                    self.processoEnc = 1;
                    
                    %Contabiliza a saida de deposito no budgetVector (o acordo é contabilizado na função externo)
                    if(carteira_.contribuidoresBudget(6))
                        carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1) = ...
                            carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1)+ ...
                            self.deposito_execucao + self.deposito_recursal1+self.deposito_recursal2 ;
                    end
                    
                case model.NohModelo.CONDENACAO
                    % cria output de condenacao
                    % encerra processo
                    self.tipoOutput = tipoDeSaida; %model.NohModelo.CONDENACAO
                    valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo+self.servTime, self.pedidos_deferidos, self.fatorMulta);
                    [dependeSentenca,naoDependeSentenca] = self.calculaHonorarioCondenacao(valor_sentenca);
                    self.custo_honorario = self.custo_honorario+dependeSentenca+naoDependeSentenca;
                    self.processoEnc = 1;
                    self.tempoEncerramentoBloco = self.carteira.indiceTempo;
                    
                    %Contabiliza a condenação e a saide de deposito no budgetVector
                    if(carteira_.contribuidoresBudget(2))
                        carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1) = ...
                            carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1)-valor_sentenca;
                    end
                    if(carteira_.contribuidoresBudget(6))
                        carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1) = ...
                            carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1)+ ...
                            self.deposito_execucao + self.deposito_recursal1+self.deposito_recursal2 ;
                    end
                    
                case model.NohModelo.EXITO
                    % cria output exito
                    % encerra processo
                    self.tipoOutput = tipoDeSaida; %model.NohModelo.EXITO
                    [parteFixa, parteVariavel] = self.calculaHonorarioExito();
                    self.custo_honorario = self.custo_honorario+parteFixa+parteVariavel;
                    self.processoEnc = 1;
                    
                    %Contabiliza a saida de deposito no budgetVector
                    if(carteira_.contribuidoresBudget(6))
                        carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1) = ...
                            carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1)+ ...
                            self.deposito_execucao + self.deposito_recursal1+self.deposito_recursal2 ;
                    end
                    
                case model.NohModelo.EXECUCAO
                    if sum(self.pedidos_deferidos) > 0
                        self.tipoOutput = model.NohModelo.COMUM;
                        % continua na arvore execucao
                    else
                        % cria output exito
                        % encerra processo
                        self.tipoOutput = model.NohModelo.EXITO;
                        [parteFixa, parteVariavel] = self.calculaHonorarioExito();
                        self.custo_honorario = self.custo_honorario+parteFixa+parteVariavel;
                        self.processoEnc = 1;
                        
                        %Contabiliza o deposito no budgetVector
                        if(carteira_.contribuidoresBudget(6))
                            carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1) = ...
                                carteira_.budgetVector(carteira_.indiceTempo+self.servTime,1)+ ...
                                self.deposito_execucao + self.deposito_recursal1+self.deposito_recursal2 ;
                        end
                    end
                    
                case model.NohModelo.JULGAMENTO_1a
                    % cria output julgamento
                    self.tipoOutput = tipoDeSaida; %model.NohModelo.JULGAMENTO_1a
                    
                case model.NohModelo.JULGAMENTO_1b
                    % cria output julgamento
                    self.tipoOutput = tipoDeSaida; %model.NohModelo.JULGAMENTO_1b
                    
                case model.NohModelo.JULGAMENTO_2a
                    % cria output julgamento
                    self.tipoOutput = tipoDeSaida; %model.NohModelo.JULGAMENTO_2a
                    
                case model.NohModelo.JULGAMENTO_2b
                    % cria output julgamento
                    self.tipoOutput = tipoDeSaida; %model.NohModelo.JULGAMENTO_2b
                    
                case model.NohModelo.JULGAMENTO_3a
                    % cria output julgamento
                    self.tipoOutput = tipoDeSaida; %model.NohModelo.JULGAMENTO_3a
                    
                case model.NohModelo.JULGAMENTO_3b
                    % cria output julgamento
                    self.tipoOutput = tipoDeSaida; %model.NohModelo.JULGAMENTO_3b
                    
                case model.NohModelo.JULGAMENTO_4a
                    % cria output julgamento
                    self.tipoOutput = tipoDeSaida; %model.NohModelo.JULGAMENTO_4a
                    
                case model.NohModelo.JULGAMENTO_4b
                    % cria output julgamento
                    self.tipoOutput = tipoDeSaida; %model.NohModelo.JULGAMENTO_4b
                    
                case model.NohModelo.JULGAMENTO_2a_EXECUCAO
                    if sum(self.pedidos_deferidos) > 0
                        % continua na arvore execucao
                        % Portanto nó é apenas un julgamento
                        self.tipoOutput = model.NohModelo.JULGAMENTO_2a;
                    else
                        % cria output Julgamento e Exito
                        % encerra processo
                        self.tipoOutput = tipoDeSaida; %model.NohModelo.JULGAMENTO_2a_EXECUCAO
                        [parteFixa, parteVariavel] = self.calculaHonorarioExito();
                        self.custo_honorario = self.custo_honorario+parteFixa+parteVariavel;
                        self.processoEnc = 1;
                        %Contabiliza o deposito no budgetVector
                        if(carteira_.contribuidoresBudget(6))
                            carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1) = ...
                                carteira_.budgetVector(carteira_.indiceTempo+self.servTime,1)+ ...
                                self.deposito_execucao + self.deposito_recursal1+self.deposito_recursal2 ;
                        end
                    end
                    
                case model.NohModelo.JULGAMENTO_2b_EXECUCAO
                    if sum(self.pedidos_deferidos) > 0
                        % continua na arvore execucao
                        % Portanto nó é apenas un julgamento
                        self.tipoOutput = model.NohModelo.JULGAMENTO_2b;
                    else
                        % cria output Julgamento e Exito
                        % encerra processo
                        self.tipoOutput =  tipoDeSaida; %model.NohModelo.JULGAMENTO_2b_EXECUCAO
                        [parteFixa, parteVariavel] = self.calculaHonorarioExito();
                        self.custo_honorario = self.custo_honorario+parteFixa+parteVariavel;
                        self.processoEnc = 1;
                        if(carteira_.contribuidoresBudget(6))
                            carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1) = ...
                                carteira_.budgetVector(carteira_.indiceTempo+self.servTime,1)+ ...
                                self.deposito_execucao + self.deposito_recursal1+self.deposito_recursal2 ;
                        end
                    end
                    
                case model.NohModelo.COMUM
                    self.tipoOutput =  tipoDeSaida; %model.NohModelo.COMUM
                    % encerra processo
                    
                otherwise
                    error('Tipo de Sink não identificado');
                    
            end % switch
            
            % calcula honorarios evento
            [dependePosicao, naoDependePosicao] = calculaHonorariosEventos(self,id_arvore_proximo,id_bloco_proximo);
            self.custo_honorario = self.custo_honorario+dependePosicao+naoDependePosicao;
            
            % Honorario de sucumbencia
            if(carteira_.honorarioSucumbencia ~= 0)
                switch arvoreModelo_.tipoModelo
                    case 2
                        if id_arvore_proximo == 101 && id_bloco_proximo == 1
                            if(carteira_.honorarioSucumbencia == 1)
                                self.fatorMulta = self.fatorMulta  * 1.1;
                            elseif(carteira_.honorarioSucumbencia == 2)
                                self.fatorMulta  = self.fatorMulta  * (1.1 + rand()*0.1);
                            else
                                error('Honorario de Sucumencia deve assumir valor 0, 1 ou 2');
                            end
                        end
                    case 3
                        if id_arvore_proximo == 101 && id_bloco_proximo == 1
                            if(carteira_.honorarioSucumbencia == 1)
                                self.fatorMulta  = self.fatorMulta  * 1.1;
                            elseif(carteira_.honorarioSucumbencia == 2)
                                self.fatorMulta  = self.fatorMulta  * (1.1 + rand()*0.1);
                            else
                                error('Honorario de Sucumencia deve assumir valor 0, 1 ou 2');
                            end
                        end
                end
            end
            
            % Atualiza a percMinimoAcordo, dependendo se o reclamante
            % ganhou o perdeu, considerando o destino do processo
            self.atualizaPercMinimoAcordo();
            
            % Atualiza o bloco atual usando a informaçõa do id_proximo e da
            % execução provisória
            self.id_arvore_atual = id_arvore_proximo;
            self.id_bloco_atual = id_bloco_proximo;
            
            %BudgetVector Honorarios
            if(carteira_.contribuidoresBudget(3))
                %Honorario de evento e de encerarmento
                carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1) = ...
                    carteira_.budgetVector(carteira_.indiceTempo+self.servTime+1,1)-self.custo_honorario;
                
                %honorario mensal
                [~, fluxoHonorarioMensal] = self.calculaHonorarioMensal(carteira_.indiceTempo, carteira_.indiceTempo+self.servTime, carteira_.taxaDescontoMensal);
                carteira_.budgetVector(carteira_.indiceTempo+1:carteira_.indiceTempo+self.servTime+1,1) = ...
                    carteira_.budgetVector(carteira_.indiceTempo+1:carteira_.indiceTempo+self.servTime+1,1)-fluxoHonorarioMensal;
            end
            
            %BudgetVector custas processuais
            if(carteira_.contribuidoresBudget(4))
                carteira_.budgetVector(carteira_.indiceTempo+1,1) = ...
                    carteira_.budgetVector(carteira_.indiceTempo+1,1)-self.custas_processuais;
            end
            
            %BudgetVector Entrada deposito
            if(carteira_.contribuidoresBudget(5))
                carteira_.budgetVector(carteira_.indiceTempo+1,1) = ...
                    carteira_.budgetVector(carteira_.indiceTempo+1,1)-self.custo_deposito;
            end
            
            
        end % termino da função executar processo
        
        function preSimulacao(self)
            % Boleana que controla a primeira proposta de acordo
            self.primeiroAcordo = 1;
            
            % Boleana que controla o primeiroServTime
            self.primeiroServTime = 1;
            
            % Boleana que controla a primeira proposta de acordo
            self.sorteiaPercMim();
        end
        
        function posLoad(self)
            
            % define a regra de multa(talvez devamos colocar a regra de multa e sucumbencia aqui)
            self.fatorMulta = 1;
            
            % define o indicador de correção monetária
            if((self.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel) || (self.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_jec))
                % verifica qual indice de correção monetaria usar de acordo
                % com a UF
                switch self.UF
                    case 'AC'
                        self.listaCm = model.ConstIndiceMonetario.ac;
                    case 'AL'
                        self.listaCm = model.ConstIndiceMonetario.al;
                    case 'AP'
                        self.listaCm = model.ConstIndiceMonetario.ap;
                    case 'AM'
                        self.listaCm = model.ConstIndiceMonetario.am;
                    case 'BA'
                        self.listaCm = model.ConstIndiceMonetario.ba;
                    case 'CE'
                        self.listaCm = model.ConstIndiceMonetario.ce;
                    case 'DF'
                        self.listaCm = model.ConstIndiceMonetario.df;
                    case 'ES'
                        self.listaCm = model.ConstIndiceMonetario.es;
                    case 'GO'
                        self.listaCm = model.ConstIndiceMonetario.go;
                    case 'MA'
                        self.listaCm = model.ConstIndiceMonetario.ma;
                    case 'MT'
                        self.listaCm = model.ConstIndiceMonetario.mt;
                    case 'MS'
                        self.listaCm = model.ConstIndiceMonetario.ms;
                    case 'MG'
                        self.listaCm = model.ConstIndiceMonetario.mg;
                    case 'PA'
                        self.listaCm = model.ConstIndiceMonetario.pa;
                    case 'PB'
                        self.listaCm = model.ConstIndiceMonetario.pb;
                    case 'PR'
                        self.listaCm = model.ConstIndiceMonetario.pr;
                    case 'PE'
                        self.listaCm = model.ConstIndiceMonetario.pe;
                    case 'PI'
                        self.listaCm = model.ConstIndiceMonetario.pi;
                    case 'RJ'
                        self.listaCm = model.ConstIndiceMonetario.rj;
                    case 'RN'
                        self.listaCm = model.ConstIndiceMonetario.rn;
                    case 'RS'
                        self.listaCm = model.ConstIndiceMonetario.rs;
                    case 'RO'
                        self.listaCm = model.ConstIndiceMonetario.ro;
                    case 'RR'
                        self.listaCm = model.ConstIndiceMonetario.rr;
                    case 'SC'
                        self.listaCm = model.ConstIndiceMonetario.sc;
                    case 'SP'
                        self.listaCm = model.ConstIndiceMonetario.sp;
                    case 'SE'
                        self.listaCm = model.ConstIndiceMonetario.se;
                    case 'TO'
                        self.listaCm = model.ConstIndiceMonetario.to;
                    otherwise
                        error('UF não reconhecida');
                end
            elseif(self.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab)
                self.listaCm = model.ConstIndiceMonetario.tr;
            end
            
            % calcula o indiceCm na data de distribuição
            self.indiceCmDataDistribuicao = exp(interp1(self.carteira.indiceMonetario{self.listaCm}(:,1),log(self.carteira.indiceMonetario{self.listaCm}(:,2)),self.data_distribuicao));
            posicaoJuros = model.ConstIndiceMonetario.juros;
            self.indiceJurosDataDistribuicao =  interp1(self.carteira.indiceMonetario{posicaoJuros}(:,1),self.carteira.indiceMonetario{posicaoJuros}(:,2),self.data_distribuicao);
            
            % ajusta o valor dos pedidos para estarem na data de distribuição            
            if(~self.carteira.isDataPedMatrixDataDistribuicao)
                indiceCmPedMatrix = exp(interp1(self.carteira.indiceMonetario{self.listaCm}(:,1),log(self.carteira.indiceMonetario{self.listaCm}(:,2)),self.data_pedmatrix));
                indiceJurosPedMatrix =  interp1(self.carteira.indiceMonetario{posicaoJuros}(:,1),self.carteira.indiceMonetario{posicaoJuros}(:,2),self.data_pedmatrix);
                self.pedidos = self.pedidos*self.indiceCmDataDistribuicao/indiceCmPedMatrix / (1+indiceJurosPedMatrix-self.indiceJurosDataDistribuicao);
            end
            
        end
        
        function valor_processo = calculaValorProcesso(self,tempoSimulacao, multiplicadorPedidos,multiplicador)
            posicaoJuros = model.ConstIndiceMonetario.juros;
            valor_processo = multiplicador * sum(self.pedidos .* multiplicadorPedidos) *...
               (self.carteira.indiceMonetario{self.listaCm}(self.carteira.posicaoIndiceMonetarioInicial(self.listaCm)+tempoSimulacao,2)/self.indiceCmDataDistribuicao) * ...
               (1+self.carteira.indiceMonetario{posicaoJuros}(self.carteira.posicaoIndiceMonetarioInicial(posicaoJuros)+tempoSimulacao,2)-self.indiceJurosDataDistribuicao);
        end
        
        %Define percentual minimo de aceitaçao de acordo
        function sorteiaPercMim(self)
            
            self.probMinimoAcordo = rand;            
            [curvaAcordo] = self.curvaAcordoAjustada(0);
            self.percMinimoAcordo = interp1(curvaAcordo(:,2), curvaAcordo(:,1),...
                self.probMinimoAcordo);
        end
                
        % Retorna a curva de acordo considerando as proposta e as
        % contrapropostas
        function curvaAcordo = curvaAcordoAjustada(self,blocoAtual)
            
            %Se bloco atual for 1, pega a curva de acordo desse bloco, caso
            %contrario pega a curva de acordo do proximo bloco de acordo
            if(blocoAtual)
                idArvoreDeAcordo = self.id_arvore_atual;
                idBlocoDeAcordo = self.id_bloco_atual;
            else
                [idArvoreDeAcordo,idBlocoDeAcordo]  = self.arvoreModelo.proximoAcordo(self.id_arvore_atual,self.id_bloco_atual);
            end
            
            curvaAcordo = self.curvas.curva_acordo{idArvoreDeAcordo,idBlocoDeAcordo};
            
            % Caso exista proposta não aceita e contraporposta
            if(self.propostaNaoAceita ~= -1 || self.contraProposta~= -1)
                delta = 1e-6*min(min(curvaAcordo(2:end,:)));
                
                valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                %valor_nao_contestado = self.calculaValorProcesso(carteira_.indiceTempo, ~self.pedidos_em_pauta, self.fatorMulta);
                valor_contestadoProp = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
             
                % Calcula percentual relativo a proposta não aceita
                if(self.propostaNaoAceita ~= -1)
                    switch self.id_arvore_atual
                        case 1
                            percNaoAceito = self.propostaNaoAceita/valor_contestadoProp;
                        otherwise
                            percNaoAceito = self.propostaNaoAceita/(valor_sentenca+0.000001);
                    end
                    if(percNaoAceito<curvaAcordo(end,1))
                        probNaoAceito = interp1(curvaAcordo(:,1),curvaAcordo(:,2),percNaoAceito);
                    else
                        disp(['Id processo:' num2str(self.idAgente)]);
                        disp(['Proposta de acordo não aceito acima do range da curva de acordo: ' num2str(self.propostaNaoAceita)]);
                        disp(['Valor_contestado: ' num2str(valor_contestadoProp)]);
                        disp(['[Maximo percentual da Curva: ' num2str(curvaAcordo(end,1))]);
                        disp('Assumindo Proposta de acordo não aceito igual ao maximo da curva');
                        disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
                        percNaoAceito = curvaAcordo(end,1)-2*delta; % 2 delta para não dar conflito com a contraproposta que é delta
                        probNaoAceito = delta;
                    end
                end
                
                % Calcula percentual relativo a contraporposta
                if(self.contraProposta ~= -1)
                    switch self.id_arvore_atual
                        case 1
                            percContraProposta= self.contraProposta/valor_contestadoProp;
                            %                         case 3
                            %                             percContraProposta=(self.contraProposta-valor_nao_contestado) / (valor_contestadoProp*(2/3)+(self.valor_sentenca-valor_nao_contestado)*(1/3));
                            %                         case 4
                            %                             percContraProposta=(self.contraProposta-valor_nao_contestado) / (valor_contestadoProp*(2/3)+(self.valor_sentenca-valor_nao_contestado)*(1/3));
                        otherwise
                            percContraProposta = self.contraProposta/(valor_sentenca+0.000001);
                    end
                    if(percContraProposta<curvaAcordo(end,1))
                        probContraProposta = interp1(curvaAcordo(:,1),curvaAcordo(:,2),percContraProposta);
                    else
                        disp(['Id processo:' num2str(self.idAgente)]);
                        disp(['Contra proposta acima do range da curva de acordo: ' num2str(self.contraProposta)]);
                        disp(['Valor_contestado: ' num2str(valor_contestadoProp)]);
                        disp(['[Maximo percentual da Curva: ' num2str(curvaAcordo(end,1))]);
                        disp('Assumindo contra proposta de acordo não aceito igual ao maximo da curva');
                        disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
                        percContraProposta = curvaAcordo(end,1)-delta;
                        probContraProposta = curvaAcordo(end,2)-delta;
                    end
                    
                end
                
                % refina a curva quando existe proposta e contra proposta
                if(self.propostaNaoAceita ~= -1 && self.contraProposta~= -1)
                    if(percContraProposta == percNaoAceito)
                        disp(['Id processo:' num2str(self.idAgente)]);
                        disp('Proposta e contraProposta são iguais');
                        disp('Criando um desvio para a proposta');
                        percNaoAceito = percNaoAceito -delta;
                        probNaoAceito = percContraProposta -delta;
                    end
                    i=2;
                    while curvaAcordo(i,1) < percNaoAceito
                        curvaAcordo(i,:) = [];
                    end
                    curvaAcordo(i+1:end+1,:) = curvaAcordo(i:end,:);
                    curvaAcordo(i,1) = percNaoAceito;
                    curvaAcordo(i,2) = delta;
                    i = i+1;
                    while curvaAcordo(i,1) < percContraProposta
                        curvaAcordo(i,1) = curvaAcordo(i,1);
                        curvaAcordo(i,2) = (curvaAcordo(i,2)-probNaoAceito+delta)/(probContraProposta - probNaoAceito - delta);
                        i=i+1;
                    end
                    curvaAcordo(i+1:end+1,:) = curvaAcordo(i:end,:);
                    curvaAcordo(i,1) = percContraProposta;
                    curvaAcordo(i,2) = 1;
                    i=i+1;
                    while (i <= size(curvaAcordo,1))
                        curvaAcordo(i,:) = [];
                    end
                end
                
                % refina a curva quando existe somente proposta
                if(self.propostaNaoAceita ~= -1 && self.contraProposta==-1)
                    i=2;
                    while curvaAcordo(i,1) < percNaoAceito
                        curvaAcordo(i,:) = [];
                    end
                    curvaAcordo(i+1:end+1,:) = curvaAcordo(i:end,:);
                    curvaAcordo(i,1) = percNaoAceito;
                    curvaAcordo(i,2) = delta;
                    i = i+1;
                    while i <= (size(curvaAcordo,1)-1)
                        curvaAcordo(i,2) = (curvaAcordo(i,2)-probNaoAceito+delta)/(1 - probNaoAceito + delta);
                        i=i+1;
                    end
                end
                
                % refina a curva quando existe somente contraProposta
                if(self.propostaNaoAceita == -1 && self.contraProposta~=-1)
                    i=2;
                    while (i <= size(curvaAcordo,1) && curvaAcordo(i,1) < percContraProposta)
                        curvaAcordo(i,2) = curvaAcordo(i,2)/(probContraProposta);
                        i=i+1;
                    end
                    curvaAcordo(i+1:end+1,:) = curvaAcordo(i:end,:);
                    curvaAcordo(i,1) = percContraProposta;
                    curvaAcordo(i,2) = 1;
                    i=i+1;
                    while (i <= size(curvaAcordo,1))
                        curvaAcordo(i,:) = [];
                    end
                end
            end
        end
        
        function preSorteiraFuncServTime(self,switchPathInterno)
            if self.carteira.isTimeRand
                distribuicao = self.cluster.distribuicao{self.id_arvore_atual,self.id_bloco_atual,switchPathInterno};
                indiceAleatorio = randi(length(distribuicao));
                self.servTimePreSorteado = distribuicao(indiceAleatorio);
            else
                self.servTimePreSorteado = self.cluster.tempo_aresta(self.id_arvore_atual,self.id_bloco_atual,switchPathInterno);
            end
        end
        
        % Define o intervalo para o proximo bloco e faz a correção
        % monetária do pedido
        function funcServTime(self)
            
            carteira_ = self.carteira;
            cluster_ = self.cluster;
            
            % Define o servTime levando em consideração se o modelo é
            % timeRand ou nao
            if(self.servTimePreSorteado == -1)
                if carteira_.isTimeRand
                    distribuicao = cluster_.distribuicao{self.id_arvore_atual,self.id_bloco_atual,self.switchPath};
                    indiceAleatorio = randi(length(distribuicao));
                    self.servTime = distribuicao(indiceAleatorio);
                else
                    self.servTime = cluster_.tempo_aresta(self.id_arvore_atual,self.id_bloco_atual,self.switchPath);
                end
            else
                self.servTime = self.servTimePreSorteado;
            end
            
            % Define se vai ocorrer o embargo, e de quanto tempo será
            probEmbargo = cluster_.probEmbargo(self.id_arvore_atual,self.id_bloco_atual);
            if probEmbargo ~= 0
                if rand < probEmbargo
                    if carteira_.isTimeRand
                        distEmbargo = cluster_.distEmbargo{self.id_arvore_atual,self.id_bloco_atual};
                        indiceAleatorio = randi(length(distEmbargo));
                        self.servTime = self.servTime + distEmbargo(indiceAleatorio);
                    else
                        self.servTime = self.servTime + cluster_.tempoEmbargo(self.id_arvore_atual,self.id_bloco_atual);
                    end
                end
            end
            
            % Retira o tempo inicial já esperado do servTime obtido.
            % Se o servTime resultante for menor do que 0, servTime é
            % setado para 0
            if(self.primeiroServTime)
                self.primeiroServTime = 0;
                self.servTime = self.servTime - self.esperaInicial;
                if(self.servTime < 0 )
                    self.servTime = 0;
                end
            end
            
            % Atualiza os valores conforme o servTime, TR, JAM e Juros
            posicaoJam = model.ConstIndiceMonetario.jam;
            jurosDeposito = self.carteira.indiceMonetario{posicaoJam}(self.carteira.posicaoIndiceMonetarioInicial(posicaoJam)+carteira_.indiceTempo+self.servTime,2)./ ...
                            self.carteira.indiceMonetario{posicaoJam}(self.carteira.posicaoIndiceMonetarioInicial(posicaoJam)+carteira_.indiceTempo,2);
%             jurosDeposito = (1+carteira_.jam)^self.servTime;
            self.deposito_recursal1 = self.deposito_recursal1.*jurosDeposito;
            self.deposito_recursal2 = self.deposito_recursal2.*jurosDeposito;
            self.deposito_execucao = self.deposito_execucao.*jurosDeposito;
            
            if(self.atualizarPropostaDeAcordo)                
                %monetaria
                monetaria  = self.carteira.indiceMonetario{self.listaCm}(self.carteira.posicaoIndiceMonetarioInicial(self.listaCm)+carteira_.indiceTempo+self.servTime,2) ...
                     / self.carteira.indiceMonetario{self.listaCm}(self.carteira.posicaoIndiceMonetarioInicial(self.listaCm)+carteira_.indiceTempo,2);
                
                % juros
                posicaoJuros = model.ConstIndiceMonetario.juros;
                juros = 1+self.carteira.indiceMonetario{posicaoJuros}(self.carteira.posicaoIndiceMonetarioInicial(posicaoJuros)+carteira_.indiceTempo+self.servTime,2) -...
                            self.carteira.indiceMonetario{posicaoJuros}(self.carteira.posicaoIndiceMonetarioInicial(posicaoJuros)+carteira_.indiceTempo,2);
               
                self.valor_acordo = self.valor_acordo .* monetaria .* juros;
                self.atualizarPropostaDeAcordo = 0;
            end
        end
        
        function calculaPrimeiroSetAcordo(self,numeroAcordo)
            carteira_ = self.carteira;
            arvoreModelo_ = self.arvoreModelo;
            
            %Multa
            if(carteira_.aplicarMulta)
                switch arvoreModelo_.tipoModelo
                    case 1 %trab
                        if self.id_arvore_atual == 101 && self.id_bloco_atual == 5
                            self.fatorMulta = self.fatorMulta * 1.1;
                        end
                    case 2%civel
                        if self.id_arvore_atual == 101 && self.id_bloco_atual == 4
                            self.fatorMulta = self.fatorMulta * 1.1;
                        end
                end
            end
            
            if(arvoreModelo_.tipoBloco(self.id_arvore_atual, self.id_bloco_atual)==model.NohModelo.ACORDO && ...
                    arvoreModelo_.tipo(self.id_arvore_atual, self.id_bloco_atual) == model.NohModelo.CONTROLE)
                
                vetorExplorado = model.blocoNaoAcordo();
                vetorExplorado.processo = self;
                [espSinkNaoAcordo,composicao,~] = vetorExplorado.getValorNaoAcordo();
                composicao(5) = composicao(5) + self.deposito_execucao+self.deposito_recursal1 + self.deposito_recursal2;
                espSinkNaoAcordo = espSinkNaoAcordo + self.deposito_execucao+self.deposito_recursal1 + self.deposito_recursal2;
                
               
                if(numeroAcordo <=3)
                    fval = self.enuplaAcordo6(espSinkNaoAcordo,numeroAcordo);
                else
                    %                     self.enuplaAcordo6(espSinkNaoAcordo, valor_contestadoProp, valor_nao_contestado,3);
                    %                     switch self.id_arvore_atual
                    %                         case 1
                    %                             percAcordo=self.valor_acordo/valor_contestadoProp;
                    %                         otherwise
                    %                             percAcordo=self.valor_acordo/(self.valor_sentenca+0.000001);
                    %                     end
                    %                     percAcordoInicial = zeros(numeroAcordo,1);
                    %                     percAcordoInicial(numeroAcordo-2:numeroAcordo,1) = percAcordo';
                    percAcordoInicial = 0.5*ones(numeroAcordo,1);
                    fval = self.enuplaAcordo(espSinkNaoAcordo,numeroAcordo,percAcordoInicial);
                    self.valor_acordo = self.valor_acordo';
                end
                
                % Obtem percentual do acordo
                switch self.id_arvore_atual
                    case 1
                        valor_contestadoProp = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
                        percAcordo=self.valor_acordo/valor_contestadoProp;
                    otherwise
                        valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                        percAcordo=self.valor_acordo/(valor_sentenca+0.000001);
                end
                
                % Obtem probabilidade do acordo
                curvaAcordo = self.curvaAcordoAjustada(0);
                probAcordo = interp1(curvaAcordo(:,1), curvaAcordo(:,2), percAcordo,'linear',1);
                
                % Obtem probAcordoDadoAnteriorFalhou (probAcordo(n)| ~probAcordo(n-1))
                probAcordoDadoAnteriorFalhou = probAcordo;
                probAcordoDadoAnteriorFalhou(2:end) = (probAcordo(2:end)-probAcordo(1:end-1)) ./ (1-probAcordo(1:end-1));
                
                % Obtem probFecharExatamenteN
                probFecharExatamenteN = probAcordo;
                probFecharExatamenteN(2:end) = (probAcordo(2:end)-probAcordo(1:end-1));
                
                carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).valorAcordo=self.valor_acordo';
                carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).percentualValorAcordo=percAcordo';
                carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).esperadoNaoAcordo=espSinkNaoAcordo';
                carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).composicaoEsperadoNaoAcordo=composicao';
                carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probAcordo = probAcordo';
                carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probAcordoDadoAnteriorFalhou = probAcordoDadoAnteriorFalhou';
                carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probFecharExatamenteNesimoAcordo = probFecharExatamenteN';
                carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probNaofecharAcordo = 1-probAcordo(end);
                carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).fval = fval;
                
            else
                disp(['O processo numero ' num2str(self.idAgente) ' não inicia em um bloco de proposta de acordo']);
            end
            
        end
        
        function estrategia(self)
            
            % Acessar mais rapido as variaveis
            carteira_ = self.carteira;
            arvoreModelo_ = self.arvoreModelo;
            
            %Multa
            if(carteira_.aplicarMulta)
                switch arvoreModelo_.tipoModelo
                    case 1 %Trab
                        if self.id_arvore_atual == 101 && self.id_bloco_atual == 5
                            self.fatorMulta = self.fatorMulta * 1.1;
                        end
                    case 2 %Civel
                        if self.id_arvore_atual == 101 && self.id_bloco_atual == 4
                            self.fatorMulta = self.fatorMulta * 1.1;
                        end
                end
            end
            
            % Defnide o valor do acordo, segunda a estratégia do
            % processo.
            switch arvoreModelo_.tipoBloco(self.id_arvore_atual, self.id_bloco_atual);
                case model.NohModelo.ACORDO % Propoe Acordo(1) / Nao Propoe Acordo(2)
                    % switch carteira_.estrategia
                    if(strcmp(carteira_.estrategia,'rand'))
                        % case 'rand'
                        vetorRand(1) = 0.7*rand();
                        vetorRand(2) = (0.9-vetorRand(1))*rand()+vetorRand(1);
                        vetorRand(3) = (1-vetorRand(2))*rand()+vetorRand(2);                        
                        
                        if(self.id_arvore_atual == 1)
                            proporcaoAcordo = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
                            self.valor_acordo = vetorRand*proporcaoAcordo;
                        else
                            proporcaoAcordo = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                            self.valor_acordo = vetorRand*proporcaoAcordo;
                        end                        
                        self.atualizarPropostaDeAcordo = 1;
                        
                    elseif(strncmp(carteira_.estrategia,'optDireto',9))
                        
                        vetorExplorado = model.blocoNaoAcordo();
                        vetorExplorado.processo = self;
                        [espSinkNaoAcordo,composicao,~] = vetorExplorado.getValorNaoAcordo();
                        composicao(5) = composicao(5) + self.deposito_execucao+self.deposito_recursal1 + self.deposito_recursal2;
                        espSinkNaoAcordo = espSinkNaoAcordo + self.deposito_execucao+self.deposito_recursal1 + self.deposito_recursal2;
                        
                        fval = self.enuplaAcordo6(espSinkNaoAcordo,3);                        
                        self.ganhoEsperado = espSinkNaoAcordo - fval;
                        
                        % Salva o primeiro acordo proposto
                        if self.primeiroAcordo
                            self.primeiroAcordo = 0;
                            
                            % Obtem percentual do acordo
                            switch self.id_arvore_atual
                                case 1
                                    valor_contestadoProp = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);                                    
                                    percAcordo=self.valor_acordo/valor_contestadoProp;
                                otherwise
                                    valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                                    percAcordo=self.valor_acordo/(valor_sentenca+0.000001);
                            end
                            
                            % Obtem probabilidade do acordo
                            curvaAcordo = self.curvaAcordoAjustada(0);
                            probAcordo = interp1(curvaAcordo(:,1), curvaAcordo(:,2), percAcordo,'linear',1);
                            
                            % Obtem probAcordoDadoAnteriorFalhou (probAcordo(n)| ~probAcordo(n-1))
                            probAcordoDadoAnteriorFalhou = probAcordo;
                            probAcordoDadoAnteriorFalhou(2:end) = (probAcordo(2:end)-probAcordo(1:end-1)) ./ (1-probAcordo(1:end-1));
                            
                            % Obtem probFecharExatamenteN
                            probFecharExatamenteN = probAcordo;
                            probFecharExatamenteN(2:end) = (probAcordo(2:end)-probAcordo(1:end-1));
                            
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).valorAcordo=self.valor_acordo';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).percentualValorAcordo=percAcordo';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).esperadoNaoAcordo=espSinkNaoAcordo';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).composicaoEsperadoNaoAcordo=composicao';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probAcordo = probAcordo';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probAcordoDadoAnteriorFalhou = probAcordoDadoAnteriorFalhou';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probFecharExatamenteNesimoAcordo = probFecharExatamenteN';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probNaofecharAcordo = 1-probAcordo(end);
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).fval = fval;
                        end
                        self.atualizarPropostaDeAcordo = 1;
                        
                    elseif(strcmp(carteira_.estrategia,'opt'))
                        
                        %acordo
                        espSinkNaoAcordo = carteira_.fatorGetEsperado*self.getEsperadoSimples(); 
                        fval = self.enuplaAcordo6(espSinkNaoAcordo, 3);
                
                        % Salva o primeiro acordo proposto
                        if self.primeiroAcordo
                            self.primeiroAcordo = 0;
                            
                            % Obtem percentual do acordo
                            switch self.id_arvore_atual
                                case 1
                                    valor_contestadoProp = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
                                    percAcordo=self.valor_acordo/valor_contestadoProp;
                                otherwise
                                    valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                                    percAcordo=self.valor_acordo/(valor_sentenca+0.000001);
                            end
                            
                            % Obtem probabilidade do acordo
                            curvaAcordo = self.curvaAcordoAjustada(0);
                            probAcordo = interp1(curvaAcordo(:,1), curvaAcordo(:,2), percAcordo,'linear',1);
                            
                            % Obtem probAcordoDadoAnteriorFalhou (probAcordo(n)| ~probAcordo(n-1))
                            probAcordoDadoAnteriorFalhou = probAcordo;
                            probAcordoDadoAnteriorFalhou(2:end) = (probAcordo(2:end)-probAcordo(1:end-1)) ./ (1-probAcordo(1:end-1));
                            
                            % Obtem probFecharExatamenteN
                            probFecharExatamenteN = probAcordo;
                            probFecharExatamenteN(2:end) = (probAcordo(2:end)-probAcordo(1:end-1));
                            
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).valorAcordo=self.valor_acordo';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).percentualValorAcordo=percAcordo';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).esperadoNaoAcordo=espSinkNaoAcordo';
                            %carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).composicaoEsperadoNaoAcordo=composicao';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probAcordo = probAcordo';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probAcordoDadoAnteriorFalhou = probAcordoDadoAnteriorFalhou';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probFecharExatamenteNesimoAcordo = probFecharExatamenteN';
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).probNaofecharAcordo = 1-probAcordo(end);
                            carteira_.outputCarteira.primeiroSetAcordo(self.idAgente).fval = fval;
                        end
                        
                        % Correção monetária e juros relativo ao tempo
                        % entre o bloco acordo de controle e externo
                        self.atualizarPropostaDeAcordo = 1;
                        
                    elseif(strcmp(carteira_.estrategia,'porcentagem'))
                        percPropAcordo = carteira_.estrategiaDouble / 100;                        
                         switch self.id_arvore_atual
                            case 1
                                valor_contestadoProp = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
                                self.valor_acordo=valor_contestadoProp*percPropAcordo;
                            otherwise
                                valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                                self.valor_acordo=percPropAcordo*valor_sentenca;
                        end
                        
                        self.atualizarPropostaDeAcordo = 1;
                        
                        %  Roda estratégia especifica do cliente
                        % A estratégia deve ser da forma 'especifica*'
                    elseif(strncmp(carteira_.estrategia,'especifica',10))
                        self.estrategiaEspecifica();
                    else
                        error(['Estratégia ' carteira_.estrategia ' não identificada']);
                    end
                    
                    if(carteira_.capacityMes == -1)
                        self.switchPath = 1;
                        if(self.valor_acordo == 0)
                            self.switchPath = 2;
                        end
                    else
                        %  Definir como vai funcionar o capaciti
                    end
                    
                case model.NohModelo.RECURSO
                    % Recorre(1) / Nao Recorre(2)
                    % reclamado decide se entra ou nao com recurso
                    self.especificoRecorrer();
                    %  Se a politica do cliente permite recorrer, então swithpath valerá 1
                    %  Caso contrario valerá 2
                 
                    if(self.switchPath == 1 && strncmp(carteira_.estrategia,'optDireto',9))
                        vetorExplorado = model.blocoNaoAcordo();
                        vetorExplorado.processo = self;
                        [~,~,decisaoRecorre] = vetorExplorado.getValorNaoAcordo();
                        self.switchPath = decisaoRecorre;
                        if(self.switchPath == 0)
                            self.switchPath = 1;
                        end
                    end
                    
                    
                    % Calculo das custas recursais e dos depositos segundo
                    % a instancia de recurso
                    switch arvoreModelo_.tipoModelo
                        case 1 %trab
                            if self.id_bloco_atual == 3
                                switch self.id_arvore_atual
                                    case 3
                                        inst = 1;
                                    case {5, 6}
                                        inst = 2;
                                    case {8, 9}
                                        inst = 3;
                                    case {104, 106, 107, 109, 110}
                                        inst = 100;
                                    otherwise
                                        disp(['Arvore errada para recorrer. idArvore = ' num2str(self.id_arvore_atual) ' idBloco = ' num2str(self.id_bloco_atual)]);
                                end
                                self.recorrer(inst);  %calcular depositos e custa recorrer
                                
                            elseif self.id_bloco_atual == 4
                                switch self.id_arvore_atual
                                    case 101
                                        inst = 100;
                                    otherwise
                                        disp(['Arvore errada para recorrer. idArvore = ' num2str(self.id_arvore_atual) ' idBloco = ' num2str(self.id_bloco_atual)]);
                                end
                                self.recorrer(inst);
                                
                            elseif self.id_bloco_atual == 1
                                switch self.id_arvore_atual
                                    case 102
                                        inst = 100;
                                    otherwise
                                        disp(['Arvore errada para recorrer. idArvore = ' num2str(self.id_arvore_atual) ' idBloco = ' num2str(self.id_bloco_atual)]);
                                end
                                self.recorrer(inst);
                            else
                                disp(['Para ser recorrer deve ter idBloco == 3. idArvore = ' num2str(self.id_arvore_atual) ' idBloco = ' num2str(self.id_bloco_atual)]);
                            end
                            
                        case 2 %civel
                            if self.id_bloco_atual == 3
                                switch self.id_arvore_atual
                                    case 3
                                        inst = 1;
                                    case {5, 6}
                                        inst = 2;
                                    case {101, 103, 105, 106}
                                        inst = 100;
                                    otherwise
                                        disp(['Arvore errada para recorrer. idArvore = ' num2str(self.id_arvore_atual) ' idBloco = ' num2str(self.id_bloco_atual)]);
                                end
                                self.recorrer(inst);
                            else
                                disp(['Para ser recorrer deve ter idBloco == 3. idArvore = ' num2str(self.id_arvore_atual) ' idBloco = ' num2str(self.id_bloco_atual)]);
                            end
                            
                        case 3 %jec
                            if self.id_bloco_atual == 3
                                switch self.id_arvore_atual
                                    case 3
                                        inst = 1;
                                    case 101
                                        inst = 100;
                                    otherwise
                                        disp(['Arvore errada para recorrer. idArvore = ' num2str(self.id_arvore_atual) ' idBloco = ' num2str(self.id_bloco_atual)]);
                                end
                                self.recorrer(inst);
                            elseif self.id_bloco_atual == 5
                                switch self.id_arvore_atual
                                    case 101
                                        inst = 100;
                                    otherwise
                                        disp(['Arvore errada para recorrer. idArvore = ' num2str(self.id_arvore_atual) ' idBloco = ' num2str(self.id_bloco_atual)]);
                                end
                                self.recorrer(inst);
                            else
                                disp(['Para ser recorrer deve ter idBloco == 3. idArvore = ' num2str(self.id_arvore_atual) ' idBloco = ' num2str(self.id_bloco_atual)]);
                            end
                    end
                otherwise
                    % ERRO
                    disp(['Controle nao aceita tipo = ' num2str(arvoreModelo_.tipoBloco(self.id_arvore_atual, self.id_bloco_atual))]);
            end
            
            % Deposito execução para casa civel e jec
            if(arvoreModelo_.tipoModelo == model.ArvoreModelo.tipo_civel && ...
                    self.id_arvore_atual == 101 &&  self.id_bloco_atual == 6)
                valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                depEx = min(valor_sentenca, max(valor_sentenca - self.deposito_recursal1-self.deposito_recursal2, 0));
                self.deposito_execucao = depEx;
                self.custo_deposito = depEx;
            end
            
            if(arvoreModelo_.tipoModelo == model.ArvoreModelo.tipo_jec && ...
                    self.id_arvore_atual == 101 &&  self.id_bloco_atual == 6)
                valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);                         
                depEx = min(valor_sentenca, max(valor_sentenca - self.deposito_recursal1-self.deposito_recursal2, 0));
                self.deposito_execucao = depEx;
                self.custo_deposito = depEx;
            end
            
            % Periciaa
            if(self.id_arvore_atual == 1 &&  self.id_bloco_atual == 10)
                if rand < 0.2
                    % Tem pericia
                    self.custas_processuais = self.custas_processuais + self.cluster.distPericia.icdf(rand);
                end
            end
            
        end
        
        function externo(self)
            
            % alias para acessar mais rapido as variaveis
            carteira_ = self.carteira;
            cluster_ = self.cluster;
            arvoreModelo_ = self.arvoreModelo;
            
            % leitura da probabilidade dos switchpath
            listaSinksProb = cluster_.prob_aresta{self.id_arvore_atual,self.id_bloco_atual};
            
            switch arvoreModelo_.tipoBloco(self.id_arvore_atual, self.id_bloco_atual)
                
                % verifica se o reclamante aceita o acordo
                case model.NohModelo.ACORDO
                    % Aceita Acordo(1) / Nao Aceita Acordo(2)
                    % Define a probabilidade do reclamente aceitar o
                    % acordo
                    if(self.id_arvore_atual == 1)
                        valor_contestadoProp = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
                        fatorAcordo = valor_contestadoProp;
                    else
                        valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                        fatorAcordo = (valor_sentenca+0.000001);
                    end
                    
                    percAcordo = self.valor_acordo/fatorAcordo;
                    tempoAcordoBudget = 0;
                    
                    fazAcordo = false; %verifica se o budgetVector permite fazer o acordo
                    aceitaAcordo = false; %verifica se o reclamante aceita o percentual de acordo
                    numeroAcordoAceito = 0;
                    if(length(percAcordo)==1)
                        % Decide-se o cliente aceita ou não o acordo
                        if percAcordo >= self.percMinimoAcordo
                            aceitaAcordo = true;
                            numeroAcordoAceito = 1;
                            fazAcordo = true;
                            
                            % verifica se o budget permite fazer o acordo
                            if(carteira_.contribuidoresBudget(1))
                                fazAcordo = false;
                                self.preSorteiraFuncServTime(1);
                                %Verifica o budget até achar um mês que de
                                %para fazer o acordo. Levando em conta o
                                %tempo até a janela de acordo não estar
                                %mais disponivel
                                for tempoAcordoBudget=0:self.servTimePreSorteado
                                    if(self.valor_acordo <= carteira_.budgetVector(carteira_.indiceTempo+1+tempoAcordoBudget))
                                        carteira_.budgetVector(carteira_.indiceTempo+1+tempoAcordoBudget,1) = carteira_.budgetVector(carteira_.indiceTempo+1+tempoAcordoBudget,1) - self.valor_acordo;
                                        fazAcordo = true;
                                        break; %Acordo concluido não precisa mais verificar o budget
                                    end
                                end
                                if(~fazAcordo)
                                    self.servTimePreSorteado = -1;  %desconsidera o pre sorteio
                                end
                            end
                        end
                        
                    else
                        for i=1:length(percAcordo)
                            if(percAcordo(i) >= self.percMinimoAcordo)
                                aceitaAcordo = true;
                                fazAcordo = true;
                                numeroAcordoAceito = i;
                                valorAcordoParcial = self.valor_acordo(i);
                                
                                %  Fazendo isso o fluxo de acordo e o numero de acordo vão estar defasados (analisar esse problema)
                                
                                if(carteira_.contribuidoresBudget(1))
                                    fazAcordo = false;
                                    self.preSorteiraFuncServTime(1);
                                    for tempoAcordoBudget=0:self.servTimePreSorteado
                                        if(valorAcordoParcial <= carteira_.budgetVector(carteira_.indiceTempo+1+tempoAcordoBudget))
                                            carteira_.budgetVector(carteira_.indiceTempo+1+tempoAcordoBudget,1) = carteira_.budgetVector(carteira_.indiceTempo+1+tempoAcordoBudget,1) - valorAcordoParcial;
                                            fazAcordo = true;
                                            break;  %sai do loop de verificação do budget
                                        end
                                    end
                                    if(~fazAcordo)
                                        self.servTimePreSorteado = -1;  %desconsidera o pre sorteio
                                        break; %sai do loop de verificação do percentual do acordo. Se o budget não foi o suficiente para concluir o menor acordo, também não será suficiente para fazer acordo maior.
                                    end
                                end
                                
                                self.valor_acordo = valorAcordoParcial;
                                break; %sai do loop de verificação do percentual do acordo, acordo realizado
                            end
                        end
                    end
                    
                    if(fazAcordo)
                        self.switchPath = 1;
                        self.tempoEncerramentoBloco = self.carteira.indiceTempo+tempoAcordoBudget;
                        
                        %Se o acordo for feito quer dizer que o reclamante
                        %aceitou o acordo e o budgetVector permitiu,
                        %então colocamos com 0 os n-1 acordos propostos e
                        %em 1 o acordo aceito e 2 os acordos acima do acordo aceito
                        
                        %Não aceito
                        for i=1:numeroAcordoAceito-1
                            self.carteira.outputCarteira.historicoAcordo{self.idAgente}(end+1,1:6) = ...
                                [self.id_arvore_atual  self.id_bloco_atual percAcordo(i) percAcordo(i)*fatorAcordo 0 self.percMinimoAcordo];
                        end
                        %Aceito
                        self.carteira.outputCarteira.historicoAcordo{self.idAgente}(end+1,1:6) = ...
                            [self.id_arvore_atual  self.id_bloco_atual percAcordo(numeroAcordoAceito) percAcordo(numeroAcordoAceito)*fatorAcordo 1 self.percMinimoAcordo];
                        %Acima do aceito
                        for i=numeroAcordoAceito+1:length(percAcordo)
                            self.carteira.outputCarteira.historicoAcordo{self.idAgente}(end+1,1:6) = ...
                                [self.id_arvore_atual  self.id_bloco_atual percAcordo(i) percAcordo(i)*fatorAcordo 2 self.percMinimoAcordo];
                        end
                        
                    else
                        self.switchPath = 2;
                        
                        % Se o acordo não foi feito, existe duas razões, a
                        % primeira é que o percentual de acordo é inferior
                        % ao minimo do reclamante, nesse caso todas as
                        % propostas de acordos são recusadas.
                        % O segundo caso é quando o reclamante aceitaria a
                        % proposta, mas o budget não permite faze-lá, então
                        % temos que colocar 0 nas n-1 proposta que o reclamante
                        % recusou, porém não adicionamos no historico a proposta
                        %  que ele aceitaria caso o budget permitisse.
                        if(~aceitaAcordo)
                            %Não aceito
                            for i=1:length(percAcordo)
                                self.carteira.outputCarteira.historicoAcordo{self.idAgente}(end+1,1:6) = ...
                                    [self.id_arvore_atual  self.id_bloco_atual percAcordo(i) percAcordo(i)*fatorAcordo 0 self.percMinimoAcordo];
                            end
                        else
                            %Não aceito
                            for i=1:numeroAcordoAceito-1
                                self.carteira.outputCarteira.historicoAcordo{self.idAgente}(end+1,1:6) = ...
                                    [self.id_arvore_atual  self.id_bloco_atual percAcordo(i) percAcordo(i)*fatorAcordo 0 self.percMinimoAcordo];
                            end
                            %Não realizado devido ao budget
                            for i=numeroAcordoAceito:length(percAcordo)
                                self.carteira.outputCarteira.historicoAcordo{self.idAgente}(end+1,1:6) = ...
                                    [self.id_arvore_atual  self.id_bloco_atual percAcordo(i) percAcordo(i)*fatorAcordo 3 self.percMinimoAcordo];
                            end
                        end
                    end
                    
                    % Decide se o reclamante recorre
                case model.NohModelo.RECURSO
                    % Recurso(1) / Nao Recurso(2)
                    if rand < listaSinksProb(1)
                        self.switchPath = 1;
                        if (~self.id_arvore_atual ~= 2) %Se for na arvore 2 sempre tem motivo para recorrer
                            if (sum(self.pedidos_em_pauta(:) & ~self.pedidos_deferidos(:)) == 0 &&  self.id_arvore_atual < 100)%Verifica se existe motive para recorrer, em execução tb tem motivo para
                                self.switchPath = 2;
                            end
                        end
                    else
                        self.switchPath = 2;
                    end
                    
                    %Atualiza a lista de pedidos em pauta caso o Reclamante nao recorre
                    if self.switchPath == 2
                        self.pedidos_em_pauta = double(self.pedidos_em_pauta & self.pedidos_deferidos); % tira os nao deferidos
                    end
                    
                case model.NohModelo.DECISAO_JUDICIAL
                    switch arvoreModelo_.tipoModelo
                        case model.ArvoreModelo.tipo_trab
                            if(self.id_arvore_atual == 1 && self.id_bloco_atual == 14)
                                % Julgamento 1a Inst
                                self.julgamento(1);
                            elseif (self.id_arvore_atual == 4 && self.id_bloco_atual == 5)
                                % Julgamento 2a Inst
                                self.julgamento(2);
                            elseif (self.id_arvore_atual == 7 && self.id_bloco_atual == 12)
                                % Julgamento 3a Inst (TST)
                                self.julgamento(3);
                            elseif (self.id_arvore_atual == 10 && self.id_bloco_atual == 6)
                                % Julgamento 4a Inst (STF)
                                self.julgamento(4);
                            else
                                error('Julgamento Nao identificado');
                            end
                            
                        case model.ArvoreModelo.tipo_civel
                            if(self.id_arvore_atual == 1 && self.id_bloco_atual == 12)
                                % Julgamento 1a Inst
                                self.julgamento(1);
                            elseif (self.id_arvore_atual == 4 && self.id_bloco_atual == 5)
                                % Julgamento 2a Inst
                                self.julgamento(2);
                            elseif (self.id_arvore_atual == 7 && self.id_bloco_atual == 10)
                                % Julgamento 3a Inst (TST)
                                self.julgamento(3);
                            else
                                error('Julgamento Nao identificado');
                            end
                            
                        case model.ArvoreModelo.tipo_jec
                            if(self.id_arvore_atual == 1 && self.id_bloco_atual == 8)
                                % Julgamento 1a Inst
                                self.julgamento(1);
                            elseif (self.id_arvore_atual == 4 && self.id_bloco_atual == 5)
                                % Julgamento 2a Inst
                                self.julgamento(2);
                            else
                                error('Julgamento Nao identificado');
                            end
                    end
                    
                case model.NohModelo.OUTRO
                    
                    % Assume que todo noh do tipo outro tem as
                    % listaSinksProb bem definido, perigoso ???
                    if rand < listaSinksProb(1)
                        self.switchPath = 1;
                    else
                        self.switchPath = 2;
                    end
                    
                    % deposito execução trabalhista
                    if (self.id_arvore_atual==102 && self.id_bloco_atual==4 && arvoreModelo_.tipoModelo == model.ArvoreModelo.tipo_trab)
                        valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);                         
                        depEx = min(valor_sentenca, max(valor_sentenca - self.deposito_recursal1-self.deposito_recursal2, 0));
                        self.deposito_execucao = depEx;
                        self.custo_deposito = depEx;
                    end
                    
                    % Custo pericial
                    if((arvoreModelo_.tipoModelo == model.ArvoreModelo.tipo_trab && self.id_arvore_atual==101 && self.id_bloco_atual==9) || ...
                            (arvoreModelo_.tipoModelo == model.ArvoreModelo.tipo_civel && self.id_arvore_atual==101 && self.id_bloco_atual==10) || ...
                            (arvoreModelo_.tipoModelo == model.ArvoreModelo.tipo_jec && self.id_arvore_atual==101 && self.id_bloco_atual==12))
                        if rand < 0.3 % hardcoding de pericia
                            % Tem pericia
                            self.custas_processuais = self.custas_processuais + self.cluster.distPericia.icdf(rand);
                        end
                    end
                    
                otherwise
                    disp(['Tipo bloco não reconhecido idArvore: ' self.id_arvore_atual ...
                        '  idBloco: ' self.id_bloco_atual']);
                    
            end
        end
        
        function julgamento(self,inst)
            
            if(inst == 1) %Primeira instancia
                
                valor_sentenca_esperada = self.calculaValorProcesso(self.carteira.indiceTempo, self.matClasseProb, self.fatorMulta);
                nPedido = size(self.pedidos,1);
                seletor = self.pedidos > 0;
                self.pedidos_deferidos = rand(nPedido, 1) < self.matClasseProb .* seletor;
                self.pedidos_deferidos = double(self.pedidos_deferidos);
                self.pedidos_em_pauta = double(seletor);
                if sum(self.pedidos_deferidos) == 0
                    % Nenhum foi deferido
                    self.switchPath = 1;
                else
                    self.switchPath = 2;
                end
                if(sum(seletor)~=0)
                    self.carteira.outputCarteira.estado1Julga(self.idAgente,seletor) = self.pedidos_deferidos(seletor)+1;
                end
                %0 pedido não julgado,1 pedido indeferido, 2 pedido
                %indeferido
                
            else %Outras instancias
                
               
                valor_sentenca_esperada = self.calculaValorProcesso(self.carteira.indiceTempo,...
                    (~self.pedidos_em_pauta).*self.pedidos_deferidos + ...
                    self.pedidos_em_pauta.*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:, inst - 1) +...
                    self.pedidos_em_pauta.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, inst - 1) ...
                    ,self.fatorMulta);
                
                pedidos_deferidosAntigos=self.pedidos_deferidos;
                
                self.pedidos_deferidos=(~self.pedidos_em_pauta & self.pedidos_deferidos) | ...
                    (self.pedidos_em_pauta & (rand(size(self.pedidos_em_pauta)) < (self.pedidos_deferidos .* self.matClasseProbDecisaoDef(:, inst - 1) ...
                    + ~self.pedidos_deferidos .* self.matClasseProbDecisaoIndef(:, inst - 1))));
                
                self.pedidos_deferidos = double(self.pedidos_deferidos);
                if sum(pedidos_deferidosAntigos~=self.pedidos_deferidos) == 0
                    % Nenhum foi alterado
                    self.switchPath = 1;
                else
                    self.switchPath = 2;
                end
                if(inst==2)
                    seletor = self.pedidos_em_pauta;
                    if(any(seletor & logical(pedidos_deferidosAntigos)))
                        self.carteira.outputCarteira.estado2JulgaDef(self.idAgente,seletor & logical(pedidos_deferidosAntigos)) = self.pedidos_deferidos(seletor & logical(pedidos_deferidosAntigos))+1;
                    end
                    if(any(seletor & ~logical(pedidos_deferidosAntigos)))
                        self.carteira.outputCarteira.estado2JulgaInd(self.idAgente,seletor & ~logical(pedidos_deferidosAntigos)) = self.pedidos_deferidos(seletor & ~logical(pedidos_deferidosAntigos))+1;
                    end
                end
                if(inst==3)
                    seletor = self.pedidos_em_pauta;
                    if(any(seletor & logical(pedidos_deferidosAntigos)))
                        self.carteira.outputCarteira.estado3JulgaDef(self.idAgente,seletor & logical(pedidos_deferidosAntigos)) = self.pedidos_deferidos(seletor & logical(pedidos_deferidosAntigos))+1;
                    end
                    if(any(seletor & ~logical(pedidos_deferidosAntigos)))
                        self.carteira.outputCarteira.estado3JulgaInd(self.idAgente,seletor & ~logical(pedidos_deferidosAntigos)) = self.pedidos_deferidos(seletor & ~logical(pedidos_deferidosAntigos))+1;
                    end
                end
                if(inst==4)
                     seletor = self.pedidos_em_pauta;
                    if(any(seletor & logical(pedidos_deferidosAntigos)))
                        self.carteira.outputCarteira.estado4JulgaDef(self.idAgente,seletor & logical(pedidos_deferidosAntigos)) = self.pedidos_deferidos(seletor & logical(pedidos_deferidosAntigos))+1;
                    end
                    if(any(seletor & ~logical(pedidos_deferidosAntigos)))
                        self.carteira.outputCarteira.estado4JulgaInd(self.idAgente,seletor & ~logical(pedidos_deferidosAntigos)) = self.pedidos_deferidos(seletor & ~logical(pedidos_deferidosAntigos))+1;
                    end
                end
            end
            valor_sentenca = self.calculaValorProcesso(self.carteira.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
            self.razaoSentenca = (valor_sentenca-valor_sentenca_esperada)/valor_sentenca_esperada;
        end
        
        function atualizaPercMinimoAcordo(self)
            %se o processo sofreu algum julgamento
            if(self.razaoSentenca~=0)
                %Aplica-se o filtro de Julgamento, sorteando um novo valor
                %aleatorio limitado caso reclamente ganha ou perde o
                %julgamento
                if(self.carteira.filtroJulgamento)
                    %se o reclamante ganhou
                    if(self.razaoSentenca > 0)
                        self.probMinimoAcordo = self.probMinimoAcordo+(1-self.probMinimoAcordo)*rand;
                        
                        %se o reclamante perdeu
                    else
                        self.probMinimoAcordo = rand*self.probMinimoAcordo;
                    end
                else
                    self.probMinimoAcordo = rand;
                end
                
                curvaAcordo = self.curvaAcordoAjustada(0);                
                self.percMinimoAcordo = interp1(curvaAcordo(:,2), curvaAcordo(:,1), self.probMinimoAcordo);
                
            end
        end
        
        % Calcula o mapa de nós (usado pela estratégio Optimum)
        function [custo,tempo] = calculaNaoAcordo(self)
            
            %Cria uma copia do processo(mais seguro)
            processoCopy  = self.deepCopy();
            % Identifica o noh atual
            idNoh = self.arvoreModelo.idPair2idNoh(processoCopy.id_arvore_atual,processoCopy.id_bloco_atual);
            %Inicializa os bloco de não acordos
            vetorExplorado = cell(206,1);
            for i=1:206
                vetorExplorado{i} = model.blocoNaoAcordo();
            end
            vetorExplorado{idNoh}.processo = processoCopy;
            
            % Cria a arvore de blocos de não acordo, separados por seção
            % onde iremos extrair o tempo e os custos fixos
            vetorExplorado{idNoh}.idArvore = processoCopy.id_arvore_atual;
            vetorExplorado{idNoh}.idBloco = processoCopy.id_bloco_atual;
            [~,vetorExplorado] = criaArvore(vetorExplorado{idNoh},vetorExplorado);
            
            % Extração do tempo e custo fixo
            custo = sparse(206,106);
            tempo = sparse(206,106);
            for i=1:206
                custo(i,:) = vetorExplorado{i}.custoFixoSecao'; %#ok<SPRIX>
                tempo(i,:) = vetorExplorado{i}.tempoSecao'; %#ok<SPRIX>
            end
            
            clear vetorExplorado;
        end
        
        % Otimiza o percentual de acordo que minimiza probAcordo.*valor_acordo + (1 - probAcordo) .* espSinkNaoAcordo
        function [self, espMin, perc, prob] = runAcordo(self,espSinkNaoAcordo) %, curva_acordo, cluster, id_arvore, id_bloco)
            
            curvaAcordo = self.curvaAcordoAjustada(0);
            percAcordo = curvaAcordo(:,1);
            probAcordo = curvaAcordo(:,2);
                      
            switch self.id_arvore_atual
                case 1
                    valor_contestadoProp = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
                    valor_acordo_vec=percAcordo*valor_contestadoProp;
                otherwise
                    valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                    valor_acordo_vec=percAcordo*valor_sentenca;
            end
            
            cesp = probAcordo.*valor_acordo_vec + (1 - probAcordo) .* espSinkNaoAcordo;
            [espMin,iEsp] = min(cesp);
            
            switch self.id_arvore_atual
                case 1
                    valor_contestadoProp = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
                    self.valor_acordo=percAcordo(iEsp)*valor_contestadoProp;
                otherwise
                    valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                    self.valor_acordo=percAcordo(iEsp)*valor_sentenca;
            end
            
            perc = percAcordo(iEsp);
            prob = probAcordo(iEsp);
            
        end
        
        % Estimativa simples do valor esperado de não acordo, considera juros
        function esperado = getEsperadoSimples(self)
            switch self.id_arvore_atual
                case 1
                    %esperado da 1a
                    esperado = self.calculaValorProcesso(carteira_.indiceTempo, self.matClasseProb, self.fatorMulta);
                 case 4
                    %esperado da 2a
                    esperado = self.calculaValorProcesso(carteira_.indiceTempo, ...
                        ((~self.pedidos_em_pauta).*self.pedidos_deferidos + ...
                        self.pedidos_em_pauta.*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:, 2 - 1) +...
                        self.pedidos_em_pauta.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 2 - 1))...
                        ,self.fatorMulta);
                case 7
                    switch  self.id_bloco_atual
                        case 1
                            %conta que inclui admissibilidade
                            esperadoAdmissivel =  self.calculaValorProcesso(carteira_.indiceTempo, ...
                                ((~self.pedidos_em_pauta).*self.pedidos_deferidos + ...
                                self.pedidos_em_pauta*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:, 3 - 1) +...
                                self.pedidos_em_pauta*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 3 - 1))...
                                ,self.fatorMulta);
                            
                            esperadoNaoAdmissivel= self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                            
                            
                            % if any(self.pedidos_em_pauta(:,2) | (self.pedidos_em_pauta(:,1) & self.pedidos_deferidos(:,1)) | (self.pedidos_em_pauta(:,3) & ~self.pedidos_deferidos(:,3)))
                            if any(self.pedidos_em_pauta)
                                switch self.arvoreModelo.tipoModelo
                                    case 1
                                        listaSinksProb = self.cluster.prob_aresta{7,3}; %idArvore 7, idbloco 3
                                    case 2
                                        listaSinksProb = self.cluster.prob_aresta{7,5};%idArvore 7, idbloco 5
                                    case 3
                                        listaSinksProb = [0 0];
                                end
                                esperado=listaSinksProb(2)*esperadoAdmissivel + listaSinksProb(1)*esperadoNaoAdmissivel;
                            else
                                esperado = esperadoNaoAdmissivel;
                            end
                        case {4,6}
                            %valor da sentença
                            esperado = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                        otherwise
                            %esperado da 3a
                            esperado = sum(self.pedidos_deferidos, ...
                                ((~self.pedidos_em_pauta).* pedidos_deferido + ...
                                self.pedidos_em_pauta.* self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:,3 - 1) +...
                                self.pedidos_em_pauta.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 3 - 1)),...
                                self.fatorMulta);
                            
                    end%switch id_bloco
                otherwise
                    %valor da sentença
                    esperado = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
            end%switch id_arvore
        end
        
        function [percentualTotal] = calculaPercentualTotal(self)
            switch self.id_arvore_atual
                case 1
                    %esperado da 1a
                    esperado = self.matClasseProb.*self.pedidos;
                    
                case 3
                    esperado = self.pedidos_deferidos.*(~self.pedidos_em_pauta).*self.pedidos + ...
                        self.pedidos_em_pauta.*self.pedidos.*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:, 2 - 1) +...
                        self.pedidos_em_pauta.*self.pedidos.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 2 - 1);
                    
                case 4
                    %esperado da 2a
                    esperado = self.pedidos_deferidos.*(~self.pedidos_em_pauta).*self.pedidos + ...
                        self.pedidos_em_pauta.*self.pedidos.*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:, 2 - 1) +...
                        self.pedidos_em_pauta.*self.pedidos.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 2 - 1);
                    
                case 5
                    %conta que inclui admissibilidade
                    esperadoAdmissivel = self.pedidos_deferidos.*(~self.pedidos_em_pauta).*self.pedidos + ...
                        self.pedidos_em_pauta.*self.pedidos.*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:, 3 - 1) +...
                        self.pedidos_em_pauta.*self.pedidos.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 3 - 1);
                    
                    esperadoNaoAdmissivel = self.pedidos_deferidos.* self.pedidos;
                    
                    % if any(self.pedidos_em_pauta(:,2) | (self.pedidos_em_pauta(:,1) & self.pedidos_deferidos(:,1)) | (self.pedidos_em_pauta(:,3) & ~self.pedidos_deferidos(:,3)))
                    if any(self.pedidos_em_pauta)
                        switch self.arvoreModelo.tipoModelo
                            case 1
                                listaSinksProb = self.cluster.prob_aresta{7,3}; %idArvore 7, idbloco 3
                            case 2
                                listaSinksProb = self.cluster.prob_aresta{7,5};%idArvore 7, idbloco 5
                            case 3
                                listaSinksProb = [0 0];
                        end
                        esperado =listaSinksProb(2)*esperadoAdmissivel + listaSinksProb(1)*esperadoNaoAdmissivel;
                    else
                        esperado = esperadoNaoAdmissivel;
                    end
                    
                case 6
                    
                    %conta que inclui admissibilidade
                    esperadoAdmissivel = self.pedidos_deferidos.*(~self.pedidos_em_pauta).*self.pedidos + ...
                        self.pedidos_em_pauta.*self.pedidos.*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:, 3 - 1) +...
                        self.pedidos_em_pauta.*self.pedidos.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 3 - 1);
                    
                    esperadoNaoAdmissivel = self.pedidos_deferidos.* self.pedidos;
                    
                    % if any(self.pedidos_em_pauta(:,2) | (self.pedidos_em_pauta(:,1) & self.pedidos_deferidos(:,1)) | (self.pedidos_em_pauta(:,3) & ~self.pedidos_deferidos(:,3)))
                    if any(self.pedidos_em_pauta)
                        switch self.arvoreModelo.tipoModelo
                            case 1
                                listaSinksProb = self.cluster.prob_aresta{7,3}; %idArvore 7, idbloco 3
                            case 2
                                listaSinksProb = self.cluster.prob_aresta{7,5};%idArvore 7, idbloco 5
                            case 3
                                listaSinksProb = [0 0];
                        end
                        esperado =listaSinksProb(2)*esperadoAdmissivel + listaSinksProb(1)*esperadoNaoAdmissivel;
                    else
                        esperado = esperadoNaoAdmissivel;
                    end
                    
                    
                case 7
                    switch  self.id_bloco_atual
                        case {2,4}
                            %conta que inclui admissibilidade
                            esperadoAdmissivel = self.pedidos_deferidos.*(~self.pedidos_em_pauta).*self.pedidos + ...
                                self.pedidos_em_pauta.*self.pedidos.*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:, 3 - 1) +...
                                self.pedidos_em_pauta.*self.pedidos.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 3 - 1);
                            
                            esperadoNaoAdmissivel = self.pedidos_deferidos.* self.pedidos;
                            
                            % if any(self.pedidos_em_pauta(:,2) | (self.pedidos_em_pauta(:,1) & self.pedidos_deferidos(:,1)) | (self.pedidos_em_pauta(:,3) & ~self.pedidos_deferidos(:,3)))
                            if any(self.pedidos_em_pauta)
                                switch self.arvoreModelo.tipoModelo
                                    case 1
                                        listaSinksProb = self.cluster.prob_aresta{7,3}; %idArvore 7, idbloco 3
                                    case 2
                                        listaSinksProb = self.cluster.prob_aresta{7,5};%idArvore 7, idbloco 5
                                    case 3
                                        listaSinksProb = [0 0];
                                end
                                esperado =listaSinksProb(2)*esperadoAdmissivel + listaSinksProb(1)*esperadoNaoAdmissivel;
                            else
                                esperado = esperadoNaoAdmissivel;
                            end
                        case {5,7}
                            %valor da sentença
                            esperado = self.pedidos_deferidos.* self.pedidos;
                        otherwise
                            %esperado da 3a
                            esperado = self.pedidos_deferidos.*(~self.pedidos_em_pauta).*self.pedidos + ...
                                self.pedidos_em_pauta.*self.pedidos.*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:,3 - 1) +...
                                self.pedidos_em_pauta.*self.pedidos.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 3 - 1);
                            
                    end%switch id_bloco
                    
                case 8
                    
                    esperado = self.pedidos_deferidos.*(~self.pedidos_em_pauta).*self.pedidos + ...
                        self.pedidos_em_pauta.*self.pedidos.*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:,4 - 1) +...
                        self.pedidos_em_pauta.*self.pedidos.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 4 - 1);
                    
                case 9
                    
                    esperado = self.pedidos_deferidos.*(~self.pedidos_em_pauta).*self.pedidos + ...
                        self.pedidos_em_pauta.*self.pedidos.*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:,4 - 1) +...
                        self.pedidos_em_pauta.*self.pedidos.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 4 - 1);
                    
                case 10
                    
                    esperado = self.pedidos_deferidos.*(~self.pedidos_em_pauta).*self.pedidos + ...
                        self.pedidos_em_pauta.*self.pedidos.*self.pedidos_deferidos.*self.matClasseProbDecisaoDef(:,4 - 1) +...
                        self.pedidos_em_pauta.*self.pedidos.*(~self.pedidos_deferidos).*self.matClasseProbDecisaoIndef(:, 4 - 1);
                    
                otherwise
                    %valor da sentença
                    esperado = self.pedidos_deferidos.* self.pedidos;
                    
            end%switch id_arvore
            
            percentualTotal = esperado./sum(esperado);
            
        end
        
        % Os custos de recorrer e os depositos foram calculados com o valor
        % definido no julgamento sem correçao monetaria nem juros após o
        % julgamento
        function recorrer(self, inst)
            
            % Verifica se existe razão para o reclamado recorrer
            %             if sum(self.pedidos_em_pauta(:) & self.pedidos_deferidos(:)) == 0
            if sum(self.pedidos_deferidos(:)) == 0
                self.switchPath = 2;
            end
            
            valor_sentenca = self.calculaValorProcesso(self.carteira.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
            
            if self.switchPath == 1
                %Reclamado recorre
                
                if(inst == 3)
                    %valor fixo para STF/STJ
                    self.custo_recorrer = 181.34;
                elseif(inst <= 2)
                    self.custo_recorrer = self.custoRecorrerUF(valor_sentenca);
                else
                    self.custo_recorrer = 0;
                end
                
                self.custo_recorrer_pago = self.custo_recorrer_pago + self.custo_recorrer;
                switch inst
                    case 1
                        if(self.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab)
                            self.deposito_recursal1 = min(8959.63, valor_sentenca);
                            self.deposito_recursal2 = 0;
                            self.custo_deposito = self.deposito_recursal1;
                        end
                        self.custas_processuais = self.custas_processuais + self.custo_recorrer;
                        
                    case 2
                        if(self.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab)
                            self.deposito_recursal2 = min(17919.29, max(valor_sentenca - self.deposito_recursal1, 0));                            
                            self.custo_deposito = self.deposito_recursal2;
                        end
                        self.custas_processuais = self.custas_processuais + self.custo_recorrer;
                    otherwise
                        self.custas_processuais = self.custas_processuais + self.custo_recorrer;
                end
            else
                % Reclamado nao recorre
                self.pedidos_em_pauta = double(self.pedidos_em_pauta & ~self.pedidos_deferidos); % tira os deferidos
            end
        end
        
        function custo = custoRecorrerUF(self,valorJulgado)
            switch self.UF
                case 'SP'
                    UFESP = 23.55;
                    custo = min(max(5*UFESP, 0.04 * valorJulgado - self.custo_recorrer_pago), 3000*UFESP);
                case 'RJ'
                    custo = 78.02;
                    % custo = 161.23 + 125.14 + 9.35 + 12.03 + 24.03 + 4.8 + 0.02 * valorJulgado;
                case 'PR'
                    custo = 252;
                    %custo = min(max(300, 0.03 * valorJulgado - self.custo_recorrer_pago), 870);
                case 'AC'
                    custo =  0.015*valorJulgado;
                    % sem maximo e minimo ???
                case 'AL'
                    custo =  10.79;
                case 'AP'
                    custo =  216.22;
                case 'AM'
                    custo =  30.22;
                case 'BA'
                    custo =  138.60;
                case 'CE'
                    custo =  0.04 *valorJulgado;
                case 'DF'
                    custo =  14.66;
                case 'ES'
                    custo =  0.0025 *valorJulgado;
                case 'GO'
                    ref = valorJulgado;
                    if (ref < 2000)
                        custo = 16.16;
                    elseif  (ref < 5000)
                        custo = 22.89;
                    elseif  (ref < 10000)
                        custo = 32.32;
                    elseif  (ref < 20000)
                        custo = 64.64;
                    elseif  (ref < 30000)
                        custo = 96.95;
                    elseif  (ref < 50000)
                        custo = 162.94;
                    elseif  (ref < 80000)
                        custo = 227.60;
                    elseif  (ref < 100000)
                        custo = 259.92;
                    elseif  (ref < 150000)
                        custo = 324.56;
                    elseif  (ref < 200000)
                        custo = 487.49;
                    else
                        custo = 649.11;
                    end
                case 'MA'
                    custo =  89;
                case 'MT'
                    custo =  288.60;
                case 'MS'
                    custo =  30*23.35;
                case 'MG'
                    custo =  252.92;
                case 'PA'
                    custo =  173.32;
                case 'PB'
                    custo =  5*44.08;
                case 'PE'
                    if( (valorJulgado - self.custo_recorrer_pago) < 1000)
                        custo =  121.92;
                    else
                        custo =  121.92 + 0.008*valorJulgado;
                    end
                case 'PI'
                    %media = (62.05+88.21+76.79+130.67+62.05+88.21+76.79+130.67)/8; %depende do numero de paginas
                    custo = 89.43;
                case 'RN'
                    custo = 151.18;
                case 'RS'
                    URS = 32.583;
                    ref = valorJulgado;
                    if (ref < 12*URS)
                        custo = 0.4*URS;
                    elseif  (ref < 24*URS)
                        custo = 0.6*URS;
                    elseif  (ref < 80*URS)
                        custo = 1*URS;
                    elseif  (ref < 400*URS)
                        custo = 1.5*URS;
                    elseif  (ref < 800*URS)
                        custo = 2*URS;
                    else
                        % valor adicional de 0.02% muito pouco
                        custo = min(2*URS + 0.0002*ref, 100*URS);
                    end
                case 'RO'
                    custo = 168.76; %pode ser maior dependendo do numero de folhas
                case 'RR'
                    custo = 17.07;
                case 'SC'
                    custo =  0.005 * valorJulgado;
                case 'SE'
                    custo =  112.35;
                case 'TO'
                    custo =  0.005 * valorJulgado;
                otherwise
                    error(['UF não reconhecida ' self.UF]);
            end
        end
        
        % Altera o atributo cluster de numero para referencia ao objeto
        % Cluster de verdade
        function changeClusterNum2Obj(self,clusterArray)
            self.cluster = clusterArray{self.cluster};
        end
        
        function f = minimoValorEsperado(self,perc,espSinkNaoAcordo,curvaAcordo)
            
            prob = interp1(curvaAcordo(:,1),curvaAcordo(:,2),perc);
            
            switch self.id_arvore_atual
                case 1
                    valor_contestado_proporcional = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
                    valor_acordo_vec=perc*valor_contestado_proporcional;
               otherwise
                    valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                    valor_acordo_vec=perc*valor_sentenca;
            end
            
            f =  prob(1).*valor_acordo_vec(1);
            for i=2:(length(perc))
                f = f+(prob(i)-prob(i-1))*valor_acordo_vec(i);
            end
            f = f+(1-prob(end))*espSinkNaoAcordo;
        end
        
        function fval = enuplaAcordo(self,espSinkNaoAcordo, n,percAcordoInicial)
            
            A = zeros(n-1,n);
            for i=1:(n-1)
                A(i,i) = 1;
                A(i,i+1) = -1;
            end
            B = zeros(n-1,1);
            
            perc0 = percAcordoInicial;
            
            curvaAcordo = self.curvaAcordoAjustada(0);
            
            options = optimset('Display','notify');
            [percMin, ~] = fmincon(@(perc)  minimoValorEsperado(self,perc,espSinkNaoAcordo, curvaAcordo)...
                ,perc0,A,B,[],[],[],[],[],options);
            
            fval = minimoValorEsperado(self,percMin,espSinkNaoAcordo, curvaAcordo);
            
            switch self.id_arvore_atual
                case 1
                    valor_contestado_proporcional = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
                    self.valor_acordo=percMin*valor_contestado_proporcional;
                otherwise
                    valor_sentenca = self.calculaValorProcesso(carteira_.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                    self.valor_acordo=percMin*valor_sentenca;
            end
        end
        
        function fval = enuplaAcordo6(self,espSinkNaoAcordo,n)
            
            switch self.id_arvore_atual
                case 1
                    valor_contestado_proporcional = self.calculaValorProcesso(self.carteira.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
                    prop = valor_contestado_proporcional;
                    fixa = 0;
                otherwise
                    valor_sentenca = self.calculaValorProcesso(self.carteira.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                    prop = valor_sentenca;
                    fixa = 0;
            end
            % [dependeValorAcordo, naoDependeValorAcordo] = self.calculaHonorarioAcordo();
            [~, naoDependeValorAcordo] = self.calculaHonorarioAcordo();
            fixa = fixa + naoDependeValorAcordo;
            
            curvaAcordo = self.curvaAcordoAjustada(0);
            curvaA = (curvaAcordo(2:end,2)-curvaAcordo(1:end-1,2))./(curvaAcordo(2:end,1)-curvaAcordo(1:end-1,1));
            curvaB = curvaAcordo(1:end-1,2) - curvaA .* curvaAcordo(1:end-1,1);
            
            switch n
                case 1
                    acordo1 = ((espSinkNaoAcordo-fixa) * curvaA - prop* curvaB)...
                        ./(2*prop*curvaA);
                    
                    validos = ones(size(acordo1));
                    validos(acordo1(:)>curvaAcordo(2:end,1)) = 0;
                    validos(acordo1(:)<curvaAcordo(1:end-1,1)) = 0;
                    
                    % Interior
                    fint = ((curvaA.*acordo1 + curvaB).*(prop.*acordo1 + fixa-espSinkNaoAcordo) + espSinkNaoAcordo);
                    fint(~validos) = 10e100;
                    [fmInt,iInt] = min(fint);
                    
                    % Pontos
                    ffinal =  ((curvaA.*curvaAcordo(2:end,1) + curvaB).*(prop.*curvaAcordo(2:end,1) + fixa-espSinkNaoAcordo) + espSinkNaoAcordo);
                    [fmFinal,iFinal] = min(ffinal);
                    
                    if(min(fmInt,fmFinal)>espSinkNaoAcordo)
                        perc = 0;
                        fval = espSinkNaoAcordo;
                    elseif fmInt < fmFinal
                        perc = acordo1(iInt);
                        fval = fmInt;
                    else
                        perc = curvaAcordo(iFinal+1,1);
                        fval = fmFinal;
                    end
                    
                case 2
                    nIntervalo = length(curvaA);
                    tamanho = 0;
                    for i=1:nIntervalo
                        tamanho = tamanho+(nIntervalo-i+1);
                    end
                    indice1 = zeros(tamanho,1);
                    indice2 = zeros(tamanho,1);
                    
                    indiceInicial = 1;
                    for i=1:nIntervalo
                        indiceFinal = indiceInicial + (nIntervalo-i);
                        indice1(indiceInicial:indiceFinal) = i*ones((nIntervalo-i+1),1);
                        indice2(indiceInicial:indiceFinal) = (i:nIntervalo)';
                        indiceInicial = indiceFinal+1;
                    end
                    
                    a1 = curvaA(indice1);
                    a2 = curvaA(indice2);
                    b1 = curvaB(indice1);
                    b2 = curvaB(indice2);
                    
                    a =2*a1*prop;
                    b = -prop*a1;
                    c = 2*prop*a2;
                    
                    x = -prop*b1;
                    y = -fixa*a2-prop*(b2-b1)+a2*espSinkNaoAcordo;
                    
                    % Interno
                    quoeciente = a.*c-b.*b;
                    acordo1 = (c.*x-b.*y)./quoeciente;
                    acordo2 = (a.*y-b.*x)./quoeciente;
                    
                    validos = ones(size(acordo1));
                    validos(acordo2<acordo1) = 0;
                    validos(acordo1>curvaAcordo(indice1+1,1)) = 0;
                    validos(acordo1<curvaAcordo(indice1,1)) = 0;
                    validos(acordo2>curvaAcordo(indice2+1,1)) = 0;
                    validos(acordo2<curvaAcordo(indice2,1)) = 0;
                    
                    fint = (a1.*acordo1 + b1).*prop.*(acordo1 - acordo2)...
                        + (a2.*acordo2 + b2).*(prop.*acordo2 + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    fint(~validos) = 10e100;
                    
                    [fmInt,iInt] = min(fint);
                    
                    % Retas
                    % y fixo
                    acordo2Retay = curvaAcordo(indice2+1,1);
                    acordo1Retay = (a1.*acordo2Retay-b1)./(2*a1);
                    fretay = (a1.*acordo1Retay + b1).*prop.*(acordo1Retay - acordo2Retay)...
                        + (a2.*acordo2Retay + b2).*(prop.*acordo2Retay + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    validos = ones(size(acordo1));
                    validos(acordo2Retay<acordo1Retay) = 0;
                    validos(acordo1Retay>curvaAcordo(indice1+1,1)) = 0;
                    validos(acordo1Retay<curvaAcordo(indice1,1)) = 0;
                    fretay(~validos) = 10e100;
                    [fmretay,iretay] = min(fretay);
                    
                    
                    % x fixo
                    acordo1Retax = curvaAcordo(indice1+1,1);
                    acordo2Retax = (fixa*a2+prop*(b2-b1)-a2*espSinkNaoAcordo-prop*a1.*acordo1Retax)./(-2*prop*a2);
                    
                    fretax = (a1.*acordo1Retax + b1).*prop.*(acordo1Retax - acordo2Retax)...
                        + (a2.*acordo2Retax + b2).*(prop.*acordo2Retax + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    validos = ones(size(acordo1));
                    validos(acordo2Retax<acordo1Retax) = 0;
                    validos(acordo2Retax>curvaAcordo(indice2+1,1)) = 0;
                    validos(acordo2Retax<curvaAcordo(indice2,1)) = 0;
                    fretax(~validos) = 10e100;
                    [fmretax,iretax] = min(fretax);
                    
                    %  Ponto
                    acordo1ponto =  curvaAcordo(indice1+1,1);
                    acordo2ponto =  curvaAcordo(indice2+1,1);
                    fponto = (a1.*acordo1ponto + b1).*prop.*(acordo1ponto - acordo2ponto)...
                        + (a2.*acordo2ponto + b2).*(prop.*acordo2ponto + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    [fmponto,iponto] = min(fponto);
                    
                    f = [fmInt,fmretay,fmretax,fmponto];
                    
                    fval = min(f);
                    
                    if(fval>espSinkNaoAcordo)
                        perc = 0;
                        fval = espSinkNaoAcordo;
                    elseif fval == fmInt
                        perc = [acordo1(iInt) acordo2(iInt)];
                    elseif fval == fmretay
                        perc = [acordo1Retay(iretay) acordo2Retay(iretay)];
                    elseif fval == fmretax
                        perc = [acordo1Retax(iretax) acordo2Retax(iretax)];
                    elseif fval == fmponto
                        perc = [acordo1ponto(iponto) acordo2ponto(iponto)];
                    end
                    
                case 3
                    nIntervalo = length(curvaA);
                    tamanho = 0;
                    for i=1:nIntervalo
                        for j=i:nIntervalo
                            tamanho = tamanho+(nIntervalo-j+1);
                        end
                    end
                    indice1 = zeros(tamanho,1);
                    indice2 = zeros(tamanho,1);
                    indice3 = zeros(tamanho,1);
                    
                    indiceInicial1 = 1;
                    for i=1:nIntervalo
                        indiceInicial2 = indiceInicial1;
                        for j=i:nIntervalo
                            indiceFinal2 = indiceInicial2 + (nIntervalo-j);
                            indice2(indiceInicial2:indiceFinal2) = j*ones((nIntervalo-j+1),1);
                            indice3(indiceInicial2:indiceFinal2) = (j:nIntervalo)';
                            indiceInicial2 = indiceFinal2+1;
                        end
                        indiceFinal1 = indiceFinal2;
                        quantidadeInterna=indiceFinal1-indiceInicial1+1;
                        indice1(indiceInicial1:indiceFinal1) = i*ones(quantidadeInterna,1);
                        indiceInicial1 = indiceFinal1+1;
                    end
                    
                    a1 = curvaA(indice1);
                    a2 = curvaA(indice2);
                    a3 = curvaA(indice3);
                    b1 = curvaB(indice1);
                    b2 = curvaB(indice2);
                    b3 = curvaB(indice3);
                    
                    a =2*a1*prop;
                    b = -prop*a1;
                    c = 2*prop*a2;
                    d = -prop*a2;
                    e = 2*prop*a3;
                    
                    x = -prop*b1;
                    y = -prop*(b2-b1);
                    z = -prop*(b3-b2)-a3*(fixa-espSinkNaoAcordo);
                    
                    % Interno
                    quoeciente = -a.*c.*e+a.*d.*d+e.*b.*b;
                    acordo1 = (-b.*d.*z+b.*e.*y-c.*e.*x+d.*d.*x)./quoeciente;
                    acordo2 = (-a.*e.*y+a.*d.*z+b.*e.*x)./quoeciente;
                    acordo3 = (-a.*c.*z+a.*d.*y+b.*b.*z-b.*d.*x)./quoeciente;
                    
                    validos = ones(size(acordo1));
                    validos(acordo2<acordo1) = 0;
                    validos(acordo3<acordo2) = 0;
                    validos(acordo1>curvaAcordo(indice1+1,1)) = 0;
                    validos(acordo1<curvaAcordo(indice1,1)) = 0;
                    validos(acordo2>curvaAcordo(indice2+1,1)) = 0;
                    validos(acordo2<curvaAcordo(indice2,1)) = 0;
                    validos(acordo3>curvaAcordo(indice3+1,1)) = 0;
                    validos(acordo3<curvaAcordo(indice3,1)) = 0;
                    
                    fint = (a1.*acordo1 + b1).*prop.*(acordo1 - acordo2)...
                        + (a2.*acordo2 + b2).*prop.*(acordo2 - acordo3)...
                        + (a3.*acordo3 + b3).*(prop.*acordo3 + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    
                    fint(~validos) = 10e100;
                    
                    [fmInt,iInt] = min(fint);
                    
                    % Faces
                    % xfixo
                    acordo1Facex = curvaAcordo(indice1+1,1);
                    
                    a =2*prop*a2;
                    b = -prop*a2;
                    c = 2*prop*a3;
                    
                    x = -prop*(b2-b1-a1.*acordo1Facex);
                    y = -prop*(b3-b2)-a3*(fixa-espSinkNaoAcordo);
                    
                    quoeciente = a.*c-b.*b;
                    acordo2Facex = (c.*x-b.*y)./quoeciente;
                    acordo3Facex = (a.*y-b.*x)./quoeciente;
                    
                    fFacex = (a1.*acordo1Facex + b1).*prop.*(acordo1Facex - acordo2Facex)...
                        + (a2.*acordo2Facex + b2).*prop.*(acordo2Facex - acordo3Facex)...
                        + (a3.*acordo3Facex + b3).*(prop.*acordo3Facex + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    
                    validos = ones(size(acordo1));
                    validos(acordo2Facex<acordo1Facex) = 0;
                    validos(acordo3Facex<acordo2Facex) = 0;
                    validos(acordo2Facex>curvaAcordo(indice2+1,1)) = 0;
                    validos(acordo2Facex<curvaAcordo(indice2,1)) = 0;
                    validos(acordo3Facex>curvaAcordo(indice3+1,1)) = 0;
                    validos(acordo3Facex<curvaAcordo(indice3,1)) = 0;
                    
                    fFacex(~validos) = 10e100;
                    [fmFacex,iFacex] = min(fFacex);
                    
                    % Faces
                    % yfixo
                    acordo2Facey = curvaAcordo(indice2+1,1);
                    acordo1Facey = (a1.*acordo2Facey-b1)./(2*a1);
                    acordo3Facey =  (-prop*(b3-b2)-a3*(fixa-espSinkNaoAcordo)+prop.*a2.*acordo2Facey)./(2*prop.*a3);
                    
                    fFacey = (a1.*acordo1Facey + b1).*prop.*(acordo1Facey - acordo2Facey)...
                        + (a2.*acordo2Facey + b2).*prop.*(acordo2Facey - acordo3Facey)...
                        + (a3.*acordo3Facey + b3).*(prop.*acordo3Facey + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    
                    validos = ones(size(acordo1));
                    validos(acordo2Facey<acordo1Facey) = 0;
                    validos(acordo3Facey<acordo2Facey) = 0;
                    validos(acordo1Facey>curvaAcordo(indice1+1,1)) = 0;
                    validos(acordo1Facey<curvaAcordo(indice1,1)) = 0;
                    validos(acordo3Facey>curvaAcordo(indice3+1,1)) = 0;
                    validos(acordo3Facey<curvaAcordo(indice3,1)) = 0;
                    
                    fFacey(~validos) = 10e100;
                    [fmFacey,iFacey] = min(fFacey);
                    
                    % Faces
                    % zfixo
                    acordo3Facez = curvaAcordo(indice3+1,1);
                    
                    a =  2*prop*a1;
                    b = -prop*a1;
                    c = 2*prop*a2;
                    
                    x = -prop*b1;
                    y = -prop*(b2-b1-a2.*acordo3Facez);
                    
                    quoeciente = a.*c-b.*b;
                    acordo1Facez = (c.*x-b.*y)./quoeciente;
                    acordo2Facez = (a.*y-b.*x)./quoeciente;
                    
                    fFacez = (a1.*acordo1Facez + b1).*prop.*(acordo1Facez - acordo2Facez)...
                        + (a2.*acordo2Facez + b2).*prop.*(acordo2Facez - acordo3Facez)...
                        + (a3.*acordo3Facez + b3).*(prop.*acordo3Facez + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    
                    validos = ones(size(acordo1));
                    validos(acordo2Facez<acordo1Facez) = 0;
                    validos(acordo3Facez<acordo2Facez) = 0;
                    validos(acordo1Facez>curvaAcordo(indice1+1,1)) = 0;
                    validos(acordo1Facez<curvaAcordo(indice1,1)) = 0;
                    validos(acordo2Facez>curvaAcordo(indice2+1,1)) = 0;
                    validos(acordo2Facez<curvaAcordo(indice2,1)) = 0;
                    
                    fFacez(~validos) = 10e100;
                    [fmFacez,iFacez] = min(fFacez);
                    
                    % Retas
                    % x varia
                    acordo2Retax = curvaAcordo(indice2+1,1);
                    acordo3Retax = curvaAcordo(indice3+1,1);
                    acordo1Retax = (a1.*acordo2Retax-b1)./(2*a1);
                    
                    fRetax = (a1.*acordo1Retax + b1).*prop.*(acordo1Retax - acordo2Retax)...
                        + (a2.*acordo2Retax + b2).*prop.*(acordo2Retax - acordo3Retax)...
                        + (a3.*acordo3Retax + b3).*(prop.*acordo3Retax + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    
                    validos = ones(size(acordo1));
                    
                    validos(acordo2Retax<acordo1Retax) = 0;
                    validos(acordo1Retax>curvaAcordo(indice1+1,1)) = 0;
                    validos(acordo1Retax<curvaAcordo(indice1,1)) = 0;
                    
                    fRetax(~validos) = 10e100;
                    [fmRetax,iRetax] = min(fRetax);
                    
                    % Retas
                    % y varia
                    acordo1Retay = curvaAcordo(indice1+1,1);
                    acordo3Retay = curvaAcordo(indice3+1,1);
                    acordo2Retay = (-b2+b1+a1.*acordo1Retay + a2.*acordo3Retay)./(2*a2);
                    
                    fRetay = (a1.*acordo1Retay + b1).*prop.*(acordo1Retay - acordo2Retay)...
                        + (a2.*acordo2Retay + b2).*prop.*(acordo2Retay - acordo3Retay)...
                        + (a3.*acordo3Retay + b3).*(prop.*acordo3Retay + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    
                    validos = ones(size(acordo1));
                    
                    validos(acordo2Retay<acordo1Retay) = 0;
                    validos(acordo3Retay<acordo2Retay) = 0;
                    validos(acordo2Retay>curvaAcordo(indice2+1,1)) = 0;
                    validos(acordo2Retay<curvaAcordo(indice2,1)) = 0;
                    
                    fRetay(~validos) = 10e100;
                    [fmRetay,iRetay] = min(fRetay);
                    
                    % Retas
                    % z varia
                    acordo1Retaz = curvaAcordo(indice1+1,1);
                    acordo2Retaz = curvaAcordo(indice2+1,1);
                    acordo3Retaz = (-prop*(b3-b2)-a3*(fixa-espSinkNaoAcordo)+prop.*a2.*acordo2Facey)./(2*prop.*a3);
                    
                    fRetaz = (a1.*acordo1Retaz + b1).*prop.*(acordo1Retaz - acordo2Retaz)...
                        + (a2.*acordo2Retaz + b2).*prop.*(acordo2Retaz - acordo3Retaz)...
                        + (a3.*acordo3Retaz + b3).*(prop.*acordo3Retaz + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    
                    validos = ones(size(acordo1));
                    
                    validos(acordo3Retaz<acordo2Retaz) = 0;
                    validos(acordo3Retaz>curvaAcordo(indice3+1,1)) = 0;
                    validos(acordo3Retaz<curvaAcordo(indice3,1)) = 0;
                    
                    fRetaz(~validos) = 10e100;
                    [fmRetaz,iRetaz] = min(fRetaz);
                    
                    %  Ponto
                    acordo1ponto =  curvaAcordo(indice1+1,1);
                    acordo2ponto =  curvaAcordo(indice2+1,1);
                    acordo3ponto =  curvaAcordo(indice3+1,1);
                    
                    fPonto = (a1.*acordo1ponto + b1).*prop.*(acordo1ponto - acordo2ponto)...
                        + (a2.*acordo2ponto + b2).*prop.*(acordo2ponto - acordo3ponto)...
                        + (a3.*acordo3ponto + b3).*(prop.*acordo3ponto + fixa-espSinkNaoAcordo) + espSinkNaoAcordo;
                    
                    [fmPonto,iPonto] = min(fPonto);
                    
                    % Verifica menor otimização
                    
                    f = [fmInt,fmPonto,fmRetax,fmRetay,fmRetaz,fmFacex,fmFacey,fmFacez];
                    
                    [fval,~] = min(f);
                    
                    
                    if(fval>espSinkNaoAcordo)
                        perc = 0;
                        fval = espSinkNaoAcordo;
                    elseif fval == fmInt
                        perc = [acordo1(iInt) acordo2(iInt) acordo3(iInt)];
                    elseif fval == fmPonto
                        perc = [acordo1ponto(iPonto) acordo2ponto(iPonto) acordo3ponto(iPonto)];
                    elseif fval == fmRetax
                        perc = [acordo1Retax(iRetax) acordo2Retax(iRetax) acordo3Retax(iRetax)];
                    elseif fval == fmRetay
                        perc = [acordo1Retay(iRetay) acordo2Retay(iRetay) acordo3Retay(iRetay)];
                    elseif fval == fmRetaz
                        perc = [acordo1Retaz(iRetaz) acordo2Retaz(iRetaz) acordo3Retaz(iRetaz)];
                    elseif fval == fmFacex
                        perc = [acordo1Facex(iFacex) acordo2Facex(iFacex) acordo3Facex(iFacex)];
                    elseif fval == fmFacey
                        perc = [acordo1Facey(iFacey) acordo2Facey(iFacey) acordo3Facey(iFacey)];
                    elseif fval == fmFacez
                        perc = [acordo1Facez(iFacez) acordo2Facez(iFacez) acordo3Facez(iFacez)];
                    end
            end
            
            switch self.id_arvore_atual
                case 1
                    valor_contestado_proporcional = self.calculaValorProcesso(self.carteira.indiceTempo, self.pedidos_em_pauta, self.fatorMulta);
                    self.valor_acordo=perc*valor_contestado_proporcional;
                otherwise
                    valor_sentenca = self.calculaValorProcesso(self.carteira.indiceTempo, self.pedidos_deferidos, self.fatorMulta);
                    self.valor_acordo=perc*valor_sentenca;
            end
        end
        
        % Carrega as propriedades base
        function loadProperties(self,nome,valor, mostrarWarning)
            switch nome
                case 'procIdU'
                    self.idAgente = valor{1};
                    if(~isnumeric(self.idAgente))
                        error('IdAgente não é numerico');
                    end
                    if(~(self.idAgente==floor(self.idAgente)))
                        error('IdAgente não é um inteiro');
                    end
                    
                case 'dataDistProc'
                    % no Excel dataDistProc é da forma (nProcessos)
                    dataDistProc = datenum(valor{1},'dd/mm/yyyy'); %Já verifica se a data é uma string
                    if(dataDistProc < 723181)  %Verifica se a data é muito antiga 1980
                        if(mostrarWarning)
                            warning(['Processo: ' num2str(self.idAgente) ': Data de distribuição menor que 1990']);
                        end
                    end
                    if(dataDistProc > self.carteira.data) %Verifica se a data é maior que a data da carteira
                        if(mostrarWarning)
                            warning(['Processo: ' num2str(self.idAgente) ': Data de distruibuição é menor que a data inicial da carteira. Considerando data de distribuição igual ao da carteira']);
                        end
                    end
                    self.data_distribuicao = dataDistProc;
                    self.data_reclamacao = (dataDistProc-self.carteira.data)/ 30;
                    
                case 'pedMatrix'
                    % no Excel pedMatrix é da forma (nProcessos,nPedidos)
                    % no Matlab pedMatrix é da forma (nPedidos)
                    self.nPedidos = length(valor);
                    self.pedidos = zeros(self.nPedidos,1);
                    self.pedidos = cell2mat(valor)'; %já verifica se os tipos são iguais
                    if(sum(isnan(self.pedidos)))
                        error(['Processo: ' num2str(self.idAgente) ': Algum pedido é NaN']);
                    end
                    if(sum(self.pedidos<0))
                        warning(['Processo: ' num2str(self.idAgente) ':Algum pedido é negativo']);
                    end
                    if(sum(self.pedidos) == 0)
                        if(mostrarWarning)
                            warning(['Processo: ' num2str(self.idAgente) ': A somatoria dos pedidos do processo é zero']);
                        end
                    end
                    self.pedidos_em_pauta = self.pedidos > 0;
                    
                case 'ArvoreBlocoProc'
                    self.id_arvore_atual = valor{1};
                    self.id_bloco_atual = valor{2};
                    if(~(isnumeric(self.id_arvore_atual) &&  isnumeric(self.id_bloco_atual)))
                        error(['Processo: ' num2str(self.idAgente) ': O bloco inicial é NaN']);
                    end
                    if(~((self.id_arvore_atual==floor(self.id_arvore_atual))  && ...
                            (self.id_bloco_atual==floor(self.id_bloco_atual))))
                        error(['Processo: ' num2str(self.idAgente) ': O bloco inicial deve ser um inteiro']);
                    end
                    if(self.arvoreModelo.idPair2idNoh(self.id_arvore_atual,self.id_bloco_atual) == 0)
                        error(['Processo: ' num2str(self.idAgente) ': O bloco inicial do processo é invalido']);
                    end
                    if(self.arvoreModelo.tipo(self.id_arvore_atual,self.id_bloco_atual) ~= model.NohModelo.CONTROLE)
                        if(mostrarWarning)
                            warning(['Processo: ' num2str(self.idAgente) ': O bloco inicial não é do tipo controle']);
                            if(self.arvoreModelo.tipoBloco(self.id_arvore_atual,self.id_bloco_atual) ~= model.NohModelo.ACORDO)
                                warning(['Processo: ' num2str(self.idAgente) ': O bloco inicial não é do tipoBloco acordo']);
                            end
                        end
                    end
                    
                case 'probabilidades'
                    %complemento{1} = nPedidos
                    % no Excel probabilidade é da forma (nProcessos, nPedidos)
                    % no matlab da forma (nPedidos)
                    if(self.nPedidos == 0)
                        error('Planilha pedMatrix deve vir antes de probabilidades, ou algum proceso não tem nenhum pedido');
                    end
                    self.matClasseProb = cell2mat(valor)'; %já verifica se os tipos são iguais
                    if(sum(isnan(self.matClasseProb)))
                        error(['Processo: ' num2str(self.idAgente) ': Alguma probabilidade é NaN']);
                    end
                    if(length(self.matClasseProb) ~= self.nPedidos)
                        error(['Processo: ' num2str(self.idAgente) ': A numero de colunas de probabilidade é diferente do numero de pedidos']);
                    end
                    if(sum(self.matClasseProb<0))
                        error(['Processo: ' num2str(self.idAgente) ': Alguma probabilidade é menor que zero']);
                    end
                    if(sum(self.matClasseProb>1))
                        error(['Processo: ' num2str(self.idAgente) ': Alguma probabilidade é maior do que 1']);
                    end
                    
                case 'MantemProc'
                    % MantemProc verifica a probabilidade de manter a
                    % decisão entre as instancia. Ele nao existe para na
                    % primeira instancia
                    if(self.nPedidos == 0)
                        error('Planilha pedMatrix deve vir antes de MantemProc');
                    end
                    nInstacia_1 = length(valor);
                    
                    % Verifica consistencia de   MantemProc
                    Instacia_1 = cell2mat(valor)';%já verifica se os tipos são iguais
                    if (nInstacia_1 ~= 3)
                        error(['Processo: ' num2str(self.idAgente) ': MantemProc não possui tres colunas']);
                    end
                    if(sum(isnan(Instacia_1)))
                        error(['Processo: ' num2str(self.idAgente) ': Alguma entrada de MantemProc é NaN']);
                    end
                    if(sum(Instacia_1<0))
                        error(['Processo: ' num2str(self.idAgente) ': Alguma entrada de MantemProc é menor que zero']);
                    end
                    if(sum(Instacia_1>1))
                        error(['Processo: ' num2str(self.idAgente) ': Alguma entrada de MantemProc é maior do que 1']);
                    end
                    
                    self.matClasseProbDecisaoDef = zeros(self.nPedidos,nInstacia_1);
                    for indInstancia = 1:nInstacia_1
                        self.matClasseProbDecisaoDef(:,indInstancia) =  ones(self.nPedidos,1) .* valor{indInstancia};
                    end
                    
                case 'reversãoImproc'
                    %mesma coisa que o matemProc
                    if(self.nPedidos == 0)
                        error('Planilha pedMatrix deve vir antes de reversãoImproc');
                    end
                    nInstacia_1 = length(valor);
                    
                    % Verifica consistencia de   MantemProc
                    Instacia_1 = cell2mat(valor)';
                    if (nInstacia_1 ~= 3)
                        error(['Processo: ' num2str(self.idAgente) ': reversãoImproc não possui tres colunas']);
                    end
                    if(sum(isnan(Instacia_1)))
                        error(['Processo: ' num2str(self.idAgente) ': Alguma entrada de reversãoImproc é NaN']);
                    end
                    if(sum(Instacia_1<0))
                        error(['Processo: ' num2str(self.idAgente) ': Alguma entrada de reversãoImproc é menor que zero']);
                    end
                    if(sum(Instacia_1>1))
                        error(['Processo: ' num2str(self.idAgente) ': Alguma entrada de reversãoImproc é maior do que 1']);
                    end
                    
                    self.matClasseProbDecisaoIndef = zeros(self.nPedidos,nInstacia_1);
                    for indInstancia = 1:nInstacia_1
                        self.matClasseProbDecisaoIndef(:,indInstancia) =  ones(self.nPedidos,1) .* valor{indInstancia};
                    end
                    
                case 'IsImproc'
                    if(self.id_arvore_atual == 0)
                        error('A planilha ArvoreBlocoProc deve vir antes de isImproc');
                    end
                    
                    % Verifica consistencia de   MantemProc
                    isImproc = cell2mat(valor)';
                    if (length(isImproc) ~= self.nPedidos)
                        error(['Processo: ' num2str(self.idAgente) ': Numero de colunas de isImproc é diferente do numero de pedidos']);
                    end
                    if(sum(isnan(isImproc)))
                        error(['Processo: ' num2str(self.idAgente) ': Alguma entrada de isImproc é NaN']);
                    end
                    if(sum(isImproc==0 | isImproc==1) ~= self.nPedidos)
                        error(['Processo: ' num2str(self.idAgente) ': Alguma entrada de isImproc é diferente de zero ou 1']);
                    end
                    
                    % pedidos_em_pauta foi definido em pedMatrix
                    self.pedidos_deferidos = self.pedidos_em_pauta;
                    
                    for i=1:self.nPedidos
                        if(valor{i})
                            self.pedidos_deferidos(i,1)=false;
                        end
                    end
                    
                    if(sum(self.pedidos_deferidos) == 0 && self.id_arvore_atual > 100)
                        if(mostrarWarning)
                            warning(['Processo: ' num2str(self.idAgente) ': Processo totalmente indeferido em execução']);
                        end
                    end
                    
                    self.provisao = (self.id_arvore_atual> 1) * sum(sum(self.pedidos_deferidos .* self.pedidos));
                    
                case 'esperaInicial'
                    self.esperaInicial = valor{1};
                    if(~(self.esperaInicial ==floor(self.esperaInicial)))
                        error(['Processo: ' num2str(self.idAgente) ':Espera inicial não é um inteiro']);
                    end
                    if(self.esperaInicial<0)
                        error(['Processo: ' num2str(self.idAgente) ':Espera incial é negativo']);
                    end
                    
                case 'proposta'
                    self.propostaNaoAceita = valor{1};
                    self.contraProposta = valor{2};
                    if(isnan(self.propostaNaoAceita) || isnan(self.contraProposta ))
                        error(['Processo: ' num2str(self.idAgente) ':Proposta ou contra proposta é NaN']);
                    end
                    if(self.propostaNaoAceita<0)
                        if(self.propostaNaoAceita ~= -1)
                            error(['Processo: ' num2str(self.idAgente) ':Proposta não aceita é negativa e diferente de -1']);
                        end
                    end
                    if(self.contraProposta<0)
                        if(self.contraProposta ~= -1)
                            error(['Processo: ' num2str(self.idAgente) ':Contra proposta não aceita é negativa e diferente de -1']);
                        end
                    end
                    
                case 'data_pedMatrix'
                    self.data_pedmatrix = datenum(valor{1},'dd/mm/yyyy');
                    if(self.data_pedmatrix < 726834)  %Verifica se a data é muito antiga 1990
                        if(mostrarWarning)
                            warning(['Processo: ' num2str(self.idAgente) ': Data do pedmatrix menor que 1990']);
                        end
                    end
                    
                    if(self.data_pedmatrix > self.carteira.data) %Verifica se a data é maior que a data da carteira
                        if(mostrarWarning)
                            warning(['Processo: ' num2str(self.idAgente) ': Data do pedmatrix é maior que a data inicial da carteira. Considerando data do pedmatrix igual ao da carteira']);
                        end
                    end
                    if(self.data_pedmatrix < self.data_distribuicao) %Verifica se a data do pedmatrix é menor que a data da distribui~ção
                        if(mostrarWarning)
                            warning(['Processo: ' num2str(self.idAgente) ': Data do pedmatrix é menor que a data_distribuicao.']);
                        end
                    end
                    
                case 'idCliente'
                    self.idCliente = valor{1};
                    
                otherwise
                    loadPropertiesEspecifico(self,nome,valor);
            end
        end
        
    end
    
end