#!/bin/bash
# Script para iniciar múltiplas instâncias do MEGAsync com contas diferentes
# DISTRO-AGNOSTIC: Compatível com Debian, Ubuntu, Fedora e Arch Linux
#
# FUNCIONALIDADES:
# - Gerenciamento de múltiplas instâncias do MEGASync
# - Configuração de inicialização automática com o sistema
# - Interface gráfica intuitiva com Zenity
# - Detecção automática de distribuição Linux
# - Instalação automática de dependências
#
# Autor: https://github.com/geraldohomero
#
# Link: https://github.com/geraldohomero/megasync_multiple_instances
#
# DISTRIBUIÇÕES SUPORTADAS:
# - Debian/Ubuntu/Mint/Pop!_OS/Zorin: apt
# - Fedora/RHEL/CentOS: dnf
# - Arch/Manjaro/EndeavourOS: pacman (AUR)
#
# NOMENCLATURA RECOMENDADA:
# - Instâncias: MEGASync_Instance_1, MEGASync_Instance_2, MEGASync_Instance_3, etc.
# - Diretórios: ~/.config/MEGASync_Instance_1, ~/.config/MEGASync_Instance_2, etc.
#
# Declare um array associativo com os nomes das instâncias e seus diretórios.
# Formato: ["Nome da Instância"]="caminho/para/o/config"
#
# IMPORTANTE: O MEGAsync armazena seus dados de configuração em um diretório.
# Para usar instâncias diferentes, cada uma DEVE ter seu próprio diretório.
# Por padrão, o MEGAsync usa ~/.config/MEGAsync.
#
# NOMENCLATURA RECOMENDADA:
# Use nomes descritivos como MEGASync_Instance_1, MEGASync_Instance_2, etc.
# Crie cópias deste diretório ou diretórios novos para cada instância.
# Exemplo:
#   mkdir -p "$HOME/.config/MEGASync_Instance_1"
#   mkdir -p "$HOME/.config/MEGASync_Instance_2"
#

# === BILINGUAL SUPPORT ===
detect_lang() {
    case "${LANG%%_*}" in
        pt)
            LANG_CODE="pt-br" ;;
        en)
            LANG_CODE="en-us" ;;
        *)
            LANG_CODE="en-us" ;;
    esac
}

# Message function
msg() {
    case "$LANG_CODE" in
        pt-br)
            case "$1" in
                install_success) echo "Instalação concluída! Use o comando 'mega' para iniciar o gerenciador de instâncias MEGAsync.";;
                alias_added) echo "Alias 'mega' adicionado em ~/.bash_aliases.";;
                already_installed) echo "O script já está instalado em ~/megasync-manager.sh.";;
                copying_script) echo "Copiando script para ~/megasync-manager.sh...";;
                chmod_script) echo "Definindo permissão de execução...";;
                sourcing_alias) echo "Atualizando aliases do bash...";;
                *) echo "$2";;
            esac
            ;;
        en-us)
            case "$1" in
                install_success) echo "Installation complete! Use the 'mega' command to start the MEGAsync instance manager.";;
                alias_added) echo "Alias 'mega' added to ~/.bash_aliases.";;
                already_installed) echo "Script is already installed at ~/megasync-manager.sh.";;
                copying_script) echo "Copying script to ~/megasync-manager.sh...";;
                chmod_script) echo "Setting executable permission...";;
                sourcing_alias) echo "Reloading bash aliases...";;
                *) echo "$2";;
            esac
            ;;
    esac
}

