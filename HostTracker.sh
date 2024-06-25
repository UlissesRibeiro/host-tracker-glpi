#!/bin/bash

################################################################################
# Script Name: HostTracker.sh
# Description: Script para automatizar a adição de hosts SNMP e ESXi ao GLPI Inventory.
# Version: 0.1
# Author: Ulisses 'Stark' Gomes Ribeiro
#
# Não consegui de forma nativa fazer essa coleta, então optei por criar o scritp
# Capaz de adicionar os hosts de forma manual.
#
# Este script é distribuído sob a licença MIT. Consulte o arquivo LICENSE para mais detalhes.
#
################################################################################

#agents : https://github.com/glpi-project/glpi-agent/releases
#docker : https://hub.docker.com/r/diouxx/glpi/tags
#
# Os pacotes baixo são necessário para poder adicionar dispositivos via SNMP e ESXi
#- glpi-netdiscovery
#- glpi-netinventory
#- glpe-exs(para ESX/ESXi)

ROOT_DIR="/hosttracker"

if [ "$EUID" -ne 0 ]; then
    echo "Este script precisa ser executado como root."
    exit 1
fi

agent="/usr/bin/dialog"

if [ -e "$agent" ]; then
        echo "Instalado"
else
    apt install dialog -y
fi

echo "############################################################################################"
echo " _    _   ____    _____  _______   _______  _____              _____  _  __ ______  _____"
echo "| |  | | / __ \  / ____||__   __| |__   __||  __ \     /\     / ____|| |/ /|  ____||  __ \ "
echo "| |__| || |  | || (___     | |       | |   | |__) |   /  \   | |     | ' / | |__   | |__) | "
echo "|  __  || |  | | \___ \    | |       | |   |  _  /   / /\ \  | |     |  <  |  __|  |  _  / "
echo "| |  | || |__| | ____) |   | |       | |   | | \ \  / ____ \ | |____ | . \ | |____ | | \ \ "
echo "|_|  |_| \____/ |_____/    |_|       |_|   |_|  \_\/_/    \_\ \_____||_|\_\|______||_|  \_\ "
echo ""
echo "Tudo pode se resover com shell script, mas não apenas em 4 clicks"
echo "Desenvolvido por : Ulisses (Stark) Ribeiro"
echo ""
echo "############################################################################################"
sleep 5

