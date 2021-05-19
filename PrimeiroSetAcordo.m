classdef PrimeiroSetAcordo
    
    properties        
        valorAcordo
        percentualValorAcordo
        esperadoNaoAcordo
        composicaoEsperadoNaoAcordo
        
        probAcordo
        probAcordoDadoAnteriorFalhou        
        probFecharExatamenteNesimoAcordo
        
        probNaofecharAcordo
        fval
    end
    
     methods
        
        %Construtor
        function self = PrimeiroSetAcordo()
            self.valorAcordo = zeros(4,1);
            self.percentualValorAcordo = zeros(4,1);
            self.esperadoNaoAcordo = 0;
            self.composicaoEsperadoNaoAcordo = zeros(6,1);
            
            self.probAcordo= zeros(4,1);
            self.probAcordoDadoAnteriorFalhou = zeros(4,1);
            self.probFecharExatamenteNesimoAcordo= zeros(4,1);
            
            self.probNaofecharAcordo = 1;
            self.fval = 0;
        end
     end
    
    
end