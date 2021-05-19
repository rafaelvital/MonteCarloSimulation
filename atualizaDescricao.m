function atualizaDescricao()
    [~,~,raw] = xlsread('logSimulação.xlsx');
    
    for iLinha=2:size(raw,1)
        load(raw{iLinha,1});
        if(~strcmp(resultSimulation.descricao,raw{iLinha,2}))
            resultSimulation.descricao = raw{iLinha,2};
            if(strcmp(resultSimulation.complemento,''))
                nomeSim =  [resultSimulation.name '_' resultSimulation.estrategia];
            else
                nomeSim = [resultSimulation.name '_' resultSimulation.estrategia '_' resultSimulation.complemento];
            end
            save(nomeSim,'resultSimulation');
        end            
    end    
end