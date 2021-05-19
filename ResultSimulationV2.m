classdef ResultSimulationV2 < handle
    
    properties
        % Se acrescentar mais algum atributo em resultSimulation, verificar
        nSim
        name
        tsim
        complemento
        parteMemoria
        nProcesso
        nPedido
        inputLogs
        estrategia
        carteiraInicial
        primeiroSetAcordo
        descricao
        limiteMemoria
        
        tamanhoAcumulado
        
        listaDiretorios
        mapaDosDiretorios
        posicaoDosDiretorios
        
        
        
        outputParcial
        outputCarteiraCarregado
        nomeDiretorioCarregado
        historicoCarregado
        historicoAcordoCarregado
        
    end
    
    % Construtor
    methods
        function self = ResultSimulationV2(name, inputLogs, estrategia,descricao,complemento)
            
            % Inicilização das variaveis comun a todas as N Simulações
            % Essa variaveis são exclusivas de resultaSimulation
            self.nSim = 0;
            self.name = name;
            self.complemento  = complemento;
            self.inputLogs = inputLogs;
            self.nProcesso = inputLogs.nProcesso;
            self.nPedido = inputLogs.nPedido;
            self.tsim = inputLogs.tsim;
            self.descricao = descricao;
            self.estrategia = estrategia;
            self.outputParcial = cell(0,1);
            self.mapaDosDiretorios =  zeros(0,1);
            self.posicaoDosDiretorios = zeros(0,1);
            self.listaDiretorios = cell(0,1);
            self.parteMemoria = -1;
            self.limiteMemoria = 5e8;
            self.tamanhoAcumulado = 0;
            self.primeiroSetAcordo = [];
        end
        
        %salva resultSimulation separando o historico para uma pasta separada
        function  salvar(self)
            nSimLocal = length(self.outputParcial);
            if(nSimLocal ~= 0)
                historico = cell(nSimLocal,1);
                historicoAcordo = cell(nSimLocal,1);
                
                % separa historico, historico acordo e primeiro set, do outputCarteira
                self.primeiroSetAcordo = self.outputParcial{1}.primeiroSetAcordo;
                for i=1:nSimLocal
                    historico{i} =  self.outputParcial{i}.historico;
                    self.outputParcial{i}.historico = [];
                    historicoAcordo{i} =  self.outputParcial{i}.historicoAcordo;
                    self.outputParcial{i}.historicoAcordo = [];
                    self.outputParcial{i}.primeiroSetAcordo = [];
                end
                
                %Cria o nome do diretorio correspondete a simulação e sua parte
                diretorio = ['simulacao\' self.name '_' self.estrategia];
                if(~strcmp(self.complemento,''))
                    diretorio = [diretorio '_' self.complemento];
                end
                if(self.parteMemoria ~= -1)
                    self.parteMemoria = self.parteMemoria +1;
                    diretorio = [diretorio '_mem' num2str(self.parteMemoria)];
                end
                
                % Cria o diretorio correspondente a simulação e a sua parte,
                % caso não exista
                if(~exist(diretorio,'dir'))
                    mkdir(diretorio);
                end
                
                save([diretorio '\historico.mat'],'historico');
                save([diretorio '\historicoAcordo.mat'],'historicoAcordo');
                outputCarteira = self.outputParcial;
                save([diretorio '\outputCarteira.mat'],'outputCarteira');
                
                
                self.listaDiretorios{end+1,1} = diretorio;
                self.mapaDosDiretorios(end+1:end+nSimLocal,1) =  length(self.listaDiretorios)*ones(nSimLocal,1);
                self.posicaoDosDiretorios(end+1:end+nSimLocal,1) = 1:nSimLocal;
                
            end
            
            resultSimulation = self;
            if(strcmp(self.complemento,''))
                save([self.name '_' self.estrategia],'resultSimulation');
            else
                save([self.name '_' self.estrategia '_' self.complemento] ,'resultSimulation');
            end
            self.outputParcial = cell(0,1);            
        end
        
        function add(self, outputSimulation)
            self.outputParcial{end+1,1} = outputSimulation;
            self.nSim = self.nSim+1;
            self.tamanhoAcumulado = self.tamanhoAcumulado+outputSimulation.getSize();
            if(self.tamanhoAcumulado >= self.limiteMemoria)
                if(self.parteMemoria == -1)
                    self.parteMemoria = 0;
                end
                self.salvar();
                self.tamanhoAcumulado = 0;
                self.outputParcial = cell(0,1);
            end
        end
                
        function apaga(self)
            for iDir=1:length(self.listaDiretorios)
                rmdir(self.listaDiretorios{iDir},'s');
            end
            if(strcmp(self.complemento,''))
                delete([self.name '_' self.estrategia '.mat']);
            else
                delete([self.name '_' self.estrategia '_' self.complemento '.mat']);
            end
        end
                
        function [outputCarteira, historico, historicoAcordo] = readSim(self,iSim)
            indiceDiretorio = self.mapaDosDiretorios(iSim);
            indicePosicao = self.posicaoDosDiretorios(iSim);
            nomeDiretorio = self.listaDiretorios{indiceDiretorio};
            if(~strcmp(self.nomeDiretorioCarregado,nomeDiretorio))
                load([nomeDiretorio '\outputCarteira.mat']);
                self.nomeDiretorioCarregado = nomeDiretorio;
                self.outputCarteiraCarregado = outputCarteira;
                if(nargout == 3)
                    load([nomeDiretorio '\historico.mat']);
                    load([nomeDiretorio '\historicoAcordo.mat']);
                    self.historicoCarregado = historico;
                    self.historicoAcordoCarregado = historicoAcordo;
                end
            end            
            outputCarteira = self.outputCarteiraCarregado{indicePosicao};
            if(nargout == 3)
                historico =  self.historicoCarregado{indicePosicao};
                historicoAcordo =  self.historicoAcordoCarregado{indicePosicao};
            end
        end
        
        function [valorPresenteCarteira,valorPresenteProcesso] = getValorPresente(self,varargin)
            
            nSimLocal = self.nSim;
            for i = 1:2:length(varargin)
                switch varargin{i}
                    case 'nSim'
                        nSimLocal = varargin{i+1};
                    otherwise
                        error(['Parametro ' varargin{i} ' não reconhecido']);
                end
            end
            
            valorPresenteProcesso = zeros(self.nProcesso,8,nSimLocal);
            t=(0:self.tsim);
            posicaoVp = model.ConstIndiceMonetario.taxa;
            matrizVp = repmat(self.carteiraInicial.indiceMonetario{posicaoVp}(self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoVp),2) ./ ...
                              self.carteiraInicial.indiceMonetario{posicaoVp}(self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoVp)+t,2)',self.nProcesso,1);
%             
            matrizCmJuros = zeros(self.nProcesso,self.tsim+1);
            posicaoJuros = model.ConstIndiceMonetario.juros;
             for iProcesso=1:self.nProcesso
                 processo = self.carteiraInicial.processos{iProcesso};
                 listaCm = processo.listaCm;
