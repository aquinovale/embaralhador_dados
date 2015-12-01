# Embaralhador de Dados para Postgresql
Este é um shell script que tem como objetivo embaralhar alguns campos das tabelas.


### Fazendo o embaralhamento
```
./ofuscador.sh arquivo_DUMP arquivo_ofuscador
```


### ARQUIVO DUMP
O arquivo de dump deve ser um dump simples feito pelo POSTGRESQL de versão 8.4 a 9.5, 
dump's que contiverem comando INSERT em vez do COPY não funcionarão


### ARQUIVO OFUSCADOR
O arquivo ofuscador é basicamente um arquivo com tabela.campo
Ex.: clientes.cpf

Caso a tabela esteja definida com Maiuscula, então deve se usar aspas duplas
Ex.: "Pessoas".cpf
Ex.: "Pessoas"."CPF"


### ARQUIVO dump_shuffle
O arquivo dump_shuffle será criado no diretório de execução do script.
O procedimento de restore é o mesmo.




















