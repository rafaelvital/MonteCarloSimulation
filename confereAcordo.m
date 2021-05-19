function confereAcordo(resultSimulation,historicoAcordo)

numeroAcordosConsiderar = 3;
% Consideramos apenaas as tres primeiras proposta de acordo, se
% considerarmos todos, além de passamos pelo julgamento que altera o
% percentual minimo de acordo, estaremos coletando informações apenas dos
% reclamantes que tem não aceitaram o primeiro set, logo, os reclamantes
% que são mais dificeis de fazer acordo.
acordosPropostosCon = [];
acordosAceitosCon = [];
acordosPropostosRec = [];
acordosAceitosRec = [];
acordosPropostosEx = [];
acordosAceitosEx = [];

for iSim=1:resultSimulation.nSim
    for iProcesso=1:resultSimulation.nProcesso
        histAcc = historicoAcordo{iSim}{iProcesso};
        %         for iHist=1:size(histAcc,1)
        
        for iHist=1:min(numeroAcordosConsiderar,size(histAcc,1))
            if(histAcc(iHist,1) == 1)
                acordosPropostosCon(end+1,1) = histAcc(iHist,3);
                if(histAcc(iHist,5)) %condições 1,2 e 3 (Aceito, acima do aceito, não feito devido ao budget)
                    acordosAceitosCon(end+1,1) = histAcc(iHist,3);
                end
            elseif(histAcc(iHist,1) < 100)
                acordosPropostosRec(end+1,1) = histAcc(iHist,3);
                if( histAcc(iHist,5)) %condições 1,2 e 3 (Aceito, acima do aceito, não feito devido ao budget)
                    acordosAceitosRec(end+1,1) = histAcc(iHist,3);
                end
            else
                acordosPropostosEx(end+1,1) = histAcc(iHist,3);
                if( histAcc(iHist,5)) %condições 1,2 e 3 (Aceito, acima do aceito, não feito devido ao budget)
                    acordosAceitosEx(end+1,1) = histAcc(iHist,3);
                end
            end
        end
    end
end

%curva de acordo de conhecimento
curvaCon = resultSimulation.carteiraInicial.processos{1}.curvas.curva_acordo{1,2};
curvaRec = resultSimulation.carteiraInicial.processos{1}.curvas.curva_acordo{4,2};
curvaEx = resultSimulation.carteiraInicial.processos{1}.curvas.curva_acordo{101,6};


%Cria histograma
[histPropostoCon,binCon] = hist(acordosPropostosCon,50);
[histAceitoCon] = hist(acordosAceitosCon,binCon);
[histPropostoRec,binRec] = hist(acordosPropostosRec,50);
[histAceitoRec] = hist(acordosAceitosRec,binRec);
[histPropostoEx,binEx] = hist(acordosPropostosEx,50);
[histAceitoEx] = hist(acordosAceitosEx,binEx);

curvaConBin = interp1(curvaCon(:,1),curvaCon(:,2), binCon);
curvaRecBin = interp1(curvaRec(:,1),curvaRec(:,2), binRec);
curvaExBin = interp1(curvaEx(:,1),curvaEx(:,2), binEx);

%Retira os bins que não foram usados
acordosNaoOferecidosCon = histPropostoCon == 0;
histPropostoCon(acordosNaoOferecidosCon) = [];
histAceitoCon(acordosNaoOferecidosCon) = [];
binConOferecido = binCon;
binConOferecido(acordosNaoOferecidosCon) = [];

acordosNaoOferecidosRec = histPropostoRec == 0;
histPropostoRec(acordosNaoOferecidosRec) = [];
histAceitoRec(acordosNaoOferecidosRec) = [];
binRecOferecido = binRec;
binRecOferecido(acordosNaoOferecidosRec) = [];

acordosNaoOferecidosEx = histPropostoEx == 0;
histPropostoEx(acordosNaoOferecidosEx) = [];
histAceitoEx(acordosNaoOferecidosEx) = [];
binExOferecido = binEx;
binExOferecido(acordosNaoOferecidosEx) = [];

figure;
if(~isempty(histAceitoCon))
    plot(binConOferecido,histAceitoCon./histPropostoCon,binCon,curvaConBin);
end
legend('Simulada','excel');
title('Curva conhecimento');


figure;
if(~isempty(histAceitoRec))
    plot(binRecOferecido,histAceitoRec./histPropostoRec,binRec,curvaRecBin);
end
legend('Simulada','excel');
title('Curva recursal');

figure;
if(~isempty(histAceitoEx))
    plot(binExOferecido,histAceitoEx./histPropostoEx,binEx,curvaExBin);
end
legend('Simulada','excel');
title('Curva Execução');

disp('Confira visualmente as curvas de acordo');


end