# === INSTALL MODE ===
if [[ "$1" == "install" ]]; then
    detect_lang
    INSTALL_PATH="$HOME/megasync-manager.sh"
    ALIAS_CMD="alias mega='bash $INSTALL_PATH'"
    BASH_ALIASES="$HOME/.bash_aliases"
    
    if [ -f "$INSTALL_PATH" ]; then
        msg already_installed
    else
        msg copying_script
        cp "$0" "$INSTALL_PATH"
        msg chmod_script
        chmod +x "$INSTALL_PATH"
    fi
    
    # Add alias if not present
    if ! grep -q "alias mega=" "$BASH_ALIASES" 2>/dev/null; then
        echo "$ALIAS_CMD" >> "$BASH_ALIASES"
        msg alias_added
    fi
    msg sourcing_alias
    source "$BASH_ALIASES" 2>/dev/null
    msg install_success
    exit 0
fi

detect_lang

declare -A CONTAS=(
    ["MEGASync_Instance_1"]="$HOME/.config/MEGASync_Instance_1"
    # Adicione mais instâncias aqui, se necessário
    # ["MEGASync_Instance_2"]="$HOME/.config/MEGASync_Instance_2"
    # ["MEGASync_Instance_3"]="$HOME/.config/MEGASync_Instance_3"
)
# --- FIM DA CONFIGURAÇÃO ---

# Detectar distribuição Linux e configurar gerenciador de pacotes
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID=$ID
        DISTRO_NAME=$PRETTY_NAME
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO_ID=$DISTRIB_ID
        DISTRO_NAME=$DISTRIB_DESCRIPTION
    elif command -v lsb_release &> /dev/null; then
        DISTRO_ID=$(lsb_release -i | cut -d: -f2 | tr -d '[:space:]')
        DISTRO_NAME=$(lsb_release -d | cut -d: -f2 | tr -d '[:space:]')
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Distribuição Desconhecida"
    fi
    
    # Converter para lowercase para facilitar comparação
    DISTRO_ID=$(echo "$DISTRO_ID" | tr '[:upper:]' '[:lower:]')
    
    echo "Distribuição detectada: $DISTRO_NAME"
}

# Configurar comandos e pacotes baseado na distribuição
setup_package_manager() {
    case $DISTRO_ID in
        ubuntu|debian|linuxmint|zorin|pop|elementary|kali|raspbian|mx|antix|pureos)
            PACKAGE_MANAGER="apt"
            INSTALL_CMD="sudo apt update && sudo apt install -y"
            MEGASYNC_PACKAGE="megasync"
            ZENITY_PACKAGE="zenity"
            ;;
        fedora|rhel|centos|almalinux|rocky|ol|nobara)
            PACKAGE_MANAGER="dnf"
            INSTALL_CMD="sudo dnf install -y"
            MEGASYNC_PACKAGE="megasync"
            ZENITY_PACKAGE="zenity"
            ;;
        arch|manjaro|endeavouros|garuda|arcolinux|artix)
            PACKAGE_MANAGER="pacman"
            INSTALL_CMD="sudo pacman -S --noconfirm"
            MEGASYNC_PACKAGE="megasync"  # Official MEGA repository package
            ZENITY_PACKAGE="zenity"
            ;;
        *)
            echo "Distribuição não reconhecida: $DISTRO_NAME"
            echo "Tentando detectar gerenciador de pacotes automaticamente..."
            
            if command -v apt &> /dev/null; then
                PACKAGE_MANAGER="apt"
                INSTALL_CMD="sudo apt update && sudo apt install -y"
                MEGASYNC_PACKAGE="megasync"
                ZENITY_PACKAGE="zenity"
            elif command -v dnf &> /dev/null; then
                PACKAGE_MANAGER="dnf"
                INSTALL_CMD="sudo dnf install -y"
                MEGASYNC_PACKAGE="megasync"
                ZENITY_PACKAGE="zenity"
            elif command -v pacman &> /dev/null; then
                PACKAGE_MANAGER="pacman"
                INSTALL_CMD="sudo pacman -S --noconfirm"
                MEGASYNC_PACKAGE="megasync"
                ZENITY_PACKAGE="zenity"
            else
                echo "ERRO: Não foi possível detectar um gerenciador de pacotes conhecido."
                echo "Por favor, instale manualmente: megasync e zenity"
                exit 1
            fi
            ;;
    esac
    
    echo "Gerenciador de pacotes: $PACKAGE_MANAGER"
}

