classdef mapaNos < handle
    
    properties
        custo
        tempo
        nProcesso
    end
    
    methods
        
        function self = mapaNos(nProcesso)
            self.nProcesso = nProcesso;
            self.custo = cell(nProcesso,1);
            self.tempo = cell(nProcesso,1);
%             for i=1:nProcesso
%                  self.custo{i} = sparse(206,106);
%                  self.tempo{i} = sparse(206,106);
%             end
        end
        
    end
    
end