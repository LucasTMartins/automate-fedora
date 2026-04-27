#!/bin/bash

# ================================================================
#  FEDORA POST-INSTALL SETUP
#  Inspirado no fluxo de containerização do Bluefin
# ================================================================

set -euo pipefail

# ----------------------------------------------------------------
#  CORES E HELPERS
# ----------------------------------------------------------------
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
cyan='\033[0;36m'
bold='\033[1m'
nc='\033[0m'

print_header() {
  echo ""
  echo -e "${bold}${cyan}════════════════════════════════════════${nc}"
  echo -e "${bold}${cyan}  $1${nc}"
  echo -e "${bold}${cyan}════════════════════════════════════════${nc}"
}

print_status() { echo -e "${green}[*] $1${nc}"; }
print_info() { echo -e "${blue}[i] $1${nc}"; }
print_warn() { echo -e "${yellow}[!] $1${nc}"; }
print_ok() { echo -e "${green}[✓] $1${nc}"; }
print_err() { echo -e "${red}[✗] $1${nc}"; }

check_status() {
  if [ $? -eq 0 ]; then
    print_ok "$1"
  else
    print_err "erro ao $1"
    exit 1
  fi
}

# Pergunta sim/não — retorna 0 (sim) ou 1 (não)
ask() {
  local prompt="$1"
  local default="${2:-N}"
  local answer
  echo -en "${yellow}[?] ${prompt} (s/N): ${nc}"
  read -r answer
  [[ "$answer" =~ ^[yYsS]$ ]]
}

# Verifica se um comando já existe no PATH
has_cmd() { command -v "$1" &>/dev/null; }

# ================================================================
#  1. BASE DO SISTEMA
# ================================================================
setup_system_base() {
  print_header "BASE DO SISTEMA"

  print_status "Atualizando o sistema..."
  sudo dnf update -y
  check_status "atualizar o sistema"

  print_status "Habilitando RPM Fusion (free + nonfree)..."
  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
  check_status "habilitar RPM Fusion"

  print_status "Instalando grupo de ferramentas de desenvolvimento C..."
  sudo dnf group install -y "c-development"
  check_status "instalar ferramentas de desenvolvimento"

  print_status "Instalando dependências essenciais de build..."
  sudo dnf install -y \
    curl wget git git-lfs \
    openssl-devel \
    readline-devel \
    zlib-devel \
    bzip2-devel \
    libffi-devel \
    sqlite-devel \
    xz-devel \
    python3-devel \
    jq
  check_status "instalar dependências de build"
}

# ================================================================
#  2. FERRAMENTAS DE TERMINAL
# ================================================================
setup_terminal_tools() {
  print_header "FERRAMENTAS DE TERMINAL"

  print_status "Instalando utilitários de terminal..."
  sudo dnf install -y \
    micro \
    neovim \
    ranger \
    bat \
    btop \
    tmux \
    fzf \
    ripgrep \
    fd-find \
    eza \
    zoxide \
    starship \
    htop \
    ncdu \
    unzip zip p7zip
  check_status "instalar ferramentas de terminal"
}

# ================================================================
#  3. CONTAINERIZAÇÃO (estilo Bluefin)
# ================================================================
setup_containerization() {
  print_header "CONTAINERIZAÇÃO"

  # Podman — container engine rootless, base de tudo
  print_status "Instalando Podman (container engine rootless)..."
  sudo dnf install -y podman podman-compose podman-docker
  check_status "instalar Podman"

  # Distrobox — rodar outras distros sem sudo
  if ask "Deseja instalar Distrobox? (recomendado para dev sem permissões de admin)"; then
    print_status "Instalando Distrobox..."
    sudo dnf install -y distrobox
    check_status "instalar Distrobox"
    print_info "Use 'distrobox create --name <nome> --image <imagem>' para criar ambientes isolados."
  fi

  # Homebrew (Linuxbrew) — instalar apps de userspace sem sudo
  if ask "Deseja instalar o Homebrew? (gerenciador de pacotes sem root, essencial no fluxo Bluefin)"; then
    print_status "Instalando Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    check_status "instalar Homebrew"

    # Adicionar brew ao shell
    local brew_profile='
# Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    echo "$brew_profile" >>~/.bashrc
    [[ -f ~/.zshrc ]] && echo "$brew_profile" >>~/.zshrc
    print_info "Homebrew instalado. Reinicie o shell ou execute: eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\""
  fi

  # Docker — opcional, pois Podman já cobre a maioria dos casos
  if ask "Deseja instalar o Docker? (Podman já está instalado e cobre a maioria dos casos)"; then
    print_status "Instalando Docker..."
    sudo dnf config-manager addrepo \
      --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    check_status "instalar Docker"
    print_warn "Você foi adicionado ao grupo 'docker'. Faça logout/login para que a mudança tenha efeito."
  fi
}