# 1. Verificar e instalar dependências (distro-agnostic)
# O script detecta automaticamente sua distribuição Linux e usa o gerenciador
# de pacotes apropriado (apt, dnf, pacman)
check_and_install() {
    local cmd=$1
    local package_name=$2
    local local_paths=("$HOME/bin/$cmd" "$HOME/local/bin/$cmd" "$HOME/.local/bin/$cmd")
    
    # Primeiro, verificar se está no PATH
    if command -v "$cmd" &> /dev/null; then
        echo "'$cmd' encontrado no PATH."
        return 0
    fi
    
    # Verificar caminhos locais comuns
    for path in "${local_paths[@]}"; do
        if [ -x "$path" ]; then
            echo "'$cmd' encontrado em: $path"
            # Definir variável global para o caminho
            if [ "$cmd" = "megasync" ]; then
                MEGASYNC_CMD="$path"
            elif [ "$cmd" = "zenity" ]; then
                ZENITY_CMD="$path"
            fi
            return 0
        fi
    done
    
    # Se não encontrou, oferecer instalar
    echo "A dependência '$cmd' não foi encontrada no PATH nem em caminhos locais comuns."
    read -p "Deseja instalá-la via $PACKAGE_MANAGER agora? (s/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo "Instalando '$package_name'... Por favor, digite sua senha se solicitado."
        
        # Avisos especiais para algumas distribuições
        case $DISTRO_ID in
            # Nenhum aviso especial necessário para as distribuições suportadas
        esac
        
        if command -v sudo &> /dev/null; then
            eval "$INSTALL_CMD $package_name"
        else
            echo "Comando 'sudo' não encontrado. Execute como root ou instale '$package_name' manualmente."
            echo "Comando sugerido: $INSTALL_CMD $package_name"
            exit 1
        fi
        
        if ! command -v "$cmd" &> /dev/null; then
            echo "A instalação falhou. Verifique o nome do pacote ou instale '$package_name' manualmente."
            echo "Comando sugerido: $INSTALL_CMD $package_name"
            exit 1
        fi
        echo "'$package_name' instalado com sucesso."
    else
        echo "Instalação cancelada. O script não pode continuar sem '$cmd'."
        echo "Instale manualmente: $INSTALL_CMD $package_name"
        exit 1
    fi
}

# Detectar distribuição e configurar
detect_distro
setup_package_manager

echo "=== MEGASync Multi-Instance Manager ==="
echo "Distribuição: $DISTRO_NAME"
echo "Gerenciador: $PACKAGE_MANAGER"
echo "========================================"
echo ""

# Verificar as dependências necessárias
check_and_install "megasync" "$MEGASYNC_PACKAGE"
check_and_install "zenity" "$ZENITY_PACKAGE"

# Definir comandos padrão se não foram definidos
MEGASYNC_CMD=${MEGASYNC_CMD:-megasync}
ZENITY_CMD=${ZENITY_CMD:-zenity}

# Arquivo para salvar instâncias adicionadas dinamicamente
CONTAS_FILE="$HOME/.config/megasync_contas.conf"

# Diretório para arquivos de inicialização automática
AUTOSTART_DIR="$HOME/.config/autostart"

# Carregar instâncias salvas se o arquivo existir
if [ -f "$CONTAS_FILE" ]; then
    while IFS='=' read -r nome caminho; do
        if [ -n "$nome" ] && [ -n "$caminho" ]; then
            CONTAS["$nome"]="$caminho"
        fi
    done < "$CONTAS_FILE"
fi

# Função para verificar se uma instância está configurada para iniciar automaticamente
is_autostart_enabled() {
    local instance_name="$1"
    local desktop_file="$AUTOSTART_DIR/megasync-${instance_name// /_}.desktop"
    [ -f "$desktop_file" ]
}

