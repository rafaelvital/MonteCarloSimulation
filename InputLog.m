classdef InputLog
    %InputLog: Objeto que contem os parametros de simulação.
    
    properties
        
        modeloArvore
		nomeCarteira
        
        simuTrab
        inputsTrab
        grafosTrab
        curvasTrab
        
        simuCivel
        inputsCivel
        grafosCivel
        curvasCivel
        
        simuJec
        inputsJec
        grafosJec
        curvasJec
        
        tsim
        nProcesso
        nPedido
        
        classeProcesso
        
        data  
        
        filtroJulgamento
        honorarioSucumbencia        
        isDataPedMatrixDataDistribuicao
        isTimeRand        
        usarIndicesCM
        arquivoIndiceCM
        isCurvasDiferentesEmCadaBloco
        ordenarGanhoEsperado
        naoPagaCondenacao
        recorreJulgamentoExecucao
        decideRecorrer
        aplicarMulta
        
        juros
        jam
        taxaDescontoAnual
        taxaDescontoMensal
        tr
        tc
        
        budgetVector
        contribuidoresBudget
        capacity
        parametrosEspecificos
        
        execucao_provisoria_port
        fatorGetEsperado
        passoCurvaAcordo
        
    end
    
end