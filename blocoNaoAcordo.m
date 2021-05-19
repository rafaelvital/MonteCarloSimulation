classdef blocoNaoAcordo < handle
    properties
        idArvore
        idBloco
        processo
        
        
        % Criar arvore
        caminho
        custoFixoBuild
        handleSwicthPath1
        handleSwicthPath2
        
        
        % Estimar Não acordo
        secaoInicial
        custoFixoSecao
        tempoSecao
        tempoAccPre
        
        % Parametros

        foiCalculado
        
    end
    
    properties (Constant)
        instArvore = [1 1 1 2 2 2 3 3 3 4];
    end
    
    methods
        
        function self = blocoNaoAcordo()
            self.foiCalculado = false;
            self.custoFixoSecao = sparse(106,1);
            self.tempoSecao = sparse(106,1);
            self.tempoAccPre = 0;
        end
        
        function [self,vetorExplorado] = criaArvore(self,vetorExplorado)
            processo_ = self.processo;
            arvoreModelo_ = processo_.arvoreModelo;
            self.custoFixoBuild = 0;
            
            idNoh = arvoreModelo_.idPair2idNoh(self.idArvore,self.idBloco);
            
            %Verificar se foi ou não explorado o noh
            if(vetorExplorado{idNoh}.foiCalculado)
                self = vetorExplorado{idNoh};
            else
                
                % Controle
                if(arvoreModelo_.tipo(self.idArvore,self.idBloco) == model.NohModelo.CONTROLE)
                    
                    % Periciaa
                    if(self.idArvore == 1 && self.idBloco == 10)
                        % Tem pericia
                        self.custoFixoBuild = self.custoFixoBuild + 0.2*self.processo.cluster.distPericia.icdf(0.5);
                        %                         self.custoFixoBuild = self.custoFixoBuild + 0.2*2500;
                    end
                    
                    switch arvoreModelo_.tipoBloco(self.idArvore,self.idBloco);
                        case model.NohModelo.ACORDO % Propoe Acordo(1) / Nao Propoe Acordo(2)
                            self.caminho = 2;  %segue caminho especifico
                            
                        case model.NohModelo.RECURSO
                            self.caminho = 1; %Considera que sempre recorre
                            
                        otherwise
                            % ERRO
                            disp(['Controle nao aceita tipo = ' num2str(arvoreModelo_.tipo(self.idArvore,self.idBloco))]);
                    end
                    %Fim de no do tipo controle
                elseif (arvoreModelo_.tipo(self.idArvore,self.idBloco) ~= model.NohModelo.FOLHA)
                    
                    % Externo
                    listaSinksProb = processo_.cluster.prob_aresta{self.idArvore,self.idBloco};
                    switch arvoreModelo_.tipoBloco(self.idArvore,self.idBloco)
                        
                        % verifica se o reclamante aceita o acordo
                        case model.NohModelo.ACORDO
                            self.caminho = 2; %segue caminho especifico
                            
                        case model.NohModelo.RECURSO
                            self.caminho = 4; %ponderar os dois caminhos
                            
                        case model.NohModelo.DECISAO_JUDICIAL
                            if(self.idArvore == 1)
                                self.caminho = 4;  %ponderar os dois caminhos
                                
                                tudoIndeferido = 1;
                                for i=1:length(self.processo.matClasseProb)
                                    tudoIndeferido = tudoIndeferido*(1-self.processo.matClasseProb(i));
                                end
                                
                                listaSinksProb = [tudoIndeferido (1-tudoIndeferido)];
                            else
                                self.caminho = 4;  %os dois caminhos são iguais, podera-se metade de cada
                                listaSinksProb = [0.5 0.5];
                            end
                            
                        case model.NohModelo.OUTRO
                            
                            % Custo pericial
                            if((arvoreModelo_.tipoModelo == model.ArvoreModelo.tipo_trab && self.idArvore==101 &&self.idBloco==9) || ...
                                    (arvoreModelo_.tipoModelo == model.ArvoreModelo.tipo_civel && self.idArvore==101 && self.idBloco==10) || ...
                                    (arvoreModelo_.tipoModelo == model.ArvoreModelo.tipo_jec && self.idArvore==101 && self.idBloco==12))
                                % Tem pericia
                                % self.custoFixoBuild = self.custoFixoBuild + 0.3*processo_.cluster.distPericia.icdf(0.5);
                                self.custoFixoBuild = self.custoFixoBuild + 0.3*2500;
                            end
                            
                            % Assume que todo noh do tipo outro tem as
                            % listaSinksProb bem definido
                            if(length(listaSinksProb)==1)
                                self.caminho = 1;
                            elseif(length(listaSinksProb)==2)
                                self.caminho = 4;
                                
                                %                                 if((processo_.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab && ...
                                %                                         processo_.id_arvore_atual == 105 && processo_.id_bloco_atual == 5) || ...
                                %                                         (processo_.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel && ...
                                %                                         processo_.id_arvore_atual == 104 && processo_.id_bloco_atual == 5))
                                %                                     self.caminho = 4;  %os dois caminhos são espelhos
                                %                                 end
                            else
                                error('listaSinksProb tem nenhum ou mais do que dois sinks')
                            end
                            
                        otherwise
                            error(['Tipo bloco não reconhecido idArvore: ' self.idArvore ...
                                '  idBloco: ' self.idBloco]);
                            
                            
                            
                    end % fim do externo
                else
                    %   folha
                    self.caminho = 3;
                end
                
                
                % Calculo do tempo acumulado
                probEmbargo = processo_.cluster.probEmbargo(self.idArvore,self.idBloco);
                if probEmbargo ~= 0
                    tempoEmbargo =probEmbargo*processo_.cluster.tempoEmbargo(self.idArvore,self.idBloco);
                else
                    tempoEmbargo = 0;
                end
                    
                
                % caminho 1 - swithpath 1
                % caminho 2 - swithpath 2
                % caminho 3 - nó é uma folha, portanto encerramento
                % caminho 4 - que pondera a probabilidade de seguir o swithpath 1 e o swithpath2
                if(self.caminho == 1)
                    self.handleSwicthPath1 = model.blocoNaoAcordo();
                    id_arvore_proximo = arvoreModelo_.proximoArvore1(self.idArvore,self.idBloco);
                    id_bloco_proximo = arvoreModelo_.proximoBloco1(self.idArvore,self.idBloco);
                    if(processo_.execucao_provisoria_port == 1)
                        if(id_arvore_proximo == 101 && id_bloco_proximo == 1 && ...
                                (arvoreModelo_.tipoModelo == 1 ||arvoreModelo_.tipoModelo == 3))
                            id_bloco_proximo = 3;
                        end
                    end
                    self.handleSwicthPath1.idArvore = id_arvore_proximo;
                    self.handleSwicthPath1.idBloco = id_bloco_proximo;
                    self.handleSwicthPath1.processo = processo_;
                    self.handleSwicthPath1.tempoAccPre = self.tempoAccPre + processo_.cluster.tempo_aresta(self.idArvore,self.idBloco,1) + tempoEmbargo;
                                        
                    [self.handleSwicthPath1,vetorExplorado] =  criaArvore(self.handleSwicthPath1,vetorExplorado);
                    
                    self.junta(1,0); %considera só handleSwicthPath1
                    
                elseif (self.caminho == 2)
                    self.handleSwicthPath2 = model.blocoNaoAcordo();
                    id_arvore_proximo = arvoreModelo_.proximoArvore2(self.idArvore,self.idBloco);
                    id_bloco_proximo = arvoreModelo_.proximoBloco2(self.idArvore,self.idBloco);
                    if(processo_.execucao_provisoria_port == 1)
                        if(id_arvore_proximo == 101 && id_bloco_proximo == 1 && ...
                                (arvoreModelo_.tipoModelo == 1 ||arvoreModelo_.tipoModelo == 3))
                            id_bloco_proximo = 3;
                        end
                    end
                    self.handleSwicthPath2.idArvore = id_arvore_proximo;
                    self.handleSwicthPath2.idBloco = id_bloco_proximo;
                    self.handleSwicthPath2.processo = processo_;
                    self.handleSwicthPath2.tempoAccPre = self.tempoAccPre + processo_.cluster.tempo_aresta(self.idArvore,self.idBloco,2) + tempoEmbargo;
                    
                    [self.handleSwicthPath2,vetorExplorado]  =  criaArvore(self.handleSwicthPath2,vetorExplorado);
                    
                    self.junta(0,1); %considera só handleSwicthPath2
                    
                elseif(self.caminho == 3) %Folha
                    
                    self.secaoInicial = processo_.arvoreModelo.secao(self.idArvore,self.idBloco);
                    self.tempoSecao  = sparse(106,1);
                    self.custoFixoSecao = sparse(106,1);
                    
                elseif(self.caminho == 4) %considera os dois caminhos
                    self.handleSwicthPath1 = model.blocoNaoAcordo();
                    id_arvore_proximo = arvoreModelo_.proximoArvore1(self.idArvore,self.idBloco);
                    id_bloco_proximo = arvoreModelo_.proximoBloco1(self.idArvore,self.idBloco);
                    self.handleSwicthPath1.idArvore = id_arvore_proximo;
                    self.handleSwicthPath1.idBloco = id_bloco_proximo;
                    self.handleSwicthPath1.processo = processo_;
                    self.handleSwicthPath1.tempoAccPre = self.tempoAccPre + processo_.cluster.tempo_aresta(self.idArvore,self.idBloco,1) + tempoEmbargo;
                                        
                    [self.handleSwicthPath1,vetorExplorado]  = criaArvore(self.handleSwicthPath1,vetorExplorado);
                    
                    self.handleSwicthPath2 = model.blocoNaoAcordo();
                    id_arvore_proximo = arvoreModelo_.proximoArvore2(self.idArvore,self.idBloco);
                    id_bloco_proximo = arvoreModelo_.proximoBloco2(self.idArvore,self.idBloco);
                    self.handleSwicthPath2.idArvore = id_arvore_proximo;
                    self.handleSwicthPath2.idBloco = id_bloco_proximo;
                    self.handleSwicthPath2.processo = processo_;                    
                    self.handleSwicthPath2.tempoAccPre = self.tempoAccPre + processo_.cluster.tempo_aresta(self.idArvore,self.idBloco,2) + tempoEmbargo;
                                      
                    [self.handleSwicthPath2,vetorExplorado]  =  criaArvore(self.handleSwicthPath2,vetorExplorado);
                    
                    self.junta(listaSinksProb(1),listaSinksProb(2)); %considera só handleSwicthPath2
                    
                else
                    error('caminho não definido')
                end
                
                self.foiCalculado = true;
                %                 self.custoOri = self.custoFixoSecao;
                self.processo = [];
                self.handleSwicthPath1 = [];
                self.handleSwicthPath2 = [];
                
                vetorExplorado{idNoh} = self;
                
            end
        end
        
        function junta(self,proporcao1,proporcao2)
            processo_ = self.processo ;
            
            % Honorario de evento
            [dependePosicao, naoDependePosicao] = processo_.calculaHonorariosEventos(self.idArvore,self.idBloco); %#ok<ASGLU> naoDependePosicao não é usado
            self.custoFixoBuild = self.custoFixoBuild + dependePosicao;
            
            % Tempo de embargo
            probEmbargo = processo_.cluster.probEmbargo(self.idArvore,self.idBloco);
            if probEmbargo ~= 0
                tempoEmbargo =probEmbargo*processo_.cluster.tempoEmbargo(self.idArvore,self.idBloco);
            else
                tempoEmbargo = 0;
            end
            
            secaoAtual = processo_.arvoreModelo.secao(self.idArvore,self.idBloco);
            self.secaoInicial  = secaoAtual;
            
            if(proporcao1*proporcao2 ~= 0)
                
                tempo1 = processo_.cluster.tempo_aresta(self.idArvore,self.idBloco,1);
                tempoSecaoP1 = self.handleSwicthPath1.tempoSecao;
                custoFixoSecaoP1 = self.handleSwicthPath1.custoFixoSecao;
                
                tempo2 = processo_.cluster.tempo_aresta(self.idArvore,self.idBloco,2);
                tempoSecaoP2 = self.handleSwicthPath2.tempoSecao;
                custoFixoSecaoP2 = self.handleSwicthPath2.custoFixoSecao;
                
                % self.tempoSecao = proporcao1*tempoSecaoP1+proporcao2*tempoSecaoP2;
                % self.custoFixoSecao = proporcao1*custoFixoSecaoP1 + proporcao2*custoFixoSecaoP2;
                
                self.tempoSecao = max(tempoSecaoP1,tempoSecaoP2);
                self.custoFixoSecao = max(custoFixoSecaoP1,custoFixoSecaoP2);
                
                self.tempoSecao(secaoAtual) = proporcao1*(tempoSecaoP1(secaoAtual)+tempo1+tempoEmbargo) + ...
                    proporcao2*(tempoSecaoP2(secaoAtual)+tempo2+tempoEmbargo);
                
                self.custoFixoSecao(secaoAtual) = ...
                    proporcao1*(custoFixoSecaoP1(secaoAtual)*self.processo.carteira.calculaTaxaPresente(self.handleSwicthPath1.tempoAccPre-tempo1-tempoEmbargo, self.handleSwicthPath1.tempoAccPre)+self.custoFixoBuild) + ...
                    proporcao2*(custoFixoSecaoP2(secaoAtual)*self.processo.carteira.calculaTaxaPresente(self.handleSwicthPath2.tempoAccPre-tempo2-tempoEmbargo, self.handleSwicthPath2.tempoAccPre)+self.custoFixoBuild);
                
            elseif(proporcao1 ~= 0)
                % Apenas caminho 1
                tempo = processo_.cluster.tempo_aresta(self.idArvore,self.idBloco,1);
                self.tempoSecao  = self.handleSwicthPath1.tempoSecao;
                self.custoFixoSecao = self.handleSwicthPath1.custoFixoSecao;
                self.tempoSecao (secaoAtual) =  self.tempoSecao (secaoAtual)+tempo+tempoEmbargo;
                self.custoFixoSecao(secaoAtual) = self.custoFixoSecao(secaoAtual)*self.processo.carteira.calculaTaxaPresente(self.handleSwicthPath1.tempoAccPre-tempo-tempoEmbargo, self.handleSwicthPath1.tempoAccPre)+self.custoFixoBuild;
            elseif(proporcao2 ~= 0)
                % Apenas caminho 2
                tempo = processo_.cluster.tempo_aresta(self.idArvore,self.idBloco,2);
                self.tempoSecao  = self.handleSwicthPath2.tempoSecao;
                self.custoFixoSecao = self.handleSwicthPath2.custoFixoSecao;
                self.tempoSecao (secaoAtual) =  self.tempoSecao (secaoAtual)+tempo+tempoEmbargo;
                self.custoFixoSecao(secaoAtual) = self.custoFixoSecao(secaoAtual)*self.processo.carteira.calculaTaxaPresente(self.handleSwicthPath2.tempoAccPre-tempo-tempoEmbargo, self.handleSwicthPath2.tempoAccPre)+self.custoFixoBuild;
            else
                error('As duas proporções são iguais a 1')
            end
            
        end
        
        function [espSinkNaoAcordo,componentesNaoAcordo,decisaoRecorrer]  = getValorNaoAcordo(self)
            tempoDep1 = 0;
            tempoDep2 = 0;
            tempoDepExe = 0;
            deposito1 = self.processo.deposito_recursal1;
            deposito2 = self.processo.deposito_recursal2;
            depositoExe = self.processo.deposito_execucao;
            coefDef = self.processo.pedidos_deferidos;
            
            ponderaProbDecisaoIndef = ones(size(coefDef));
            
            idNoh = self.processo.arvoreModelo.idPair2idNoh(self.processo.id_arvore_atual,self.processo.id_bloco_atual);
            self.tempoSecao = self.processo.carteira.mapaNoh.tempo{self.processo.idAgente}(idNoh,:);
            self.custoFixoSecao = self.processo.carteira.mapaNoh.custo{self.processo.idAgente}(idNoh,:);
            
            if(self.processo.id_arvore_atual < 100)
                arvore = self.processo.id_arvore_atual;
            else
                arvore = self.processo.arvoreModelo.secao(self.processo.id_arvore_atual,self.processo.id_bloco_atual);
            end
            
            [valorNaoAcordo,decisaoRecorrer] = getValorNaoAcordoRecursivo(self,coefDef,0, arvore, tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef);
            componentesNaoAcordo = valorNaoAcordo;
            espSinkNaoAcordo = sum(valorNaoAcordo);
            
        end
        
        function [valorNaoAcordo,decisaoRecorrer] = getValorNaoAcordoRecursivo(self,coefDef,tempoAcc, arvore, tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef)
            
            processo_ = self.processo;
            
            valorNaoAcordo = zeros(1,6);
            probAresta = processo_.cluster.prob_aresta;
            decisaoRecorrer = 0;
            [parteFixa, parteVariavel] = processo_.calculaHonorarioExito(); %#ok<ASGLU> parteVariavel não é usada
            custoExito = parteFixa;
            multa = 1;
            
            % Conhecimento
            if(arvore < 100)
                
                %Identifia a secao do no, pegando o tempo da secao e o custo
                if((self.processo.arvoreModelo.tipoModelo ~= model.ArvoreModelo.tipo_jec) && ...
                        arvore == 7 || arvore == 10 || (arvore == 1 && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab))
                    if(processo_.id_arvore_atual == 7 && processo_.id_bloco_atual >=6)
                        nSecao =  processo_.arvoreModelo.secao(processo_.id_arvore_atual, processo_.id_bloco_atual);
                        tempo = self.tempoSecao(nSecao);
                        custoSecao = self.custoFixoSecao(nSecao) ;
                        consideraAdmissibilidade = false;
                    elseif(processo_.id_arvore_atual == 10 && processo_.id_bloco_atual >=6)
                        nSecao =  processo_.arvoreModelo.secao(processo_.id_arvore_atual, processo_.id_bloco_atual);
                        tempo = self.tempoSecao(nSecao);
                        custoSecao = self.custoFixoSecao(nSecao) ;
                        consideraAdmissibilidade = false;
                    elseif(processo_.id_arvore_atual == 1 && processo_.id_bloco_atual >=6)
                        nSecao =  processo_.arvoreModelo.secao(processo_.id_arvore_atual, processo_.id_bloco_atual);
                        tempo = self.tempoSecao(nSecao);
                        custoSecao = self.custoFixoSecao(nSecao);
                        consideraAdmissibilidade = false;
                    else
                        if(arvore == 7)
                            adicional = 2;
                        else
                            adicional = 1; %%arvore 10 e 1
                        end
                        nSecao =  processo_.arvoreModelo.secao(arvore, 1);
                        tempo = self.tempoSecao(nSecao)+self.tempoSecao(nSecao+adicional);