# Função para criar arquivo .desktop para inicialização automática
create_autostart_desktop() {
    local instance_name="$1"
    local config_path="$2"
    
    mkdir -p "$AUTOSTART_DIR"
    
    local desktop_file="$AUTOSTART_DIR/megasync-${instance_name// /_}.desktop"
    local exec_path=""
    
    # Determinar o caminho do executável
    if [ -n "$MEGASYNC_CMD" ]; then
        exec_path="$MEGASYNC_CMD"
    else
        exec_path="megasync"
    fi
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Type=Application
Name=MEGASync ($instance_name)
Exec=env HOME="$config_path" "$exec_path"
Icon=megasync
Comment=MEGASync instance for $instance_name
Terminal=false
StartupNotify=false
X-GNOME-Autostart-enabled=true
EOF
    
    chmod +x "$desktop_file"
}

# Função para remover arquivo .desktop de inicialização automática
remove_autostart_desktop() {
    local instance_name="$1"
    local desktop_file="$AUTOSTART_DIR/megasync-${instance_name// /_}.desktop"
    [ -f "$desktop_file" ] && rm "$desktop_file"
}

# Função para configurar inicialização automática
configure_autostart() {
    local title="Configurar Inicialização Automática"
    
    # Construir lista de instâncias com status atual
    local autostart_options=""
    for instance_name in "${!CONTAS[@]}"; do
        if is_autostart_enabled "$instance_name"; then
            autostart_options+="TRUE \"$instance_name (Ativado)\" "
        else
            autostart_options+="FALSE \"$instance_name (Desativado)\" "
        fi
    done
    
    # Remover trailing space
    autostart_options=${autostart_options% }
    
    # Mostrar diálogo de configuração
    local selections
    selections=$(eval "$ZENITY_CMD --list \
                        --title=\"$title\" \
                        --text=\"Selecione as instâncias que devem iniciar automaticamente com o sistema:\n\n• Marque as instâncias que deseja ativar\n• Desmarque as que deseja desativar\n• Clique em 'Voltar' para retornar ao menu principal\" \
                        --checklist \
                        --column=\"Ativar\" \
                        --column=\"Instância\" \
                        --width=650 --height=500 \
                        --extra-button=\"Voltar\" \
                        --ok-label=\"Aplicar\" \
                        --cancel-label=\"Cancelar\" \
                        $autostart_options \
                        --separator=\"|\"")
    
    local exit_code=$?
    
    # Verificar se o usuário clicou em "Voltar" ou cancelou
    if [ $exit_code -eq 1 ]; then
        # Usuário clicou em "Voltar" - retornar ao menu principal
        return 0
    elif [ $exit_code -ne 0 ]; then
        # Usuário cancelou ou fechou a janela
        return 1
    fi
    
    # Processar seleções
    IFS='|' read -ra selected_instances <<< "$selections"
    
    # Extrair apenas os nomes das instâncias (remover "(Ativado)" e "(Desativado)")
    local instances_to_enable=()
    for selection in "${selected_instances[@]}"; do
        # Remover sufixos e extrair nome da instância
        local instance_name=$(echo "$selection" | sed 's/ (Ativado)//' | sed 's/ (Desativado)//')
        instances_to_enable+=("$instance_name")
    done
    
    # Atualizar configuração de inicialização automática
    local changes_made=false
    for instance_name in "${!CONTAS[@]}"; do
        local should_enable=false
        
        # Verificar se esta instância deve ser ativada
        for enabled_instance in "${instances_to_enable[@]}"; do
            if [ "$enabled_instance" = "$instance_name" ]; then
                should_enable=true
                break
            fi
        done
        
        if $should_enable; then
            if ! is_autostart_enabled "$instance_name"; then
                create_autostart_desktop "$instance_name" "${CONTAS[$instance_name]}"
                changes_made=true
                echo "Inicialização automática ATIVADA para: $instance_name"
            fi
        else
            if is_autostart_enabled "$instance_name"; then
                remove_autostart_desktop "$instance_name"
                changes_made=true
                echo "Inicialização automática DESATIVADA para: $instance_name"
            fi
        fi
    done
    
    if $changes_made; then
        $ZENITY_CMD --info --text="Configuração de inicialização automática atualizada com sucesso!" --width=500 --height=100
    else
        $ZENITY_CMD --info --text="Nenhuma alteração foi feita na configuração." --width=500 --height=100
    fi
}

