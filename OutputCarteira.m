classdef OutputCarteira < handle
    % OutputCarteira: Objeto que indica a evolução da carteira de processos
    % no tempo
    
    properties
        
        % tSim deve ser o primeiro atributo, os outros não importam
        tsim
        nProcesso
        nPedido
        
        nAcordo
        nCondenacao
        nExito
        
        fluxoAcordoFechados
        fluxoAcordo
        fluxoCondenacao   
        fluxoCustoHonorario
        fluxoCustasProcessuais
        fluxoEntradaDeposito
        fluxoSaidaDeposito
        
        fluxoAcordoProcesso
        fluxoCondenacaoProcesso
        fluxoCustoHonorarioProcesso
        fluxoCustasProcessuaisProcesso
        fluxoEntradaDepositoProcesso
        fluxoSaidaDepositoProcesso
        
        individuaisAcordos
        individuaisCondenacoes
        individuaisTipoEncerramento
        individuaisDepositoSaida
        
        individuaisJulgamento1a
        individuaisJulgamento1b
        individuaisJulgamento2a
        individuaisJulgamento2b
        individuaisJulgamento3a
        individuaisJulgamento3b
        individuaisJulgamento4a
        individuaisJulgamento4b
        
%         individuaisDepositoEntrada
        
        historico
        historicoAcordo
        %  hisotico acordo para cada {sim}{Processo} tem a forma
        % [idArvore idBloco percOferecido AcordoOferecido condição percMinimoAcordo]
        % As condições podem ser:
        % 0 - Acordo Recusado;1 - Acordo aceito; 2 - Acordo acima do percMim (mas não chegamos a oferecelo, o reclamante aceitou acordo anterior)
        % 3 - Acordo acima do percMim mas não foi fechado devido ao budget
        
        primeiroSetAcordo
        
        estado1Julga
        estado2JulgaDef
        estado2JulgaInd
        estado3JulgaDef
        estado3JulgaInd
        estado4JulgaDef
        estado4JulgaInd
        
        budgetVector
        
    end
    
    methods
        
        % constructor
        function self = OutputCarteira(tsim, nProcesso, nPedido)
            if(nargin == 3)
                self.tsim = tsim;
                self.nProcesso = nProcesso;
                self.nPedido = nPedido;
                
                self.nAcordo = 0;
                self.nCondenacao = 0;
                self.nExito = 0;
                
                self.fluxoAcordoFechados = sparse(tsim+1,1);
                self.fluxoAcordo = sparse(tsim+1,1);
                self.fluxoCondenacao = sparse(tsim+1,1);
                self.fluxoCustoHonorario = sparse(tsim+1,1);
                self.fluxoCustasProcessuais = sparse(tsim+1,1);
                self.fluxoEntradaDeposito = sparse(tsim+1,1);
                self.fluxoSaidaDeposito = sparse(tsim+1,1);
                
                self.fluxoAcordoProcesso = sparse(nProcesso,tsim+1);
                self.fluxoCondenacaoProcesso = sparse(nProcesso,tsim+1);
                self.fluxoCustoHonorarioProcesso = sparse(nProcesso,tsim+1);
                self.fluxoCustasProcessuaisProcesso = sparse(nProcesso,tsim+1);
                self.fluxoEntradaDepositoProcesso = sparse(nProcesso,tsim+1);
                self.fluxoSaidaDepositoProcesso = sparse(nProcesso,tsim+1);                
                
                self.individuaisAcordos = sparse(nProcesso,nPedido+3);
                self.individuaisCondenacoes = sparse(nProcesso,nPedido+3);
                self.individuaisTipoEncerramento = zeros(nProcesso,2);
                self.individuaisDepositoSaida = sparse(nProcesso,4);
        
                self.individuaisJulgamento1a = zeros(0,3);
                self.individuaisJulgamento1b = zeros(0,3);
                self.individuaisJulgamento2a = zeros(0,3);
                self.individuaisJulgamento2b = zeros(0,3);
                self.individuaisJulgamento3a = zeros(0,3);
                self.individuaisJulgamento3b = zeros(0,3);
                self.individuaisJulgamento4a = zeros(0,3);
                self.individuaisJulgamento4b = zeros(0,3);
                
                self.historico = cell(nProcesso,1);
                self.historicoAcordo  = cell(nProcesso,1);
                
                self.estado1Julga = sparse(nProcesso,nPedido);
                self.estado2JulgaDef= sparse(nProcesso,nPedido);
                self.estado2JulgaInd= sparse(nProcesso,nPedido);
                self.estado3JulgaDef= sparse(nProcesso,nPedido);
                self.estado3JulgaInd= sparse(nProcesso,nPedido);
                self.estado4JulgaDef= sparse(nProcesso,nPedido);
                self.estado4JulgaInd= sparse(nProcesso,nPedido);
                
                self.budgetVector = zeros(tsim+1,1);
                self.primeiroSetAcordo = [];
                
            elseif nargin == 0
                %Default Constructor         
            else
                error('Numero de argumentos no construtor de OutputCarteira inválido. Ou o construtor é o defacult ou receve tSim')
            end
        end
        
           % identifica o tamanho do objeto
        function [totSize] = getSize(self)
            props = properties(self);
            totSize = 0;
            for ii=1:length(props)
                %                 if(~(strcmp(props{ii},'historico') || strcmp(props{ii},'historicoAcordo')))
                % carteira inicial não entra na conta
                currentProperty = self.(props{ii});
                s = whos('currentProperty');
                totSize = totSize + s.bytes;
                %                 end
            end
        end
        
        % deepCopy
        function obj = deepCopy(self)
            obj = model.OutputCarteira();
            
            obj.tsim = self.tsim ;
            obj.nProcesso = self.nProcesso;
            obj.nPedido = self.nPedido;
            
            obj.nAcordo = self.nAcordo;
            obj.nCondenacao = self.nCondenacao;
            obj.nExito = self.nExito;
            
            obj.fluxoAcordoFechados = self.fluxoAcordoFechados;
            obj.fluxoAcordo = self.fluxoAcordo;
            obj.fluxoCondenacao = self.fluxoCondenacao;
            obj.fluxoCustoHonorario =  self.fluxoCustoHonorario;
            obj.fluxoCustasProcessuais = self.fluxoCustasProcessuais;
            obj.fluxoEntradaDeposito = self.fluxoEntradaDeposito;
            obj.fluxoSaidaDeposito =  self.fluxoSaidaDeposito ;
            
            obj.fluxoAcordoProcesso = self.fluxoAcordoProcesso;
            obj.fluxoCondenacaoProcesso = self.fluxoCondenacaoProcesso;
            obj.fluxoCustoHonorarioProcesso =  self.fluxoCustoHonorarioProcesso;
            obj.fluxoCustasProcessuaisProcesso = self.fluxoCustasProcessuaisProcesso;
            obj.fluxoEntradaDepositoProcesso = self.fluxoEntradaDepositoProcesso;
            obj.fluxoSaidaDepositoProcesso = self.fluxoSaidaDepositoProcesso;
            
            obj.individuaisAcordos = self.individuaisAcordos;
            obj.individuaisCondenacoes =  self.individuaisCondenacoes;
            obj.individuaisTipoEncerramento = self.individuaisTipoEncerramento ;
            obj.individuaisDepositoSaida = self.individuaisDepositoSaida;
            
            obj.individuaisJulgamento1a = self.individuaisJulgamento1a;
            obj.individuaisJulgamento1b = self.individuaisJulgamento1b;
            obj.individuaisJulgamento2a =  self.individuaisJulgamento2a;
            obj.individuaisJulgamento2b = self.individuaisJulgamento2b;
            obj.individuaisJulgamento3a =self.individuaisJulgamento3a;
            obj.individuaisJulgamento3b = self.individuaisJulgamento3b;
             obj.individuaisJulgamento4a =self.individuaisJulgamento4a;
            obj.individuaisJulgamento4b = self.individuaisJulgamento4b;
            
            obj.estado1Julga =  self.estado1Julga;
            obj.estado2JulgaDef =  self.estado2JulgaDef;
            obj.estado2JulgaInd =  self.estado2JulgaInd;
            obj.estado3JulgaDef =  self.estado3JulgaDef;
            obj.estado3JulgaInd =  self.estado3JulgaInd;
            obj.estado4JulgaDef =  self.estado4JulgaDef;
            obj.estado4JulgaInd =  self.estado4JulgaInd;
                        
            obj.primeiroSetAcordo =  self.primeiroSetAcordo;
            obj.historico = self.historico;
            obj.historicoAcordo = self.historicoAcordo;
            
        end
        
        % Adiciona as novas informações do processo no output da carteira
        function self = addOutput(self,processo,indiceTempo)
            
            tempoApos = indiceTempo + processo.servTime+1; %Lembrar que o matlab começa do 1,. quanto o tempo do 0
            
            % Caso o tempo extrapole o limiete da simulação, o output será
            % adicionado em tsim+1
            if(tempoApos > self.tsim+1)
                tempoApos = self.tsim+1;
            end
            
            % Analisa quais operações de output deve ser executadas
            % dependendo do tipoOutput
            switch  processo.tipoOutput
                case model.NohModelo.ACORDO
                    self.nAcordo = self.nAcordo + 1;
                    self.fluxoAcordo(tempoApos) = self.fluxoAcordo(tempoApos) + processo.valor_acordo;
                    self.fluxoAcordoProcesso(processo.idAgente,tempoApos) = self.fluxoAcordoProcesso(processo.idAgente,tempoApos) + processo.valor_acordo;
                    self.fluxoAcordoFechados(tempoApos) = self.fluxoAcordoFechados(tempoApos)+1;
                    self.individuaisTipoEncerramento(processo.idAgente,:) = [tempoApos-1 1];
                   
                    if(self.nPedido >1)
                        [percentualTotal] = processo.calculaPercentualTotal();
                        self.individuaisAcordos(processo.idAgente,:) = [tempoApos-1 processo.tempoEncerramentoBloco processo.valor_acordo percentualTotal'*processo.valor_acordo];
                    else
                        self.individuaisAcordos(processo.idAgente,:) = [tempoApos-1 processo.tempoEncerramentoBloco processo.valor_acordo processo.valor_acordo];
                    end
                                      
                   if((processo.deposito_recursal1+processo.deposito_recursal2+processo.deposito_execucao ) > 0)
                       self.fluxoSaidaDeposito(tempoApos) =  self.fluxoSaidaDeposito(tempoApos) + processo.deposito_recursal1+ processo.deposito_recursal2+processo.deposito_execucao;
                       self.fluxoSaidaDepositoProcesso(processo.idAgente,tempoApos) =  self.fluxoSaidaDepositoProcesso(processo.idAgente,tempoApos) + processo.deposito_recursal1+ processo.deposito_recursal2+processo.deposito_execucao;                       
                       self.individuaisDepositoSaida(processo.idAgente,:) = [tempoApos-1 processo.deposito_recursal1 processo.deposito_recursal2 processo.deposito_execucao];
                   end
                                        
                case model.NohModelo.CONDENACAO
                    
                    self.nCondenacao = self.nCondenacao + 1;
%                     self.fluxoCondenacao(tempoApos) = self.fluxoCondenacao(tempoApos) + processo.valor_sentenca;
                    valorSentenca = processo.calculaValorProcesso(tempoApos-1, processo.pedidos_deferidos, processo.fatorMulta);
                    self.fluxoCondenacao(tempoApos) = self.fluxoCondenacao(tempoApos) + valorSentenca;
                    self.fluxoCondenacaoProcesso(processo.idAgente,tempoApos) = self.fluxoCondenacaoProcesso(processo.idAgente,tempoApos) + valorSentenca;
                    self.individuaisTipoEncerramento(processo.idAgente,:) = [tempoApos-1 2];
                    
                    if(self.nPedido >1)
                        [percentualTotal] = processo.calculaPercentualTotal();
                        self.individuaisCondenacoes(processo.idAgente,:) = [tempoApos-1 processo.tempoEncerramentoBloco valorSentenca percentualTotal'*valorSentenca];
                    else
                        self.individuaisCondenacoes(processo.idAgente,:) = [tempoApos-1 processo.tempoEncerramentoBloco valorSentenca valorSentenca];
                    end
                    
                    if((processo.deposito_recursal1+processo.deposito_recursal2+processo.deposito_execucao ) > 0)
                        self.fluxoSaidaDeposito(tempoApos) =  self.fluxoSaidaDeposito(tempoApos) + processo.deposito_recursal1+ processo.deposito_recursal2+processo.deposito_execucao;
                        self.fluxoSaidaDepositoProcesso(processo.idAgente,tempoApos) =  self.fluxoSaidaDepositoProcesso(processo.idAgente,tempoApos) + processo.deposito_recursal1+ processo.deposito_recursal2+processo.deposito_execucao;
                        self.individuaisDepositoSaida(processo.idAgente,:) = [tempoApos-1 processo.deposito_recursal1 processo.deposito_recursal2 processo.deposito_execucao];
                    end
                    
                case model.NohModelo.EXITO
                    self.nExito = self.nExito + 1;
                    
                    self.individuaisTipoEncerramento(processo.idAgente,:) = [tempoApos-1 3];
                    if((processo.deposito_recursal1+processo.deposito_recursal2+processo.deposito_execucao ) > 0)
                        self.fluxoSaidaDeposito(tempoApos) =  self.fluxoSaidaDeposito(tempoApos) + processo.deposito_recursal1+ processo.deposito_recursal2+processo.deposito_execucao;
                        self.fluxoSaidaDepositoProcesso(processo.idAgente,tempoApos) =  self.fluxoSaidaDepositoProcesso(processo.idAgente,tempoApos) + processo.deposito_recursal1+ processo.deposito_recursal2+processo.deposito_execucao;
                        self.individuaisDepositoSaida(processo.idAgente,:) = [tempoApos-1 processo.deposito_recursal1 processo.deposito_recursal2 processo.deposito_execucao];
                    end
                    
                case model.NohModelo.JULGAMENTO_1a
                     valorSentenca = processo.calculaValorProcesso(tempoApos-1, processo.pedidos_deferidos, processo.fatorMulta);
                     self.individuaisJulgamento1a(end+1,:) = [tempoApos-1 valorSentenca processo.idAgente];
                   
                case model.NohModelo.JULGAMENTO_1b
                     valorSentenca = processo.calculaValorProcesso(tempoApos-1, processo.pedidos_deferidos, processo.fatorMulta);
                   self.individuaisJulgamento1b(end+1,:) = [tempoApos-1 valorSentenca processo.idAgente];
                     
                case model.NohModelo.JULGAMENTO_2a
                     valorSentenca = processo.calculaValorProcesso(tempoApos-1, processo.pedidos_deferidos, processo.fatorMulta);
                    self.individuaisJulgamento2a(end+1,:) = [tempoApos-1 valorSentenca processo.idAgente];
                    
                case model.NohModelo.JULGAMENTO_2b
                     valorSentenca = processo.calculaValorProcesso(tempoApos-1, processo.pedidos_deferidos, processo.fatorMulta);
                    self.individuaisJulgamento2b(end+1,:) = [tempoApos-1 valorSentenca processo.idAgente];
                    
                case model.NohModelo.JULGAMENTO_3a
                     valorSentenca = processo.calculaValorProcesso(tempoApos-1, processo.pedidos_deferidos, processo.fatorMulta);
                    self.individuaisJulgamento3a(end+1,:) = [tempoApos-1 valorSentenca processo.idAgente];
                    
                case model.NohModelo.JULGAMENTO_3b
                     valorSentenca = processo.calculaValorProcesso(tempoApos-1, processo.pedidos_deferidos, processo.fatorMulta);
                    self.individuaisJulgamento3b(end+1,:) = [tempoApos-1 valorSentenca processo.idAgente];
                    
                case model.NohModelo.JULGAMENTO_4a
                     valorSentenca = processo.calculaValorProcesso(tempoApos-1, processo.pedidos_deferidos, processo.fatorMulta);
                    self.individuaisJulgamento4a(end+1,:) = [tempoApos-1 valorSentenca processo.idAgente];
                    
                case model.NohModelo.JULGAMENTO_4b
                     valorSentenca = processo.calculaValorProcesso(tempoApos-1, processo.pedidos_deferidos, processo.fatorMulta);
                    self.individuaisJulgamento4b(end+1,:) = [tempoApos-1 valorSentenca processo.idAgente];
                    
                case model.NohModelo.JULGAMENTO_2a_EXECUCAO  
                     valorSentenca = processo.calculaValorProcesso(tempoApos-1, processo.pedidos_deferidos, processo.fatorMulta);
                    self.individuaisJulgamento2a(end+1,:) = [tempoApos-1 valorSentenca processo.idAgente]; 
                    %self.individuaisJulgamento2a(end+1,:) = [indiceTempo processo.valor_deferido processo.idAgente]; 
                    
                    self.nExito = self.nExito + 1;
                    self.individuaisTipoEncerramento(processo.idAgente,:) = [tempoApos-1 3];
                    if((processo.deposito_recursal1+processo.deposito_recursal2+processo.deposito_execucao ) > 0)
                        self.fluxoSaidaDeposito(tempoApos) =  self.fluxoSaidaDeposito(tempoApos) + processo.deposito_recursal1+ processo.deposito_recursal2+processo.deposito_execucao;
                        self.fluxoSaidaDepositoProcesso(processo.idAgente,tempoApos) =  self.fluxoSaidaDepositoProcesso(processo.idAgente,tempoApos) + processo.deposito_recursal1+ processo.deposito_recursal2+processo.deposito_execucao;
                        self.individuaisDepositoSaida(end+1,:) = [tempoApos-1 processo.deposito_recursal1 processo.deposito_recursal2 processo.deposito_execucao];
                    end
                    
                case model.NohModelo.JULGAMENTO_2b_EXECUCAO
                     valorSentenca = processo.calculaValorProcesso(tempoApos-1, processo.pedidos_deferidos, processo.fatorMulta);
                    self.individuaisJulgamento2b(end+1,:) = [tempoApos-1 valorSentenca processo.idAgente];
                    %self.individuaisJulgamento2b(end+1,:) = [indiceTempo processo.valor_deferido processo.idAgente];
                    
                    self.nExito = self.nExito + 1;
                    self.individuaisTipoEncerramento(processo.idAgente,:) = [tempoApos-1 3];
                    if((processo.deposito_recursal1+processo.deposito_recursal2+processo.deposito_execucao ) > 0)
                        self.fluxoSaidaDeposito(tempoApos) =  self.fluxoSaidaDeposito(tempoApos) + processo.deposito_recursal1+ processo.deposito_recursal2+processo.deposito_execucao;
                        self.fluxoSaidaDepositoProcesso(processo.idAgente,tempoApos) =  self.fluxoSaidaDepositoProcesso(processo.idAgente,tempoApos) + processo.deposito_recursal1+ processo.deposito_recursal2+processo.deposito_execucao;
                        self.individuaisDepositoSaida(end+1,:) = [tempoApos-1 processo.deposito_recursal1 processo.deposito_recursal2 processo.deposito_execucao];
                    end
                    
                case model.NohModelo.COMUM
                    % Não tem nada especifico para esse tipo de output,
                    % apenas a parte comum a todos os nós que está logo
                    % abaixo
                otherwise
                    disp('tipo de output não reconhecido');
            end %switch
            
            %Honorarios
            % honorarios é tempoApos, pois honorario de exito, acordo e
            % condenação acontece em tempoApos
            if(processo.custo_honorario ~= 0)
                self.fluxoCustoHonorario(tempoApos) = self.fluxoCustoHonorario(tempoApos) + processo.custo_honorario;
                self.fluxoCustoHonorarioProcesso(processo.idAgente,tempoApos) = self.fluxoCustoHonorarioProcesso(processo.idAgente,tempoApos) + processo.custo_honorario;
            end
            
            % output comum a todos os nós
            %Custas processuais
            if(processo.custas_processuais ~= 0)
                self.fluxoCustasProcessuais(indiceTempo+1) = self.fluxoCustasProcessuais(indiceTempo+1) + processo.custas_processuais;
                self.fluxoCustasProcessuaisProcesso(processo.idAgente,indiceTempo+1) = self.fluxoCustasProcessuaisProcesso(processo.idAgente,indiceTempo+1) + processo.custas_processuais;
            end
            
            %Deposito            
            if(processo.custo_deposito ~= 0)
                self.fluxoEntradaDeposito(indiceTempo+1) = self.fluxoEntradaDeposito(indiceTempo+1) + processo.custo_deposito;
                self.fluxoEntradaDepositoProcesso(processo.idAgente, indiceTempo+1) =  self.fluxoEntradaDepositoProcesso(processo.idAgente, indiceTempo+1) + processo.custo_deposito;
%                 self.individuaisDepositoEntrada(end+1,:) = [indiceTempo  processo.custo_deposito];
            end
                    
             
            % historico, util para debug
            % As vezes, o processo termina em exito quando o valor_setença é
            % zero e o processo vai para arvore de execução. Nesse caso o historico 
            % interpreta que o vai para o noh (101,1), porém não é verdade,
            % pois o processo é encerrado.
            % Assim, para identificar quando ocorre o encerramento por
            % valor_setença = 0, o Id do proximo noh será (0,0)
            if(processo.tipoOutput ~= model.NohModelo.EXITO)
                self.historico{processo.idAgente,1}(end+1,1:4) = [tempoApos-1 processo.id_arvore_atual processo.id_bloco_atual processo.switchPath];
            else
                self.historico{processo.idAgente,1}(end+1,1:4) = [tempoApos-1 0 0 processo.switchPath];
            end
            
        end %addOutput
        
        
    end %methods
    
    
end