%                         taxaVpLocal = processo_.carteira.calculaTaxaPresente(tempoAcc,tempoAcc+tempo); 
                        taxaVpLocal = processo_.carteira.calculaTaxaPresente(tempoAcc+self.tempoSecao(nSecao+adicional),tempoAcc+tempo); 
                        custoSecao = self.custoFixoSecao(nSecao) + self.custoFixoSecao(nSecao+adicional).*taxaVpLocal;
                        consideraAdmissibilidade = true;
                        coefDefNaoAdmissivel = coefDef;
                        tempoAccNaoAdimissibilidade = tempoAcc;
                    end
                else
                    nSecao =  processo_.arvoreModelo.secao(arvore,1);
                    tempo = self.tempoSecao(nSecao);
                    custoSecao = self.custoFixoSecao(nSecao);
                    consideraAdmissibilidade = false;
                end
                
                % Considera nao adimissibilidade
                if(consideraAdmissibilidade)
                    nSecao = processo_.arvoreModelo.secao(arvore,1);
                    if(arvore == 7)
                        if(self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab)
                            probAdmissivel =  probAresta{7,3}(2);
                        elseif(self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel)
                            probAdmissivel =  probAresta{7,5}(2);
                        end
                        tempoAd = self.tempoSecao(nSecao) + self.tempoSecao(nSecao+1);
                        custoSecaoAd = self.custoFixoSecao(nSecao)+self.custoFixoSecao(nSecao+1);
                    elseif(arvore == 10)
                        probAdmissivel =  probAresta{10,5}(2);
                        tempoAd = self.tempoSecao(nSecao);
                        custoSecaoAd = self.custoFixoSecao(nSecao);
                    elseif(arvore == 1)
                        probAdmissivel =  1-probAresta{1,3}(1)*probAresta{1,4}(1);
                        tempoAd = self.tempoSecao(nSecao);
                        custoSecaoAd = self.custoFixoSecao(nSecao);
                    end
                    
