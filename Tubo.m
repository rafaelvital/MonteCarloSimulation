function Tubo( x, Dados )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%percentis padroes que plotamos
percentis=[0 10 25 50 75 90 100];


%calcular os percentis (obviamente modificar aqui)
faixas=prctile(Dados',percentis);


% figure
%o grafico de area plota incremental, como queremos usar ele, mas não incremental, fazemos o caminho inverso antes
%h armazena um handle para cada área plotada
h=area(x, [faixas(1,:);diff(faixas)]');

%aqui uma matriz de Nx3 para N cores (RGB) no caso, [1 1 1] é porque estamos usando tons de cinza
%[1 1 1] é branco, [0 0 0] é preto, k*[1 1 1] com k entre ]0,1[ é cinza
%se mudar o número de percentis, mude as cores de acordo aqui
%se quiser mudar as cores, mude aqui que fica mais organizado
cores=[1 .9 .8 .6 .6 .8 .9]'*[1 1 1];

%apagar primeira área pois não é de nosso interesse, nos interessamos somente pelas áreas entre as curvas
set(h(1),'Visible','off')

%para todas outras áreas, colocamos as cores de acordo
for i=2:length(percentis)
set(h(i),'FaceColor',cores(i,:))
end 

end

