#!/bin/bash
#  Script criado por Vinicius Vale - 30/11/2015
#  Lê um DUMP (COPY) postgresql e faz o embaralhamento de alguns campos definidos em arquivo anexo


# O arquivo ofuscador deve conter o nome da tabela seguido pelo nome do campo
#  Ex: pessoal.cpf
# cada linha deve conter um tabela.campo


# Verifica quantidade de argumentos
if [ $# -lt 2 ]; then
   echo "$0 <DUMP>  <ofuscador>"
   exit 1
fi

# Arquivo de DUMP
DUMP=$1
echo -e "Local do arquivo de DUMP: $1"

# Arquivo de ofuscacao tabela.campo
OFUSCADORES=$2
echo -e "Arquivo ofuscador: $2"
 
#Local do novo arquivo gerado
NEW=$PWD/dump_shuffle

#Limpando Arquivo
echo '' > $NEW

# Variavel para identificar modificacoes
ENTROU=false
POS_CAMPO=0
POS=0
VECTOR=()

# Lê todo o arquivo de DUMP linha a linha
while read line 
do  
	# Armazena o nome da tabela	
	TABLE=$(echo -e "$line" | cut -f2 -d' ')
	#echo -e "Tabela $TABLE encontrada."

	# Verifica se o inicio da linha começa com COPY
	if [ "COPY" = "$(echo -e "$line" | cut -f1 -d' ')" ]
	then
		ENTROU=true
		VECTOR=()

		# Lê todo o arquivo ofuscadores linha a linha
		while read ofuscador
		do
			# Pega a tabela que será ofuscada
			TABLE_OFUSCADOR=$(echo -e "$ofuscador" | cut -f1 -d.)

			# Verifica se a linha do arquivo contém 
			# o nome da tabela que será ofuscada
			if [ "$TABLE" = "$TABLE_OFUSCADOR" ]
			then
			    	# Pega o nome do campo a ser ofuscado
				CAMPO_OFUSCADO=$(echo -e "$ofuscador" | cut -f2 -d.)	
				
				# Pega todos os campos da tabela
				CAMPOS=$( echo -e "$line" | grep -o '(.*)' | grep -o '(.*)' | tr '(' ' ' | tr ')' ' ' | tr ',' '\n')
				
				# reinicia o contador da posição do campo				
				POS_CAMPO=0

				#Laço para identificar a posicao do campo
				for i in $CAMPOS
				do
					# Verifica se o campo é será campo_ofuscado
					if [ "$i" = "$CAMPO_OFUSCADO" ]
					then
						VECTOR+=("$POS_CAMPO")
						echo -e "Tabela $TABLE_OFUSCADOR - Campo: $CAMPO_OFUSCADO"
					fi
					let "POS_CAMPO++"
				done		
			fi
		# Deixa o arquivo ordenado por tabela,campo
		done < $( echo -e "$OFUSCADORES" | sort )
		
		# Verifica se a tabela tem campos a serem embralhadados
		# caso 
		if ! [ ${#VECTOR} -gt 0 ] 
		then
			echo -e "Tabela $TABLE não será embaralhada"
			ENTROU=false
		fi

		echo -e "$line" >> $NEW
	else
		# Verifica se acabou de ofuscar dados na tabela com \.
		if [ "." = "$(echo -e "$line" | cut -f1 -d' ')" ]
		then
			ENTROU=false
			#echo -e "Embaralhamento concluído." 
			# Deve se definir o \\ para que o mesmo seja colocado no final do COPY
			echo -e "\\$line" >> $NEW
		else	
			# Verifica se está na linha com os dados que podem ser embaralhados		
			if [ $ENTROU = true ]
			then
				POS=0
				READY_LINE=()

				# Pega campo por campo da linha
				for dado in $line
				do
					# Verifica a posica do campo com a posicao a ser embaralhada
					LIMITE=false
					for campo in "${VECTOR[@]}"; 
					do
						
						# Verifica se a posicao é a mesma posicao do campo
						if [ $POS = $campo ]
						then
							LIMITE=true
							VECT_LETRA=()
							
							# loop para pegar letra por letra
							for letra in $(seq 1 ${#dado})
							do
								WORD=$( echo -e "$dado" | cut -b "$letra" )
								VECT_LETRA+=("$WORD")
							done
							# RANDOM na palavra							
							# $RANDOM % (i+1) is biased because of the limited range of $RANDOM
							# Compensate by using a range which is a multiple of the array size.
							size=${#VECT_LETRA[*]}
							max=$(( 32768 / size * size ))

							for ((i=size-1; i>0; i--)); do
							   while (( (rand=$RANDOM) >= max )); do :; done
							   rand=$(( rand % (i+1) ))
							   tmp=${VECT_LETRA[i]} VECT_LETRA[i]=${VECT_LETRA[rand]} VECT_LETRA[rand]=$tmp
							done
							
							# Adiciona campo dentro de um array
							NEW_FIELD=$(echo -e "${VECT_LETRA[@]}" | sed 's/ //g' )
							READY_LINE+=("$NEW_FIELD")
						fi
					done	
					# Verifica se o LIMITE não foi atingido
					if [ $LIMITE = false ]
					then						
						# Adiciona campo dentro de um array		
						READY_LINE+=("$dado")
					fi				
					let "POS++"
				done
				# Salva os campos adicionando a tabulação dentro do arquivo
				echo -e "${READY_LINE[@]}" | sed 's/ /'$'\t''/g' >> $NEW
			else
				echo -e "$line" >> $NEW
			fi
		fi
	fi
done < $DUMP

echo -e "Embaralhamento FINALIZADO"
echo -e "Arquivo criado: $NEW"


unset VECTOR
