function fazBackup(nome,dirOrigem,dirDestino,apagar)
%  model.fazBackup('testeResult_0','C:/optimum/backUp',pwd,0)

% verifica se o diretorio destino já existe e cria o logSimulação caso não
% exista
if(~exist(dirDestino,'dir'))
    mkdir(dirDestino);
end
xlswrite([dirDestino '/logSimulação.xlsx'],{'Nome','Descrição'});

% verifica se existe o arquivo no destino
continua = true;
if(exist([dirDestino '/' nome '.mat'],'file'))
    continua = input('Já existe um arquivo com o mesmo nome no destino. Deseja continuar (1-sim/0-não) \n');
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
    [~,~,raw] = xlsread([dirDestino '\logSimulação']);
    nLinhas = size(raw,1);
    idx = find(ismember(raw(1:end,1), nome),1);
    if(isempty(idx))
        raw{nLinhas+1,1} = nome;
        raw{nLinhas+1,2} = resultSimulation.descricao;
    else
        raw{idx,2} = resultSimulation.descricao;
    end
    xlswrite([dirDestino '/logSimulação.xlsx'],raw);
    disp('Backup concluido');
    
    if(apagar)
        if(strcmp(dirOrigem,pwd))
            resultSimulation.apaga();
            disp('Simulação original apagada');
        else
            disp('Simulação original não foi apagada, essa opção só esta disponivel quando dirOrigem é igual ao diretorio raiz(pwd)');
        end
    end
else
    disp('Não foi realizado o backup');
end

end