%                     taxaVp = 1/(1+self.taxaDescontoMensal)^tempoAd;
                    taxaVp = processo_.carteira.calculaTaxaPresente(tempoAcc,tempoAcc+tempoAd);                       
                    
                    % honorario mensal para o caso não admissivel
                    honorarioMensal = processo_.calculaHonorarioMensal(tempoAccNaoAdimissibilidade,...
                        tempoAccNaoAdimissibilidade+tempoAd);
                    
                    tempoAccNaoAdimissibilidade = tempoAccNaoAdimissibilidade+tempoAd;
                    valorNaoAcordoNaoAdmissivel = zeros(1,6);
                    valorNaoAcordoNaoAdmissivel(3) = valorNaoAcordoNaoAdmissivel(3)+custoSecaoAd+honorarioMensal;
                    if(arvore == 7 || arvore == 10)
                        tudoIndeferidoNaoAdmissivel = prod(1-coefDefNaoAdmissivel);
                        depositoAcumulado =  deposito1.*processo_.carteira.calculaJam(tempoAccNaoAdimissibilidade,tempoDep1) + ...
                                            deposito2.*processo_.carteira.calculaJam(tempoAccNaoAdimissibilidade,tempoDep2);
                        if(tudoIndeferidoNaoAdmissivel~=1)
                            coefDefNaoAdmissivel = coefDefNaoAdmissivel/(1-tudoIndeferidoNaoAdmissivel);
                            valorNaoAcordoNaoAdmissivel = valorNaoAcordoNaoAdmissivel + tudoIndeferidoNaoAdmissivel.*[0,0,custoExito,0,0,-depositoAcumulado].*taxaVp+...
                                (1-tudoIndeferidoNaoAdmissivel)*self.getValorNaoAcordoRecursivo(coefDefNaoAdmissivel,tempoAccNaoAdimissibilidade,101,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef).*taxaVp;
                        else
                            valorNaoAcordoNaoAdmissivel = valorNaoAcordoNaoAdmissivel  + [0,0,custoExito,0,0,-depositoAcumulado].*taxaVp;
                        end
                        
                    else
                        valorNaoAcordoNaoAdmissivel = valorNaoAcordoNaoAdmissivel + [0,0,custoExito,0,0,0].*taxaVp;
                    end
                end
                
                % parte adimissivel (sempre acontece)