while true; do
    choice=$(dialog --title "HostTracker" --radiolist "Escolha uma opção" 15 50 15 \
    "1" "Instalar dependencias" OFF \
    "2" "Testar conexão SNMP" OFF \
    "3" "Adicionar HOSTs(SNMP) ao GLPI" OFF \
	"4" "Adicionar HOSTs(SNMP) range de IP" OFF \
    "5" "Adicionar ESXi" OFF \
    "6" "Verificar HOST UP" OFF \
    "7" "Sair" OFF \
    --stdout)

    case $choice in
        1) 
        #dependencias
            clear
            if [ ! -d "$ROOT_DIR/packages" ]; then
                mkdir "$ROOT_DIR/packages"
                echo "Pasta criada!"
            else
                echo "A pasta já existe!"
            fi
            cd "$ROOT_DIR/packages"
            rm glpi-agent*
            agent="/usr/bin/glpi-agent"

            if [ -e "$agent" ]; then
                    echo "Instalado"
            else
                wget https://github.com/glpi-project/glpi-agent/releases/download/1.8/glpi-agent_1.8-1_all.deb
                wget https://github.com/glpi-project/glpi-agent/releases/download/1.8/glpi-agent-task-network_1.8-1_all.deb
                wget https://github.com/glpi-project/glpi-agent/releases/download/1.8/glpi-agent-task-esx_1.8-1_all.deb
                dpkg -i glpi-agent_1.8-1_all.deb
                dpkg -i glpi-agent-task-esx_1.8-1_all.deb
                dpkg -i glpi-agent-task-network_1.8-1_all.deb
                apt install -f -y
            fi
            sleep 3
            ;;
        2)
        #teste de conexão SNMP
            ip_host=$(dialog --inputbox "Informe o IP do host" 8 25 --stdout)
            snmp_credential=$(dialog --insecure --passwordbox "Informe a credencial SNMP" 8 35 --stdout)
            output=$(mktemp)
            clear
            echo "Só foi possivel fazer em 4 clicks por que levei horas desenvolvendo!"
            echo "Carregando..." && \
            glpi-netinventory --host "$ip_host" --credentials "version:2c,community:$snmp_credential" > "$output" 2>&1
            dialog --textbox "$output" 20 90
            rm -f "$output"
            ;;
        3)
        #add host via SNMP
            clear
            if [ ! -d "$ROOT_DIR/single_host" ]; then
                mkdir "$ROOT_DIR/single_host"
                echo "Pasta criada!"
            else
                echo "A pasta já existe!"
            fi
            cd "$ROOT_DIR/single_host"
            ip_host=$(dialog --inputbox "Informe o IP do host" 8 25 --stdout)
            snmp_credential=$(dialog --inputbox "Informe a credencial SNMP" 8 25 --stdout)
			glpi-netinventory --host "$ip_host" --insecure --credentials "version:2c,community:$snmp_credential" > $ip_host.xml
			glpi-injector -v -f $ip_host.xml --url http://glpi:glpi@glpi.voxtecnologia.com.br
            ;;
        4)
        #add hosts baseado numa range de IP via SNMP
            clear
            if [ ! -d "$ROOT_DIR/multi_host" ]; then
                mkdir "$ROOT_DIR/multi_host"
                echo "Pasta criada!"
            else
                echo "A pasta já existe!"
            fi
            cd "$ROOT_DIR/multi_host"
            name_task=$(dialog --inputbox "Informe o nome para task" 8 30 --stdout)
            start_range=$(dialog --inputbox "Informe o primeiro IP da range" 8 25 --stdout)
            final_range=$(dialog --inputbox "Informe o ultimo IP da range" 8 25 --stdout)
            snmp_credential=$(dialog --insecure --passwordbox "Informe a credencial SNMP" 8 25 --stdout)

            glpi-netdiscovery --first "$start_range" --last "$final_range" --credentials "version:2c,community:$snmp_credential" > $name_task.xml
            python3 splitxml.py $name_task.xml
            ll *.xml |awk '{print $9}' > $name_task.txt

            while IFS= read -r hostsnmp; do
                echo "Processando $hostsnmp..."
                glpi-injector -v -f "$hostsnmp" --url http://glpi:glpi@glpi.voxtecnologia.com.br
            done < "$name_task.txt"
            ;;
		5)
            #add esxi unico
            clear
            if [ ! -d "$ROOT_DIR/esxi_xml" ]; then
                mkdir "$ROOT_DIR/esxi_xml"
                echo "Pasta criada!"
            else
                echo "A pasta já existe!"
            fi
            cd "$ROOT_DIR/esxi_xml"
            ESX_USER=$(dialog --inputbox "Informe o usuario de acesso ao ESXi" 8 30 --stdout)
            ESX_PASSWORD=$(dialog --insecure --passwordbox "Informe a senha de acesso aos ESXi" 8 30 --stdout)
            HOST_ESX=$(dialog --inputbox "Informe o IP do ESXi" 8 30 --stdout)
            clear
            glpi-esx --host "$HOST_ESX" --user "$ESX_USER" --password $ESX_PASSWORD --path $HOST_ESX.xml --debug
            clear
            glpi-injector -v -f "$HOST_ESX.xml" --url http://glpi:glpi@glpi.voxtecnologia.com.br
            sleep 5
            ;;

        6)
            #scan para ver hosts UP
            cd "$ROOT_DIR"
            network=$(dialog --inputbox "Informe a network, ex.: 10.0.10.0/24" 8 30 --stdout)
            clear
            echo "Carregando..." && \
            nmap -sn -n $network -oG - | grep "Up" | awk '{print $2}' > network.txt
            
            echo "Os hosts foram adicionados ao arquivo network.txt"
            sleep 5
        ;;
        7)
            clear
            exit 0
            ;;
        *)
            dialog --msgbox "Opção inválida!" 8 40
            ;;
    esac
done