%                  matrizCmJuros(iProcesso,:)  = matrizVp(iProcesso,:) .* processo.indiceCmDataDistribuicao ./ ...
%                      self.carteiraInicial.indiceMonetario{listaCm}(self.carteiraInicial.posicaoIndiceMonetarioInicial(listaCm)+(0:self.tsim),2)' ./ ...
%                      (self.carteiraInicial.indiceMonetario{posicaoJuros}(self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoJuros)+(0:self.tsim),2)'-...
%                      processo.indiceJurosDataDistribuicao);
                 
                   matrizCmJuros(iProcesso,:)  = matrizVp(iProcesso,:) .* processo.indiceCmDataDistribuicao ./ ...
                     (self.carteiraInicial.indiceMonetario{listaCm}(self.carteiraInicial.posicaoIndiceMonetarioInicial(listaCm)+(0:self.tsim),2)' .* ...
                     (1-processo.indiceJurosDataDistribuicao+self.carteiraInicial.indiceMonetario{posicaoJuros}(self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoJuros)+(0:self.tsim),2)'));
                 
                 
             end
            
            for iSim = 1:nSimLocal
                outputCarteira = self.readSim(iSim);
                valorPresenteProcesso(:,1,iSim) = sum(outputCarteira.fluxoAcordoProcesso.* matrizVp,2);
                valorPresenteProcesso(:,2,iSim) = sum(outputCarteira.fluxoCondenacaoProcesso .*matrizVp,2);
                valorPresenteProcesso(:,3,iSim) = sum(outputCarteira.fluxoCustoHonorarioProcesso .*matrizVp,2);
                valorPresenteProcesso(:,4,iSim) = sum(outputCarteira.fluxoCustasProcessuaisProcesso .*matrizVp,2);
                valorPresenteProcesso(:,5,iSim) = sum(outputCarteira.fluxoEntradaDepositoProcesso .*matrizVp,2);
                valorPresenteProcesso(:,6,iSim) = - sum(outputCarteira.fluxoSaidaDepositoProcesso .*matrizVp,2);
                valorPresenteProcesso(:,7,iSim) = sum(outputCarteira.fluxoAcordoProcesso .*matrizCmJuros,2);
                valorPresenteProcesso(:,8,iSim) = sum(outputCarteira.fluxoCondenacaoProcesso .*matrizCmJuros,2);
                
                % pós processamento do custo de honorario mensal
                honorarioMensal = zeros(self.nProcesso,1);
                tempoFinal = outputCarteira.individuaisTipoEncerramento(:,1);
                for iProcesso=1:self.nProcesso
                    processo = self.carteiraInicial.processos{iProcesso};
                    tempoFinalLocal = tempoFinal(iProcesso);
                    tempoInicial = -processo.data_reclamacao;
                        
                    if(tempoInicial < 0) % verifica se o processo é entrante
                        tempoInicialLocal = -round(tempoInicial); %instante de tempo que o processo entra na carteira
                        honorarioMensal(iProcesso) = processo.calculaHonorarioMensal(tempoInicialLocal, tempoFinalLocal);                        
                        honorarioMensal(iProcesso) = honorarioMensal(iProcesso) * self.carteiraInicial.calculaTaxaPresente(0,tempoInicialLocal);
                    else
                        tempoInicialLocal = 0;
                        honorarioMensal(iProcesso) = processo.calculaHonorarioMensal(tempoInicialLocal, tempoFinalLocal);
                    end
                end
                
                % adiciona o custo mensal no custo de honorario valor presente da carteira
                valorPresenteProcesso(:,3,iSim) =  valorPresenteProcesso(:,3,iSim) + honorarioMensal;
            end
            
            valorPresenteCarteira = shiftdim(sum(valorPresenteProcesso,1),1)';
            
        end
        
        function [hEvolucao,hAcordo,hCondenacao,hExito,hAndamento,hAccAcordo,hAccCondenacao,hAccExito] = evolucaoEstado(self,tempoMax,varargin)
            
            import model.Tubo;
            temFiltroEntrante = false;
            
            filtro = true(self.nProcesso,1);
            for i = 1:2:length(varargin)
                switch varargin{i}
                    case 'filtro'
                        filtro = varargin{i+1};
                    case 'filtroEntrante'
                        temFiltroEntrante = true;
                        filtroEntrante = varargin{i+1};
                    otherwise
                        error(['Parametro ' varargin{i} ' não reconhecido']);
                end
            end
            
            evolucaoAcordo = zeros(self.tsim,self.nSim);
            evolucaoCondenacao = zeros(self.tsim,self.nSim);
            evolucaoExito = zeros(self.tsim,self.nSim);
            for iSim = 1:self.nSim
                outputCarteira = self.readSim(iSim);
                for iProcesso = 1:self.nProcesso
                    if(filtro(iProcesso))
                        if(outputCarteira.individuaisTipoEncerramento(iProcesso,2)==1)
                            tempo = outputCarteira.individuaisTipoEncerramento(iProcesso,1)+1; %+1 vem da correção do indice
                            evolucaoAcordo(tempo,iSim) = evolucaoAcordo(tempo,iSim) +1;
                        end
                        if(outputCarteira.individuaisTipoEncerramento(iProcesso,2)==2)
                            tempo = outputCarteira.individuaisTipoEncerramento(iProcesso,1)+1;
                            evolucaoCondenacao(tempo,iSim) = evolucaoCondenacao(tempo,iSim) +1;
                        end
                        if(outputCarteira.individuaisTipoEncerramento(iProcesso,2)==3)
                            tempo = outputCarteira.individuaisTipoEncerramento(iProcesso,1)+1;
                            evolucaoExito(tempo,iSim) = evolucaoExito(tempo,iSim) +1;
                        end
                    end
                end
            end
            mediaEvolucaoAcordo = cumsum(mean(evolucaoAcordo,2));
            mediaEvolucaoCondenacao = cumsum(mean(evolucaoCondenacao,2));
            mediaEvolucaoExito = cumsum(mean(evolucaoExito,2));
            
            %Contabiliza quantos processos está em andamento na carteira
            if(temFiltroEntrante)
                totalProcesso = sum(filtro)*ones(self.tsim,1);
                for iProcesso=1:self.nProcesso
                    if(filtroEntrante(iProcesso))
                        dataEntrada  = round(self.carteiraInicial.processos{iProcesso}.data_reclamacao);
                        totalProcesso(1:dataEntrada) = totalProcesso(1:dataEntrada)-1;
                    end
                end
            else
                totalProcesso = sum(filtro);
            end
            evolucaoAberto = totalProcesso-mediaEvolucaoAcordo-mediaEvolucaoCondenacao-mediaEvolucaoExito;
            
            hEvolucao = figure;
            set(hEvolucao,'position',get(hEvolucao,'position').*[0.4 0.4 1.3 1.3]);
            area(0:tempoMax-1,[evolucaoAberto(1:tempoMax) mediaEvolucaoAcordo(1:tempoMax) mediaEvolucaoCondenacao(1:tempoMax) mediaEvolucaoExito(1:tempoMax)]);
            %             legend('Andamento','Acordos','Condenação','Exito','Location','NorthEastOutside');
            legend('Andamento','Acordos','Condenação','Exito','Location','SouthWest');
            mes = str2double(datestr(self.inputLogs.data,'mm'));
            ano = str2double(datestr(self.inputLogs.data,'yyyy'));
            xlim([0 tempoMax-1]);
            ylim([0 max(totalProcesso)]);
            ax = gca;
            
            ax.XTick = (12-mes):12:tempoMax-1;
            ax.XTickLabel = (ano+1):ano+length(ax.XTick);
            ax.YTick(ax.YTick >= max(totalProcesso)) = [];
            ax.YTick = [ax.YTick max(totalProcesso)];
            if(temFiltroEntrante)
                title('Evolução da carteira com entrada de novos processos','FontSize',14,'FontWeight','bold');
            else
                title('Evolução da carteira','FontSize',14,'FontWeight','bold');
            end
            xlabel('tempo','FontSize',14,'FontWeight','bold');
            ylabel('número de processos','FontSize',14,'FontWeight','bold');
            
            hold on;
            for i=1:length(ax.XTick)
                plot([ax.XTick(i) ax.XTick(i)], [ax.YLim(1) ax.YLim(end)],'--','color',[1 1 1]*0.4,'LineWidth',0.02);
            end
            for i=2:length(ax.YTick)-1
                plot([ax.XLim(1) ax.XLim(end)], [ax.YTick(i) ax.YTick(i)],'--','color',[1 1 1]*0.4,'LineWidth',0.02);
            end
            
            hAcordo = figure;
            Tubo(1:tempoMax,evolucaoAcordo(1:tempoMax,:));
            ylabel('Número de acordos','FontSize',12,'FontWeight','bold');
            xlabel('Mês','FontSize',10,'FontWeight','bold');
            title('Número de acordos');
            grid on;
            
            hCondenacao = figure;
            Tubo(1:tempoMax,evolucaoCondenacao(1:tempoMax,:));
            ylabel('Número de condenações','FontSize',12,'FontWeight','bold');
            xlabel('Mês','FontSize',10,'FontWeight','bold');
            title('Número de condenações');
            grid on;
            
            hExito = figure;
            Tubo(1:tempoMax,evolucaoExito(1:tempoMax,:));
            ylabel('Número de exitos','FontSize',12,'FontWeight','bold');
            xlabel('Mês','FontSize',10,'FontWeight','bold');
            title('Número de exitos');
            grid on;
            
            hAccAcordo = figure;
            Tubo(1:tempoMax,cumsum(evolucaoAcordo(1:tempoMax,:)));
            ylabel('Número de acordos','FontSize',12,'FontWeight','bold');
            xlabel('Mês','FontSize',10,'FontWeight','bold');
            title('Número de acordos acumulados');
            grid on;
            
            hAccCondenacao = figure;
            Tubo(1:tempoMax,cumsum(evolucaoCondenacao(1:tempoMax,:)));
            ylabel('Número de condenações','FontSize',12,'FontWeight','bold');
            xlabel('Mês','FontSize',10,'FontWeight','bold');
            title('Número de condenações acumulados');
            grid on;
            
            hAccExito = figure;
            Tubo(1:tempoMax,cumsum(evolucaoExito(1:tempoMax,:)));
            ylabel('Número de exitos','FontSize',12,'FontWeight','bold');
            xlabel('Mês','FontSize',10,'FontWeight','bold');
            title('Número de exitos acumulados');
            grid on;
            
            hAndamento = figure;
            acumumulado = cumsum(evolucaoAcordo,1)+cumsum(evolucaoCondenacao,1)+cumsum(evolucaoExito,1);
            Tubo(1:tempoMax,self.nProcesso-acumumulado(1:tempoMax,:));
            ylabel('Número de processos','FontSize',12,'FontWeight','bold');
            xlabel('Mês','FontSize',10,'FontWeight','bold');
            title('Número de processos em andamento');
            grid on;
            
        end
        
        function [hCarteiraTempoFuturo, hCarteiraTempoPresente] = carteiraNoTempoTubo(self,tempoGrafico,varargin)
            
            import model.Tubo;
            
            temFiltro = false;
            temFiltroEntrante = false;
            vp = 1+self.inputLogs.taxaDescontoMensal;
            for i = 1:2:length(varargin)
                switch varargin{i}
                    case 'taxaAnualPresente'
                        vp = (1+varargin{i+1})^(1/12);
                    case 'filtro'
                        temFiltro = true;
                        filtro = varargin{i+1};
                    case 'filtroEntrante'
                        temFiltroEntrante = true;
                        filtroEntrante = varargin{i+1};
                    otherwise
                        error(['Parametro ' varargin{i} ' não reconhecido']);
                end
            end
            
            %calcula o tempoInicial de cada processo
            tempoInicial = zeros(self.nProcesso,1);
            for iProcesso=1:self.nProcesso
                tp= -self.carteiraInicial.processos{iProcesso}.data_reclamacao;
                % calcula o tempo inicial para o caso de processo entrante
                if(tp < 0)
                    tempoInicial(iProcesso) = -round(tp);
                else
                    tempoInicial(iProcesso) = 0;
                end
            end
            
            % calcula o valor da carteira no tempo para cada instante de simulação
            valorNoTempo = zeros(tempoGrafico,self.nSim);
            for iSim=1:self.nSim
                outputCarteira = self.readSim(iSim);
                %Calcula custo mensal para adicionar no fluxo de custos
                fluxoCustoMensal = zeros(self.nProcesso,self.tsim+1);
                for iProcesso=1:self.nProcesso
                    
                    processo = self.carteiraInicial.processos{iProcesso};
                    tempoFinalLocal = outputCarteira.individuaisTipoEncerramento(iProcesso,1);
                    tempoInicial = -processo.data_reclamacao;                    
                    if(tempoInicial < 0) % verifica se o processo é entrante
                        tempoInicialLocal = -round(tempoInicial); %instante de tempo que o processo entra na carteira
                    else
                        tempoInicialLocal = 0;
                    end                    
                    [~,fluxoHonorario] = processo.calculaHonorarioMensal(tempoInicialLocal, tempoFinalLocal);
                    fluxoCustoMensal(iProcesso,tempoInicialLocal+1:tempoFinalLocal) = fluxoHonorario;
                end
                
                % junta os fluxos
                fluxoJuntado = zeros(self.nProcesso,self.tsim+1);
                fluxoJuntado(:,:) = outputCarteira.fluxoAcordoProcesso + outputCarteira.fluxoCondenacaoProcesso +...
                    fluxoCustoMensal + outputCarteira.fluxoCustoHonorarioProcesso + outputCarteira.fluxoCustasProcessuaisProcesso + ...
                    + outputCarteira.fluxoEntradaDepositoProcesso - outputCarteira.fluxoSaidaDepositoProcesso;
                
                % valor presente no tempo
                valorNoTempoProcesso = zeros(self.nProcesso,tempoGrafico);
                t=(tempoGrafico:self.tsim);
                posicaoVp = model.ConstIndiceMonetario.taxa;
                matrizVpFinal = repmat(self.carteiraInicial.indiceMonetario{posicaoVp}(self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoVp)+tempoGrafico,2) ./ ...
                                       self.carteiraInicial.indiceMonetario{posicaoVp}(self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoVp)+t,2)',self.nProcesso,1);
                
                valorNoTempoProcesso(:,tempoGrafico) = sum(fluxoJuntado(:,tempoGrafico:self.tsim) .* matrizVpFinal,2);
                for iTempo=(tempoGrafico-1):-1:1
                    valorNoTempoProcesso(:,iTempo) = valorNoTempoProcesso(:,iTempo+1)/...
                                                    self.carteiraInicial.indiceMonetario{posicaoVp}(self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoVp)+iTempo,3) ...
                                                    + fluxoJuntado(:,iTempo);
                end
                
                % Elimina o valor presente dos processos entrantes até o momento de sua chegada
                if(temFiltroEntrante)
                    for iProcesso=1:self.nProcesso
                        if(filtroEntrante(iProcesso))
                            dataEntrada  = round(self.carteiraInicial.processos{iProcesso}.data_reclamacao);
                            valorNoTempoProcesso(iProcesso,1:dataEntrada) = 0;
                        end
                    end
                end
                
                % Soma os processos
                if(temFiltro)
                    valorNoTempo(:,iSim) = sum(valorNoTempoProcesso(filtro,:),1);
                else
                    valorNoTempo(:,iSim) = sum(valorNoTempoProcesso,1);
                end
                
            end
            
            % Plota grafico
            hCarteiraTempoFuturo = figure;
            set(hCarteiraTempoFuturo,'position',get(hCarteiraTempoFuturo,'position').*[0.4 0.4 1.2 1.2]);
            Tubo(0:tempoGrafico-1,valorNoTempo(1:tempoGrafico,:)/1e6);
            if(temFiltroEntrante)
                title('Valor da carteira no tempo com entrada de novos processos - Valor Futuro','FontSize',14,'FontWeight','bold');
            else
                title('Valor da carteira no tempo - Valor Futuro ','FontSize',14,'FontWeight','bold');
            end
            xlabel('tempo','FontSize',14,'FontWeight','bold');
            ylabel('Valor da carteira (MM R$)','FontSize',14,'FontWeight','bold');
            mes = str2double(datestr(self.inputLogs.data,'mm'));
            ano = str2double(datestr(self.inputLogs.data,'yyyy'));
            ax = gca;
            ax.XLim(1) = 0;
            ax.XTick = (12-mes):12:tempoGrafico-1;
            ax.XTickLabel = (ano+1):ano+length(ax.XTick);
            grid on;
            
            matrizVp = repmat(self.carteiraInicial.indiceMonetario{posicaoVp}(self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoVp),2) ./ ...
                self.carteiraInicial.indiceMonetario{posicaoVp}(self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoVp)+(0:tempoGrafico-1),2),1,self.nSim);
                                               
            % Plota grafico
            hCarteiraTempoPresente = figure;
            set(hCarteiraTempoPresente,'position',get(hCarteiraTempoPresente,'position').*[0.4 0.4 1.2 1.2]);
            Tubo(0:tempoGrafico-1,valorNoTempo(1:tempoGrafico,:).*matrizVp/1e6);
            if(temFiltroEntrante)
                title('Valor da carteira no tempo com entrada de novos processos - Valor Presente','FontSize',14,'FontWeight','bold');
            else
                title('Valor da carteira no tempo - Valor Presente ','FontSize',14,'FontWeight','bold');
            end
            xlabel('tempo','FontSize',14,'FontWeight','bold');
            ylabel('Valor da carteira (MM R$)','FontSize',14,'FontWeight','bold');
            mes = str2double(datestr(self.inputLogs.data,'mm'));
            ano = str2double(datestr(self.inputLogs.data,'yyyy'));
            ax = gca;
            ax.XTick = (12-mes):12:tempoGrafico-1;
            ax.XTickLabel = (ano+1):ano+length(ax.XTick);
            grid on;            
        end
               
        function [hJunto,hSeparado,hJuros,hDeposito,hFluxoAcordo,hFluxoCondenacao,hFluxoHonorario,hFluxoCustas] = plotTuboCaixa(self,intervalo,varargin)
            
            import model.Tubo;
            
            filtro = true(self.nProcesso,1);
            amostragem = 1;
            
            for i = 1:2:length(varargin)
                switch varargin{i}
                    case 'filtro'
                        filtro = varargin{i+1};
                    case 'amostragem'
                        amostragem = varargin{i+1};
                        if(mod(intervalo,amostragem) ~= 0)
                            error('Intervalo deve ser um multiplo de amostragem');
                        end
                    otherwise
                        error(['Parametro ' varargin{i} ' não reconhecido']);
                end
            end
            
            switch amostragem
                case 1
                    xLabel = 'Mês';
                case 2
                    xLabel = 'Bimestre';
                case 3
                    xLabel = 'Trimestre';
                case 4
                    xLabel = 'Quadrimestre';
                case 6
                    xLabel = 'Semestre';
                case 12
                    xLabel = 'Ano';
                otherwise
                    error('Amostragem não definida');
            end
            
