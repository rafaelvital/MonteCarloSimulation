classdef NohModelo < handle
    % NohModelo: Nó da arvore de rito processual
    
    properties
        
        id  
        idArvore
        idBloco
        tipo % controle(controle), acordo(externo), outro(externo), raiz
        tipoBloco% acordo, decisão_judicial, recurso, outro
        
        sink1 %"id" do proximo bloco caso o swithpath=1
        sink2 %"id" do proximo bloco caso o swithpath=2
        
        tipoSink1 %ACORDO, EXECUCAO, CONDENACAO, JULGAMENTO_*, COMUM
        tipoSink2
		secao
    end
    
    properties (Constant)
        CONTROLE = 5
        ACORDO = 1
        FOLHA = 7
        RAIZ = 6
        OUTRO = 4
        RECURSO = 2
        DECISAO_JUDICIAL = 3
        EXITO = 8
        EXECUCAO = 9
        CONDENACAO = 10
        JULGAMENTO_1 = 11
        JULGAMENTO_2a = 12
        JULGAMENTO_2b = 13
        JULGAMENTO_3a = 14
        JULGAMENTO_3b = 15
        JULGAMENTO_2a_EXECUCAO = 16
        JULGAMENTO_2b_EXECUCAO = 17
        COMUM = 18;
        JULGAMENTO_1a = 19
        JULGAMENTO_1b = 20        
        JULGAMENTO_4a = 21
        JULGAMENTO_4b = 22
    end
    
    methods
        
        %
        function self = NohModelo(id, idArvore, idBloco, tipo, tipoBloco, sink1, sink2, tipoSink1, tipoSink2,secao)
            
            self.id = id;
            self.idArvore = idArvore;
            self.idBloco = idBloco;
            self.tipo = self.str2Const(tipo);
            self.tipoBloco = self.str2Const(tipoBloco);
            self.sink1 = sink1;
            self.sink2 = sink2;
            self.tipoSink1 = self.str2Const(tipoSink1);
            self.tipoSink2 = self.str2Const(tipoSink2);
			self.secao = secao;
            
        end %constructor
        
        % Baseado na propriedadas constantes do NohModelo traduz string para
        % constante
        function const = str2Const(self,str)
            if( isnan(str))
                const = self.COMUM;
            elseif( strcmp(str,'CONTROLE'))
                const = self.CONTROLE;
            elseif( strcmp(str,'ACORDO'))
                const = self.ACORDO;
            elseif( strcmp(str,'FOLHA'))
                const = self.FOLHA;
            elseif( strcmp(str,'RAIZ'))
                const = self.RAIZ;
            elseif( strcmp(str,'OUTRO'))
                const = self.OUTRO;
            elseif( strcmp(str,'RECURSO'))
                const = self.RECURSO;
            elseif( strcmp(str,'DECISAO_JUDICIAL') || strcmp(str,'DECISAO JUDICIAL'))
                const = self.DECISAO_JUDICIAL;
            elseif( strcmp(str,'EXITO'))
                const = self.EXITO;
            elseif( strcmp(str,'EXECUCAO'))
                const = self.EXECUCAO;
            elseif( strcmp(str,'CONDENACAO'))
                const = self.CONDENACAO;
            elseif( strcmp(str,'JULGAMENTO_1'))
                const = self.JULGAMENTO_1;
            elseif( strcmp(str,'JULGAMENTO_2a'))
                const = self.JULGAMENTO_2a;
            elseif( strcmp(str,'JULGAMENTO_2b'))
                const = self.JULGAMENTO_2b;
            elseif( strcmp(str,'JULGAMENTO_3a'))
                const = self.JULGAMENTO_3a;
            elseif( strcmp(str,'JULGAMENTO_3b'))
                const = self.JULGAMENTO_3b;
            elseif( strcmp(str,'JULGAMENTO_2a_EXECUCAO'))
                const = self.JULGAMENTO_2a_EXECUCAO;
            elseif( strcmp(str,'JULGAMENTO_2b_EXECUCAO'))
                const = self.JULGAMENTO_2b_EXECUCAO;
            elseif( strcmp(str,'JULGAMENTO_1a'))
                const = self.JULGAMENTO_1a;
            elseif( strcmp(str,'JULGAMENTO_1b'))
                const = self.JULGAMENTO_1b;
            elseif( strcmp(str,'JULGAMENTO_4a'))
                const = self.JULGAMENTO_4a;
            elseif( strcmp(str,'JULGAMENTO_4b'))
                const = self.JULGAMENTO_4b;
            else
                disp('String de tipo não reconhecido')
            end
        end %str2const
        
        
    end %methods
    
end