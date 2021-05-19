classdef ArvoreModelo < handle
    
     properties

        nNoh %numero de nós
        listaNohs %lista com todos os nós, segue a mesma numeração do arquivo excel
        idPair2idNoh %converte o nó da dupla (arvore, bloco) para id
        tipoModelo %Civel, Jec, Trab
        
        % Essas properties sao matrizes que tem tamanho (maxIdarvore e maxIdBloco)
        % Quando o noh nao existe, o respectivo elemento da matriz é zero,
        % e quando existe, o elemento da matriz corresponde aos atributos
        % do noh, essas matrizes são pre-processadas
        tipo
        tipoBloco
        tipoSink1 %tipo de saida caso o swithpath seja 1
        tipoSink2
        proximoBloco1 %id do proximo bloco caso o swithpath seja 1
        proximoBloco2
        proximoArvore1 %id da proxima arvore caso o swithpath seja 1
        proximoArvore2
        
		secao
		
     end
     
     properties (Constant)
        col_id = 1;
        col_idArvore = 2;
        col_idBloco = 3;
        col_tipo = 4;
        col_sinks1 = 5;
        col_sinks2 = 6;
        col_tipoBloco = 7;
        col_tipoSink1 = 8;
        col_tipoSink2 = 9;
		col_secao = 10;
        tipo_trab = 1;
        tipo_civel = 2;
        tipo_jec = 3;        
        
     end
    
     methods (Static)
         
         % Cria logicamente a Arvore de decisão baseado no arquivo excel e 
         % no tipo de arvore.
         % Salva a arvore em um arquivo .mat chamado [excelFileName tipoModelo],
         % assim carrega mais rapido em futuras utilizações
         
         % excelFileName: Nome do arquivo excel
         % tipoModelo: String 'Trab', 'Civel' ou 'Jec'
         % verificar: Boolean que indica se verifica a existencia do
         % arquivo .mat correspondente ao excel. Caso exista e seja atual,
         % carrega a arvore atraves do .mat ao invés do excel
         function self = excelBuild(excelFileName,tipoModelo, verificar)
                         
              import model.ArvoreModelo 
             
              DirInfoMat = dir([excelFileName tipoModelo '.mat']);
              DirInfoXls = dir([excelFileName '.xlsx']);
              
              % verifica se o .mat é atual e corresponde excelFileName
              if (verificar && exist([excelFileName tipoModelo '.mat'],'file') && DirInfoMat.datenum > DirInfoXls.datenum )
                  % carrega a arvore através do .mat
                  load([excelFileName tipoModelo '.mat']);
                  self = arv;
              else
                  
                  % Le o excel
                  self = ArvoreModelo();
                  [~,~,raw] = xlsread(excelFileName,tipoModelo);
                  self.nNoh = size(raw,1)-1;
                  self.listaNohs = model.NohModelo.empty(self.nNoh,0);
                  
                  % Para cada linha do excel, cria-se o noh correspondente
                  for i=1: self.nNoh
                      
                      id = raw{i+1, self.col_id};
                      idArvore = raw{i+1, self.col_idArvore};
                      idBloco = raw{i+1, self.col_idBloco};
                      
                      self.idPair2idNoh(idArvore,idBloco) = id;
                      
                      % Cria o noh
                     self.listaNohs(i) = model.NohModelo(id,idArvore,idBloco,raw{i+1, self.col_tipo},...
                          raw{i+1, self.col_tipoBloco}, raw{i+1, self.col_sinks1}, raw{i+1, self.col_sinks2},...
                          raw{i+1, self.col_tipoSink1}, raw{i+1, self.col_tipoSink2},raw{i+1, self.col_secao});
                  end %for
                  
                  %Passa o tipo da arvore de string para const
                  if(strcmp(tipoModelo,'Trab'))
                      self.tipoModelo = self.tipo_trab;
                  elseif(strcmp(tipoModelo,'Civel'))
                      self.tipoModelo =  self.tipo_civel;
                  elseif(strcmp(tipoModelo,'Jec'))
                      self.tipoModelo =  self.tipo_jec;
                  else
                      error('Tipo não identificado');
                  end
                  
                  %preCompute o modeloArvore, isto é, através da lista de
                  %nos lida do excel, cria as matrizes de acesso rapido da
                  %forma proprieda(idArvore,idBloco)
                  self.preCompute();

                  arv = self;
                  % salva o .mat
                  save([excelFileName tipoModelo '.mat'],'arv');
              end
              
          end  %excelBuild
     end
    
     methods
         
          % Construtor Default
          function self = ArvoreModelo()
          end
          
          % Pre processa as matrizes que indicam os atributos dos nós.
          % Teoricamente isso não é preciso, já que podemos usar o
          % comando objetoArvore.getNoh(idArvore,idBloco).atributo. 
          % Mas pre processando, o acesso objetoArvore.atributo(idArvore,idBloco)
          % é significantemente mais rapido
          % Prerequisito: A arvore deve ter sido criado com o comando
          % excelBuild.
          function self = preCompute(self)
              
              % Incializa as matrizes com as dimensoes de idPair2idNoh
              self.tipo = zeros(size(self.idPair2idNoh));
              self.tipoBloco = zeros(size(self.idPair2idNoh));
              self.tipoSink1 = zeros(size(self.idPair2idNoh));
              self.tipoSink2 = zeros(size(self.idPair2idNoh));
              self.proximoBloco1 = zeros(size(self.idPair2idNoh));
              self.proximoBloco2 = zeros(size(self.idPair2idNoh));
              self.proximoArvore1 = zeros(size(self.idPair2idNoh));
              self.proximoArvore2 = zeros(size(self.idPair2idNoh));
			  self.secao = zeros(size(self.idPair2idNoh));
        
              % Para cada uns dos noh do modelo, transfere os seus
              % atributos para as matrizes na posição adequada.
              for i=1:length(self.listaNohs)
                  % Identifica o noh
                  noh = self.listaNohs(i);
                  
                  % Identifica a posição
                  idArvore  = noh.idArvore;
                  idBloco  = noh.idBloco;                  
                  
                  %Copia os atributos diretos
                  self.tipo(idArvore,idBloco) = noh.tipo;
                  self.tipoBloco(idArvore,idBloco) = noh.tipoBloco;
                  self.tipoSink1(idArvore,idBloco) = noh.tipoSink1;
                  self.tipoSink2(idArvore,idBloco) = noh.tipoSink2;
				  self.secao(idArvore,idBloco) = noh.secao;
              
                  % Identifica qual é o proximo noh para cada swithpath
                  % possivel. Considera-se que só existe duas
                  % possibilidades.
                  [self.proximoArvore1(idArvore,idBloco),  self.proximoBloco1(idArvore,idBloco)] = ...
                      proximoNoh(self,noh.idArvore, noh.idBloco, 1);     

                  [self.proximoArvore2(idArvore,idBloco),  self.proximoBloco2(idArvore,idBloco)] = ...
                      proximoNoh(self,noh.idArvore, noh.idBloco, 2);
              end
              
          end
 
          % Método que acessa o nó da arvore de decisão.
          % O acesso pode ser tanto com o (idNoh) ou com o dupla (idArvore,idBloco)
          function noh = getNoh(self,varargin)
              nInput = length(varargin);              
              if(nInput==1)
                noh = self.listaNohs{varargin{1}}; % (idNoh)
              elseif (nInput==2)
                noh = self.listaNohs{self.idPair2idNoh(varargin{1},varargin{2})};   % (idArvore,idBloco)
              else
                disp('Numero inválido de input')
              end
          end
          
          % Dado o nó na forma (arvore,bloco) e o swithPath descobre o proximo nó
          % A resposta idArvore = 0 indica que o noh atual não possui o
          % swithpath escolhido
          function [idArvore_proximo, idBloco_proximo] = proximoNoh(self, idArvore_atual, idBloco_atual, swithPath)
              
              % Coleta o 'sink' correspondente ao nó atual ao swithPath
              if swithPath == 1
                proximoId = self.listaNohs(self.idPair2idNoh(idArvore_atual,idBloco_atual)).sink1;
              else
                proximoId = self.listaNohs(self.idPair2idNoh(idArvore_atual,idBloco_atual)).sink2;
              end
                            
              % Se o valor do sink for positivo, ele representa o idBloco
              % do proximo nó e este nó pertence a mesma arvore que o nó
              % atual.
              % Se o valor do sink for negativo, ele representa o oposto do 
              % proximo idNoh e este nó pertencera a uma nova arvore.              
              if proximoId > 0 
                  idArvore_proximo = idArvore_atual;
                  idBloco_proximo = proximoId;
              elseif proximoId < 0              
                  if(self.listaNohs(-proximoId).tipo ~= model.NohModelo.RAIZ)
                      idArvore_proximo = self.listaNohs(-proximoId).idArvore;
                      idBloco_proximo = self.listaNohs(-proximoId).idBloco;
                  else
                      % O nó do tipo raiz é apenas um encontro de varias
                      % entradas, para trasformar o nó Raiz para um nó
                      % 'funcional' basta acessar a informação que está contida
                      % em sink 1, que irá redirecionar para o proximo nó
                      % funcional.
                      idArvore_proximo = self.listaNohs(-proximoId).idArvore;
                      idBloco_proximo = self.listaNohs(-proximoId).sink1;
                  end
                  
              else
                  %idArvore = 0 significa que não existe respectivo swithPath
                  idArvore_proximo = 0; 
                  idBloco_proximo = 0 ;
              end
                  
                 
                  
          end %proximo noh
          
          % Dado o nó na forma (arvore,bloco) verifica qual o proximo bloco
          % de acordo.
          % A procura do proximo bloco de acordo leva em consideração
          % apenas o idnoh e não os caminhos.
          function [idArvore,idBloco] = proximoAcordo(self, idArvore_atual, idBloco_atual)
              idNoh = self.idPair2idNoh(idArvore_atual,idBloco_atual);
              while(self.listaNohs(idNoh).tipo~=model.NohModelo.ACORDO)
                  idNoh = idNoh+1;
              end
              idArvore = self.listaNohs(idNoh).idArvore;
              idBloco = self.listaNohs(idNoh).idBloco;              
          end  
          
     end %methods
    
end %classdef