# Função para adicionar nova instância
adicionar_conta() {
    # Calcular o próximo número para MEGASync_Instance
    numero_conta=1
    while [ "${CONTAS[MEGASync_Instance_$numero_conta]}" ]; do
        ((numero_conta++))
    done
    
    # Nome padrão da conta
    nome_padrao="MEGASync_Instance_$numero_conta"
    
    # Diálogo para nome da conta
    nome_conta=$($ZENITY_CMD --entry \
                    --title="Adicionar Nova Conta MEGASync" \
                    --text="Digite o nome da nova conta:\n\n• Deixe em branco ou clique em 'Voltar' para cancelar" \
                    --entry-text="$nome_padrao" \
                    --width=500 --height=180 \
                    --extra-button="Voltar" \
                    --ok-label="Próximo" \
                    --cancel-label="Cancelar")
    
    local exit_code=$?
    
    # Verificar se o usuário clicou em "Voltar" ou cancelou
    if [ $exit_code -eq 1 ] || [ $exit_code -ne 0 ] && [ -z "$nome_conta" ]; then
        return 1
    fi
    
    # Verificar se já existe
    if [ "${CONTAS[$nome_conta]}" ]; then
        $ZENITY_CMD --error --text="Uma instância com esse nome já existe!" --width=400 --height=100
        return 1
    fi
    
    # Caminho padrão baseado no nome da conta
    caminho_padrao="$HOME/.config/MEGASync_Instance_$numero_conta"
    
    # Diálogo para caminho do config
    caminho_config=$($ZENITY_CMD --entry \
                        --title="Caminho de Configuração" \
                        --text="Digite o caminho para o diretório de configuração:\n\n• Clique em 'Voltar' para retornar e alterar o nome\n• Deixe em branco para cancelar" \
                        --entry-text="$caminho_padrao" \
                        --width=600 --height=180 \
                        --extra-button="Voltar" \
                        --ok-label="Criar Instância" \
                        --cancel-label="Cancelar")
    
    local exit_code=$?
    
    # Verificar se o usuário clicou em "Voltar" ou cancelou
    if [ $exit_code -eq 1 ]; then
        # Usuário clicou em "Voltar" - retornar para alterar o nome
        adicionar_conta
        return $?
    elif [ $exit_code -ne 0 ] || [ -z "$caminho_config" ]; then
        return 1
    fi
    
    # Adicionar ao array
    CONTAS["$nome_conta"]="$caminho_config"
    
    # Salvar no arquivo
    echo "$nome_conta=$caminho_config" >> "$CONTAS_FILE"
    
    $ZENITY_CMD --info --text="Instância '$nome_conta' adicionada com sucesso!" --width=400 --height=100
    return 0
}

# 2. Construir os argumentos para o diálogo do zenity
zenity_args=()
for nome_conta in "${!CONTAS[@]}"; do
    zenity_args+=(FALSE "$nome_conta")
done
# Adicionar opção de adicionar nova instância
zenity_args+=(FALSE "Adicionar nova instância...")
# Adicionar opção de configurar inicialização automática
zenity_args+=(FALSE "Configurar inicialização automática...")