%                 taxaVp = 1/(1+self.taxaDescontoMensal)^tempo;
                taxaVp = processo_.carteira.calculaTaxaPresente(tempoAcc,tempoAcc+tempo);    
                
                % honorário mensal para o caso admissivel
                honorarioMensal = processo_.calculaHonorarioMensal(tempoAcc,...
                    tempoAcc+tempo);
                
                tempoAcc = tempoAcc + tempo;
                valorNaoAcordo(3) = valorNaoAcordo(3)+custoSecao+honorarioMensal;
                
                switch arvore
                    case 1
                        coefDef =  processo_.matClasseProb;
                        tudoIndeferido = prod(1-coefDef);
                        tudoDeferido =  prod(coefDef);
                    case {4,7,10}
                        coefDef = coefDef.*(~processo_.pedidos_em_pauta) + ...
                            processo_.pedidos_em_pauta.*coefDef.*processo_.matClasseProbDecisaoDef(:, self.instArvore(arvore)-1) +...
                            processo_.pedidos_em_pauta.*(1-coefDef).*ponderaProbDecisaoIndef.*processo_.matClasseProbDecisaoIndef(:,self.instArvore(arvore)-1);
                        tudoIndeferido = prod(1-coefDef);
                        tudoDeferido =  prod(coefDef);
                    otherwise
                        tudoIndeferido = all(~processo_.pedidos_deferidos(logical(processo_.pedidos_em_pauta)));
                        tudoDeferido =  all(processo_.pedidos_deferidos(logical(processo_.pedidos_em_pauta)));
                end
                
                ponderaProbDecisaoIndef = 1;
                
                %Se ainda tiver julgamento em conhecimento
                if((self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab && arvore ~=10) || ...
                        (self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel && ~(arvore ==7 || arvore ==8 ||  arvore ==9)) || ...
                        (self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_jec && arvore ~=4))
                    % Caso exista possibildiade de ser tudo indeferido
                    if(tudoIndeferido~=0)
                        switch arvore
                            case {1,2,3}
                                probIndeferidoRecorre = probAresta{2,1}(1);
                                proximaArvore = 4;
                            case {4,5,6}
                                probIndeferidoRecorre = probAresta{5,5}(1);
                                proximaArvore = 7;
                            case {7,8,9}
                                probIndeferidoRecorre = probAresta{8,5}(1);
                                proximaArvore = 10;
                            otherwise
                                error('Opção inválida de arvore');
                        end
                        
                        % Inderido e reclamante não Recorre
                        depositoAcumulado =  deposito1.*processo_.carteira.calculaJam(tempoAcc,tempoDep1) + ...
                                             deposito2.*processo_.carteira.calculaJam(tempoAcc,tempoDep2);
                        valorNaoAcordo = valorNaoAcordo +tudoIndeferido.*(1-probIndeferidoRecorre).*[0,0,custoExito,0,0,-depositoAcumulado].*taxaVp;
                        
                        % Inderido e reclamante Recorre
                        valorNaoAcordo = valorNaoAcordo +tudoIndeferido.*probIndeferidoRecorre*(self.getValorNaoAcordoRecursivo(zeros(size(coefDef)),tempoAcc,proximaArvore,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef)).*taxaVp;
                        
                    end
                    
                    % Caso deferido ou parcialmente deferido
                    if(tudoIndeferido ~= 1)
                        
                        coefDef = coefDef/(1-tudoIndeferido);
                        
                        % Reclamado Recorre
                        switch arvore
                            case {1,2,3}
                                probReclamanteRecorre = probAresta{3,4}(1);
                                proximaArvore = 4;
                                tempoDep1 = tempoAcc;
                                valorJulgado = processo_.calculaValorProcesso(round(processo_.carteira.indiceTempo+tempoAcc), coefDef, multa);
                                if(processo_.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab)
                                    deposito1  = min(8959.63,valorJulgado);
                                    custoDeposito =  deposito1;
                                else
                                    custoDeposito = 0;
                                end
                                custoRecurso = self.processo.custoRecorrerUF(valorJulgado);
                            case {4,5,6}
                                probReclamanteRecorre = probAresta{5,4}(1);
                                proximaArvore = 7;
                                tempoDep2 = tempoAcc;
                                depositoAcumulado =  deposito1.*processo_.carteira.calculaJam(tempoAcc,tempoDep1);
                                valorJulgado = processo_.calculaValorProcesso(round(processo_.carteira.indiceTempo+tempoAcc), coefDef, multa);
                                if(processo_.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab)
                                    deposito2  = min(17919.29,max(valorJulgado-depositoAcumulado,0));
                                    custoDeposito =  deposito2;
                                else
                                    custoDeposito = 0;
                                end
                                custoRecurso = self.processo.custoRecorrerUF(valorJulgado);
                            case {7,8,9}
                                probReclamanteRecorre = probAresta{8,4}(1);
                                proximaArvore = 10;
                                custoDeposito = 0;
                                custoRecurso = 181.34;
                            otherwise
                                error('Opção inválida de arvore');
                        end
                        
                        %Efeito do reclamante recorrer ou nao
                        ponderaProbDecisaoIndef = probReclamanteRecorre;
                        valorNaoAcordoRecorre  = (self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,proximaArvore,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe, ponderaProbDecisaoIndef)+...
                            [0,0,0,custoRecurso,custoDeposito,0]).*taxaVp;
                        
                        % Reclamado Nao Recorre
                        if(tudoDeferido == 1)
                            valorNaoAcordoNaoRecorre  = self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,101,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef);
                        else
                            switch arvore
                                case {1,3}
                                    probReclamanteRecorre = probAresta{3,5}(1);
                                    proximaArvore = 4;
                                    tempoDep1 = tempoAcc;
                                    deposito1  = 0;
                                case {4,5,6}
                                    probReclamanteRecorre = probAresta{5,5}(1);
                                    proximaArvore = 7;
                                    tempoDep2 = tempoAcc;
                                    deposito2  = 0;
                                case {7,8,9}
                                    probReclamanteRecorre = probAresta{8,5}(1);
                                    proximaArvore = 10;
                                otherwise
                                    error('Opção inválida de arvore');
                            end
                            
                            ponderaProbDecisaoIndef = 1;
                            %Reclamante nao recorre (vai para execução)
                            valorNaoAcordoNaoRecorre  = (tudoDeferido+(1-tudoDeferido)*(1-probReclamanteRecorre))*self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,101,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef).*taxaVp;
                            
                            %Reclamante recorre (proxima Arvore)
                            %Efeito do reclamado nao recorrer
                            valorNaoAcordoNaoRecorre = valorNaoAcordoNaoRecorre + (1-tudoDeferido)*probReclamanteRecorre*self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,proximaArvore,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef).*taxaVp;
                            %                           processo_.matClasseProbDecisaoDefAnterior = matClasseProbDecisaoDefAnterior;
                        end
                        
                        
                        if(self.processo.carteira.decideRecorrer)
                            if(sum(valorNaoAcordoRecorre) < sum(valorNaoAcordoNaoRecorre))
                                decisaoRecorrer = 1;
                                valorNaoAcordo = valorNaoAcordo +(1-tudoIndeferido)*valorNaoAcordoRecorre;
                            else
                                decisaoRecorrer = 2;
                                valorNaoAcordo = valorNaoAcordo +(1-tudoIndeferido)*valorNaoAcordoNaoRecorre;
                            end
                        else
                            valorNaoAcordo = valorNaoAcordo +(1-tudoIndeferido)*valorNaoAcordoRecorre;
                        end
                    end
                    
                else
                    
                    % Verfica se após o ultimo julgamento o processo
                    % teve exito
                    depositoAcumulado =  deposito1.*processo_.carteira.calculaJam(tempoAcc,tempoDep1) + ...
                                         deposito2.*processo_.carteira.calculaJam(tempoAcc,tempoDep2);
                    valorNaoAcordo = valorNaoAcordo + tudoIndeferido*[0,0,custoExito,0,0,-depositoAcumulado].*taxaVp;
                    if(tudoIndeferido~=1)
                        coefDef = coefDef/(1-tudoIndeferido);
                        valorNaoAcordo = valorNaoAcordo + (1-tudoIndeferido).*self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,101,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef).*taxaVp;
                    end
                end
                
                % Considera nao adimissibilidade
                if(consideraAdmissibilidade)
                    valorNaoAcordo = valorNaoAcordo.*probAdmissivel + (1-probAdmissivel)*valorNaoAcordoNaoAdmissivel;
                end
                
                %Final de conhecimento
            else
                %  Execução
                %  Por enquanto vamos supor que sempre recorre em execução
                
                ponderaProbDecisaoIndef = 1;
                nSecao = arvore;
                tempo = self.tempoSecao(nSecao);
