# MEGASync Multi-Instance Manager

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
| **Debian/Ubuntu/Mint/Pop!_OS/Zorin** | `apt` | `megasync`, `zenity` | Testado (Ubuntu, Mint)|
| **Fedora/RHEL/CentOS** | `dnf` | `megasync`, `zenity` | Testado (Fedora 42)|
| **Arch/Manjaro/EndeavourOS** | `pacman` | `megasync`, `zenity` | Não Testado |

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

## Licença

Este script é distribuído sob a licença MIT. Use por sua conta e risco.

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
