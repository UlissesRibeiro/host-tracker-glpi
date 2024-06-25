#!/bin/bash

# Definindo o número máximo de IDs
max_id=40
output_file="/vox/phpmailer/computers_inativo.txt"

# Inicialize o arquivo de saída
> $output_file

# Iterando sobre os IDs de 0 a max_id
for id in $(seq 0 $max_id); do
    # Fazendo a solicitação para cada computador individualmente
    response=$(curl -s -X GET \
        -H 'Content-Type: application/json' \
        -H "Session-Token: jue05m7jsd1r6moflvp0tcv5l4" \
        -H "App-Token: b7GsHjO6spac0nKHXzq8cxyGe8YjkUGvpi5mTaPI" \
        "http://10.0.10.224:8030/apirest.php/Computer/$id?expand_dropdowns=true")

    # Verificando se a solicitação retornou algo válido
    if [[ $? -ne 0 || -z $response ]]; then
        echo "Erro ao recuperar dados para o computador ID $id"
        continue
    fi

    # Filtrando os campos desejados com jq
    name=$(echo $response | jq -r '.name')
    state_id=$(echo $response | jq -r '.states_id')

    # Checando se o estado é 'Agent_Desconectado'
    if [[ $state_id == "Inativo" ]]; then
        # Se sim, adicionar ao arquivo de texto
        echo "{name: \"$name\", states_id: \"$state_id\"}" >> $output_file
    fi
done

echo "Computadores com estado 'Inativo' foram salvos no arquivo: $output_file"