# Loop principal para seleção de contas
while true; do
    # 3. Exibir o diálogo de lista de verificação para o usuário
    escolhas=$($ZENITY_CMD --list \
                    --title="Gerenciador de Instâncias MEGASync" \
                    --text="Quais instâncias do MEGASync você deseja iniciar?\n\nSelecione 'Adicionar nova instância...' para criar uma nova instância.\nSelecione 'Configurar inicialização automática...' para gerenciar inicialização com o sistema.\n\n• Use 'OK' para iniciar as instâncias selecionadas\n• Use 'Cancelar' para sair do programa" \
                    --checklist \
                    --column="Marcar" --column="Instância" \
                    --width=650 --height=500 \
                    --ok-label="Iniciar Selecionadas" \
                    --cancel-label="Sair" \
                    "${zenity_args[@]}" \
                    --separator="|")

    # Verificar se o usuário cancelou
    if [ $? -ne 0 ]; then
        echo "Nenhuma instância selecionada. Saindo."
        exit 0
    fi

    # 4. Processar as escolhas
    IFS='|' read -ra contas_selecionadas <<< "$escolhas"

    # Verificar se "Adicionar nova instância" foi selecionada
    adicionar_selecionada=false
    configurar_autostart_selecionada=false
    
    for conta in "${contas_selecionadas[@]}"; do
        if [ "$conta" = "Adicionar nova instância..." ]; then
            adicionar_selecionada=true
        elif [ "$conta" = "Configurar inicialização automática..." ]; then
            configurar_autostart_selecionada=true
        fi
    done

    if [ "$configurar_autostart_selecionada" = true ]; then
        # Remover "Configurar inicialização automática" da lista de selecionadas
        contas_selecionadas=("${contas_selecionadas[@]/Configurar inicialização automática...}")
        
        # Configurar inicialização automática
        if configure_autostart; then
            # Reconstruir a lista com a nova instância
            zenity_args=()
            for nome_conta in "${!CONTAS[@]}"; do
                zenity_args+=(FALSE "$nome_conta")
            done
            zenity_args+=(FALSE "Adicionar nova instância...")
            zenity_args+=(FALSE "Configurar inicialização automática...")
            continue  # Voltar ao loop para mostrar a lista atualizada
        fi
    fi

    if [ "$adicionar_selecionada" = true ]; then
        # Remover "Adicionar nova instância" da lista de selecionadas
        contas_selecionadas=("${contas_selecionadas[@]/Adicionar nova instância...}")
        
        # Adicionar nova conta
        if adicionar_conta; then
            # Reconstruir a lista com a nova instância
            zenity_args=()
            for nome_conta in "${!CONTAS[@]}"; do
                zenity_args+=(FALSE "$nome_conta")
            done
            zenity_args+=(FALSE "Adicionar nova instância...")
            zenity_args+=(FALSE "Configurar inicialização automática...")
            continue  # Voltar ao loop para mostrar a lista atualizada
        fi
    fi

    # Se não há contas selecionadas (apenas "Adicionar nova conta" foi removida)
    if [ ${#contas_selecionadas[@]} -eq 0 ]; then
        continue
    fi

    # Prosseguir com as contas selecionadas
    break
done

# 5. Iniciar o MEGAsync para cada instância selecionada
for conta in "${contas_selecionadas[@]}"; do
    config_path="${CONTAS[$conta]}"
    
    if [ -n "$config_path" ]; then
        echo "Iniciando MEGAsync para a instância: $conta"
        
        # Cria o diretório de configuração se não existir
        mkdir -p "$config_path"
        
        # Inicia o MEGAsync em segundo plano, definindo a variável HOME
        # para que ele use o diretório de configuração correto.
        # Esta é a forma recomendada para isolar as instâncias.
        (HOME="$config_path" "$MEGASYNC_CMD" &)
        
        $ZENITY_CMD --notification --text="MEGASync '$conta' iniciado." --timeout=3
    else
        $ZENITY_CMD --error --text="Configuração não encontrada para a instância: $conta" --width=500 --height=100
    fi
done

echo "Processo concluído."
