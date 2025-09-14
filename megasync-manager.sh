#!/bin/bash
################################################################################
# Script para iniciar múltiplas instâncias do MEGAsync com contas diferentes
# DISTRO-AGNOSTIC: Compatível com Debian, Ubuntu, Fedora e Arch Linux
#
# Autor: https://github.com/geraldohomero
# Link: https://github.com/geraldohomero/megasync_multiple_instances
#
# DISTRIBUIÇÕES SUPORTADAS:
# - Debian/Ubuntu/Mint/Pop!_OS/Zorin: apt (Testado)
# - Fedora/RHEL/CentOS: dnf (Testado)
# - Arch/Manjaro/EndeavourOS: pacman (AUR) (Não testado)
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
#   mkdir -p "$HOME/.config/MEGASync_Instance_1"...
#
# Os comentários durante o código vão te ajudar a compreendê-lo melhor.
# Leia com atenção! # 
################################################################################
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

# Carregar instâncias salvas se o arquivo existir
if [ -f "$CONTAS_FILE" ]; then
    while IFS='=' read -r nome caminho; do
        if [ -n "$nome" ] && [ -n "$caminho" ]; then
            CONTAS["$nome"]="$caminho"
        fi
    done < "$CONTAS_FILE"
fi

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
                    --text="Digite o nome da nova conta:" \
                    --entry-text="$nome_padrao")
    
    if [ $? -ne 0 ] || [ -z "$nome_conta" ]; then
        return 1
    fi
    
    # Verificar se já existe
    if [ "${CONTAS[$nome_conta]}" ]; then
        $ZENITY_CMD --error --text="Uma instância com esse nome já existe!"
        return 1
    fi
    
    # Caminho padrão baseado no nome da conta
    caminho_padrao="$HOME/.config/MEGASync_Instance_$numero_conta"
    
    # Diálogo para caminho do config
    caminho_config=$($ZENITY_CMD --entry \
                        --title="Caminho de Configuração" \
                        --text="Digite o caminho para o diretório de configuração:" \
                        --entry-text="$caminho_padrao")
    
    if [ $? -ne 0 ] || [ -z "$caminho_config" ]; then
        return 1
    fi
    
    # Adicionar ao array
    CONTAS["$nome_conta"]="$caminho_config"
    
    # Salvar no arquivo
    echo "$nome_conta=$caminho_config" >> "$CONTAS_FILE"
    
    $ZENITY_CMD --info --text="Instância '$nome_conta' adicionada com sucesso!"
    return 0
}

# 2. Construir os argumentos para o diálogo do zenity
zenity_args=()
for nome_conta in "${!CONTAS[@]}"; do
    zenity_args+=(FALSE "$nome_conta")
done
# Adicionar opção de adicionar nova instância
zenity_args+=(FALSE "Adicionar nova instância...")

# Loop principal para seleção de contas
while true; do
    # 3. Exibir o diálogo de lista de verificação para o usuário
    escolhas=$($ZENITY_CMD --list \
                    --title="Gerenciador de Instâncias MEGASync" \
                    --text="Quais instâncias do MEGASync você deseja iniciar?\n\nSelecione 'Adicionar nova instância...' para criar uma nova instância." \
                    --checklist \
                    --column="Marcar" --column="Instância" \
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
    for conta in "${contas_selecionadas[@]}"; do
        if [ "$conta" = "Adicionar nova instância..." ]; then
            adicionar_selecionada=true
            break
        fi
    done

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
        # Esta é a forma recomendada para isolar as instâncias. Tem funcionado bem.
        (HOME="$config_path" "$MEGASYNC_CMD" &)
        
        $ZENITY_CMD --notification --text="MEGASync '$conta' iniciado." --timeout=3
    else
        $ZENITY_CMD --error --text="Configuração não encontrada para a instância: $conta"
    fi
done

echo "Processo concluído."
