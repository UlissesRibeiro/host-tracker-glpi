- Altere a variavel : ROOT_DIR="/hosttracker" passando path absoluto, caso esteja rodando de outro path que não seja o /
- A opção 6 é indicado, quando for executar a opção 4 para add hosts em massa dentro de um range de IP, assim você vai saber
quais hosts estão UPs, economizando seu tempo, cada host DOWN dentro do range de IP toma em media 1 minuto para ir para o próximo hosts

# Indice

- [Instalando o GLPI](#instalando-o-glpi-server)
- [Instalando o Agent GLPI](#instalando-o-agent-glpi)
- [Comunicação SERVER X AGENT](#como-funciona-a-comunicação-entra-server-e-agent)
- [Configurações do Server](#configurando)
- [Usando API](#sobre-uso-da-api)
- [Scripts](#scripts)

## Instalando o GLPI (server)

- Optei por instalar sua versão em container(Docker) com persistência dos dados.
- O link da imagem esta disponivel <a href="https://hub.docker.com/r/diouxx/glpi/">aqui</a> !
- Faça o ajuste referente ao timezone para ficar correto com sua região.

## Instalando o Agent GLPI

- <b>Requisito</b> :
- Estar com a VPN conectada!

[Linux]

- Faça o download através do link :
https://github.com/glpi-project/glpi-agent/releases/download/1.9/glpi-agent-1.9-linux-installer.pl
- Agora é necessário dar permissão de execução apenas no binario, para isso abra o seu terminal(por padrão o atalho é ctrl+alt+t).
- Navegue até o path onde você salvou o binario, acredito que o padrão esteja em Downloads,então : cd /home/$USER/Downloads
- Dentro do path, rode o seguinte comando : sudo chmod 744 glpi-agent-1.9-linux-installer.pl
- Agora execute com o comando : sudo ./glpi-agent-1.9-linux-installer.pl
- No momento da instalação responda as 3 perguntas, sendo a primeira a mais importante que é a URL do server do GLPI, passe : http://10.0.10.224:8030
- Na segunda pergunta, apenas pressione ENTER
- Na terceira pergunta é referente a TAG(número de patrimonio), caso não esteja legivel, pode deixar em branco e pressionar ENTER.
- Para finalizar, rode o comando : sudo glpi-agent --server http://10.0.10.224:8030 , aguarde a finalização do comando!
- Processo finalizado!


[Windows]
- Faça o download através do link :
https://github.com/glpi-project/glpi-agent/releases/download/1.9/GLPI-Agent-1.9-x64.msi
- Abre o executavel do instalador, Next,Next,Next.
- Na tela de "Choose Setup Type", escolha "Custom", depois Next.
- Na tela de "Choose Targets", passe a url do server GLPI : http://10.0.10.224:803 , DESMARQUE a checkbox "Quick Installation" e Next.
- Next e Next, até chegar na tela "Choose an Executinon Mode", e selecione "As a Widnows Service" e também "Run inventory inmmediatly after installation", Next Next.
- Na tela "Miscelaneous Options", você pode adicionar o patrimonio no campo "Tag", caso não esteja legivel, deixe em branco e Next.
- Next,Next, e finalmente "Install", e ao terminar clique em "Finish".
- Abra o browser de sua preferência e acesso : localhost:62354 , e clique em "Force an inventory".
- Finalizado!

### Como funciona a comunicação entra Server e Agent

- No server é configurado a frequência em <b>horas</b> para a atualização do inventário, que se dá pela comunicação com o agent, assim como a alteração de status de <b>Ativo</b> para <b>Inativo</b>, sendo essa alteração baseado na quantidade de dias sem comunicação com o agent.

### Configurando

#### Instalando Plugin GPLI Inventory
- Acesse o menu :
    - Configurar > Plug-ins
    - Vai ser sugerido a troca para o <b>Marketplaca</b>, aceite a sugestão.
    - Será necessário ter uma "chave ssh" da GLPI Network, para isso vá em :
        - https://services.glpi-network.com/ 
        - Faça login com a conta que deseja configurar, depois vá em Registro e copie a chave.
        - Volte ao GLPI.
        - Configurar > Geral > GLPI Network , adicione a chave ao campo de texto e <b>salvar</b> .

#### Para alterar a frequência de coleta de inventário :
    
- Administração > Inventário
- Frequência do inventário(em horas) <b>a minima é de 1 hora</b> .
- Na mesma seção de inventário no fim da pagina ir em :
    - Limpeza do agente
    - Agentes de atualização que não entraram em contato com o servidor por (em dias) <b>minimo de 1 dia</b> .

- <b>Obs.: a coleta de dados de maquinas via SNMP(Chassis,Switchs,ESXi) por não terem a necessidade de coleta constante, será mantido o status de Ativo via script em crontab, garantindo sempre o status ativo. </b>


### Sobre uso da API

Primeiro é necessário que seja ativa indo em :
- Configurar > Geral > API
- Habilitar APIREST
- Habilitar os modos de autenticação :
    - Com credenciais
    - Token Externo

É necessário que seja criada uma sessão para poder usar a API, segue abaixo o modelo que funcionou para mim :

    curl -X POST \
    -H 'Content-Type: application/json' \
    -H "Authorization: user_token TOKEN_DO_USUARIO" \
    -H "App-Token: TOKEN_GERADO_AO_ATIVAR_A_API" \
    -d '{
    "login_name": "usuario",
    "login_password": "senha"
    }' \
    'http://URL_DA_API/apirest.php/initSession?get_full_session=true'

Com a sessão iniciada, anote o token da sessão.

### Exemplos de requisições

#### Obtendo os status

    curl -X GET \
    -H 'Content-Type: application/json' \
    -H "Session-Token: session_token" \
    -H "App-Token: app_token" \
    'http://url_da_api/apirest.php/State' | jq

#### Obtendo informações sobre um agent

    curl -X GET \
    -H 'Content-Type: application/json' \
    -H "Session-Token: session_token" \
    -H "App-Token: app_token" \
    'http://1url_da_api/apirest.php/Computer/32?expand_dropdowns=true' \
    | jq '{name: .name, states_id: .states_id}'

#### Obter informações mais especificas
- exemplo : memoria

    curl -X GET \
    -H 'Content-Type: application/json' \
    -H "Session-Token: session_token" \
    -H "App-Token: app_token" \
    'http://url_da_api/apirest.php/Computer/32/Item_DeviceMemory/' \
    | jq '[.[] | {size: .size}]'

### Scripts
- Com base na coleta de dados via API, desenvolvi alguns scripts para realizar as ações necessárias.

    - Na maquina server(centralizadora) um crontab é executado com um script fora dos containers, por não haver a necessidade de ser executado por eles.

        - [Manter os ESXis ativos]
    
            00 09 * * * /usr/bin/bash /vox/host-tracker-glpi/esxi_xml/add_esxi.sh /vox/host-tracker-glpi/esxi_xml/lista_xml.txt > /vox/log_cron_addesxi.log 2>&1

    - No container <b>PHPMAILER</b>:
        - <b>create_db_glpi_local.sh</b>
        - Esse script tem como intuito gerar uma base de dados local em formato .json com os dados de todos os agents, referente a :
            - name
            - states_id
            - serial
            - computertypes_id
            - memory
                - size
                - serial
            - hard_drives
                - id
                - capacity
                - serial
        - É para ser executado esse script uma unica vez ou se necessário fazer atualização em massa da base.

        - <b>computer_check.sh</b>
        - Segue a mesma ideia do primeiro script, porém esse vai ser executado semanalmente, onde gera um arquivo .json de nome diferente, pois servirá para comparação em caso de alteração de hardware.

        - <b>mamus.sh</b>
        - Nome provisorio, ele é o responsavél por coletar agents com status de Inativo, gerando um log para ser enviado por e-mail.

        - <b>session_api.sh</b>
        - Caso ocorra algum erro referente a sessão não criada, basta rodar esse script, coletar a ID da session e alterar no script mamus.sh

        - <b>carregajson.py</b>
        - Esse script em python é para fazer a comparação de .json de inventario base com inventario de alteração, retornado as alterações que vão ser enviadas por e-mail, se houver.