%                 taxaVp = 1/(1+self.taxaDescontoMensal)^tempo;
                taxaVp = processo_.carteira.calculaTaxaPresente(tempoAcc,tempoAcc+tempo);   
                
                
                      
                
                % honorario mensal para a execução
                honorarioMensal = processo_.calculaHonorarioMensal(tempoAcc,...
                    tempoAcc+tempo);
                
                tempoAcc = tempoAcc + tempo;
                valorNaoAcordo = zeros(1,6);
                valorNaoAcordo(3) = valorNaoAcordo(3)+self.custoFixoSecao(nSecao)+honorarioMensal;
                
                % verifica multa e honorario de sucumbencia
                if(self.processo.carteira.aplicarMulta)
                    if(self.processo.arvoreModelo.tipoModelo ~= model.ArvoreModelo.tipo_jec)
                        multa = 1.1;
                    end
                end
                
                if(self.processo.carteira.honorarioSucumbencia ~= 0)
                    if(self.processo.arvoreModelo.tipoModelo ~= model.ArvoreModelo.tipo_trab)
                        if(self.processo.carteira.honorarioSucumbencia == 1)
                            multa = multa*1.1;
                        else
                            multa = multa*1.15;
                        end
                    end
                end
                
                % switch nSecao
                % Decide se paga a condenção, ou se continua recorrendo pagando multa e  deposito
                if(((nSecao == 102 || nSecao == 101) && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab)) || ...
                        (nSecao == 101 && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel) || ...
                        (nSecao == 101 && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_jec)
                    
                    if(self.processo.carteira.naoPagaCondenacao)
                        valorNaoAcordo = valorNaoAcordo + self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,nSecao+1,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef).*taxaVp;
                    else
                        valorSentenca = processo_.calculaValorProcesso(round(processo_.carteira.indiceTempo+tempoAcc), coefDef, multa);
                        depositoAcumulado =  deposito1.*processo_.carteira.calculaJam(tempoAcc,tempoDep1) + ...
                                             deposito2.*processo_.carteira.calculaJam(tempoAcc,tempoDep2);
