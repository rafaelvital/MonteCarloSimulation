function confereCondenacao(resultSimulation,historico)

    confere = true;
    dataCarteira = resultSimulation.inputLogs.data;
    juros = resultSimulation.inputLogs.juros;
    
    dataDistribuicao = zeros(resultSimulation.nProcesso,1);
    cm = zeros(resultSimulation.nProcesso,1);
    pedmatrix = zeros(resultSimulation.nProcesso,resultSimulation.nPedido);
    for iProcesso=1:resultSimulation.nProcesso
        dataDistribuicao(iProcesso) = resultSimulation.carteiraInicial.processos{iProcesso}.data_distribuicao;
        cm(iProcesso) = resultSimulation.carteiraInicial.processos{iProcesso}.cmonetaria;
        pedmatrix(iProcesso,:) = resultSimulation.carteiraInicial.processos{iProcesso}.pedidos';
    end
    difData = (dataCarteira-dataDistribuicao)/30;
    
    for iSim=1:resultSimulation.nSim
        for iProcesso=1:resultSimulation.nProcesso
            % Se encerrado por condenação             
            if(resultSimulation.individuaisTipoEncerramento{iSim}(iProcesso,2) == 2)
                tempo = resultSimulation.individuaisTipoEncerramento{iSim}(iProcesso,1)+difData(iProcesso);
                %  define o fatorMulta   
                fatorMulta = 1;
                if(resultSimulation.inputLogs.aplicarMulta)
                    if(resultSimulation.carteiraInicial.processos{iProcesso}.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_trab)
                        if(sum(ismember(historico{iSim}{iProcesso}(:,2:3),[101 5],'rows')))
                            fatorMulta = 1.1;
                        end
                    end
                    if(resultSimulation.carteiraInicial.processos{iProcesso}.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel)
                        if(sum(ismember(historico{iSim}{iProcesso}(:,2:3),[101 4],'rows')))
                            fatorMulta = 1.1;
                        end
                    end
                end
                
                fatorSucumbencia = 1;
                if(resultSimulation.inputLogs.honorarioSucumbencia == 1)
                    if(resultSimulation.carteiraInicial.processos{iProcesso}.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_civel || ...
                       resultSimulation.carteiraInicial.processos{iProcesso}.arvoreModelo.tipoModelo == model.ArvoreModelo.tipo_jec)
                        if(sum(ismember(historico{iSim}{iProcesso}(:,2:3),[101 1],'rows')))
                            fatorSucumbencia = 1.1;
                        end
                    end
                end
                
                pedidosCondenados = zeros(1,resultSimulation.nPedido);
                
                %4 indef
                vetorLogico = resultSimulation.estado4JulgaInd{iSim}(iProcesso,:) ~= 0;
                vetorLogicoAcc = vetorLogico;
                pedidosCondenados(vetorLogico) = resultSimulation.estado4JulgaInd{iSim}(iProcesso,vetorLogico)-1;
                
                %4 def
                vetorLogico = ~vetorLogicoAcc & resultSimulation.estado4JulgaDef{iSim}(iProcesso,:) ~= 0;
                vetorLogicoAcc = vetorLogicoAcc | vetorLogico;
                pedidosCondenados(vetorLogico) = resultSimulation.estado4JulgaDef{iSim}(iProcesso,vetorLogico)-1;
                
                %3 indef
                vetorLogico = ~vetorLogicoAcc & resultSimulation.estado3JulgaInd{iSim}(iProcesso,:) ~= 0;
                vetorLogicoAcc = vetorLogicoAcc | vetorLogico;
                pedidosCondenados(vetorLogico) = resultSimulation.estado3JulgaInd{iSim}(iProcesso,vetorLogico)-1;
                
                %3 def
                vetorLogico = ~vetorLogicoAcc & resultSimulation.estado3JulgaDef{iSim}(iProcesso,:) ~= 0;
                vetorLogicoAcc = vetorLogicoAcc | vetorLogico;
                pedidosCondenados(vetorLogico) = resultSimulation.estado3JulgaDef{iSim}(iProcesso,vetorLogico)-1;
                
                %2 indef
                vetorLogico = ~vetorLogicoAcc & resultSimulation.estado2JulgaInd{iSim}(iProcesso,:) ~= 0;
                vetorLogicoAcc = vetorLogicoAcc | vetorLogico;
                pedidosCondenados(vetorLogico) = resultSimulation.estado2JulgaInd{iSim}(iProcesso,vetorLogico)-1;
                
                %2 def
                vetorLogico = ~vetorLogicoAcc & resultSimulation.estado2JulgaDef{iSim}(iProcesso,:) ~= 0;
                vetorLogicoAcc = vetorLogicoAcc | vetorLogico;
                pedidosCondenados(vetorLogico) = resultSimulation.estado2JulgaDef{iSim}(iProcesso,vetorLogico)-1;
                
                % 1              
                vetorLogico = ~vetorLogicoAcc & resultSimulation.estado1Julga{iSim}(iProcesso,:) ~= 0;
                vetorLogicoAcc = vetorLogicoAcc | vetorLogico;
                pedidosCondenados(vetorLogico) = resultSimulation.estado1Julga{iSim}(iProcesso,vetorLogico)-1;
                  
                pedidosCondenados(~vetorLogicoAcc) = resultSimulation.carteiraInicial.processos{iProcesso}.pedidos_deferidos(~vetorLogicoAcc);
                
                valorCondenacadoCalculado = fatorSucumbencia*fatorMulta*sum(pedmatrix(iProcesso,:).*pedidosCondenados).*(1+juros*(tempo)).*(1+cm(iProcesso)).^(tempo);

                
                if(abs(valorCondenacadoCalculado-resultSimulation.individuaisCondenacoes{iSim}(iProcesso,3)) > 0.01)
                    disp(['Processo ' num2str(iProcesso) ' da simulação ' num2str(iSim) 'não confere']);
                    confere = false;
                end
            end
        end
    end
    
    if(confere)
        disp('Todas as condenações conferem');
    end
end