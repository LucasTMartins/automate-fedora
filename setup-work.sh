#!/bin/bash

# cores para output
red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m' # no color

# função para imprimir mensagens de status
print_status() {
    echo -e "${green}[*] $1${nc}"
}

# função para verificar se o comando foi executado com sucesso
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${green}[✓] $1${nc}"
    else
        echo -e "${red}[✗] erro ao $1${nc}"
        exit 1
    fi
}

# atualizar o sistema
print_status "atualizando o sistema..."
sudo dnf update -y
check_status "atualizar o sistema"

# habilitar rpm fusion
print_status "habilitando rpm fusion..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -e %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -e %fedora).noarch.rpm
check_status "habilitar rpm fusion"

# instalar grupo de desenvolvimento c
print_status "instalando ferramentas de desenvolvimento c..."
sudo dnf group install -y "c-development"
check_status "instalar ferramentas de desenvolvimento"

# apps de terminal
print_status "instalando apps de terminal..."
sudo dnf install -y \
    micro \
    neovim \
    ranger \
    bat \
    btop \
    tmux \
    chromium
check_status "instalar apps de terminal"

# apps de sistema
print_status "instalando apps de sistema..."
sudo dnf install -y \
    qlipper \
    flameshot \
    filezilla \
    vlc \
    timeshift
check_status "instalar apps de sistema"

# instalar docker
print_status "instalando docker..."
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
check_status "instalar docker"

# adicionar usuário ao grupo docker
print_status "adicionando usuário ao grupo docker..."
sudo usermod -ag docker $user
check_status "adicionar usuário ao grupo docker"

# instalar visual studio code
print_status "instalando visual studio code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=visual studio code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install -y code
check_status "instalar vscode"

# instalar flatpak
print_status "configurando flatpak..."
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
check_status "configurar flatpak"

# instalar apps flatpak
print_status "instalando apps flatpak..."
flatpak install -y flathub \
    com.github.tchx84.flatseal \
    com.obsproject.studio \
    eu.scarpetta.pdfmixtool \
    io.dbeaver.dbeavercommunity \
    md.obsidian.obsidian \
    org.telegram.desktop \
    com.anydesk.anydesk \
    com.bitwarden.desktop
check_status "instalar apps flatpak"

# criar diretórios
print_status "criando diretórios..."
mkdir -p ~/workspace ~/gitclones
check_status "criar diretórios"

print_status "instalação concluída! por favor, reinicie o sistema para aplicar todas as alterações."
