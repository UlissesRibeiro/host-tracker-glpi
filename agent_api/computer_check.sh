##script para fazer a primeira coleta original

#!/bin/bash

# Definindo o número máximo de IDs
max_id=60
output_file="computers_check.json"

# Inicialize o arquivo de saída
echo "[" > $output_file

# Iterando sobre os IDs de 0 a max_id
for id in $(seq 0 $max_id); do
    # Coletando informações básicas do computador
    response=$(curl -s -X GET \
        -H 'Content-Type: application/json' \
        -H "Session-Token: jue05m7jsd1r6moflvp0tcv5l4" \
        -H "App-Token: b7GsHjO6spac0nKHXzq8cxyGe8YjkUGvpi5mTaPI" \
        "http://10.0.10.224:8030/apirest.php/Computer/$id?expand_dropdowns=true")

    if [[ $? -ne 0 || -z $response ]]; then
        echo "Erro ao recuperar dados para o computador ID $id"
        continue
    fi

    name=$(echo $response | jq -r '.name')
    states_id=$(echo $response | jq -r '.states_id')
    serial=$(echo $response | jq -r '.serial')
    computertypes_id=$(echo $response | jq -r '.computertypes_id')
    computertype_name=$(echo $response | jq -r '.computertype_name')  # Nome do tipo de computador

    # Verificando se o estado é "Ativo"
    if [[ $states_id != "Ativo" ]]; then
        continue
    fi

    # Verificando se o tipo de computador é "VMware" ou contém "esxi"
    if [[ $computertype_name == "VMware" || "$name" == *"esxi"* || "$name" == *"localhost"* || "$computertype_name" == *"esxi"* ]]; then
        continue
    fi

    # Coletando informações da memória
    memory_response=$(curl -s -X GET \
        -H 'Content-Type: application/json' \
        -H "Session-Token: jue05m7jsd1r6moflvp0tcv5l4" \
        -H "App-Token: b7GsHjO6spac0nKHXzq8cxyGe8YjkUGvpi5mTaPI" \
        "http://10.0.10.224:8030/apirest.php/Computer/$id/Item_DeviceMemory/")

    memory_info=$(echo $memory_response | jq '[.[] | {size: .size, serial: .serial}]')

    # Coletando informações do HD
    hd_response=$(curl -s -X GET \
        -H 'Content-Type: application/json' \
        -H "Session-Token: jue05m7jsd1r6moflvp0tcv5l4" \
        -H "App-Token: b7GsHjO6spac0nKHXzq8cxyGe8YjkUGvpi5mTaPI" \
        "http://10.0.10.224:8030/apirest.php/Computer/$id/Item_DeviceHardDrive/")

    hd_info=$(echo $hd_response | jq '[.[] | {id: .id, capacity: .capacity, serial: .serial}]')

    # Construindo o JSON final para este computador
    computer_info=$(jq -n \
        --arg name "$name" \
        --arg states_id "$states_id" \
        --arg serial "$serial" \
        --arg computertypes_id "$computertypes_id" \
        --argjson memory_info "$memory_info" \
        --argjson hd_info "$hd_info" \
        '{name: $name, states_id: $states_id, serial: $serial, computertypes_id: $computertypes_id, memory: $memory_info, hard_drives: $hd_info}')

    # Adicionando a informação ao arquivo de saída
    echo "$computer_info," >> $output_file
done

# Removendo a última vírgula e fechando o JSON array
truncate -s-2 $output_file
echo "]" >> $output_file

echo "Inventário dos computadores ativos (excluindo VMware e esxi) foi salvo no arquivo: $output_file"

