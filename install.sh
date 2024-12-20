#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Função para imprimir mensagens de status
print_status() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Função para verificar se o comando foi executado com sucesso
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] $1${NC}"
    else
        echo -e "${RED}[✗] Erro ao $1${NC}"
        exit 1
    fi
}

# Atualizar o sistema
print_status "Atualizando o sistema..."
sudo dnf update -y
check_status "atualizar o sistema"

# Habilitar RPM Fusion
print_status "Habilitando RPM Fusion..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
check_status "habilitar RPM Fusion"

# Instalar grupo de desenvolvimento C
print_status "Instalando ferramentas de desenvolvimento C..."
sudo dnf group install -y "c-development"
check_status "instalar ferramentas de desenvolvimento"

# Apps de Terminal
print_status "Instalando apps de terminal..."
sudo dnf install -y \
    micro \
    neovim \
    ranger \
    bat \
    btop \
    tmux \
    gh
check_status "instalar apps de terminal"

# Apps de Sistema
print_status "Instalando apps de sistema..."
sudo dnf install -y \
    qlipper \
    flameshot \
    filezilla \
    qbittorrent \
    steam \
    vlc \
    timeshift
check_status "instalar apps de sistema"

# Instalar Docker
print_status "Instalando Docker..."
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
check_status "instalar Docker"

# Adicionar usuário ao grupo Docker
print_status "Adicionando usuário ao grupo Docker..."
sudo usermod -aG docker $USER
check_status "adicionar usuário ao grupo Docker"

# Instalar Visual Studio Code
print_status "Instalando Visual Studio Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install -y code
check_status "instalar VSCode"

# Instalar Flatpak
print_status "Configurando Flatpak..."
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
check_status "configurar Flatpak"

# Instalar apps Flatpak
print_status "Instalando apps Flatpak..."
flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    com.discordapp.Discord \
    com.heroicgameslauncher.hgl \
    com.obsproject.Studio \
    com.parsecgaming.parsec \
    eu.scarpetta.PDFMixTool \
    io.dbeaver.DBeaverCommunity \
    md.obsidian.Obsidian \
    org.telegram.desktop \
    com.anydesk.Anydesk
check_status "instalar apps Flatpak"

# Criar diretórios
print_status "Criando diretórios..."
mkdir -p ~/workspace ~/gitclones
check_status "criar diretórios"

print_status "Instalação concluída! Por favor, reinicie o sistema para aplicar todas as alterações."
