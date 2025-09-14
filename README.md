# MEGASync Multi-Instance Manager

Script distro-agn- **Persistência**: Instâncias adicionadas são salvas automaticamente

## Navegação na Interface

A interface gráfica foi projetada para ser intuitiva e oferecer controle total ao usuário:

### Menu Principal:
- **"Iniciar Selecionadas"**: Inicia as instâncias marcadas
- **"Sair"**: Fecha o programa
- **Opções especiais**: "Adicionar nova instância..." e "Configurar inicialização automática..."

### Configuração de Inicialização Automática:
- **"Aplicar"**: Salva as alterações e retorna ao menu principal
- **"Voltar"**: Retorna ao menu principal sem salvar alterações
- **"Cancelar"**: Fecha a janela sem fazer alterações

### Adicionar Nova Instância:
- **"Próximo"**: Avança para configurar o caminho
- **"Voltar"**: Retorna ao menu principal
- **"Cancelar"**: Fecha a janela

### Navegação Inteligente:
- Botões de "Voltar" permitem retornar etapas anteriores
- Cancelamento seguro em qualquer momento
- Confirmação de ações importantes

## Distribuições Suportadasic para gerenciar múltiplas instâncias do MEGASync em diferentes contas MEGA.

## Características

- **Distro-Agnostic**: Funciona automaticamente em Debian, Ubuntu, Fedora e Arch Linux
- **Interface Gráfica**: Usa Zenity para uma experiência amigável com janelas dimensionadas adequadamente e navegação intuitiva
- **Instâncias Isoladas**: Cada instância tem seu próprio diretório de configuração
- **Gerenciamento Dinâmico**: Adicione novas instâncias diretamente pela interface
- **Persistência**: Instâncias adicionadas são salvas automaticamente
- **Inicialização Automática**: Configure quais instâncias iniciam com o sistema

## Distribuições Suportadas

O script permite configurar quais instâncias do MEGASync devem iniciar automaticamente quando você faz login no sistema.

### Como configurar:

1. Execute o script normalmente
2. Selecione "Configurar inicialização automática..."
3. Marque/desmarque as instâncias desejadas
4. As configurações são aplicadas imediatamente

### Como funciona:

- Cria arquivos `.desktop` no diretório `~/.config/autostart/`
- Cada instância tem seu próprio arquivo de configuração
- Funciona com qualquer ambiente desktop que suporte XDG Autostart
- As instâncias são isoladas e usam seus próprios diretórios de configuração

### Gerenciar configurações:

- **Ativar**: Marque a instância na lista de configuração
- **Desativar**: Desmarque a instância na lista de configuração
- **Verificar status**: O status atual é mostrado na lista (Ativado/Desativado)

## Nomenclatura Recomendada*: Funciona automaticamente em Debian, Ubuntu, Fedora e Arch Linux
- **Interface Gráfica**: Usa Zenity para uma experiência amigável
- **Instâncias Isoladas**: Cada instância tem seu próprio diretório de configuração
- **Gerenciamento Dinâmico**: Adicione novas instâncias diretamente pela interface
- **Persistência**: Instâncias adicionadas são salvas automaticamente
- **Inicialização Automática**: Configure quais instâncias iniciam com o sistemaMulti-Instance Manager

Script distro-agnostic para gerenciar múltiplas instâncias do MEGASync em diferentes contas MEGA.

## Características

- **Distro-Agnostic**: Funciona automaticamente em Debian, Ubuntu, Fedora e Arch Linux
- **Interface Gráfica**: Usa Zenity para uma experiência amigável
- **Instâncias Isoladas**: Cada instância tem seu próprio diretório de configuração
- **Gerenciamento Dinâmico**: Adicione novas instâncias diretamente pela interface
- **Persistência**: Instâncias adicionadas são salvas automaticamente

## Distribuições Suportadas

| Distribuição | Gerenciador | Pacotes | Funcionando? |
|--------------|-------------|---------|--------------|
| **Debian/Ubuntu/Mint/Pop!_OS/Zorin** | `apt` | `megasync`, `zenity` | Sim |
| **Fedora/RHEL/CentOS** | `dnf` | `megasync`, `zenity` | Sim |
| **Arch/Manjaro/EndeavourOS** | `pacman` | `megasync`, `zenity` | Não testado |

## Instalação

1. **Clone ou baixe o script:**
   ```bash
   wget https://raw.githubusercontent.com/geraldohomero/megasync_multiple_instances/main/megasync-manager.sh
   ```

2. **Dê permissão de execução:**
   ```bash
   chmod +x megasync-manager.sh
   ```

3. **Execute o script:**
   ```bash
   ./megasync-manager.sh
   ```

O script detectará automaticamente sua distribuição e instalará as dependências necessárias.

## Nomenclatura Recomendada

- **Instâncias:** `MEGASync_Instance_1`, `MEGASync_Instance_2`, etc.
- **Diretórios:** `~/.config/MEGASync_Instance_1`, `~/.config/MEGASync_Instance_2`, etc.

## Configuração Manual

Edite a seção `INSTÂNCIAS` no script para adicionar suas instâncias:

```bash
declare -A CONTAS=(
    ["MEGASync_Instance_1"]="$HOME/.config/MEGASync_Instance_1"
    ["MEGASync_Instance_2"]="$HOME/.config/MEGASync_Instance_2"
    # Adicione mais instâncias aqui
)
```

## Notas Importantes

### Permissões
Certifique-se de que o usuário tem permissões para:
- Executar `sudo` (para instalação de pacotes)
- Criar diretórios em `~/.config/`
- Executar aplicações gráficas

### Isolamento
Cada instância do MEGASync usa um diretório de configuração separado, garantindo isolamento completo entre as contas.

## Troubleshooting

### Script não detecta a distribuição
Se o script não conseguir detectar sua distribuição, ele tentará detectar automaticamente o gerenciador de pacotes disponível.

### MEGASync não inicia
Verifique se:
- O diretório de configuração existe e tem permissões corretas
- Não há conflitos com outras instâncias rodando
- As dependências estão instaladas corretamente

### Interface gráfica não aparece
Certifique-se de que:
- Você está em um ambiente gráfico (X11 ou Wayland)
- O Zenity está instalado
- As variáveis de ambiente DISPLAY estão configuradas

### Inicialização Automática
Se as instâncias não estiverem iniciando automaticamente:

- **Verifique os arquivos**: Os arquivos `.desktop` devem estar em `~/.config/autostart/`
- **Permissões**: Certifique-se de que os arquivos têm permissão de execução
- **Ambiente Desktop**: Alguns ambientes podem ignorar arquivos `.desktop` corrompidos
- **Teste manual**: Execute o arquivo `.desktop` manualmente para testar
- **Logs**: Verifique os logs do sistema para mensagens de erro

### Comando para testar:
```bash
# Listar arquivos de inicialização
ls -la ~/.config/autostart/megasync-*

# Executar manualmente um arquivo .desktop
gtk-launch ~/.config/autostart/megasync-MEGASync_Instance_1.desktop
```

## Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para:
- Reportar bugs
- Sugerir melhorias
- Adicionar suporte para novas distribuições
- Traduzir para outros idiomas

## Suporte

Para suporte ou dúvidas:
- Abra uma issue no repositório
- Verifique os logs do script para mensagens de erro
- Certifique-se de que todas as dependências estão instaladas