# ================================================================
#  4. GERENCIAMENTO DE VERSÕES — MISE
# ================================================================
setup_mise() {
  print_header "GERENCIAMENTO DE VERSÕES (MISE)"

  if has_cmd mise; then
    print_info "Mise já está instalado. Pulando..."
    return
  fi

  print_status "Instalando Mise (substituto moderno do asdf)..."
  curl https://mise.run | sh
  check_status "instalar Mise"

  # Adicionar ao shell
  local mise_profile='
# Mise - gerenciador de versões
eval "$(~/.local/bin/mise activate bash)"'
  echo "$mise_profile" >>~/.bashrc

  if [[ -f ~/.zshrc ]]; then
    echo '
# Mise
eval "$(~/.local/bin/mise activate zsh)"' >>~/.zshrc
  fi

  # Ativar para a sessão atual
  eval "$(~/.local/bin/mise activate bash)" 2>/dev/null || true

  print_info "Mise instalado. Use 'mise use node@lts', 'mise use java@latest', etc."
}

# ================================================================
#  5. FLATPAK — CONFIGURAÇÃO E APPS
# ================================================================
setup_flatpak() {
  print_header "FLATPAK"

  print_status "Configurando Flatpak e repositório Flathub..."
  sudo dnf install -y flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  check_status "configurar Flatpak"
}

install_flatpak_browsers() {
  print_header "NAVEGADORES (Flatpak)"

  print_info "Navegadores rodam muito bem como Flatpak — sandbox nativa de segurança."

  flatpak install -y flathub org.mozilla.firefox
  flatpak install -y flathub org.chromium.Chromium
  flatpak install -y flathub com.brave.Browser
}

install_flatpak_communication() {
  print_header "COMUNICAÇÃO (Flatpak)"

  if ask "Deseja instalar apps de comunicação (telegram, discord)?"; then
    flatpak install -y flathub org.telegram.desktop
    flatpak install -y flathub com.discordapp.Discord
  fi
}

install_flatpak_productivity() {
  print_header "PRODUTIVIDADE (Flatpak)"

  flatpak install -y flathub md.obsidian.Obsidian
  flatpak install -y flathub org.libreoffice.LibreOffice
}

install_flatpak_media() {
  print_header "MÍDIA E ENTRETENIMENTO (Flatpak)"

  flatpak install -y flathub org.videolan.VLC
  flatpak install -y flathub com.obsproject.Studio
}

install_flatpak_tools() {
  print_header "UTILITÁRIOS (Flatpak)"

  print_status "Instalando utilitários essenciais via Flatpak..."
  flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    eu.scarpetta.PDFMixTool \
    org.gnome.FontManager
  flatpak install -y flathub com.rustdesk.RustDesk
  flatpak install -y flathub io.dbeaver.DBeaverCommunity
  flatpak install flathub org.qbittorrent.qBittorrent
  flatpak install flathub com.valvesoftware.Steam
  check_status "instalar utilitários Flatpak essenciais"
}

# ================================================================
#  6. PACOTES NATIVOS — APPS QUE PRECISAM DE INTEGRAÇÃO PROFUNDA
# ================================================================
setup_native_apps() {
  print_header "APLICAÇÕES NATIVAS"

  print_info "Estas apps são instaladas nativamente por precisarem de integração com o sistema."

  # Ferramentas GUI de sistema
  print_status "Instalando utilitários de sistema..."
  sudo dnf install -y \
    flameshot \
    qlipper
  check_status "instalar utilitários de sistema"

  # VSCode — nativo por causa de integração com Podman/Docker, SSH, extensões
  if ask "Deseja instalar o Visual Studio Code?"; then
    print_status "Instalando VSCode..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf install -y code
    check_status "instalar VSCode"
  fi

  sudo dnf install -y timeshift
  check_status "instalar Timeshift"
}

# ================================================================
#  7. ESTRUTURA DE DIRETÓRIOS
# ================================================================
setup_directories() {
  print_header "ESTRUTURA DE DIRETÓRIOS"

  print_status "Criando diretórios de trabalho..."
  mkdir -p \
    ~/workspace \
    ~/gitclones \
    ~/bin \
    ~/.local/bin
  check_status "criar diretórios"

  # Garantir que ~/bin está no PATH
  if ! grep -q 'export PATH="$HOME/bin' ~/.bashrc; then
    echo 'export PATH="$HOME/bin:$HOME/.local/bin:$PATH"' >>~/.bashrc
  fi
}

# ================================================================
#  MAIN
# ================================================================
main() {
  print_header "FEDORA POST-INSTALL SETUP"
  echo -e "${blue}Este script irá configurar seu ambiente Fedora.${nc}"
  echo -e "${blue}Você será consultado antes de cada instalação opcional.${nc}"
  echo ""

  setup_system_base
  setup_terminal_tools
  setup_containerization
  setup_mise
  setup_flatpak
  install_flatpak_browsers
  install_flatpak_communication
  install_flatpak_productivity
  install_flatpak_media
  install_flatpak_tools
  setup_native_apps
  setup_dev_tools
  setup_directories

  print_header "INSTALAÇÃO CONCLUÍDA"
  echo -e "${green}Tudo pronto! Algumas mudanças requerem reinicialização para ter efeito.${nc}"
  echo ""
  echo -e "${yellow}Próximos passos sugeridos:${nc}"
  echo -e "  • Reinicie o sistema"
  echo -e "  • Configure o Starship: https://starship.rs/config/"
  echo -e "  • Crie seu primeiro distrobox: distrobox create --name dev --image ubuntu:24.04"
  echo -e "  • Configure o Mise: mise use --global node@lts python@latest"
  echo ""

  if ask "Deseja reiniciar o sistema agora?"; then
    sudo reboot
  fi
}

main "$@"
