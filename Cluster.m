classdef Cluster < handle
    %CLUSTER Guarda as informações relevantes de cada um dos cluster / UF
    
    properties
        
        id %id do cluster
        curva_acordo %cell da forma (idArvore,idBloco)
        
        % onde cada cedula contem uma matrix bidmensional da  forma [percAcordo probAcordo] 
        prob_aresta %array com 0,1 ou 2 campos que indicam a probabilidade de cada swithpah
        tempo_aresta %matriz da forma (idArvore,idBloco,swithpath) que representa o tempo aresta entre os blocos
        
        distribuicao %cell da forma (idArvore,idBloco,swithpath) que representa
                     % a distribuição do tempo aresta entre os blocos
        distEmbargo %cell da forma (idArvore,idBloco) que representa
                    %a distribuição do embargo do nó especificado
        tempoEmbargo %matriz da forma (idArvore,idBloco,swithpath)
        probEmbargo %matriz da forma (idArvore,idBloco) que indica 
                    %a probabilide de embargo do nó especificado
                    
        curvaA
        curvaB
                    
    end
    
    properties (Constant)
        % Distribuição da pericia
        distPericia = makedist('Triangular', 'a', 2000, 'b', 2500, 'c', 3000);
    end
    
end