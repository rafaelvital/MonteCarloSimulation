function confereSimulacao(nome,acordo)

    load(nome);
    load(['resultado\historico\historico_' nome]);
    model.confereCondenacao(resultSimulation,historico);
    
    if(acordo)
        load(['resultado\historicoAcordo\historicoAcordo_' nome]);
        model.confereAcordo(resultSimulation,historicoAcordo);
    end
    
end