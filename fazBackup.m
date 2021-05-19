function fazBackup(nome,dirOrigem,dirDestino,apagar)
%  model.fazBackup('testeResult_0','C:/optimum/backUp',pwd,0)

% verifica se o diretorio destino j� existe e cria o logSimula��o caso n�o
% exista
if(~exist(dirDestino,'dir'))
    mkdir(dirDestino);
end
xlswrite([dirDestino '/logSimula��o.xlsx'],{'Nome','Descri��o'});

% verifica se existe o arquivo no destino
continua = true;
if(exist([dirDestino '/' nome '.mat'],'file'))
    continua = input('J� existe um arquivo com o mesmo nome no destino. Deseja continuar (1-sim/0-n�o) \n');
end

if(continua)
    % Carrega o log que vai ser feito o backup
    load([dirOrigem '/' nome]);
    
    % copia diretorio
    for i=1:size(resultSimulation.listaDiretorios)
        copyfile([dirOrigem '/' resultSimulation.listaDiretorios{i}],[dirDestino '/' resultSimulation.listaDiretorios{i}]);
    end
    copyfile([dirOrigem '/' nome '.mat'],[dirDestino '/' nome '.mat'],'f');
    
    % Adiciona o log no inputlog de destino
    [~,~,raw] = xlsread([dirDestino '\logSimula��o']);
    nLinhas = size(raw,1);
    idx = find(ismember(raw(1:end,1), nome),1);
    if(isempty(idx))
        raw{nLinhas+1,1} = nome;
        raw{nLinhas+1,2} = resultSimulation.descricao;
    else
        raw{idx,2} = resultSimulation.descricao;
    end
    xlswrite([dirDestino '/logSimula��o.xlsx'],raw);
    disp('Backup concluido');
    
    if(apagar)
        if(strcmp(dirOrigem,pwd))
            resultSimulation.apaga();
            disp('Simula��o original apagada');
        else
            disp('Simula��o original n�o foi apagada, essa op��o s� esta disponivel quando dirOrigem � igual ao diretorio raiz(pwd)');
        end
    end
else
    disp('N�o foi realizado o backup');
end

end