%                         depositoAcumulado =  deposito1.*(1+self.jam).^(tempoAcc-tempoDep1)+deposito2.*(1+self.jam).^(tempoAcc-tempoDep2);
                        [dependeSentenca,naoDependeSentenca]  = processo_.calculaHonorarioCondenacao(valorSentenca); %#ok<ASGLU> naoDependeSentenca não é usado
                        valorNaoAcordo = valorNaoAcordo + [0 valorSentenca dependeSentenca 0 0 -depositoAcumulado].*taxaVp;
                    end
                    
                 % Trata do deposito execução (trab, civel, jec)
                elseif(nSecao == 103 && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab) || ...
                        (nSecao == 102 && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel) || ...
                        (nSecao == 102 && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_jec)
                    
                    % deposito execução
                    tempoDepExe = tempoAcc;
                    valorSentenca = processo_.calculaValorProcesso(round(processo_.carteira.indiceTempo+tempoAcc),coefDef,multa);
                    depositoAcumulado =  deposito1.*processo_.carteira.calculaJam(tempoAcc,tempoDep1) + ...
                                         deposito2.*processo_.carteira.calculaJam(tempoAcc,tempoDep2);
                    depositoExe  = min(valorSentenca,max(valorSentenca-depositoAcumulado,0));
                    valorNaoAcordo = valorNaoAcordo + ([0,0,0,0,depositoExe,0] + self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,nSecao+1,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef)).*taxaVp;
                    
                % Trata da recorrencia de primeira instancia (trab, civel)
                elseif(nSecao == 104 && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab) || ...
                        (nSecao == 103 && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel)
                    % Reclamante recorrer na arvore 103 - trab
                    if(self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab)
                        probArvore103 = probAresta{102,7}(1);
                        probNaorecorrer = probAresta{103,3}(2);
                        % se o processo iniciar 103,1 quer dizer que a probArvore103 = 1, afinal foi para a arvore 103
                        if(processo_.id_arvore_atual == 103 && processo_.id_bloco_atual == 1)
                            probArvore103 = 1;
                        end
                        % se o processo iniciar 103,1 quer dizer que o reclamante ganhou o julgamento, logo ele não vai recorrer e nem vai para a arvore 103
                        if(processo_.id_arvore_atual == 104)
                            probArvore103 = 0;
                            probNaorecorrer = 0;
                        end
                        
                        % Reclamante recorrer na arvore 102 - civel
                    elseif(self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel)
                        probArvore103 = probAresta{101,16}(1);
                        probNaorecorrer = probAresta{102,3}(2);
                        % se o processo iniciar 102,1 quer dizer que a probArvore103 = 1, afinal foi para a arvore 103
                        if(processo_.id_arvore_atual == 102 && processo_.id_bloco_atual == 1)
                            probArvore103 = 1;
                        end
                        % se o processo iniciar 103,1 quer dizer que o reclamante ganhou o julgamento, logo ele não vai recorrer e nem vai para a arvore 103
                        if(processo_.id_arvore_atual == 103)
                            probArvore103 = 0;
                            probNaorecorrer = 0;
                        end
                    else
                        error('Configurado apenas para civel e trab');
                    end
                    
                    valorSentenca = processo_.calculaValorProcesso(round(processo_.carteira.indiceTempo+tempoAcc), coefDef, multa);
                    depositoAcumulado =  deposito1.*processo_.carteira.calculaJam(tempoAcc,tempoDep1) + ...
                                         deposito2.*processo_.carteira.calculaJam(tempoAcc,tempoDep2)+ ...
                                         depositoExe.*processo_.carteira.calculaJam(tempoAcc,tempoDepExe);                                         
                    [dependeSentenca,naoDependeSentenca]  = processo_.calculaHonorarioCondenacao(valorSentenca); %#ok<ASGLU> naoDependeSentenca não é usado
                    
                    if(self.processo.carteira.recorreJulgamentoExecucao)
                        valorNaoAcordo = valorNaoAcordo + (probArvore103*probNaorecorrer*[0 valorSentenca dependeSentenca 0 0 -depositoAcumulado]+...
                            (1-probArvore103*probNaorecorrer)*self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,nSecao+1,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef)).*taxaVp;
                    else
                        valorNaoAcordo = valorNaoAcordo +(probNaorecorrer*[0 valorSentenca dependeSentenca 0 0 -depositoAcumulado]+...
                            (1-probNaorecorrer)*self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,nSecao+1,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef)).*taxaVp;
                    end
                    
                    % Trata da recorrencia de segunda instancia (trab, civel)
                elseif((nSecao == 105  && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab) || ...
                        (nSecao == 104 && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel))
                    
                    if(self.processo.carteira.recorreJulgamentoExecucao)
                        valorNaoAcordo = valorNaoAcordo + self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,nSecao+1,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef).*taxaVp;
                    else
                        if(self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab)
                            probReclamanteRecorre = probAresta{107,5}(1);
                        end
                        if(self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel)
                            probReclamanteRecorre = probAresta{106,5}(1);
                        end
                        valorSentenca = processo_.calculaValorProcesso(round(processo_.carteira.indiceTempo+tempoAcc), coefDef, multa);
                        depositoAcumulado =  deposito1.*processo_.carteira.calculaJam(tempoAcc,tempoDep1) + ...
                                         deposito2.*processo_.carteira.calculaJam(tempoAcc,tempoDep2)+ ...
                                         depositoExe.*processo_.carteira.calculaJam(tempoAcc,tempoDepExe);
                        [dependeSentenca,naoDependeSentenca]  = processo_.calculaHonorarioCondenacao(valorSentenca); %#ok<ASGLU> naoDependeSentenca não é usado
                        valorNaoAcordo = valorNaoAcordo + ((1-probReclamanteRecorre)*[0 valorSentenca dependeSentenca 0 0 -depositoAcumulado]+...
                            probReclamanteRecorre*self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,nSecao+1,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef)).*taxaVp;
                    end
                    
                    % Trata da condenação (trab, civel)
                elseif(nSecao == 106  && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab) || ...
                        (nSecao == 105 && self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel)
                    valorSentenca = processo_.calculaValorProcesso(round(processo_.carteira.indiceTempo+tempoAcc), coefDef, multa);
                    depositoAcumulado =  deposito1.*processo_.carteira.calculaJam(tempoAcc,tempoDep1) + ...
                                         deposito2.*processo_.carteira.calculaJam(tempoAcc,tempoDep2)+ ...
                                         depositoExe.*processo_.carteira.calculaJam(tempoAcc,tempoDepExe);
                    [dependeSentenca,naoDependeSentenca]  = processo_.calculaHonorarioCondenacao(valorSentenca); %#ok<ASGLU> naoDependeSentenca não é usado
                    valorNaoAcordo = valorNaoAcordo + [0 valorSentenca dependeSentenca 0 0 -depositoAcumulado].*taxaVp;
                    
                    % Trata da condenação (jec)
                elseif(self.processo.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_jec  && nSecao == 103)
                    valorSentenca = processo_.calculaValorProcesso(round(processo_.carteira.indiceTempo+tempoAcc), coefDef, multa);
                    depositoAcumulado =  deposito1.*processo_.carteira.calculaJam(tempoAcc,tempoDep1) + ...
                                         deposito2.*processo_.carteira.calculaJam(tempoAcc,tempoDep2)+ ...
                                         depositoExe.*processo_.carteira.calculaJam(tempoAcc,tempoDepExe);
                    [dependeSentenca,naoDependeSentenca]  = processo_.calculaHonorarioCondenacao(valorSentenca); %#ok<ASGLU> naoDependeSentenca não é usado
                    valorNaoAcordo = valorNaoAcordo + [0 valorSentenca dependeSentenca 0 0 -depositoAcumulado].*taxaVp;
                else
                    disp('Opa não foi pego pelos ifs');
                    valorNaoAcordo = valorNaoAcordo + self.getValorNaoAcordoRecursivo(coefDef,tempoAcc,nSecao+1,tempoDep1,tempoDep2,tempoDepExe,deposito1,deposito2,depositoExe,ponderaProbDecisaoIndef).*taxaVp;
                end
                
            end
            
            
        end
    end
    
end