%             
            filtroMat = repmat(filtro,1,self.tsim+1);
            filtroJuros = zeros(self.nProcesso,self.tsim+1);
            posicaoJuros = model.ConstIndiceMonetario.juros;
            for iProcesso=1:self.nProcesso
				processo = self.carteiraInicial.processos{iProcesso};
                if(filtro(iProcesso))
                    listaCm = processo.listaCm;
                    filtroJuros(iProcesso,:) = processo.indiceCmDataDistribuicao ./ ...
                    (self.carteiraInicial.indiceMonetario{listaCm}(self.carteiraInicial.posicaoIndiceMonetarioInicial(listaCm)+(0:self.tsim),2) .* ...
                    (1-processo.indiceJurosDataDistribuicao+self.carteiraInicial.indiceMonetario{posicaoJuros}(self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoJuros)+(0:self.tsim),2)));

                                           
                end
            end

            fluxoAcordo = zeros(self.tsim+1,self.nSim);
            fluxoCondenacao = zeros(self.tsim+1,self.nSim);
            fluxoCustoHonorario = zeros(self.tsim+1,self.nSim);
            fluxoCustasProcessuais = zeros(self.tsim+1,self.nSim);
            fluxoEntradaDeposito = zeros(self.tsim+1,self.nSim);
            fluxoSaidaDeposito = zeros(self.tsim+1,self.nSim);
            fluxoAcordoSemJuros = zeros(self.tsim+1,self.nSim);
            fluxoCondenacaoSemJuros = zeros(self.tsim+1,self.nSim);
            for i=1:self.nSim
                outputCarteira = self.readSim(i);
                fluxoAcordo(:,i) = sum(outputCarteira.fluxoAcordoProcesso.*filtroMat,1);
                fluxoCondenacao(:,i) = sum(outputCarteira.fluxoCondenacaoProcesso.*filtroMat,1);
                fluxoCustoHonorario(:,i) = sum(outputCarteira.fluxoCustoHonorarioProcesso.*filtroMat,1);
                fluxoCustasProcessuais(:,i) = sum(outputCarteira.fluxoCustasProcessuaisProcesso.*filtroMat,1);
                fluxoEntradaDeposito(:,i) = sum(outputCarteira.fluxoEntradaDepositoProcesso.*filtroMat,1);
                fluxoSaidaDeposito(:,i) = sum(outputCarteira.fluxoSaidaDepositoProcesso.*filtroMat,1);
                fluxoAcordoSemJuros(:,i) = sum(outputCarteira.fluxoAcordoProcesso.*filtroJuros,1);
                fluxoCondenacaoSemJuros(:,i) = sum(outputCarteira.fluxoCondenacaoProcesso.*filtroJuros,1);
                 
                % honorário mensal
                for iProcesso=1:self.nProcesso
                    if(filtro(iProcesso)) %se o processo estiver no filtro                                                
                        tempoInicial = -self.carteiraInicial.processos{iProcesso}.data_reclamacao;                        
                        if(tempoInicial < 0) % verifica se o processo é entrante
                            tempoInicial = -round(tempoInicial); %instante de tempo que o processo entra na carteira
                        else
                            tempoInicial = 0;
                        end                        
                        tempoFinal = outputCarteira.individuaisTipoEncerramento(iProcesso,1);
                        %caso exista limite de numero de meses de honorario mensal
                        [~,fluxoHonorarioMensal] = self.carteiraInicial.processos{iProcesso}.calculaHonorarioMensal(tempoInicial, tempoFinal);
                        fluxoCustoHonorario(tempoInicial+1:tempoFinal,i) = ...
                            fluxoCustoHonorario(tempoInicial+1:tempoFinal,i)+fluxoHonorarioMensal;
                    end
                end
            end
            
            %% fluxo Junto
            fluxo = fluxoAcordo+fluxoCondenacao+fluxoCustoHonorario+...
                fluxoCustasProcessuais+fluxoEntradaDeposito-fluxoSaidaDeposito;
            
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            
            limitey = max(max(fluxo));
            if(limitey==0)
                limitey = 1;
            end
            
            if(limitey < 1e3)
                divisor = 1;
                letra = '';
            elseif(limitey < 1e6)
                divisor = 1e3;
                letra = 'Mil';
            elseif(limitey < 1e9)
                divisor = 1e6;
                letra = 'MM';
            else
                divisor = 1e9;
                letra = 'Bi';
            end
            
            hJunto = figure;
            
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylim([0 limitey/divisor])
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            title('Fluxo de Caixa');
            grid on;
            title('Fluxo');
            
            
            %% Depostiso
            hDeposito = figure;
            
            fluxoAcumulado(1,:) = fluxoEntradaDeposito(1,:) - fluxoSaidaDeposito(1,:);
            posicaoJam = model.ConstIndiceMonetario.jam;
            posicaoInicialJam = self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoJam);
            for i=2:(self.tsim+1)
                fluxoAcumulado(i,:) =  fluxoAcumulado(i-1,:)* self.carteiraInicial.indiceMonetario{posicaoJam}(posicaoInicialJam+i,2)...
                                                            / self.carteiraInicial.indiceMonetario{posicaoJam}(posicaoInicialJam+i-1,2)...
                                                            + fluxoEntradaDeposito(i,:) - fluxoSaidaDeposito(i,:);
            end
            
            fluxoEntrada = fluxoEntradaDeposito;
            fluxoEntrada = fluxoEntrada(1:intervalo,:);
            fluxoSaida = fluxoSaidaDeposito;
            fluxoSaida = fluxoSaida(1:intervalo,:);
            fluxoEntrada = reshape(full(fluxoEntrada),amostragem,[],self.nSim);
            fluxoEntrada= sum(fluxoEntrada,1);
            fluxoEntrada = shiftdim(fluxoEntrada,1);
            fluxoSaida = reshape(full(fluxoSaida),amostragem,[],self.nSim);
            fluxoSaida= sum(fluxoSaida,1);
            fluxoSaida = shiftdim(fluxoSaida,1);
            fluxoAcumuladoOutput = reshape(full(fluxoAcumulado(1:intervalo,:)),amostragem,[],self.nSim);
            fluxoAcumuladoOutput= sum(fluxoAcumuladoOutput,1);
            fluxoAcumuladoOutput = shiftdim(fluxoAcumuladoOutput,1);
            
            limitey = max(max(max(fluxoSaida)), max(max(fluxoEntrada)));
            if(limitey == 0)
                limitey = 1;
            end
            
            subplot(2,2,1);
            if(size(fluxoEntrada,2) == 1)
                fluxoEntrada = [fluxoEntrada fluxoEntrada];
            end
            Tubo(1:(intervalo/amostragem),fluxoEntrada/divisor);
            ylim([0 1.1*limitey/divisor]);
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Fluxo Entrada de Depósito');
            
            subplot(2,2,2);
            if(size(fluxoSaida,2) == 1)
                fluxoSaida = [fluxoSaida fluxoSaida];
            end
            Tubo(1:(intervalo/amostragem),fluxoSaida/divisor);
            ylim([0 1.1*limitey/divisor]);
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Fluxo Saída de Depósito');
            
            limitey = max(max(fluxoAcumuladoOutput));
            if(limitey == 0)
                limitey = divisor;
            end
            
            subplot(2,1,2);
            if(size(fluxoAcumuladoOutput,2) == 1)
                fluxoAcumuladoOutput = [fluxoAcumuladoOutput fluxoAcumuladoOutput];
            end
            Tubo(1:(intervalo/amostragem),fluxoAcumuladoOutput/divisor);
            ylim([0 1.1*limitey/divisor]);
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Depósito Acumulado');
            
            %% fluxo separado em um unico figure
            hSeparado =  figure;
            subplot(2,2,1);
            
            fluxo = fluxoAcordo;
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylim([0 limitey/divisor])
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Fluxo Acordo');
            
            subplot(2,2,2);
            fluxo = fluxoCondenacao;
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylim([0 limitey/divisor])
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Fluxo Condenação');
            
            subplot(2,2,3);
            fluxo = fluxoCustoHonorario;
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylim([0 limitey/divisor])
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Fluxo Honorários');
            
            subplot(2,2,4);
            fluxo = fluxoCustasProcessuais;
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylim([0 limitey/divisor])
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Fluxo Custas Processuais');
            
            
            %% fluxo separado em varios figure
            hFluxoAcordo =  figure;
            fluxo = fluxoAcordo;
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Fluxo Acordo');
            
            hFluxoCondenacao =  figure;
            fluxo = fluxoCondenacao;
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Fluxo Condenação');
            
            hFluxoHonorario =  figure;
            fluxo = fluxoCustoHonorario;
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Fluxo Honorários');
            
            hFluxoCustas =  figure;
            fluxo = fluxoCustasProcessuais;
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Fluxo Custas Processuais');
            
            
            
            %% fluxo juros
            hJuros = figure;
            
            subplot(2,2,1);
            
            fluxo = fluxoAcordo+fluxoCondenacao;
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylim([0 limitey/divisor])
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Principal + Juros + Correção');
            
            subplot(2,2,2);
            fluxo = fluxoAcordoSemJuros+fluxoCondenacaoSemJuros;
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylim([0 limitey/divisor])
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Principal');
            
            subplot(2,2,3);
            fluxo = fluxoAcordo+fluxoCondenacao-fluxoAcordoSemJuros-fluxoCondenacaoSemJuros;
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylim([0 limitey/divisor])
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Juros+Cm');
            
            subplot(2,2,4);
            posicaoTaxa = model.ConstIndiceMonetario.taxa;
            posicaoInicialTaxa = self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoTaxa);
            fluxo = fluxoCustoHonorario + fluxoCustasProcessuais+fluxoAcumulado.*...
                repmat(self.carteiraInicial.indiceMonetario{posicaoTaxa}(posicaoInicialTaxa+(0:self.tsim),3)-1,1,self.nSim);
            fluxo = fluxo(1:intervalo,:);
            fluxo = reshape(full(fluxo),amostragem,[],self.nSim);
            fluxo= sum(fluxo,1);
            fluxo = shiftdim(fluxo,1);
            if(size(fluxo,2) == 1)
                fluxo = [fluxo fluxo];
            end
            Tubo(1:(intervalo/amostragem),fluxo/divisor);
            ylim([0 limitey/divisor])
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title('Custos');
            
        end
        
        function [hComposicao,hJuros] = composicaoValorCarteira(self,varargin)
            
            filtro = true(self.nProcesso,1);
            taxaDiferente = false;
            for i = 1:2:length(varargin)
                switch varargin{i}
                    case 'filtro'
                        filtro = varargin{i+1};
                    case 'taxaAnualPresente'
                        taxaDiferente = true;
                        taxa = varargin{i+1};
                    otherwise
                        error(['Parametro ' varargin{i} ' não reconhecido']);
                end
            end
            
            if(taxaDiferente)
                [~,valorPresenteProcesso] = self.getValorPresente('taxaAnualPresente',taxa);
            else
                [~,valorPresenteProcesso] = self.getValorPresente();
            end
            
            valorPresenteProcesso = shiftdim(sum(valorPresenteProcesso(filtro,:,:),1),1)';
            
            valorCarteira = sum(valorPresenteProcesso(:,1:6),2);
            principal = sum(valorPresenteProcesso(:,1:2),2);
            principalSemJuros = sum(valorPresenteProcesso(:,7:8),2);
            
            maximo = max(max(valorCarteira));
            if(maximo < 1e6)
                fatorReducao = 1e3;
                letra = 'Mil';
            elseif(maximo < 1e9)
                fatorReducao = 1e6;
                letra = 'MM';
            else
                fatorReducao = 1e9;
                letra = 'Bi';
            end
            
            hComposicao = figure;
            label = {'Valuation','Principal','Juros+CM','Custos'};
            matrizPlot =   [valorCarteira principalSemJuros principal-principalSemJuros valorCarteira-principal]/fatorReducao;
            boxplot(matrizPlot,'label',label,'whisker',20);
            
            ylabel(['Valor presente (' letra 'R$)'],'FontSize',16,'FontWeight','bold');
            ylim([-0.05*maximo 1.1*maximo]/fatorReducao);
            set(gca,'YGrid','on','YMinorGrid','on');
            hold on;
            media = mean(matrizPlot);
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
            title('Custo total');
            
            hJuros=figure;
            label1 = {'Principal+Juros+CM', 'Principal',' Juros+CM'};
            matrizPlot=[principal principalSemJuros principal-principalSemJuros]/fatorReducao;
            boxplot(matrizPlot,'label',label1,'whisker',20);
            
            ylabel(['Valor presente (' letra 'R$)'],'FontSize',16,'FontWeight','bold');
            ylim([-0.05*maximo 1.1*maximo]/fatorReducao);
            
            set(gca,'YGrid','on','YMinorGrid','on');
            hold on;
            media = mean(matrizPlot);
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
            title('Principal divido em juros e cm');
            
        end
        
        function [hNumeroBloco, hFluxoBloco] = acordoMensal(self,intervalo, varargin)
            
            import model.Tubo;
            
            tipo = 'tubo';
            local = 'folha';
            filtro = true(self.nProcesso,1);
            amostragem = 1;
            
            for i = 1:2:length(varargin)
                switch varargin{i}
                    case 'filtro'
                        filtro = varargin{i+1};
                    case 'tipo'
                        tipo = varargin{i+1}; %pode ser tubo ou boxPlot
                    case 'local'
                        local = varargin{i+1};%pode ser folha ou bloco
                    case 'amostragem'
                        amostragem = varargin{i+1};
                        if(mod(intervalo,amostragem) ~= 0)
                            error('Intervalo deve ser um multiplo de amostragem');
                        end
                    otherwise
                        error(['Parametro ' varargin{i} ' não reconhecido']);
                end
            end
            
            fluxoAcordo = zeros(self.tsim+1,self.nSim);
            numeroAcordo = zeros(self.tsim+1,self.nSim);
            if(strcmp(local,'folha'))
                filtro = repmat(filtro,1,self.tsim+1);
                for i=1:self.nSim
                    fluxoAcordo(:,i) = sum(self.fluxoAcordoProcesso{i}.*filtro,1);
                    numeroAcordo(:,i) = sum(self.fluxoAcordoProcesso{i}>0.*filtro,1);
                end
                tituloFluxo = 'Fluxo de acordo';
                tituloNumero = 'Numero de acordo';
            elseif(strcmp(local,'bloco'))
                for i=1:self.nSim
                    outputCarteira = self.readSim(i);
                    for iProcesso=1:self.nProcesso
                        if(filtro(iProcesso) && outputCarteira.individuaisTipoEncerramento(iProcesso,2) == 1)
                            tempo =  outputCarteira.individuaisAcordos(iProcesso,2);
                            fluxoAcordo(tempo+1,i) = fluxoAcordo(tempo+1,i) + outputCarteira.individuaisAcordos(iProcesso,3);
                            numeroAcordo(tempo+1,i) = numeroAcordo(tempo+1,i)+1;
                        end
                    end
                end
                tituloFluxo = 'Fluxo de Proposta Aceita';
                tituloNumero = 'Qtd de acordos fechados por mês';
            else
                error('local não reconhecido. As opções são folha ou bloco');
            end
            
            switch amostragem
                case 1
                    xLabel = 'Mês';
                case 2
                    xLabel = 'Bimestre';
                case 3
                    xLabel = 'Trimestre';
                case 4
                    xLabel = 'Quadrimestre';
                case 6
                    xLabel = 'Semestre';
                case 12
                    xLabel = 'Ano';
                otherwise
                    error('Amostragem não definida');
            end
            
            
            
            %plot fluxo de acordo
            hFluxoBloco = figure;
            fluxoAcordo = fluxoAcordo(1:intervalo,:);
            fluxoAcordo = reshape(full(fluxoAcordo),amostragem,[],self.nSim);
            fluxoAcordo= sum(fluxoAcordo,1);
            fluxoAcordo = shiftdim(fluxoAcordo,1);
            if(size(fluxoAcordo,2) == 1)
                fluxoAcordo = [fluxoAcordo fluxoAcordo];
            end
            
            limitey = max(max(fluxoAcordo));
            if(limitey==0)
                limitey = 1;
            end
            
            if(limitey < 1e3)
                divisor = 1;
                letra = '';
            elseif(limitey < 1e6)
                divisor = 1e3;
                letra = 'Mil';
            elseif(limitey < 1e9)
                divisor = 1e6;
                letra = 'MM';
            else
                divisor = 1e9;
                letra = 'Bi';
            end
            
            Tubo(1:(intervalo/amostragem),fluxoAcordo/divisor);
            ylim([0 1.1*limitey/divisor]);
            ylabel([ letra ' R$'],'FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title(tituloFluxo);
            
            %plot numero de acordo
            hNumeroBloco = figure;
            numeroAcordo = numeroAcordo(1:intervalo,:);
            numeroAcordo = reshape(full(numeroAcordo),amostragem,[],self.nSim);
            numeroAcordo= sum(numeroAcordo,1);
            numeroAcordo = shiftdim(numeroAcordo,1);
            if(size(numeroAcordo,2) == 1)
                numeroAcordo = [numeroAcordo numeroAcordo];
            end
            if(strcmp(tipo,'tubo'))
                Tubo(1:(intervalo/amostragem),numeroAcordo);
            elseif(strcmp(tipo,'boxPlot'))
                boxplot(numeroAcordo','whisker',20)
            else
                error('tipo inválido. Tipo deve ser tubo ou boxPlot')
            end
            gca.ylim(1) = 0;
            ylabel('Quantidade','FontSize',12,'FontWeight','bold');
            xlabel(xLabel,'FontSize',10,'FontWeight','bold');
            grid on;
            title(tituloNumero);
            
        end
        
        function tabelaResumo(self,nomeExcel, nomeAba, varargin)
            
            filtro = true(self.nProcesso,1);
            taxaDiferente = false;
            overwrite = true;
            for i = 1:2:length(varargin)
                switch varargin{i}
                    case 'filtro'
                        filtro = varargin{i+1};
                    case 'taxaAnualPresente'
                        taxaDiferente = true;
                        taxa = varargin{i+1};
                    case 'overwrite'
                        overwrite = varargin{i+1};
                    otherwise
                        error(['Parametro ' varargin{i} ' não reconhecido']);
                end
            end
            
            if(taxaDiferente)
                [~,vpProcesso] = self.getValorPresente('taxaAnualPresente',taxa);
            else
                [~,vpProcesso] = self.getValorPresente();
            end
            maximo = max(sum(sum(vpProcesso(filtro,1:6,:),1),2));
            
            
            % Identifica fase do processo
            faseProcesso = zeros(self.nProcesso,1);
           for iProcesso=1:self.nProcesso
                processo = self.carteiraInicial.processos{iProcesso};
               arvoreInicial =processo.id_arvore_atual;
                if(arvoreInicial == 1)
                    faseProcesso(iProcesso) = 1;
                elseif(arvoreInicial < 100)
                    faseProcesso(iProcesso) = 2;
                else
                    faseProcesso(iProcesso) = 3;
                end
            end
            
            % media do principal
            principalCon = mean(sum(vpProcesso(filtro & faseProcesso==1,1,:)+vpProcesso(filtro & faseProcesso==1,2,:)));
            semJurosCon = mean(sum(vpProcesso(filtro & faseProcesso==1,7,:)+vpProcesso(filtro & faseProcesso==1,8,:),1));
            custosCon = mean(sum(sum(vpProcesso(filtro & faseProcesso==1,3:6,:),2),1));
            
            principalRec = mean(sum(vpProcesso(filtro & faseProcesso==2,1,:)+vpProcesso(filtro & faseProcesso==2,2,:)));
            semJurosRec = mean(sum(vpProcesso(filtro & faseProcesso==2,7,:)+vpProcesso(filtro & faseProcesso==2,8,:),1));
            custosRec = mean(sum(sum(vpProcesso(filtro & faseProcesso==2,3:6,:),2),1));
            
            principalEx = mean(sum(vpProcesso(filtro & faseProcesso==3,1,:)+vpProcesso(filtro & faseProcesso==3,2,:)));
            semJurosEx = mean(sum(vpProcesso(filtro & faseProcesso==3,7,:)+vpProcesso(filtro & faseProcesso==3,8,:),1));
            custosEx = mean(sum(sum(vpProcesso(filtro & faseProcesso==3,3:6,:),2),1));
            
            %total de acordo e condenação por simulação
            acordoCon = sum(vpProcesso(filtro & faseProcesso==1,1,:),1);
            condencaoCon =  sum(vpProcesso(filtro & faseProcesso==1,2,:),1);
            acordoRec = sum(vpProcesso(filtro & faseProcesso==2,1,:),1);
            condencaoRec =  sum(vpProcesso(filtro & faseProcesso==2,2,:),1);
            acordoEx = sum(vpProcesso(filtro & faseProcesso==3,1,:),1);
            condencaoEx =  sum(vpProcesso(filtro & faseProcesso==3,2,:),1);
            
            %total de juros de acordo e condenação por simulação
            acordoJurosCon = acordoCon - sum(vpProcesso(filtro & faseProcesso==1,7,:),1);
            condencaoJurosCon =  condencaoCon - sum(vpProcesso(filtro & faseProcesso==1,8,:),1);
            acordoJurosRec = acordoRec - sum(vpProcesso(filtro & faseProcesso==2,7,:),1);
            condencaoJurosRec =  condencaoRec - sum(vpProcesso(filtro & faseProcesso==2,8,:),1);
            acordoJurosEx = acordoEx - sum(vpProcesso(filtro & faseProcesso==3,7,:),1);
            condencaoJurosEx = condencaoEx -  sum(vpProcesso(filtro & faseProcesso==3,8,:),1);
            
            % Identificação de termino
            terminoAcordo = zeros(4,self.nSim);
            terminoCondenacao = zeros(4,self.nSim);
            terminoExito = zeros(4,self.nSim);
            
            acordoFuturo = zeros(4,self.nSim);
            jurosAcordoFuturo = zeros(4,self.nSim);
            tempoAcordo = zeros(4,self.nSim);
            
            condenacaoFuturo = zeros(4,self.nSim);
            jurosCondenacaoFuturo = zeros(4,self.nSim);
            tempoCondenacao = zeros(4,self.nSim);
            
            tempoExito  = zeros(4,self.nSim);
            
            matrizJuros = zeros(self.nProcesso,self.tsim+1);
            posicaoJuros = model.ConstIndiceMonetario.juros;
            for iProcesso=1:self.nProcesso
                processo = self.carteiraInicial.processos{iProcesso};
                listaCm = processo.listaCm;
                matrizJuros(iProcesso,:)  = processo.indiceCmDataDistribuicao ./ ...
                    (self.carteiraInicial.indiceMonetario{listaCm}(self.carteiraInicial.posicaoIndiceMonetarioInicial(listaCm)+(0:self.tsim),2)' .* ...
                    (1-processo.indiceJurosDataDistribuicao+self.carteiraInicial.indiceMonetario{posicaoJuros}(self.carteiraInicial.posicaoIndiceMonetarioInicial(posicaoJuros)+(0:self.tsim),2)'));
            end
            
            
            for iSim=1:self.nSim
                 outputCarteira = self.readSim(iSim);
                tipoTermino = outputCarteira.individuaisTipoEncerramento(:,2);
                tempoEnc = outputCarteira.individuaisTipoEncerramento(:,1);
                acc = outputCarteira.individuaisAcordos(:,3);
                cond = outputCarteira.individuaisCondenacoes(:,3);
                
                matriJurosEnc = zeros(self.nProcesso);
                for iProcesso=1:self.nProcesso
                    matriJurosEnc(iProcesso) = matrizJuros(iProcesso,tempoEnc(iProcesso)+1);
                end
                
                % encerramento acordo
                fProcessos = filtro & tipoTermino==1;
                terminoAcordo(1,iSim) = sum(fProcessos);
                acordoFuturo(1,iSim) = sum(acc(fProcessos));
                jurosAcordoFuturo(1,iSim) = acordoFuturo(1,iSim)-sum(acc(fProcessos).*matriJurosEnc(fProcessos));
%                 jurosAcordoFuturo(1,iSim) = acordoFuturo(1,iSim)-sum(acc(fProcessos)./((1+0.01*(tempoInicial(fProcessos)+tempoEnc(fProcessos))).*((1+cmInicial(fProcessos)).^(tempoInicial(fProcessos)+tempoEnc(fProcessos)))));
                tempoAcordo(1,iSim) = sum(tempoEnc(fProcessos));
                
                fProcessos = filtro & faseProcesso==1 & tipoTermino==1;
                terminoAcordo(2,iSim) = sum(fProcessos);
                acordoFuturo(2,iSim) = sum(acc(fProcessos));
                jurosAcordoFuturo(2,iSim) = acordoFuturo(2,iSim)-sum(acc(fProcessos).*matriJurosEnc(fProcessos));
                tempoAcordo(2,iSim) = sum(tempoEnc(fProcessos));
                
                fProcessos = filtro & faseProcesso==2 & tipoTermino==1;
                terminoAcordo(3,iSim) = sum(fProcessos);
                acordoFuturo(3,iSim) = sum(acc(fProcessos));
                jurosAcordoFuturo(3,iSim) = acordoFuturo(3,iSim)-sum(acc(fProcessos).*matriJurosEnc(fProcessos));
                tempoAcordo(3,iSim) = sum(tempoEnc(fProcessos));
                
                fProcessos = filtro & faseProcesso==3 & tipoTermino==1;
                terminoAcordo(4,iSim) = sum(fProcessos);
                acordoFuturo(4,iSim) = sum(acc(fProcessos));
                jurosAcordoFuturo(4,iSim) = acordoFuturo(4,iSim)-sum(acc(fProcessos).*matriJurosEnc(fProcessos));
                tempoAcordo(4,iSim) = sum(tempoEnc(fProcessos));
                
                % encerramento condenacao
                fProcessos = filtro & tipoTermino==2;
                terminoCondenacao(1,iSim) = sum(fProcessos);
                condenacaoFuturo(1,iSim) = sum(cond(fProcessos));
                jurosCondenacaoFuturo(1,iSim) = condenacaoFuturo(1,iSim)-sum(cond(fProcessos).*matriJurosEnc(fProcessos));
                tempoCondenacao(1,iSim) = sum(tempoEnc(fProcessos));
                
                fProcessos = filtro & faseProcesso==1 & tipoTermino==2;
                terminoCondenacao(2,iSim) = sum(fProcessos);
                condenacaoFuturo(2,iSim) = sum(cond(fProcessos));
                jurosCondenacaoFuturo(2,iSim) = condenacaoFuturo(2,iSim)-sum(cond(fProcessos).*matriJurosEnc(fProcessos));
                tempoCondenacao(2,iSim) = sum(tempoEnc(fProcessos));
                
                fProcessos = filtro & faseProcesso==2 & tipoTermino==2;
                terminoCondenacao(3,iSim) = sum(fProcessos);
                condenacaoFuturo(3,iSim) = sum(cond(fProcessos));
                jurosCondenacaoFuturo(3,iSim) = condenacaoFuturo(3,iSim)-sum(cond(fProcessos).*matriJurosEnc(fProcessos));
                tempoCondenacao(3,iSim) = sum(tempoEnc(fProcessos));
                
                fProcessos = filtro & faseProcesso==3 & tipoTermino==2;
                terminoCondenacao(4,iSim) = sum(fProcessos);
                condenacaoFuturo(4,iSim) = sum(cond(fProcessos));
                jurosCondenacaoFuturo(4,iSim) = condenacaoFuturo(4,iSim)-sum(cond(fProcessos).*matriJurosEnc(fProcessos));
                tempoCondenacao(4,iSim) = sum(tempoEnc(fProcessos));
                
                % encerramento exito
                terminoExito(1,iSim) = sum(tipoTermino(filtro)==3);
                terminoExito(2,iSim) = sum(tipoTermino(filtro & faseProcesso==1)==3);
                terminoExito(3,iSim) = sum(tipoTermino(filtro & faseProcesso==2)==3);
                terminoExito(4,iSim) = sum(tipoTermino(filtro & faseProcesso==3)==3);
                
                tempoExito(1,iSim) = sum(tempoEnc(filtro & tipoTermino==3));
                tempoExito(2,iSim) = sum(tempoEnc(filtro & faseProcesso==1 & tipoTermino==3));
                tempoExito(3,iSim) = sum(tempoEnc(filtro & faseProcesso==2 & tipoTermino==3));
                tempoExito(4,iSim) = sum(tempoEnc(filtro & faseProcesso==3 & tipoTermino==3));
            end
            
            tool.copiaSheet('+model\templateResumo',nomeExcel,'Resumo',nomeAba, overwrite);
            
            % Fator de redução para a planilha resumo gerada
            if(maximo < 1e7)
                fatorReducao = 1e3;
                letra = 'Mil';
            elseif(maximo < 1e10)
                fatorReducao = 1e6;
                letra = 'MM';
            else
                fatorReducao = 1e9;
                letra = 'Bi';
            end
            
            % tabela de valor da carteira
            xlswrite(nomeExcel,{['Valor da carteira (' letra ' R$)']},nomeAba,'B2');
            xlswrite(nomeExcel,[semJurosCon semJurosRec semJurosEx;...
                principalCon-semJurosCon principalRec-semJurosRec principalEx-semJurosEx;...
                custosCon custosRec custosEx]/fatorReducao,nomeAba,'C4');
            
            % tabela de principal
            xlswrite(nomeExcel,{['Principal (' letra ' R$)']},nomeAba,'B9');
            xlswrite(nomeExcel,[mean(acordoCon) mean(acordoRec) mean(acordoEx);...
                mean(condencaoCon) mean(condencaoRec) mean(condencaoEx)]/fatorReducao,nomeAba,'C11');
            
            % tabela de numero de ocorrencia
            xlswrite(nomeExcel,[mean(terminoAcordo(2,:)) mean(terminoAcordo(3,:)) mean(terminoAcordo(4,:));
                mean(terminoCondenacao(2,:)) mean(terminoCondenacao(3,:)) mean(terminoCondenacao(4,:));...
                mean(terminoExito(2,:)) mean(terminoExito(3,:)) mean(terminoExito(4,:))],nomeAba,'C17');
            
            % tabela de valor médio trazido a valor presente
            xlswrite(nomeExcel,{'Valor médio presente (R$)'},nomeAba,'B22');
            xlswrite(nomeExcel,[mean(shiftdim(acordoCon,1)./terminoAcordo(2,:)) mean(shiftdim(acordoRec,1)./terminoAcordo(3,:)) mean(shiftdim(acordoEx,1)./terminoAcordo(4,:));
                mean(shiftdim(condencaoCon,1)./terminoCondenacao(2,:)) mean(shiftdim(condencaoRec,1)./terminoCondenacao(3,:)) mean(shiftdim(condencaoEx,1)./terminoCondenacao(4,:))],nomeAba,'C24');
            
            % tabela de valor médio futro
            xlswrite(nomeExcel,{'Valor médio futuro (R$)'},nomeAba,'B27');
            xlswrite(nomeExcel,[mean(acordoFuturo(2,:)./terminoAcordo(2,:)) mean(acordoFuturo(3,:)./terminoAcordo(3,:)) mean(acordoFuturo(4,:)./terminoAcordo(4,:));
                mean(condenacaoFuturo(2,:)./terminoCondenacao(2,:)) mean(condenacaoFuturo(3,:)./terminoCondenacao(3,:)) mean(condenacaoFuturo(4,:)./terminoCondenacao(4,:))],nomeAba,'C29');
            
            % tabela de tempo médio
            xlswrite(nomeExcel,{'Tempo médio'},nomeAba,'B32');
            xlswrite(nomeExcel,[mean(tempoAcordo(2,:)./terminoAcordo(2,:)) mean(tempoAcordo(3,:)./terminoAcordo(3,:)) mean(tempoAcordo(4,:)./terminoAcordo(4,:));
                mean(tempoCondenacao(2,:)./terminoCondenacao(2,:)) mean(tempoCondenacao(3,:)./terminoCondenacao(3,:)) mean(tempoCondenacao(4,:)./terminoCondenacao(4,:));
                mean(tempoExito(2,:)./terminoExito(2,:)) mean(tempoExito(3,:)./terminoExito(3,:)) mean(tempoExito(4,:)./terminoExito(4,:))],nomeAba,'C34');
            
            % tabela de juros médio trazido a valor presente
            xlswrite(nomeExcel,{'Juros médio presente (R$)'},nomeAba,'G22');
            xlswrite(nomeExcel,[mean(shiftdim(acordoJurosCon,1)./terminoAcordo(2,:)) mean(shiftdim(acordoJurosRec,1)./terminoAcordo(3,:)) mean(shiftdim(acordoJurosEx,1)./terminoAcordo(4,:));
                mean(shiftdim(condencaoJurosCon,1)./terminoCondenacao(2,:)) mean(shiftdim(condencaoJurosRec,1)./terminoCondenacao(3,:)) mean(shiftdim(condencaoJurosEx,1)./terminoCondenacao(4,:))],nomeAba,'H24');
            
            % tabela de juros médio em valor futuro
            xlswrite(nomeExcel,{'Juros médio futuro (R$)'},nomeAba,'G27');
            xlswrite(nomeExcel,[mean(jurosAcordoFuturo(2,:)./terminoAcordo(2,:)) mean(jurosAcordoFuturo(3,:)./terminoAcordo(3,:)) mean(jurosAcordoFuturo(4,:)./terminoAcordo(4,:));
                mean(jurosCondenacaoFuturo(2,:)./terminoCondenacao(2,:)) mean(jurosCondenacaoFuturo(3,:)./terminoCondenacao(3,:)) mean(jurosCondenacaoFuturo(4,:)./terminoCondenacao(4,:))],nomeAba,'H29');
            
        end
        
        function [hValuationTipo,hValuationFase,hValuationEncerramento,...
                hPrincipalTipo,hPrincipalFase,hPrincipalEncerramento] = valorCarteiraPorTipo(self,varargin)
            
            filtro = true(self.nProcesso,1);
            taxaDiferente = false;
            for i = 1:2:length(varargin)
                switch varargin{i}
                    case 'filtro'
                        filtro = varargin{i+1};
                    case 'taxaAnualPresente'
                        taxaDiferente = true;
                        taxa = varargin{i+1};
                    otherwise
                        error(['Parametro ' varargin{i} ' não reconhecido']);
                end
            end
            
            tipo = zeros(self.nProcesso,1);
            fase = zeros(self.nProcesso,1);
            for i=1:self.nProcesso
                processo = self.carteiraInicial.processos{i};
                if(processo.id_arvore_atual == 1)
                    fase(i) = 1;
                elseif(processo.id_arvore_atual < 100)
                    fase(i) = 2;
                else
                    fase(i) = 3;
                end
                tipo(i) = processo.arvoreModelo.tipoModelo;
            end
            
            if(taxaDiferente)
                [~,valorPresenteProcesso] = self.getValorPresente('taxaAnualPresente',taxa);
            else
                [~,valorPresenteProcesso] = self.getValorPresente();
            end
            
            %separa o valorPresenteProcesso em duas partes, uma para os
            %acordos e outra para a condenação
            valorPresentaAcordo = valorPresenteProcesso;
            valorPresentaCondenacao = valorPresenteProcesso;
            for iSim=1:self.nSim
                for iProcesso=1:self.nProcesso
                    if( valorPresentaAcordo(iProcesso,1,iSim)==0)
                        valorPresentaAcordo(iProcesso,:,iSim)=0;
                    end
                    if(valorPresentaCondenacao(iProcesso,2,iSim)==0)
                        valorPresentaCondenacao(iProcesso,:,iSim)=0;
                    end
                end
            end
            
            % valuation (valor da carteira)
            valuationProcesso = sum(valorPresenteProcesso(:,1:6,:),2);
            valuationAcordo = sum(valorPresentaAcordo(:,1:6,:),2);
            valuationCondenacao = sum(valorPresentaCondenacao(:,1:6,:),2);
            [hValuationTipo,hValuationFase,hValuationEncerramento] = self.separaPlot(valuationProcesso,valuationAcordo,valuationCondenacao,tipo,fase,filtro,'Valuation');
            
            % principal (valor da carteira)
            principalProcesso = sum(valorPresenteProcesso(:,1:2,:),2);
            principalAcordo = sum(valorPresentaAcordo(:,1:2,:),2);
            principalCondenacao = sum(valorPresentaCondenacao(:,1:2,:),2);
            [hPrincipalTipo,hPrincipalFase,hPrincipalEncerramento] = self.separaPlot(principalProcesso,principalAcordo,principalCondenacao,tipo,fase,filtro,'Principal');
            
        end
        
        %  usado pela função valorCarteiraPorTipo
        function [hTipo,hFase,hEncerramento] = separaPlot(self,valuationProcesso,valuationAcordo,valuationCondenacao,tipo,fase,filtro,nometitulo)
            
            valuationAcordo =  sum(valuationAcordo(filtro,:,:));
            valuationnCondenacao =  sum(valuationCondenacao(filtro,:,:));
            
            valuationTotal = sum(valuationProcesso(filtro,:,:));
            valuationTrab = sum(valuationProcesso(filtro & tipo == 1,:,:));
            valuationCivel = sum(valuationProcesso(filtro & tipo == 2,:,:));
            valuationJEC = sum(valuationProcesso(filtro & tipo == 3,:,:));
            
            valuationCon = sum(valuationProcesso(filtro & fase == 1,:,:));
            valuationRec = sum(valuationProcesso(filtro & fase == 2,:,:));
            valuationEx = sum(valuationProcesso(filtro & fase == 3,:,:));
            
            % valuation tipo
            matrizPlot = [shiftdim(valuationTotal(1,1,:),2) shiftdim(valuationTrab(1,1,:),2) ...
                shiftdim(valuationCivel(1,1,:),2) shiftdim(valuationJEC(1,1,:),2)];
            label = {'Total','Trab','JC','JEC'};
            
            if(sum(matrizPlot(:,4))==0)  % eliminana JEC se não houver
                matrizPlot(:,4) = [];
                label(4) = [];
            end
            if(sum(matrizPlot(:,3))==0)  % eliminana Civel se não houver
                matrizPlot(:,1) = [];
                label(3) = [];
            end
            if(sum(matrizPlot(:,2))==0)% eliminana Trab se não houver
                matrizPlot(:,2) = [];
                label(2) = [];
            end
            
            maximo = max(max(matrizPlot));
            if(maximo < 1e6)
                fatorReducao = 1e3;
                letra = 'Mil';
            elseif(maximo < 1e9)
                fatorReducao = 1e6;
                letra = 'MM';
            else
                fatorReducao = 1e9;
                letra = 'Bi';
            end
            
            hTipo = figure;
            
            matrizPlot = matrizPlot./fatorReducao;
            boxplot(matrizPlot,'label',label,'whisker',20);
            
            ylabel(['Valor presente (' letra 'R$)'],'FontSize',16,'FontWeight','bold');
            ylim([-0.05*maximo 1.1*maximo]/fatorReducao);
            set(gca,'YGrid','on','YMinorGrid','on');
            hold on;
            media = mean(matrizPlot);
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
            title(nometitulo);
            
            % valuation fase
            matrizPlot = [shiftdim(valuationTotal(1,1,:),2) shiftdim(valuationCon(1,1,:),2) ...
                shiftdim(valuationRec(1,1,:),2) shiftdim(valuationEx(1,1,:),2)];
            
            maximo = max(max(matrizPlot));
            if(maximo < 1e6)
                fatorReducao = 1e3;
                letra = 'Mil';
            elseif(maximo < 1e9)
                fatorReducao = 1e6;
                letra = 'MM';
            else
                fatorReducao = 1e9;
                letra = 'Bi';
            end
            
            hFase = figure;
            label = {'Total','Conhecimento','Recursal','Execução'};
            matrizPlot = matrizPlot./fatorReducao;
            boxplot(matrizPlot,'label',label,'whisker',20);
            
            ylabel(['Valor presente (' letra 'R$)'],'FontSize',16,'FontWeight','bold');
            ylim([-0.05*maximo 1.1*maximo]/fatorReducao);
            set(gca,'YGrid','on','YMinorGrid','on');
            hold on;
            media = mean(matrizPlot);
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
            title(nometitulo);
            
            % valuation encerramento
            matrizPlot = [shiftdim(valuationTotal(1,1,:),2) shiftdim(valuationAcordo(1,1,:),2) ...
                shiftdim(valuationnCondenacao(1,1,:),2) shiftdim(valuationTotal(1,1,:),2)-shiftdim(valuationAcordo(1,1,:),2)-shiftdim(valuationnCondenacao(1,1,:),2)];
            label = {'Total','Acordo','Condenação','Exito'};
            
            if(abs(sum(matrizPlot(:,4),1)/sum(matrizPlot(:,1),1)) <= 1e-8)
                matrizPlot(:,4) = [];
                label(4) = [];
            end
            
            maximo = max(max(matrizPlot));
            if(maximo < 1e6)
                fatorReducao = 1e3;
                letra = 'Mil';
            elseif(maximo < 1e9)
                fatorReducao = 1e6;
                letra = 'MM';
            else
                fatorReducao = 1e9;
                letra = 'Bi';
            end
            
            hEncerramento = figure;
            
            matrizPlot = matrizPlot./fatorReducao;
            boxplot(matrizPlot,'label',label,'whisker',20);
            
            ylabel(['Valor presente (' letra 'R$)'],'FontSize',16,'FontWeight','bold');
            ylim([-0.05*maximo 1.1*maximo]/fatorReducao);
            set(gca,'YGrid','on','YMinorGrid','on');
            hold on;
            media = mean(matrizPlot);
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
            title(nometitulo);
        end
        
        % provisão brookfield
        function [hProvisao] = provisao(self,varargin)
            
            filtro = true(self.nProcesso,1);
            taxaDiferente = false;
            for i = 1:2:length(varargin)
                switch varargin{i}
                    case 'filtro'
                        filtro = varargin{i+1};
                    case 'taxaAnualPresente'
                        taxaDiferente = true;
                        taxa = varargin{i+1};
                    otherwise
                        error(['Parametro ' varargin{i} ' não reconhecido']);
                end
            end
            
            tipo = zeros(self.nProcesso,1);
            fase = zeros(self.nProcesso,1);
            classificacao = zeros(self.nProcesso,1);
            for i=1:self.nProcesso
                processo = self.carteiraInicial.processos{i};
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
            
            if(taxaDiferente)
                [~,valorPresenteProcesso] = self.getValorPresente('taxaAnualPresente',taxa);
            else
                [~,valorPresenteProcesso] = self.getValorPresente();
            end
            
            provisao = sum(valorPresenteProcesso(filtro,1,:),1);
            provisao = provisao + sum(valorPresenteProcesso(filtro & classificacao == 1,2,:),1);
            contingente = sum(valorPresenteProcesso(filtro & classificacao == 2,2,:),1);
            remoto = sum(valorPresenteProcesso(filtro & classificacao == 3,2,:),1);
            
            matrizPlot = [shiftdim(provisao(1,1,:),2) shiftdim(contingente(1,1,:),2) shiftdim(remoto(1,1,:),2)];
            
            maximo = max(max(matrizPlot));
            if(maximo < 1e6)
                fatorReducao = 1e3;
                letra = 'Mil';
            elseif(maximo < 1e9)
                fatorReducao = 1e6;
                letra = 'MM';
            else
                fatorReducao = 1e9;
                letra = 'Bi';
            end
            
            hProvisao = figure;
            label = {'Provisão','Contingente','Remoto'};
            matrizPlot = matrizPlot./fatorReducao;
            boxplot(matrizPlot,'label',label,'whisker',20);
            
            ylabel(['Valor presente (' letra 'R$)'],'FontSize',16,'FontWeight','bold');
            ylim([-0.05*maximo 1.1*maximo]/fatorReducao);
            set(gca,'YGrid','on','YMinorGrid','on');
            hold on;
            media = mean(matrizPlot);
            plot(media,'o');
            for j=1:length(media)
                if(media(j) > 100 || media(j) == 0)
                    text(j+0.27,media(j),num2str(media(j),3));
                elseif(media(j) > 10 || media(j) == 0)
                    text(j+0.27,media(j),num2str(media(j),2));
                else
                    text(j+0.27,media(j),num2str(media(j),'%1.2f'));
                end
            end
            title('Provisão');
            
        end        
        
    end    
    
end
